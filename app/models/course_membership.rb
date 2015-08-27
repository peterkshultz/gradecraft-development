class CourseMembership < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  attr_accessible :auditing,
    :character_profile,
    :course_id,
    :instructor_of_record,
    :user_id,
    :role

  ROLES = %w(student professor gsi admin)

  ROLES.each do |role|
    scope role.pluralize, ->(course) { where role: role }
    define_method("#{role}?") do
      self.role == role
    end
  end

  scope :auditing, -> { where( :auditing => true ) }
  scope :being_graded, -> { where( :auditing => false) }

  validates_presence_of :course_id
  validates_presence_of :user_id

  validates :instructor_of_record, instructor_of_record: true
  validates_uniqueness_of :course_id,  scope: :user_id

  def assign_role_from_lti(auth_hash)
    return unless auth_hash['extra'] && auth_hash['extra']['raw_info'] && auth_hash['extra']['raw_info']['roles']

    auth_hash['extra']['raw_info'].tap do |extra|

      case extra['roles'].downcase
      when /instructor/
        self.update_attribute(:role, 'professor')
        self.update_attribute(:instructor_of_record, true)
      when /teachingassistant/
        self.update_attribute(:role, 'gsi')
        self.update_attribute(:instructor_of_record, true)
      else
        self.update_attribute(:role, 'student')
        self.update_attribute(:instructor_of_record, false)
      end
    end
  end

  def staff?
    professor? || gsi? || admin?
  end

  protected

  def student_id
    @student_id ||= user.id
  end
end
