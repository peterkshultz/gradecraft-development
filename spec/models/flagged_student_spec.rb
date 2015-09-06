require "active_record_spec_helper"

describe FlaggedUser do
  let(:course) { create :course }
  let(:professor) { create :user }
  let(:student) { create :user }

  it "creates a relationship between staff and a student" do
    FlaggedUser.flag!(course, professor, student.id)
    result = FlaggedUser.last
    expect(result.course_id).to eq course.id
    expect(result.flagger_id).to eq professor.id
    expect(result.flagged_id).to eq student.id
  end

  xit "does not allow a student to be flagged by another student"
end
