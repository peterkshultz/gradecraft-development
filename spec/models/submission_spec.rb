require 'spec_helper'

describe Submission do

  before do
    @submission = build(:submission)
  end

  subject { @submission }

  it { should respond_to("assignment_id")}
  it { should respond_to("student_id")}
  it { should respond_to("feedback")}
  it { should respond_to("comment")}
  it { should respond_to("created_at")}
  it { should respond_to("updated_at")}
  it { should respond_to("attachment_file_name")}
  it { should respond_to("attachment_content_type")}
  it { should respond_to("attachment_file_size")}
  it { should respond_to("attachment_updated_at")}
  it { should respond_to("link")}
  it { should respond_to("text_feedback")}
  it { should respond_to("text_comment")}
  it { should respond_to("creator_id")}
  it { should respond_to("group_id")}
  it { should respond_to("graded")}
  it { should respond_to("released_at")}
  it { should respond_to("task_id")}
  it { should respond_to("course_id")}
  it { should respond_to("assignment_type_id")}
  it { should respond_to("assignment_type")}

  it { should be_valid }

  describe "when an source url is invalid" do
    before { @submission.link = "not a url" }
    it { should_not be_valid }
  end

  it "can't be saved without any information" do
    @submission.link = nil
    @submission.text_comment = nil
    expect { @submission.save! }.to raise_error(ActiveRecord::RecordNotSaved)
  end

  it "can be saved with only a text comment" do
    @submission.text_comment = "I volunteer! I volunteer! I volunteer as tribute!"
    @submission.save!
    expect @submission.should have(0).errors
  end

  it "can be saved with only a link" do
    @submission.link = "http://www.amazon.com/dp/0439023521"
    @submission.save!
    expect @submission.should have(0).errors
  end

  it "can be saved with only an attached file" do
    @submission.submission_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
    @submission.save!
    expect @submission.should have(0).errors
  end

  it "can have an an attached file, comment, and link" do
    @submission.text_comment = "I volunteer! I volunteer! I volunteer as tribute!"
    @submission.link = "http://www.amazon.com/dp/0439023521"
    @submission.submission_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
    @submission.save!
    expect @submission.should have(0).errors
  end
end
