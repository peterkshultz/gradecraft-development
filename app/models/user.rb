class User < ActiveRecord::Base
  authenticates_with_sorcery!

  include Canable::Cans

  ROLES = %w(student professor gsi admin)

  class << self
    def with_role_in_course(role, course)
      if role == "staff"
        user_ids = CourseMembership.where('course_id=? AND (role=? OR role=?)', course, 'professor', 'gsi').pluck(:user_id)
      else
        user_ids = CourseMembership.where(course: course, role: role).pluck(:user_id)
      end
      User.where(id: user_ids)
    end

    ROLES.each do |role|
      define_method(role.pluralize) do |course|
        with_role_in_course(role,course)
      end
    end

    def students_being_graded(course, team=nil)
      user_ids = CourseMembership.where(course: course, role: "student", auditing: false).pluck(:user_id)
      query = User.where(id: user_ids)
      query = query.students_in_team(team.id, user_ids) if team
      query
    end

    def students_auditing(course, team=nil)
      user_ids = CourseMembership.where(course: course, role: "student", auditing: true).pluck(:user_id)
      query = User.where(id: user_ids)
      query = query.students_in_team(team.id, user_ids) if team
      query
    end

    def students_by_team(course, team)
      user_ids = CourseMembership.where(course: course, role: "student").pluck(:user_id)
      User.where(id: user_ids).students_in_team(team.id, user_ids)
    end

    def instructors_of_record(course)
      user_ids = CourseMembership
        .where(course: course, instructor_of_record: true)
        .pluck(:user_id)
      User.where(id: user_ids)
    end
  end

  attr_accessor :password, :password_confirmation, :cached_last_login_at, :course_team_ids, :score, :team
  attr_accessible :username, :email, :password, :password_confirmation,
    :avatar_file_name, :first_name, :last_name, :rank, :user_id,
    :display_name, :private_display, :default_course_id, :last_activity_at,
    :last_login_at, :last_logout_at, :team_ids, :courses, :course_ids,
    :earned_badges, :earned_badges_attributes, :major, :gpa, :current_term_credits,
    :accumulated_credits,  :year_in_school, :state_of_residence, :high_school, :athlete,
    :act_score, :sat_score, :student_academic_history_attributes, :team_role,
    :course_memberships_attributes, :character_profile, :team_id, :lti_uid, :course_team_ids

  # all student display pages are ordered by last name except for the leaderboard, and top 10/bottom 10
  default_scope { order('last_name ASC') }

  scope :order_by_high_score, -> { includes(:course_memberships).order 'course_memberships.score DESC' }
  scope :order_by_low_score, -> { includes(:course_memberships).order 'course_memberships.score ASC' }
  scope :students_in_team, -> (team_id, student_ids) \
    { includes(:team_memberships).where(team_memberships: { team_id: team_id, student_id: student_ids }) }

  mount_uploader :avatar_file_name, AvatarUploader

  has_many :course_memberships, :dependent => :destroy
  has_many :courses, :through => :course_memberships
  has_many :course_users, :through => :courses, :source => 'users'
  accepts_nested_attributes_for :courses
  accepts_nested_attributes_for :course_memberships

  belongs_to :default_course, :class_name => 'Course', touch: true

  has_many :student_academic_histories, :foreign_key => :student_id, :dependent => :destroy
  accepts_nested_attributes_for :student_academic_histories

  has_many :assignments, :through => :grades

  has_many :unlock_states, :foreign_key => :student_id, :dependent => :destroy

  has_many :assignment_weights, :foreign_key => :student_id

  has_many :submissions, :foreign_key => :student_id, :dependent => :destroy
  has_many :created_submissions, :as => :creator

  has_many :grades, :foreign_key => :student_id, :dependent => :destroy
  has_many :graded_grades, foreign_key: :graded_by_id, :class_name => 'Grade'

  has_many :earned_badges, :foreign_key => :student_id, :dependent => :destroy
  accepts_nested_attributes_for :earned_badges, :reject_if => proc { |attributes| attributes['earned'] != '1' }
  has_many :badges, :through => :earned_badges

  has_many :group_memberships, :foreign_key => :student_id, :dependent => :destroy
  has_many :groups, :through => :group_memberships
  has_many :assignment_groups, :through => :groups

  has_many :team_memberships, :foreign_key => :student_id, :dependent => :destroy
  has_many :team_leaderships, :foreign_key => :leader_id, :dependent => :destroy
  has_many :teams, :through => :team_memberships do
    def set_for_course(course_id, ids)
      other_team_ids = proxy_association.owner.teams.where("course_id != ?", course_id).pluck(:id)
      if proxy_association.owner.course_memberships.where("course_id = ?", course_id).first.role == "student"
        proxy_association.owner.team_ids = other_team_ids | [ids]
      else
        if ids.present?
          proxy_association.owner.team_ids = other_team_ids | ids
        end
      end
    end
  end

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  # Users are automatically logged into this course if they have access to multiple.
  # Longterm, we'd like to build a way for students enrolled in multiple gameful coursres to see
  # a unified dashboard.

  validates :username, :presence => true,
                    :length => { :maximum => 50 }
  validates :email, :presence => true,
                    :format   => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }

  validates :first_name, :last_name, :presence => true
  validates :password, :confirmation => true
  validates :password_confirmation, :presence => true, if: :password, on: :update

  def self.find_or_create_by_lti_auth_hash(auth_hash)
    criteria = { email: auth_hash['info']['lis_person_contact_email_primary'] }
    where(criteria).first || create!(criteria) do |u|
      u.lti_uid = auth_hash['uid']
      auth_hash['info'].tap do |info|
        u.first_name = info['lis_person_name_given']
        u.last_name = info['lis_person_name_family']
        u.username = info["lis_person_contact_email_primary.split('@')[0]"]
        u.kerberos_uid = info["lis_person_contact_email_primary.split('@')[0]"]
      end
    end
  end

  def self.find_by_kerberos_auth_hash(auth_hash)
    where(kerberos_uid: auth_hash['uid']).first
  end

  def self.find_by_insensitive_email(email)
    where("LOWER(email) = :email", email: email.downcase).first
  end

  #Course
  def find_scoped_courses(course_id)
    if is_admin? || self.course_ids.include?(course_id)
      Course.find(course_id)
    else
      raise
    end
  end

  def activated?
    activation_state == "active"
  end

  def default_course
    super || courses.first
  end

  def name
    @name = [first_name,last_name].reject(&:blank?).join(' ').presence || "User #{id}"
  end

  def public_name
    if display_name?
      display_name
    else
      name
    end
  end

  # Any users who are connected to multiple classes
  def multiple_courses?
    course_memberships.count > 1
  end

  def enrolled_in_course?(course)
  end

  def self.auditing_students_in_course(course_id)
    User
      .select("users.id, users.first_name, users.last_name, users.email, users.display_name, course_memberships.score as cached_score")
      .joins("INNER JOIN course_memberships ON course_memberships.user_id = users.id")
      .where("course_memberships.course_id = ?", course_id)
      .where("course_memberships.auditing = ?", true)
      .where("course_memberships.role = ?", "student")
      .includes(:course_memberships)
      .group("users.id, course_memberships.score")
  end

  def self.graded_students_in_course(course_id)
    User
      .select("users.id, users.first_name, users.last_name, users.email, users.display_name, users.updated_at, course_memberships.score as cached_score")
      .joins("INNER JOIN course_memberships ON course_memberships.user_id = users.id")
      .where("course_memberships.course_id = ?", course_id)
      .where("course_memberships.auditing = ?", false)
      .where("course_memberships.role = ?", "student")
      .includes(:course_memberships)
      .group("users.id, course_memberships.score")
  end

  def self.graded_students_in_course_include_and_join_team(course_id)
    self.graded_students_in_course(course_id)
      .joins("INNER JOIN team_memberships ON team_memberships.student_id = users.id")
      .where("course_memberships.user_id = team_memberships.student_id")
      .includes(:team_memberships)
  end

  def self.auditing_students_in_course_include_and_join_team(course_id)
    self.auditing_students_in_course(course_id)
      .joins("INNER JOIN team_memberships ON team_memberships.student_id = users.id")
      .where("course_memberships.user_id = team_memberships.student_id")
      .includes(:team_memberships)
  end

  def auditing_course?(course)
    course.membership_for_student(self).auditing?
  end

  def team_leaders(course)
    @team_leaders ||= course_team(course).includes(:leaders) rescue nil
  end

  ROLES.each do |role|
    define_method("is_#{role}?") do |course|
      self.role(course) == role
    end
  end

  def role(course)
    return nil if self.course_memberships.where(course_id: course).empty?
    self.course_memberships.where(course: course).first.role
  end

  # TODO redefine staff as professors and gsi only.
  # We want to create admin with comprehensive access.
  def is_staff?(course)
    is_professor?(course) || is_gsi?(course) || is_admin?(course)
  end

  ### TEAMS
  # Find the team associated with the team membership for a given course id
  def course_team(course)
    team_memberships.joins(:team).where("teams.course_id = ?", course.id).first.team rescue nil
  end

  def team_for_course(course)
    @cached_team ||= teams.where(course_id: course).first
  end

  def load_team(course)
    @team ||= team_for_course(course)
  end

  # Space for users to build a narrative around their identity
  def character_profile(course)
    course_memberships.where(course: course).try('character_profile')
  end

  #Import Users
  def self.csv_header
    "First Name,Last Name,Email,Username".split(',')
  end

  def archived_courses
    courses.where(:status => false)
  end


  ### SCORE
  def cached_score_for_course(course)
    @cached_score ||= course_memberships.where(:course_id => course).first.score || 0
  end

  # Powers the grade distribution box plot
  def scores_for_course(course)
     user_score = course_memberships.where(:course_id => course, :auditing => FALSE).pluck('score')
     scores = CourseMembership.where(course: course, role: "student", auditing: false).pluck(:score)
     return {
      :scores => scores,
      :user_score => user_score
     }
  end

  ### EARNED LEVELS AND GRADE LETTERS

  def grade_level_for_course(course)
    @grade_level ||= Course.find(course.id).grade_level_for_score(cached_score_for_course(course))
  end

  def grade_letter_for_course(course)
    @grade_letter_for_course ||= course.grade_letter_for_score(cached_score_for_course(course))
  end

  def next_element_level(course)
    next_element = nil
    course.grade_scheme_elements.order_by_low_range.each_with_index do |element, index|
      if (element.high_range >= cached_score_for_course(course)) && (cached_score_for_course(course) >= element.low_range)
        next_element = course.grade_scheme_elements[index + 1]
      end
      if next_element.nil?
        if element.low_range > cached_score_for_course(course)
          next_element = course.grade_scheme_elements.order_by_low_range.first
        end
      end
    end
    return next_element
  end

  def points_to_next_level(course)
    next_element_level(course).low_range - cached_score_for_course(course)
  end


  ### COURSE POINTS AVAILABLE

  def point_total_for_course(course)
    @point_total_for_course ||= course.assignments.point_total_for_student(self) + earned_badge_score_for_course(course)
  end

  #TODO: Should take into account students weights
  def point_total_for_assignment_type(assignment_type)
    assignment_type.assignments.map{ |a| a.point_total }.sum
  end

  ### ASSIGNMENT TYPE SCORES
  def scores_by_assignment_type
    grades.group(:assignment_type_id).pluck('assignment_type_id, SUM(score)')
  end

  def score_for_assignment_type(assignment_type)
    grades.where(assignment_type: assignment_type).score
  end

  ### GRADES

  #Checking specifically if there is a released grade for an assignment
  def grade_released_for_assignment?(assignment)
    if grade_for_assignment(assignment).present?
      (grade_for_assignment(assignment).status == "Graded" && !assignment.release_necessary?) || grade_for_assignment(assignment).status == "Released"
    end
  end

  def score_for_assignment(assignment)
    grades.where(:assignment_id => assignment.id).first.score
  end

  #Grabbing the grade for an assignment
  def grade_for_assignment(assignment)
    grades.where(:assignment_id => assignment.id).first || grades.new(assignment: assignment)
  end

  def grade_for_assignment_id(assignment_id)
    grades.where(assignment_id: assignment_id)
  end

  def released_score_for_assignment_type(assignment_type)
    grades.released.where(assignment_type: assignment_type).score
  end

  def assignment_scores_for_course(course)
    grades.released.where(course: course).score
  end

  def point_total_for_assignment(assignment)
    grades.where(:assignment_id => assignment.id).first.try(:point_total) || nil
  end

  # Powers the worker to recalculate student scores
  def cache_course_score(course_id)
    course = Course.find(course_id)
    membership = course_memberships.where(course_id: course_id).first
    unless membership.nil?
      if membership.course.add_team_score_to_student?
        membership.update_attribute :score, (
          total_score = 0
          course.assignment_types.each do |assignment_type|
            total_score += assignment_type.visible_score_for_student(self)
          end
          total_score += earned_badge_score_for_course(course_id)
          total_score += self.team_for_course(course_id).try(:score)
        )
      else
        membership.update_attribute :score, (
          total_score = 0
          course.assignment_types.each do |assignment_type|
            total_score += assignment_type.visible_score_for_student(self)
          end
          total_score += earned_badge_score_for_course(course_id)
        )
      end
    end
  end

  ### Scoreboard chart on the bottom of the student dashboard

  def total_scores_for_chart(course)
    scores = []
    course.assignment_types.each do |assignment_type|
      scores << { data: [assignment_type.visible_score_for_student(self)], name: assignment_type.name }
    end


    _assignments = assignments.where(course: course)
    in_progress_score = _assignments.graded_for_student(self).sum('point_total')
    earned_badge_score = earned_badges.where(course: course).score
    if earned_badge_score > 0
      scores << { :data => [earned_badge_score], :name => "#{course.badge_term.pluralize}" }
    end

    return {
      :student_name => name,
      :scores => scores,
      :course_total => course.total_points + earned_badge_score,
      :in_progress => in_progress_score + earned_badge_score,
      # :grade_levels => grade_levels
      }
  end

  ### TEAMS
  # Find the team associated with the team membership for a given course id
  def course_team(course)
    team_memberships.joins(:team).where("teams.course_id = ?", course.id).first.team rescue nil
  end

  def team_for_course(course)
    @cached_team ||= teams.where(course_id: course).first
  end

  def load_team(course)
    @team ||= team_for_course(course)
  end

  def team_score(course)
    teams.where(:course => course).pluck('score').first
  end

  ### SUBMISSIONS
  def submissions_by_assignment_id
    @submissions_by_assignment ||= submissions.group_by(&:assignment_id)
  end

  def submission_for_assignment(assignment)
    submissions_by_assignment_id[assignment.id].try(:first)
  end

  ### BADGES

  def earned_badge?(badge)
    earned_badges[badge.id].present?
  end

  def earned_badges_by_badge
    @earned_badges_by_badge ||= earned_badges.group_by(&:badge_id)
  end

  def earned_badge_score_for_course(course)
    earned_badges.where(:course_id => course).score
  end

  def earned_badges_for_course(course)
    earned_badges.where(course: course)
  end

  def earned_badge_count_for_course(course)
    earned_badges.where(course: course).count
  end

  def earned_badge_for_badge(badge)
    earned_badges.where(badge: badge)
  end

  def earned_badges_for_badge_count(badge)
    earned_badges.where(badge: badge).count
  end

  def earned_badge_score
    @earned_badge_score ||= earned_badges.sum(:score)
  end

  # Unique badges associated with all of the earned badges for a given student/course combo
  def unique_student_earned_badges(course)
    @unique_student_earned_badges ||= Badge
      .includes(:earned_badges)
      .where("earned_badges.course_id = ?", course[:id])
      .where("earned_badges.student_id = ?", self[:id])
      .where("earned_badges.student_visible = ?", true)
      .references(:earned_badges)
  end

  # this should be all earned badges that either:
  # 1) have no associated grade and have been awarded to the student, or...
  # 2) have an associated grade that has been marked graded_or_released? (indicated through the student_visible boolean)
  def student_visible_earned_badges(course)
    @student_visible_earned_badges ||= EarnedBadge
      .includes(:badge)
      .where(course: course)
      .where(student_id: self[:id])
      .where(student_visible: true)
  end

  # this should be all badges that:
  # 1) exist in the current course, in which the student is enrolled, AND:
  # 2) the student has either not earned at all for any grade, or:
  # 3) the student has earned the badge, but multiple are allowed, or:
  # 3) the student has earned the badge, multiple are not allowed, but the earned badge is for the current grade
  def earnable_course_badges_for_grade(grade)
    Badge
      .where(course_id: grade[:course_id])
      .where(final_earnable_course_badges_sql(grade))
  end

  private
  def final_earnable_course_badges_sql(grade)
    earnable_course_badges_sql_conditions(grade).where_values.join(" OR ")
  end

  public
  def earnable_course_badges_sql_conditions(grade)
    Badge
      .unscoped
      .where("(id not in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ?))", self[:id], grade[:course_id])
      .where("(id in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ?) and can_earn_multiple_times = ?)", self[:id], grade[:course_id], true)
      .where("(id in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ? and earned_badges.grade_id = ?) and can_earn_multiple_times = ?)", self[:id], grade[:course_id], grade[:id], false)
  end

  public
  # this should be all badges that:
  # 1) exist in the current course, in which the student is enrolled
  # 2) the student has either not earned at all, but is visible and available, or...
  # 3) the student has earned_badge for, but that earned_badge is set to student_visible 'false'
  def student_visible_unearned_badges(course)
    Badge
      .where(course_id: course[:id])
      .where(visible: true)
      .where("id not in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ? and earned_badges.student_visible = ?)", self[:id], course[:id], true)
  end

  # badges that have not been marked 'visible' by the instructor, and for which
  # the student has earned a badge, but the earned badge has yet to be marked 'student_visible'
  def student_invisible_badges(course)
    Badge
      .where(visible: false)
      .where(course_id: course[:id])
      .where("id in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ? and earned_badges.student_visible = ?)", self[:id], course[:id], false)
  end

  def earn_badge(badge)
    raise TypeError, "Argument must be a Badge object" unless badge.class == Badge
    earned_badges.create badge: badge, course: badge.course
  end

  def earn_badge_for_grade(badge, grade)
    raise TypeError, "First argument must be a Badge object" unless badge.class == Badge
    earned_badges.create badge: badge, course: badge.course, grade: grade
  end

  def earn_badges_for_grade(badges, grade)
    raise TypeError, "First argument must be a Badge object" unless badge.class == Badge
    badges.collect do |badge|
      earned_badges.create badge: badge, course: badge.course, grade: grade
    end
  end

  def earn_badges(badges)
    raise TypeError, "Argument must be an array of Badge objects" unless badges.class == Array
    badges.each do |badge|
      earned_badges.create badge: badge, course: badge.course
    end
  end


  ### WEIGHTS
  def assignment_type_weights(course)
    @assignment_type_weights ||= {}.tap do |assignment_type_weights|
      course.assignment_types.weights_for_student(self).each do |assignment_type_id, weight|
        assignment_type_weights[assignment_type_id] = weight
      end
    end
  end

  #Returns the student's assigned weight for a specific assignment
  def weight_for_assignment(assignment)
    assignment_weights.where(:assignment => assignment).first.weight
  end

  # Returns the student's assigned weight for an assignment type category
  def weight_for_assignment_type(assignment_type)
    assignment_weights.where(assignment_type: assignment_type).first.try(:weight) || 0
  end

  def weight_spent?(course)
    total = 0
    course.assignment_types.each do |at|
      total += weight_for_assignment_type(at)
    end
    if total == course.total_assignment_weight
      return true
    else
      false
    end
  end

  def total_weight_spent(course)
    total = 0
    course.assignment_types.each do |at|
      total += weight_for_assignment_type(at)
    end
    return total
  end

  def weighted_assignments?
    assignment_weights.count > 0
  end

  #Counts how many assignments are weighted for this student - note that this is an ASSIGNMENT count,
  #and not the assignment type count. Because students make the choice at the AT level rather than the A level,
  #this can be confusing.
  def weight_count(course)
    assignment_weights.where(course: course).pluck('weight').count
  end

  #Used to allow students to self-log a grade, currently only a boolean (complete or not)
  def self_reported_done?(assignment)
    grade = grade_for_assignment(assignment)
    grade.present? && grade.is_student_visible?
  end


  ### GROUPS
  def groups_by_assignment_id
    @group_by_assignment ||= groups.group_by(&:assignment_id)
  end

  def group_for_assignment(assignment)
    @group_for_assignment ||= assignment_groups.where(assignment: assignment).first.try(:group)
  end


  private

  def set_default_course
    self.default_course ||= courses.first
  end

  def cache_last_login
    self.cached_last_login_at = self.last_login_at
  end

end
