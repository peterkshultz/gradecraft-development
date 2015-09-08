class NullStudent
  attr_accessor :course, :grades

  def initialize(course=nil)
    @course = course
    @grades = NullStudentGrades.new
  end

  def id
    0
  end

  def submission_for_assignment(*)
    self
  end

  def weight_for_assignment_type(*)
    0
  end

  def present?
    false
  end

  def team_for_course(*)
    NullTeam.new
  end
end


class NullStudentGrades

  def where(*)
    self
  end

  def select(*)
    self
  end

  def first
    NullStudentGrade.new
  end
end


class NullStudentGrade
  attr_accessor :predicted_score

  def initialize
    @predicted_score = 0
  end

  def is_student_visible?
    true
  end

  def id
    0
  end

  def team_id
    0
  end

  def challenge_id
    0
  end

  def point_total
    555
  end

  def score
    nil
  end

  def final_score
    nil
  end

  def status
    nil
  end

  def pass_fail_status
    nil
  end
end


class NullTeam
  def id
    0
  end
  def challenge_grades
    NullStudentGrades.new
  end
end
