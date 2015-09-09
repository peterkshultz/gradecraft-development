class BadgesController < ApplicationController

  before_filter :ensure_staff?, :except => [:student_predictor_data, :predict_times_earned]
  before_filter :ensure_student?, only: [:predict_times_earned]

  def index
    @title = "#{term_for :badges}"
    @badges = current_course.badges
  end

  def show
    @badge = current_course.badges.find(params[:id])
    @title = @badge.name
    @earned_badges = @badge.earned_badges
    @teams = current_course.teams
    if params[:team_id].present?
      @team = @teams.find_by(id: params[:team_id]) if params[:team_id]
      students = current_course.students_being_graded_by_team(@team)
    else
      students = current_course.students_being_graded
    end
    @students = students
  end

  def new
    @title = "Create a New #{term_for :badge}"
    @badge = current_course.badges.new
  end

  def edit
    @badge = current_course.badges.find(params[:id])
    @title = "Editing #{@badge.name}"
  end

  def create

    if params[:badge][:badge_files_attributes].present?
      @badge_files = params[:badge][:badge_files_attributes]["0"]["file"]
      params[:badge].delete :badge_files_attributes
    end

    @badge = current_course.badges.new(params[:badge])

    if @badge_files
      @badge_files.each do |af|
        @badge.badge_files.new(file: af, filename: af.original_filename[0..49])
      end
    end

    respond_to do |format|
      if @badge.save
        format.html { redirect_to @badge, notice: "#{@badge.name} #{term_for :badge} successfully created" }
        format.json { render json: @badge, status: :created, location: @badge }
      else
        # TODO: refactor, see submissions_controller
        @title = "Create a New #{term_for :badge}"
        format.html { render action: "new" }
        format.json { render json: @badge.errors, status: :unprocessable_entity }
      end
    end
  end

  def update

    if params[:badge][:badge_files_attributes].present?
      @badge_files = params[:badge][:badge_files_attributes]["0"]["file"]
      params[:badge].delete :badge_files_attributes
    end

    @badge = current_course.badges.find(params[:id])

    if @badge_files
      @badge_files.each do |af|
        @badge.badge_files.new(file: af, filename: af.original_filename[0..49])
      end
    end

    respond_to do |format|

      if @badge.update_attributes(params[:badge])
        format.html { redirect_to badges_path, notice: "#{@badge.name} #{term_for :badge} successfully updated" }
        format.json { head :ok }
      else
        # TODO: refactor, see submissions_controller
        @title = "Edit #{term_for :badge}"
        format.html { render action: "edit" }
        format.json { render json: @badge.errors, status: :unprocessable_entity }
      end
    end
  end

  def sort
    params[:"badge"].each_with_index do |id, index|
      current_course.badges.update(id, position: index + 1)
    end
    render nothing: true
  end

  def destroy
    @badge = current_course.badges.find(params[:id])
    @name = @badge.name
    @badge.destroy

    respond_to do |format|
      format.html { redirect_to badges_path, notice: "#{@name} #{term_for :badge} successfully deleted" }
      format.json { head :ok }
    end
  end

  def predict_times_earned
    @badge = current_course.badges.find(params[:badge_id])
    @badgePrediction = PredictedEarnedBadge.where(student: current_student, badge: @badge).first
    @badgePrediction.times_earned = params[:times_earned]
    respond_to do |format|
      format.json do
        if @badgePrediction.save
          render :json => {id: @badge.id, times_earned: @badgePrediction.times_earned}
        else
          render :json => { errors:  @badgePrediction.errors.full_messages }, :status => 400
        end
      end
    end
  end

  def student_predictor_data
    if current_user.is_student?(current_course)
      @student = current_student
      @update_badges = true
    elsif params[:id]
      @student = User.find(params[:id])
      @update_badges = false
    else
      @student = NullStudent.new
      @update_badges = false
    end

    @badges = predictor_badge_data
    @badges.each do |badge|
      badge.student_predicted_earned_badge = badge.find_or_create_predicted_earned_badge(@student)
    end
  end

  private

  def predictor_badge_data
    current_course.badges.select( :id,
                                  :name,
                                  :description,
                                  :point_total,
                                  :visible,
                                  :visible_when_locked,
                                  :can_earn_multiple_times,
                                  :position,
                                  :updated_at,
                                  :icon)
  end
end
