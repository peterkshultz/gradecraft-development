class GradeFile < ActiveRecord::Base
  include S3File

  attr_accessible :file, :filename, :filepath, :grade_id

  belongs_to :grade

  validates :filename, presence: true, length: { maximum: 50 }

  mount_uploader :file, AttachmentUploader
  process_in_background :file

  def course
    grade.course
  end

  def assignment
    grade.assignment
  end
end
