class GradesController < ApplicationController
  respond_to :html, :json
  before_filter :set_assignment, only: [:show, :edit, :update, :destroy, :submit_rubric]
  before_filter :ensure_staff?, except: [:feedback_read, :self_log, :show, :predict_score, :async_update]
  before_filter :ensure_student?, only: [:feedback_read, :predict_score]

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def show
    @assignment = current_course.assignments.find(params[:assignment_id])
    if current_user_is_student?
      redirect_to @assignment
    end
    if @assignment.rubric.present? && @assignment.is_individual?
      @rubric = @assignment.rubric
      @metrics = @rubric.metrics
      @rubric_grades = serialized_rubric_grades

      @viewable_rubric_grades = RubricGrade.joins("left outer join submissions on submissions.id = rubric_grades.submission_id").where(student_id: current_student.id).where(assignment_id: params[:assignment_id])
      @comments_by_metric_id = @viewable_rubric_grades.inject({}) do |memo, rubric_grade|
        memo.merge(rubric_grade.metric_id => rubric_grade.comments)
      end
    end

    fetch_grades_based_on_group
  end

  private

  def fetch_grades_based_on_group
    if @assignment.has_groups?
      @group = current_course.groups.find(params[:group_id])
      @title = "#{@group.name}'s Grade for #{ @assignment.name }"
      @grades_for_assignment = @assignment.grades.graded_or_released
    else
      @title = "#{current_student.name}'s Grade for #{ @assignment.name }"
      @grades_for_assignment = @assignment.grades_for_assignment(current_student)
    end
  end

  public

  def edit
    session[:return_to] = request.referer

    @student = current_student

    # TODO: what is this needed for?
    redirect_to @assignment and return unless current_student.present?

    @grade = Grade.where(student_id: @student[:id], assignment_id: @assignment[:id]).first
    create_student_assignment_grade unless @grade
    @title = "Editing #{@student.name}'s Grade for #{@assignment.name}"

    @submission = @student.submission_for_assignment(@assignment)

    @badges = @student.earnable_course_badges_for_grade(@grade)
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value

    if @assignment.rubric.present?
      @rubric = @assignment.rubric
      @rubric_grades = serialized_rubric_grades
    end

    @serialized_init_data = serialized_init_data
  end

  private

  def temp_view_context
    @temp_view_context ||= ApplicationController.new.view_context
  end

  def serialized_init_data
    JbuilderTemplate.new(temp_view_context).encode do |json|
      json.grade do
        json.partial! "grades/grade", grade: @grade, assignment: @assignment
      end

      json.badges do
        json.partial! "grades/badges", badges: @badges, student_id: @student[:id]
      end

      json.assignment do
        json.partial! "grades/assignment", assignment: @assignment
      end

      json.assignment_score_levels do
        json.partial! "grades/assignment_score_levels", assignment_score_levels: @assignment_score_levels
      end
    end.to_json
  end

  def empty_score_levels_hash
    {assignment_score_levels: []}.to_json
  end

  def fetch_serialized_assignment_score_levels
    ActiveModel::ArraySerializer.new(@assignment_score_levels, each_serializer: AssignmentScoreLevelSerializer).to_json
  end

  def create_student_assignment_grade
    @grade = Grade.create student_id: @student[:id], assignment_id: @assignment[:id], assignment_type_id: @assignment[:assignment_type_id]#, raw_score: 0
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

  def async_update
    Grade
      .where(id: params[:id])
      .update_all(async_update_params)
    render nothing: true
  end

  def earn_student_badge
    @earned_badge = EarnedBadge.create params[:earned_badge]
    logger.info @earned_badge.errors.full_messages
    render json: @earned_badge
  end

  def earn_student_badges
    @earned_badges = EarnedBadge.create params[:earned_badges]
    render json: @earned_badges
  end

  def delete_all_earned_badges
    if EarnedBadge.where(grade_id: params[:grade_id]).destroy_all
      destroy_earned_badge_with_duplicates
    else
      destroy_single_earned_badge
    end
  end

  def delete_earned_badge
    if all_earned_badge_ids_present?
      destroy_earned_badge_with_duplicates
    else
      destroy_single_earned_badge
    end
  end

  private

  def destroy_earned_badge_with_duplicates
    if EarnedBadge.where(duplicate_earned_badges_params).destroy_all
      delete_earned_badge_success
    else
      delete_earned_badge_failure
    end
  end

  def destroy_single_earned_badge
    if EarnedBadge.where(id: params[:id]).destroy_all
      delete_earned_badge_success
    else
      delete_earned_badge_failure
    end
  end

  def duplicate_earned_badges_params
    [:grade_id, :student_id, :badge_id].inject({}) do |memo, param|
      memo.merge(param.to_sym => params[param])
    end
  end

  def delete_earned_badge_success
    render json: {message: "Earned badge successfully deleted", success: true}, status: 200
  end

  def delete_earned_badge_failure
    render json: {message: "Earned badge failed to delete", success: false}, status: 417
  end

  def all_earned_badge_ids_present?
    params[:grade_id] and params[:student_id] and params[:badge_id]
  end

  def async_update_params
    if params[:save_type] == "feedback"
      base_async_params
    else
      base_async_params.merge(raw_score: sanitized_raw_score)
    end
  end

  def sanitized_raw_score
    if params[:raw_score].class == String
      params[:raw_score].gsub(/\D/, '')
    else
      params[:raw_score]
    end
  end

  def base_async_params
    {
      feedback: params[:feedback],
      instructor_modified: true,
      status: params[:status],
      updated_at: Time.now
    }
  end

  public

  # To avoid duplicate grades, we don't supply a create method. Update will
  # create a new grade if none exists, and otherwise update the existing grade
  def update
    redirect_to @assignment and return unless current_student.present?
    extract_file_attributes_from_grade_params
    @grade = current_student.grade_for_assignment(@assignment)

    if @grade_files
      add_grade_files_to_grade
    end

    sanitize_grade_params

    if @grade.update_attributes params[:grade].merge(instructor_modified: true)
      Resque.enqueue(GradeUpdater, [@grade.id]) if @grade.is_released?
      update_success_redirect
    else
      update_failure_redirect
    end
  end

  private

  def sanitize_grade_params
    params[:grade][:raw_score] = params[:grade][:raw_score].gsub(/\D/,"").to_i rescue nil
  end

  def update_failure_redirect
    redirect_to edit_assignment_grade_path(@assignment, :student_id => @grade.student.id), alert: "#{@grade.student.name}'s #{@assignment.name} was not successfully submitted! Please try again."
  end

  def update_success_redirect
    if session[:return_to].present?
      redirect_to session[:return_to], notice: "#{@grade.student.name}'s #{@assignment.name} was successfully updated"
    else
      redirect_to assignment_path(@assignment), notice: "#{@grade.student.name}'s #{@assignment.name} was successfully updated"
    end
  end

  def add_grade_files_to_grade
    @grade_files.each do |gf|
      @grade.grade_files.new(file: gf, filename: gf.original_filename[0..49])
    end
  end

  def extract_file_attributes_from_grade_params
    if params[:grade][:grade_files_attributes].present?
      @grade_files = params[:grade][:grade_files_attributes]["0"]["file"]
      params[:grade].delete :grade_files_attributes
    end
  end

  public

  def submit_rubric
    if @submission = Submission.where(current_assignment_and_student_ids).first
      @submission.update_attributes(graded: true)
    end

    @grade = Grade.where(student_id: current_student[:id], assignment_id: @assignment[:id]).first

    if @grade
      @grade.update_attributes grade_attributes_from_rubric
    else
      @grade = Grade.create(new_grade_from_rubric_grades_attributes)
    end

    delete_existing_rubric_grades
    create_rubric_grades # create an individual record for each rubric grade

    delete_existing_earned_badges_for_metrics # if earned_badges_exist? # destroy earned_badges where assignment_id and student_id match
    create_earned_tier_badges if params[:tier_badges]# create_earned_tier_badges

    Resque.enqueue(GradeUpdater, [@grade.id]) if @grade.is_student_visible?

    respond_to do |format|
      format.json { render nothing: true }
    end
  end

  private
  def rubric_grades_exist?
    rubric_grades.count > 0
  end

  def rubric_grades
    @rubric_grades ||= RubricGrade.where(assignment_student_metric_params)
  end

  def rubric_grades_by_metric_id
    @rubric_grades_by_metric_id = rubric_grades.inject({}) do |memo, rubric_grade|
      memo[rubric_grade.metric_id] = rubric_grade
      memo
    end
  end

  def update_rubric_grades
    params[:rubric_grades].each do |rubric_grade_params|
      rubric_grades_by_metric_id[rubric_grade_params["metric_id"]].update_attributes rubric_grade_params
    end
  end

  def earned_badges_exist?
    EarnedBadge.where(assignment_student_metric_params).count > 0
  end

  def delete_existing_rubric_grades
    RubricGrade.where(assignment_student_metric_params).delete_all
  end

  def delete_existing_earned_badges_for_metrics
    EarnedBadge.where(assignment_student_metric_params).delete_all
  end

  def existing_earned_badges_by_tier_badge_id
    @existing_earned_tier_badges ||= EarnedBadge.where(student_earned_tier_badge_attrs)
  end

  def student_earned_tier_badge_attrs
    { student_id: params[:student_id], tier_badge_id: existing_tier_badge_ids }
  end

  def assignment_student_metric_params
    { assignment_id: params[:assignment_id], student_id: params[:student_id], metric_id: params[:metric_ids] }
  end

  def create_rubric_grades
    params[:rubric_grades].collect do |rubric_grade|
      RubricGrade.create! rubric_grade.merge(extra_rubric_grade_params)
    end
  end

  def extra_rubric_grade_params
    { submission_id: submission_id,
      assignment_id: @assignment[:id],
      student_id: params[:student_id]
    }
  end

  def create_earned_tier_badges
    EarnedBadge.import(new_earned_tier_badges, :validate => true)
  end

  def new_earned_tier_badges
    params[:tier_badges].collect do |tier_badge|
      EarnedBadge.new({
        badge_id: tier_badge["badge_id"],
        submission_id: submission_id,
        course_id: current_course[:id],
        student_id: current_student[:id],
        assignment_id: @assignment[:id],
        tier_id: tier_badge[:tier_id],
        metric_id: tier_badge[:metric_id],
        score: tier_badge[:point_total],
        tier_badge_id: tier_badge[:id],
        student_visible: @grade.is_student_visible?
      })
    end
  end

  def submission_id
    @submission[:id] rescue nil
  end

  def serialized_course_badges
    ActiveModel::ArraySerializer.new(course_badges, each_serializer: CourseBadgeSerializer).to_json
  end

  def course_badges
    @course_badges ||= @assignment.course.badges.visible
  end

  public

  def remove
    @grade = Grade.find(params[:grade_id])
    @grade.raw_score = nil
    @grade.status = nil
    @grade.feedback = nil
    @grade.instructor_modified = false
    @grade.update_attributes(params[:grade])
    redirect_to @grade.assignment, notice: "#{ @grade.student.name}'s #{@grade.assignment.name} grade was successfully deleted."
  end

  def destroy
    redirect_to @assignment and return unless current_student.present?
    @grade = current_student.grade_for_assignment(@assignment)
    @grade.destroy

    redirect_to assignment_path(@assignment), notice: "#{ @grade.student.name}'s #{@assignment.name} grade was successfully deleted."
  end

  def feedback_read
    @assignment = current_course.assignments.find params[:id]
    @grade = @assignment.grades.find params[:grade_id]
    @grade.feedback_read!
    redirect_to assignment_path(@assignment), notice: "Thank you for letting us know!"
  end

  # Allows students to self log grades for a particular assignment if the instructor has turned that feature on - currently only used to log attendance
  def self_log
    @assignment = current_course.assignments.find(params[:id])
    if @assignment.open?
      @grade = current_student.grade_for_assignment(@assignment)
      if params[:present] == "true"
        if params[:grade].present? && params[:grade][:raw_score].present?
          @grade.raw_score = params[:grade][:raw_score]
        else
          @grade.raw_score = @assignment.point_total
        end
      else
        @grade.raw_score = 0
      end
      @grade.status = "Graded"
      respond_to do |format|
        if @grade.save
          Resque.enqueue(GradeUpdater, [@grade.id])
          format.html { redirect_to syllabus_path, notice: 'Nice job! Thanks for logging your grade!' }
        else
          format.html { redirect_to syllabus_path, notice: "We're sorry, this grade could not be added." }
        end
      end
    else
      format.html { redirect_to dashboard_path, notice: "We're sorry, this assignment is no longer open." }
    end
  end

  # Students predicting the score they'll get on an assignent using the grade predictor
  def predict_score
    @assignment = current_course.assignments.find(params[:id])
    if current_student.grade_released_for_assignment?(@assignment)
      @grade = nil
    else
      @grade = current_student.grade_for_assignment(@assignment)
      @grade.predicted_score = params[:predicted_score]
    end
    respond_to do |format|
      format.json do
        if @grade.nil?
          render :json => {errors: "You cannot predict this assignment!"}, :status => 400
        elsif @grade.save
          render :json => {id: @grade.id, predicted_score: @grade.predicted_score}
        else
          render :json => { errors:  @grade.errors.full_messages }, :status => 400
        end
      end
    end
  end

  # Quickly grading a single assignment for all students
  def mass_edit
    @assignment = current_course.assignments.find(params[:id])
    @title = "Quick Grade #{@assignment.name}"
    @assignment_type = @assignment.assignment_type
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value

    if params[:team_id].present?
      @team = current_course.teams.find_by(id: params[:team_id])
      @students = current_course.students_by_team(@team)
    else
      @students = current_course.students
    end

    @grades = Grade.where(student_id: mass_edit_student_ids, assignment_id: @assignment[:id] ).includes(:student,:assignment)

    create_missing_grades # create grade objects for the student/assignment pair unless present

    @grades = @grades.sort_by { |grade| [ grade.student.last_name, grade.student.first_name ] }
  end

  private

    def mass_edit_student_ids
      @mass_edit_student_ids ||= @students.pluck(:id)
    end

    def no_grade_students
      @no_grade_students ||= @students.where(id: mass_edit_student_ids - @grades.pluck(:student_id))
    end

    def create_missing_student_grades
      no_grade_students.each do |student|
        Grade.create(student: student, assignment: @assignment, graded_by_id: current_user)
      end
    end

    def create_missing_grades
      create_missing_student_grades
    end

  public

  def mass_update
    @assignment = current_course.assignments.find(params[:id])
    if @assignment.update_attributes(params[:assignment])
      grade_ids = []
      @assignment.grades.each do |grade|
        scored_changed = grade.previous_changes[:raw_score].present?
        if scored_changed && grade.graded_or_released?
          grade_ids << grade.id
        end
      end
      Resque.enqueue(MultipleGradeUpdater, grade_ids)
      if !params[:team_id].blank?
        redirect_to assignment_path(@assignment, :team_id => params[:team_id])
      else
        respond_with @assignment
      end
    else
      redirect_to mass_grade_assignment_path(id: @assignment.id,team_id:params[:team_id]),  notice: "Oops! There was an error while saving the grades!"
    end
  end

  # Grading an assignment for a whole group
  def group_edit
    @assignment = current_course.assignments.find(params[:id])
    @group = @assignment.groups.find(params[:group_id])
    @title = "Grading #{@group.name}'s #{@assignment.name}"
    @assignment_type = @assignment.assignment_type
    @assignment_score_levels = @assignment.assignment_score_levels
    @grades = @group.students.map do |student|
      @assignment.grades.where(:student_id => student).first || @assignment.grades.new(:student => student, :assignment => @assignment, :graded_by_id => current_user, :status => "Graded")
    end
    @submit_message = "Submit Grades"
  end

  def group_update
    @assignment = current_course.assignments.find(params[:id])
    @group = @assignment.groups.find(params[:group_id])
    @grades = @group.students.map do |student|
      @assignment.grades.where(:student_id => student).first || @assignment.grades.new(:student => student, :assignment => @assignment, :graded_by_id => current_user, :status => "Graded", :group_id => @group.id)
    end
    grade_ids = []
    @grades = @grades.each do |grade|
      grade.update_attributes(params[:grade])
      grade_ids << grade.id
    end

    Resque.enqueue(MultipleGradeUpdater, grade_ids)

    respond_with @assignment
  end

  # Changing the status of a grade - allows instructors to review "Graded" grades, before they are "Released" to students
  def edit_status
    session[:return_to] = request.referer

    @assignment = current_course.assignments.find(params[:id])
    @title = "#{@assignment.name} Grade Statuses"
    @grades = @assignment.grades.find(params[:grade_ids])
  end

  def update_status
    @assignment = current_course.assignments.find(params[:id])
    @grades = @assignment.grades.find(params[:grade_ids])
    grade_ids = []
    @grades.each do |grade|
      grade.update_attributes!(params[:grade].reject { |k,v| v.blank? })
      grade_ids << grade.id
    end
    Resque.enqueue(MultipleGradeUpdater, grade_ids)

    if session[:return_to].present?
      redirect_to session[:return_to]
    else
      redirect_to @assignment
    end

    flash[:notice] = "Updated Grades!"

  end

  #upload grades for an assignment
  def import
    @assignment = current_course.assignments.find(params[:id])
    @title = "Import Grades for #{@assignment.name}"
  end

  def upload
    if params[:file].blank?
      flash[:notice] = "File missing"
      redirect_to assignment_path(@assignment)
    else
      @assignment = current_course.assignments.find(params[:id])
      @students = current_course.students

      @result = GradeImporter.new(params[:file].tempfile).import(current_course, @assignment)
      Resque.enqueue(MultipleGradeUpdater, @result.successful.map(&:id))
      render :import_results
    end
  end

  private

  def new_grade_from_rubric_grades_attributes
    {
      course_id: current_course[:id],
      assignment_type_id: @assignment.assignment_type_id
    }
      .merge(current_assignment_and_student_ids)
      .merge(grade_attributes_from_rubric)
  end

  def current_assignment_and_student_ids
    {
      assignment_id: @assignment[:id],
      student_id: params[:student_id]
    }
  end

  def grade_attributes_from_rubric
    {
      raw_score: params[:points_given],
      submission_id: submission_id,
      point_total: params[:points_possible],
      status: params[:grade_status],
      instructor_modified: true
    }
  end

  def existing_metrics_as_json
    ActiveModel::ArraySerializer.new(rubric_metrics_with_tiers, each_serializer: ExistingMetricSerializer).to_json
  end

  def rubric_metrics_with_tiers
    @rubric_metrics_with_tiers ||= @rubric.metrics.order(:order).includes(:tiers)
  end

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id]) if params[:assignment_id]
  end
end
