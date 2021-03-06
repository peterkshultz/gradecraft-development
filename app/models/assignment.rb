class Assignment < ActiveRecord::Base
  include UploadsMedia
  include UploadsThumbnails

  attr_accessible :name, :assignment_type_id, :assignment_type, :description, :point_total,
    :open_at, :due_at, :accepts_submissions_until, :release_necessary, :student_logged,
    :accepts_submissions, :accepts_links, :accepts_text, :accepts_attachments, :resubmissions_allowed,
    :grade_scope, :visible, :visible_when_locked, :required, :pass_fail, :use_rubric, :hide_analytics,
    :points_predictor_display, :notify_released, :mass_grade_type,
    :include_in_timeline, :include_in_predictor, :include_in_to_do,
    :grades_attributes, :assignment_file_ids, :assignment_files_attributes, :assignment_file,
    :assignment_score_levels_attributes, :assignment_score_level,
    :unlock_conditions, :unlock_conditions_attributes

  attr_accessor :current_student_grade

  belongs_to :course
  belongs_to :assignment_type, -> { order('order_placement ASC') }, touch: true

  has_one :rubric
  delegate :mass_grade?, :student_weightable?, :to => :assignment_type

  # For instances where the assignment needs its own unique score levels
  has_many :assignment_score_levels, -> { order "value" }
  accepts_nested_attributes_for :assignment_score_levels, allow_destroy: true, :reject_if => proc { |a| a['value'].blank? || a['name'].blank? }

  # This is the assignment weighting system (students decide how much assignments will be worth for them)
  has_many :weights, :class_name => 'AssignmentWeight'

  # Student created groups, can connect to multiple assignments and receive group level or individualized feedback
  has_many :assignment_groups
  has_many :groups, :through => :assignment_groups

  # Multipart assignments
  has_many :tasks, :as => :assignment, :dependent => :destroy

  # Unlocks
  has_many :unlock_conditions, :as => :unlockable, :dependent => :destroy
  has_many :unlock_keys, :class_name => 'UnlockCondition', :foreign_key => :condition_id, :dependent => :destroy

  accepts_nested_attributes_for :unlock_conditions, allow_destroy: true, :reject_if => proc { |a| a['condition_type'].blank? || a['condition_id'].blank? }

  has_many :unlock_states, :as => :unlockable, :dependent => :destroy

  # Student created submissions to be graded
  has_many :submissions, as: :assignment

  has_many :rubric_grades

  has_many :grades, :dependent => :destroy
  accepts_nested_attributes_for :grades, :reject_if => Proc.new { |attrs| attrs[:raw_score].blank? }

  has_many :users, :through => :grades

  # Instructor uploaded resource files
  has_many :assignment_files, :dependent => :destroy
  accepts_nested_attributes_for :assignment_files

  has_many :assignment_weights

  # Preventing malicious content from being submitted
  before_save :clean_html

  # Strip points from pass/fail assignments
  before_save :zero_points_for_pass_fail

  # Check to make sure the assignment has a name before saving
  validates_presence_of :name

  validates_presence_of :assignment_type_id

  validate :open_before_close, :submissions_after_due, :submissions_after_open

  # Filtering Assignments by Team Work, Group Work, and Individual Work
  scope :individual_assignments, -> { where grade_scope: "Individual" }
  scope :group_assignments, -> { where grade_scope: "Group" }
  scope :team_assignments, -> { where grade_scope: "Team" }

  # Filtering Assignments by where in the interface they are displayed
  scope :timelineable, -> { where(:include_in_timeline => true) }
  scope :predictable, -> { where(:include_in_predictor => true) }
  scope :todoable, -> { where(:include_in_to_do => true) }

  # Invisible Assignments are displayed on the instructor side, but not students (until they have a grade for them)
  scope :visible, -> { where visible: TRUE }

  # Sorting assignments by different properties
  scope :chronological, -> { order('due_at ASC') }
  scope :alphabetical, -> { order('name ASC') }
  acts_as_list scope: :assignment_type

  default_scope { order('position ASC') }

  # Filtering Assignments by various date properties
  scope :with_dates, -> { where('assignments.due_at IS NOT NULL OR assignments.open_at IS NOT NULL') }
  scope :with_due_date, -> { where('assignments.due_at IS NOT NULL') }
  scope :without_due_date, ->  { where('assignments.due_at IS NULL') }
  scope :future, -> { with_due_date.where('assignments.due_at >= ?', Time.now) }
  scope :still_accepted, -> { with_due_date.where('assignments.accepts_submissions_until >= ?', Time.now) }
  scope :past, -> { with_due_date.where('assignments.due_at < ?', Time.now) }

  # Assignments and Grading
  scope :graded_for_student, ->(student) { where('EXISTS(SELECT 1 FROM grades WHERE assignment_id = assignments.id AND (status = ?) OR (status = ? AND NOT assignments.release_necessary) AND (assignments.due_at < NOW() OR student_id = ?))', 'Released', 'Graded', student.id) }
  scope :weighted_for_student, ->(student) { joins("LEFT OUTER JOIN assignment_weights ON assignments.id = assignment_weights.assignment_id AND assignment_weights.student_id = '#{sanitize student.id}'") }

  scope :released, ->(student) { where('EXISTS (SELECT 1 FROM released_grades WHERE ((released_grades.assignment_id = assignments.id) AND (released_grades.student_id = ?)))', student.id) }

  def to_json(options = {})
    super(options.merge(:only => [ :id, :content, :order, :done ] ))
  end

  def content
    content = ""
    if course.show_see_details_link_in_timeline?
      content << "<p><a href='/assignments/#{self.id}'>See the details</a></p>"
    end
    if assignment_files.present?
      content << '<ul class="attachments">'
      assignment_files.each do |af|
        content << "<li class='document'><i class='fa fa-file-o fa-fw'></i><a href='#{af.url}'>#{af.filename}</a></li>"
      end
      content << '</ul>'
    end
    if description.present?
      content << description
    end
    return content
  end

  def point_total
    super.presence || 0
  end

  def self.assignment_type_point_totals_for_student(student)
    group('assignments.assignment_type_id').weighted_for_student(student).pluck('assignments.assignment_type_id, COALESCE(SUM(COALESCE(assignment_weights.point_total, self.course.total_points)), 0)')
  end

  def self.point_total_for_student(student)
    weighted_for_student(student).pluck('SUM(COALESCE(assignment_weights.point_total, self.course.total_points))').first || 0
  end

  def self.with_assignment_weights_for_student(student)
    joins("LEFT OUTER JOIN assignment_weights ON assignments.id = assignment_weights.assignment_id AND assignment_weights.student_id = '#{sanitize student.id}'").select('assignments.*, COALESCE(assignment_weights.point_total, self.course.total_points) AS student_point_total')
  end

  # Used for calculating scores in the analytics tab in Assignments# show
  def grades_for_assignment(student)
    user_score = grades.where(:student_id => student.id).first.try(:raw_score)
    scores = grades.graded_or_released.pluck('raw_score')
    return {
    :scores => scores,
    :user_score => user_score
   }
  end

  def all_grades_for_assignment
    scores = grades.graded_or_released.pluck('raw_score')
    return {
    :scores => scores
   }
  end

  # Basic result stats - high, low, average, median
  def high_score
    grades.graded_or_released.maximum('grades.raw_score')
  end

  def low_score
    grades.graded_or_released.minimum('grades.raw_score')
  end

  # Average of all grades for an assignment
  def average
    grades.graded_or_released.average('grades.raw_score').to_i if grades.graded_or_released.present?
  end

  # Average of above-zero grades for an assignment
  def earned_average
    if grades.graded_or_released.present?
      grades.graded_or_released.where("score > 0").average('score').to_i
    else
      0
    end
  end

  def median
    sorted_grades = grades.graded_or_released.pluck('score').sort
    len = sorted_grades.length
    return (sorted_grades[(len - 1) / 2] + sorted_grades[len / 2]) / 2
  end

  def has_rubric?
    !! rubric
  end

  def visible_for_student?(student)
    if is_unlockable?
      if visible_when_locked? || is_unlocked_for_student?(student)
        return true
      end
    else
      if visible?
        return true
      end
    end
  end

  def fetch_or_create_rubric
    return rubric if rubric
    Rubric.create assignment_id: self[:id]
  end

  def ungraded_submissions
    submissions.where("id not in (select submission_id from rubric_grades)")
  end

  # Checking to see if an assignment is individually graded
  def is_individual?
    !['Group'].include? grade_scope
  end

  # Checking to see if the assignment is a group assignment
  def has_groups?
    grade_scope=="Group"
  end

  # Checking to see if the assignment has unlock conditions
  def is_unlockable?
    unlock_conditions.present?
  end

  def is_a_condition?
    UnlockCondition.where(:condition_id => self.id, :condition_type => "Assignment").present?
  end

  def unlockable
    UnlockCondition.where(:condition_id => self.id, :condition_type => "Assignment").first.unlockable
  end

  def is_predicted_by_student?(student)
    grades.where(:student => student).first.predicted_score > 0 rescue nil
  end

  def is_unlocked_for_student?(student)
    if unlock_states.where(:student_id => student.id).present?
      unlock_states.where(:student_id => student.id).first.is_unlocked?
    elsif ! unlock_conditions.present?
      return true
    end
  end

  def check_unlock_status(student)
    if ! is_unlocked_for_student?(student)
      goal = unlock_conditions.count
      count = 0
      unlock_conditions.each do |condition|
        if condition.is_complete?(student)
          count += 1
        end
      end
      if goal == count
        if unlock_states.where(:student_id => student.id).present?
          unlock_states.where(:student_id => student.id).first.unlocked = true
        else
          self.unlock_states.create(:student_id => student.id, :unlocked => true, :unlockable_id => self.id, :unlockable_type => "Assignment")
        end
      else
        return false
      end
    end
  end

  def find_or_create_unlock_state(student)
    UnlockState.where(student: student, unlockable: self).first || UnlockState.create(student_id: student.id, unlockable_id: self.id, unlockable_type: "Assignment")
  end

  # Custom point total if the class has weighted assignments
  def point_total_for_student(student, weight = nil)
    (point_total * weight_for_student(student, weight)).round rescue 0
    # rescue methods with a '0' for pass/fail assignments that are also student weightable for some untold reason
  end

  # Grabbing a student's set weight for the assignment - returns one if the course doesn't have weights
  def weight_for_student(student, weight = nil)
    return 1 unless student_weightable?
    weight ||= (weights.where(student: student).pluck('weight').first || 0)
    weight > 0 ? weight : default_weight
  end

  # Allows instructors to set a value (presumably less than 1) that would be multiplied by *not* weighted assignments
  def default_weight
    course.default_assignment_weight
  end

  # Getting a student's grade object for an assignment
  def grade_for_student(student)
    grades.graded_or_released.where(student_id: student).first
  end

  # Getting a student's score for an assignment
  def score_for_student(student)
    grades.graded_or_released.where(student_id: student).pluck('score').first
  end

  # Getting a student's released score for an assignment
  def released_score_for_student(student)
    grades.released.where(student: student).pluck('score').first
  end

  # Get a grade object for a student if it exists - graded or not. this is used in the import grade
  def all_grade_statuses_grade_for_student(student)
    grades.where(student_id: student).first
  end

  # Checking to see if an assignment's due date is past
  def past?
    due_at != nil && due_at < Time.now
  end

  # Checking to see if an assignment's due date is in the future
  def future?
    due_at != nil && due_at >= Time.now
  end

  # Checking to see if an assignment is still accepted - there's often a grey space between due and no longer accepted
  def still_accepted?
    (accepts_submissions_until.present? && accepts_submissions_until >= Time.now) || (accepts_submissions_until == nil)
  end

  # Checking to see if the assignment has submissions that don't have grades
  def has_ungraded_submissions?
    has_submissions == true && submissions.try(:ungraded)
  end

  # Checking to see if an assignment is due soon
  def soon?
    if due_at?
      Time.now <= due_at && due_at < (Time.now + 7.days)
    end
  end

  # Setting the grade predictor displays
  def fixed?
    points_predictor_display == "Fixed"
  end

  def slider?
    points_predictor_display == "Slider"
  end

  def select?
    points_predictor_display == "Select List"
  end

  # The below four are the Quick Grading Types, can be set at either the assignment or assignment type level
  def grade_checkboxes?
    self.mass_grade_type == "Checkbox"
  end

  def grade_select?
    (self.mass_grade_type == "Select List" && self.assignment_score_levels.present?)
  end

  def grade_radio?
    (self.mass_grade_type == "Radio Buttons" && self.assignment_score_levels.present?)
  end

  def grade_text?
    self.mass_grade_type == "Text"
  end

  # Checking to see if an assignment has related score levels
  def has_levels?
   self.assignment_score_levels.present?
  end

  # Finding what grade level was earned for a particular assignment
  def grade_level(grade)
    assignment_score_levels.each do |assignment_score_level|
      return assignment_score_level.name if grade.raw_score == assignment_score_level.value
    end
    nil
  end

  # Using the parent assignment type's score levels if they're present - otherwise getting the assignment score levels
  def score_levels_set
    if self.assignment_score_levels.present?
      assignment_score_levels
    end
  end

  # Checking to see if the assignment is still open and accepting submissons
  def open?
    # No due dates whatsoever, always accept
    (open_at.nil? && due_at.nil?) ||
    # Open date has passed and due date is nil, accept submissions
    ((open_at != nil && open_at < Time.now) && (due_at.nil? )) ||
    # No open date present, due date is after now, accept submissions
    (open_at.nil? && due_at != nil && due_at > Time.now) ||
    # No open date is present, due date has passed, but accept until limit is absent
    (open_at.nil? && due_at != nil && due_at < Time.now && accepts_submissions_until.nil?) ||
    # Open date is absent, due date and accept until date are present
    (open_at.nil? && due_at != nil && (accepts_submissions_until != nil && accepts_submissions_until > Time.now)) ||
    # Open date and due date both defined, limit from accepts submissions until absent - accept assignments indefinitely
    ((open_at != nil && open_at < Time.now) && (due_at != nil && due_at > Time.now) && accepts_submissions_until.nil?) ||
    # Open date and due date are both defined, it is after the due date but no accept_submissions_until date is present
    ((open_at != nil && open_at < Time.now) && (due_at != nil && due_at < Time.now) && accepts_submissions_until.nil?) ||
    #if both the open date and the accept until date are present and it is between them, accept submissions
    ((open_at != nil && open_at < Time.now) && (accepts_submissions_until != nil && accepts_submissions_until > Time.now))
  end

  # Counting how many grades there are for an assignment
  def grade_count
    grades.graded_or_released.count
  end

  # Counting how many non-zero grades there are for an assignment
  def positive_grade_count
    grades.graded_or_released.where("score > 0").count
  end

  # Calculating attendance rate, which tallies number of people who have positive grades for attendance divided by the total number of students in the class
  def completion_rate(course)
   ((grade_count / course.graded_student_count.to_f) * 100).round(2)
  end

  # Counting the percentage of submissions from the entire class
  def submission_rate(course)
    ((submissions.count / course.graded_student_count.to_f) * 100).round(2)
  end

  def group_submission_rate
    ((submissions.count / groups.count.to_f) * 100).round(2)
  end

  # Calculates attendance rate as an integer.
   def attendance_rate_int(course)
    if course.graded_student_count > 0
     ((positive_grade_count / course.graded_student_count.to_f) * 100).to_i
    end
  end

  # Single assignment gradebook
  def gradebook_for_assignment(options = {})
    CSV.generate(options) do |csv|
      csv << ["First Name", "Last Name", "Uniqname", "Score", "Raw Score", "Statement", "Feedback", "Last Updated" ]
      course.students.each do |student|
        grade = student.grade_for_assignment(self)
        if grade and (grade.instructor_modified? || grade.graded_or_released?)
          csv << [student.first_name, student.last_name, student.username, student.grade_for_assignment(self).score, student.grade_for_assignment(self).raw_score, student.submission_for_assignment(self).try(:text_comment), student.grade_for_assignment(self).try(:feedback), student.grade_for_assignment(self).updated_at ]
        else
          csv << [student.first_name, student.last_name, student.username, "", "", student.submission_for_assignment(self).try(:text_comment), "" ]
        end
      end
    end
  end

  def grade_import(students, options = {})
    CSV.generate(options) do |csv|
      csv << ["First Name", "Last Name", "Email", "Score", "Feedback"]
      students.each do |student|
        grade = student.grade_for_assignment(self)
        if grade and (grade.instructor_modified? || grade.graded_or_released?)
          csv << [student.first_name, student.last_name, student.email, student.grade_for_assignment(self).score, student.grade_for_assignment(self).try(:feedback) ]
        else
          csv << [student.first_name, student.last_name, student.email, "", "" ]
        end
      end
    end
  end

  # Calculating how many of each score exists
  def score_count
    Hash[grades.graded_or_released.group_by{ |g| g.score }.map{ |k, v| [k, v.size] }]
  end

  def predicted_count
    grades.predicted_to_be_done.count
  end

  # Calculating how many of each score exists
  def earned_score_count
    Hash[grades.graded_or_released.group_by{ |g| g.raw_score }.map{ |k, v| [k, v.size ] }]
  end

  def earned_scores
    scores = []
    earned_score_count.each do |score|
      scores << { :data => score[1], :name => score[0] }
    end
    return {
      :scores => scores
    }
  end

  # Creating an array with the set of scores earned on the assignment, and
  def percentage_score_earned
    scores = []
    earned_score_count.each do |score|
      scores << { :data => score[1], :name => score[0] }
    end
    return {
      :scores => scores
    }
  end

  private

  def open_before_close
    if (due_at.present? && open_at.present?) && (due_at < open_at)
      errors.add :base, 'Due date must be after open date.'
    end
  end

  def submissions_after_due
    if (accepts_submissions_until.present? && due_at.present?) && (accepts_submissions_until < due_at)
      errors.add :base, 'Submission accept date must be after due date.'
    end
  end

  def submissions_after_open
    if (accepts_submissions_until.present? && open_at.present?) && (accepts_submissions_until < open_at)
      errors.add :base, 'Submission accept date must be after open date.'
    end
  end

  # Stripping the description of extra code
  def clean_html
    self.description = Sanitize.clean(description, Sanitize::Config::BASIC)
  end

  def zero_points_for_pass_fail
    self.point_total = 0 if self.pass_fail?
  end

  # Checking to see if the assignment point total has altered, and if it has resaving weights
  def save_weights
    if self.point_total_changed?
      weights.reload.each(&:save)
    end
  end
end
