class InfoController < ApplicationController
  helper_method :sort_column, :sort_direction, :predictions

  before_filter :ensure_staff?, :except => [ :dashboard ]

  # Displays instructor dashboard, with or without Team Challenge dates 
  def dashboard
    @grade_scheme_elements = current_course.grade_scheme_elements
    if current_course.team_challenges?
      @events = current_course.assignments.timelineable.to_a + current_course.challenges
    else
      @events = current_course.assignments.timelineable.to_a
    end
  end

  # Displaying all ungraded (but submitted) assignments in the system, needs to have a new section that highlights "Graded-not-Released"
  def grading_status
    @team = current_course.teams.find_by(id: params[:team_id]) if params[:team_id]
    @students = current_course.students
    user_search_options = {}
    user_search_options['team_memberships.team_id'] = params[:team_id] if params[:team_id].present?
    @ungraded_submissions = current_course.submissions.ungraded
    @count_ungraded = @ungraded_submissions.count
    @badges = current_course.badges.includes(:tasks)
  end

  #grade index export
  def gradebook
    respond_to do |format|
      format.html
      format.json { render json: current_course.assignments }
      format.csv { send_data current_course.assignments.gradebook_for_course(current_course) }
      format.xls { send_data current_course.assignments.to_csv(col_sep: "\t") }
    end
  end
  
  # Chart displaying all of the student weighting choices thus far
  def choices
    @title = "View all #{current_course.weight_term} Choices"
    @assignment_types = current_course.assignment_types
    @team = current_course.teams.find_by(id: params[:team_id]) if params[:team_id]
  end

  # Display all grades in the course in list form
   def all_grades
    @grades = current_course.grades.paginate(:page => params[:page], :per_page => 500)
  end

end
