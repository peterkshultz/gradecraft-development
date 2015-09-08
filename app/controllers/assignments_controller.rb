class AssignmentsController < ApplicationController

  before_filter :ensure_staff?, :except => [:show, :index, :guidelines, :student_predictor_data]

  respond_to :html, :json

  def index
    if current_user_is_student?
      redirect_to syllabus_path
    else
      @title = "#{term_for :assignments}"
      @assignment_types = current_course.assignment_types.includes(:assignments)
      @assignments = current_course.assignments.includes(:rubric)

      respond_to do |format|
        format.html
        format.csv { send_data @assignments.csv_for_course(current_course) }
      end
    end
  end

  #Gives the instructor the chance to quickly check all assignment settings for the whole course
  def settings
    @title = "Review #{term_for :assignment} Settings"
    @assignments = current_course.assignments
  end

  def show
    @assignment = current_course.assignments.find(params[:id])
    @assignment_type = @assignment.assignment_type
    @title = @assignment.name
    @groups = @assignment.groups

    # Returns a hash of grades given for the assignment in format of {student_id: grade}
    @grades = @assignment.grades
    @teams = current_course.teams
    if params[:team_id].present?
      @team = current_course.teams.find_by(id: params[:team_id])
      @students = current_course.students_by_team(@team)
    else
      @students = current_course.students
    end
    if @assignment.rubric.present?
      @rubric = @assignment.fetch_or_create_rubric
      @metrics = @rubric.metrics.ordered.includes(:tiers => :tier_badges)
    end
    @course_badges = serialized_course_badges
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value
    @course_student_ids = current_course.students.map(&:id)

    # Data for displaying student grading distribution
    @submissions_count = @assignment.submissions.count
    @ungraded_submissions_count = @assignment.ungraded_submissions.count
    @ungraded_percentage = @ungraded_submissions_count / @submissions_count rescue 0
    @graded_count = @submissions_count - @ungraded_submissions_count

    if current_user_is_student?
      @grades_for_assignment = @assignment.grades_for_assignment(current_student)
      @rubric_grades = RubricGrade.joins("left outer join submissions on submissions.id = rubric_grades.submission_id").where(student_id: current_user[:id]).where(assignment_id: params[:id])
      @comments_by_metric_id = @rubric_grades.inject({}) do |memo, rubric_grade|
        memo.merge(rubric_grade.metric_id => rubric_grade.comments)
      end
      if @assignment.has_groups? && current_student.group_for_assignment(@assignment).present?
        @group = current_student.group_for_assignment(@assignment)
      end

      if current_student.grade_released_for_assignment?(@assignment)
        grade = current_student.grade_for_assignment(@assignment)
        if grade && !grade.new_record?
          grade.feedback_reviewed!
        end
      end
    else
      @grades_for_assignment = @assignment.all_grades_for_assignment
    end
  end

  def new
    @title = "Create a New #{term_for :assignment}"
    @assignment = current_course.assignments.new
  end

  def edit
    @assignment = current_course.assignments.find(params[:id])
    @title = "Editing #{@assignment.name}"
  end

  # Duplicate an assignment - important for super repetitive items like attendance and reading reactions
  def copy
    session[:return_to] = request.referer
    @assignment = current_course.assignments.find(params[:id])
    new_assignment = @assignment.dup
    new_assignment.name.prepend("Copy of ")
    new_assignment.save
    if @assignment.assignment_score_levels.present?
      @assignment.assignment_score_levels.each do |asl|
        new_asl = asl.dup
        new_asl.assignment_id = new_assignment.id
        new_asl.save
      end
    end
    if @assignment.rubric.present?
      new_rubric = @assignment.rubric.dup
      new_rubric.assignment_id = new_assignment.id
      new_rubric.save
      if @assignment.rubric.metrics.present?
        @assignment.rubric.metrics.each do |metric|
          new_metric = metric.dup
          new_metric.rubric_id = new_rubric.id
          new_metric.add_default_tiers = false
          new_metric.save
          if metric.tiers.present?
            metric.tiers.each do |tier|
              new_tier = tier.dup
              new_tier.metric_id = new_metric.id
              new_tier.save
              if tier.tier_badges.present?
                tier.tier_badges.each do |tier_badge|
                  new_tier_badge = tier_badge.dup
                  new_tier_badge.tier_id = new_tier.id
                  new_tier_badge.save
                end
              end
            end
          end
        end
      end
    end
    if session[:return_to].present?
      redirect_to session[:return_to]
    else
      redirect_to assignments_path
    end
  end

  def create
    if params[:assignment][:assignment_files_attributes].present?
      @assignment_files = params[:assignment][:assignment_files_attributes]["0"]["file"]
      params[:assignment].delete :assignment_files_attributes
    end

    @assignment = current_course.assignments.new(params[:assignment])
    if @assignment_files
      @assignment_files.each do |af|
        @assignment.assignment_files.new(file: af, filename: af.original_filename[0..49])
      end
    end
    respond_to do |format|
      if @assignment.save
        set_assignment_weights
        format.html { respond_with @assignment, notice: "#{(term_for :assignment).titleize}  #{@assignment.name} successfully created" }
      else
        # TODO: refactor, see submissions_controller
        @title = "Create a New #{term_for :assignment}"
        format.html {render :action => "new", :group => @group }
      end
    end
  end

  def update
    if params[:assignment][:assignment_files_attributes].present?
      @assignment_files = params[:assignment][:assignment_files_attributes]["0"]["file"]
      params[:assignment].delete :assignment_files_attributes
    end

    @assignment = current_course.assignments.includes(:assignment_score_levels).find(params[:id])

    if @assignment_files
      @assignment_files.each do |af|
        @assignment.assignment_files.new(file: af, filename: af.original_filename[0..49])
      end
    end

    respond_to do |format|

      if @assignment.update_attributes(params[:assignment])
        set_assignment_weights
        format.html { redirect_to assignments_path, notice: "#{(term_for :assignment).titleize}  <strong>#{@assignment.name }</strong> successfully updated" }
      else
        # TODO: refactor, see submissions_controller
        @title = "Edit #{term_for :assignment}"
        format.html {render :action => "edit", :group => @group }
      end
    end
  end

  def sort
    params[:"assignment"].each_with_index do |id, index|
      current_course.assignments.update(id, position: index + 1)
    end
    render nothing: true
  end

  def update_rubrics
    @assignment = current_course.assignments.find params[:id]
    @assignment.update_attributes use_rubric: params[:use_rubric]
    respond_with @assignment
  end

  def rubric_grades_review
    @assignment = current_course.assignments.find(params[:id])
    @title = @assignment.name
    @groups = @assignment.groups

    @teams = current_course.teams

    if params[:team_id].present?
      @team = @teams.find_by(team_params)
      @students = current_course.students_being_graded.joins(:teams).where(:teams => team_params)
      @auditors = current_course.students_auditing.joins(:teams).where(:teams => team_params)
    else
      @students = current_course.students_being_graded
      @auditors = current_course.students_auditing
    end

    @students.sort_by { |student| [ student.last_name, student.first_name ] }

    @rubric = @assignment.fetch_or_create_rubric
    @metrics = @rubric.metrics.ordered
    @metrics.each do |m|
      m.tiers = m.tiers.includes(:tier_badges).order("points ASC")
    end
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value
    @course_student_ids = current_course.students.map(&:id)

    @viewable_rubric_grades = @assignment.rubric_grades
  end

  # current student visible assignment
  def student_predictor_data
    if current_user.is_student?(current_course)
      @student = current_student
      @update_assignments = true
    elsif params[:id]
      @student = User.find(params[:id])
      @update_assignments = false
    else
      @student = NullStudent.new(current_course)
      @update_assignments = false
    end

    @assignments = predictor_assignments_data
    @grades = predictor_grades(@student)

    @assignments.each do |assignment|
      @grades.where(:assignment_id => assignment.id).first.tap do |grade|
        if grade.nil?
          grade = Grade.create(:assignment => assignment, :student => @student)
        end
        assignment.current_student_grade = grade

        # Only pass through points if they have been released by the professor
        unless grade.is_student_visible?
          assignment.current_student_grade.pass_fail_status = nil
          assignment.current_student_grade.score = nil
        end

        # don't allow professors to view predictions
        unless current_user.is_student?(current_course)
          assignment.current_student_grade.predicted_score = 0
        end
      end
    end
  end

  private

    def predictor_assignments_data
      @assignments = current_course.assignments.select(
        :accepts_attachments,
        :accepts_links,
        :accepts_resubmissions_until,
        :accepts_submissions,
        :accepts_submissions_until,
        :accepts_text,
        :assignment_type_id,
        :course_id,
        :description,
        :due_at,
        :grade_scope,
        :id,
        :include_in_predictor,
        :media,
        :media_caption,
        :media_credit,
        :name,
        :open_at,
        :pass_fail,
        :point_total,
        :points_predictor_display,
        :position,
        :updated_at,
        :release_necessary,
        :required,
        :resubmissions_allowed,
        :student_logged,
        :student_logged_button_text,
        :student_logged_revert_button_text,
        :thumbnail,
        :use_rubric,
        :visible,
        :visible_when_locked
      )
    end

    def predictor_grades(student)
      @grades = student.grades.where(:course_id => current_course).select(
        :assignment_id,
        :assignment_type_id,
        :course_id,
        :id,
        :predicted_score,
        :pass_fail_status,
        :status,
        :student_id,
        :raw_score,
        :final_score,
        :updated_at,
        :score
      )
    end

    def team_params
      @team_params ||= params[:team_id] ? { id: params[:team_id] } : {}
    end

    def serialized_rubric_grades
      ActiveModel::ArraySerializer.new(fetch_rubric_grades, each_serializer: ExistingRubricGradesSerializer).to_json
    end

    def fetch_rubric_grades
      RubricGrade.where(fetch_rubric_grades_params)
    end

    def fetch_rubric_grades_params
      { student_id: params[:student_id], assignment_id: params[:assignment_id], metric_id: existing_metric_ids }
    end

    def existing_metric_ids
      rubric_metrics_with_tiers.collect {|metric| metric[:id] }
    end

  public

  def destroy
    @assignment = current_course.assignments.find(params[:id])
    @name = @assignment.name
    @assignment.destroy
    redirect_to assignments_url, notice: "#{(term_for :assignment).titleize} #{@name} successfully deleted"
  end

  def grade_import
    @assignment = current_course.assignments.find(params[:id])
    respond_to do |format|
      format.csv { send_data @assignment.grade_import(current_course.students) }
    end
  end

  def export_grades
    @assignment = current_course.assignments.find(params[:id])
    respond_to do |format|
      format.csv { send_data @assignment.gradebook_for_assignment }
    end
  end

  def export_submissions

    @assignment = current_course.assignments.find(params[:id])

    if params[:team_id].present?
      team = current_course.teams.find_by(id: params[:team_id])
      zip_name = "#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}_#{team.name}"
      @students = current_course.students_being_graded_by_team(team)
    else
      zip_name = "#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}"
      @students = current_course.students_being_graded
    end

    respond_to do |format|
      format.zip do

        export_dir = Dir.mktmpdir
        export_zip zip_name, export_dir do

          require 'open-uri'
          error_log = ""

          open( "#{export_dir}/_grade_import_template.csv",'w' ) do |f|
            f.puts @assignment.grade_import(@students)
          end

          @students.each do |student|
            if submission = student.submission_for_assignment(@assignment)
              if submission.has_multiple_components?
                student_dir = File.join(export_dir, "#{student.last_name}_#{student.first_name}")
                Dir.mkdir(student_dir)
              else
                student_dir = export_dir
              end

              if submission.text_comment.present? or submission.link.present?
                open(File.join(student_dir, "#{student.last_name}_#{student.first_name}_#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}_submission_text.txt"),'w' ) do |f|
                  f.puts "Submission items from #{student.last_name}, #{student.first_name}\n"
                  f.puts "\ntext comment: #{submission.text_comment}\n" if submission.text_comment.present?
                  f.puts "\nlink: #{submission.link }\n" if submission.link.present?
                end
              end

              if submission.submission_files
                submission.submission_files.each_with_index do |submission_file, i|

                  if Rails.env.development?
                    FileUtils.cp File.join(Rails.root,'public',submission_file.url), File.join(student_dir, "#{student.last_name}_#{student.first_name}_#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}-#{i + 1}#{File.extname(submission_file.filename)}")
                  else
                    begin
                      destination_file = File.join(student_dir, "#{student.last_name}_#{student.first_name}_#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}-#{i + 1}#{File.extname(submission_file.filename)}")
                      open(destination_file,'w' ) do |f|
                        f.binmode
                        stringIO = open(submission_file.url)
                        f.write stringIO.read
                      end
                    rescue OpenURI::HTTPError => e
                      error_log += "\nInvalid link for file. Student: #{student.last_name}, #{student.first_name}, submission_file-#{submission_file.id}: #{submission_file.filename}, error: #{e}\n"
                      FileUtils.remove_entry destination_file if File.exist? destination_file
                    rescue Exception => e
                      error_log += "\nError on file. Student: #{student.last_name}, #{student.first_name}, submission_file#{submission_file.id}: #{submission_file.filename}, error: #{e}\n"
                      FileUtils.remove_entry destination_file if File.exist? destination_file
                    end
                  end
                end
              end
            end
          end

          if ! error_log.empty?
            open( "#{export_dir}/_error_Log.txt",'w' ) do |f|
              f.puts "Some errors occurred on download:\n"
              f.puts error_log
            end
          end
        end
      end # format.zip
    end
  end

  private

  def find_or_create_assignment_rubric
    @assignment.rubric || Rubric.create(assignment_id: @assignment[:id])
  end

  def assignment_params
    params.require(:assignment).permit(:assignment_rubrics_attributes => [:id, :rubric_id, :_destroy])
  end

  def set_assignment_weights
    return unless @assignment.student_weightable?
    @assignment.weights = current_course.students.map do |student|
      assignment_weight = @assignment.weights.where(student: student).first || @assignment.weights.new(student: student)
      assignment_weight.weight = @assignment.assignment_type.weight_for_student(student)
      assignment_weight
    end
    @assignment.save
  end

  def serialized_course_badges
    MultiJson.dump(ActiveModel::ArraySerializer.new(course_badges, each_serializer: CourseBadgeSerializer))
  end

  def course_badges
    @course_badges ||= @assignment.course.badges.visible
  end

  def rubric_metrics_with_tiers
    @rubric.metrics.order(:order)
  end

end
