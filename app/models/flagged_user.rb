class FlaggedUser < ActiveRecord::Base
  belongs_to :course

  def self.flag!(course, flagger, flagged_id)
    self.create course_id: course.id, flagger_id: flagger.id, flagged_id: flagged_id
  end
end
