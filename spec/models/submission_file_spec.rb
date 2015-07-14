require 'spec_helper'

describe SubmissionFile do

  before do
    @submission = build(:submission)
    @submission_file = @submission.submission_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
  end

  subject { @submission_file }

  it { should respond_to("filename")}
  it { should respond_to("submission_id")}
  it { should respond_to("file")}

  it { should be_valid }

  describe "when filename is not present" do
    before { @submission_file.filename = nil }
    it { should_not be_valid }
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      @submission.save!
      @submission_file.submission_id.should equal @submission.id
      @submission_file.new_record?.should be_false
    end

    it "is deleted when the parent submission is destroyed" do
      @submission.save!
      expect {@submission.destroy}.to change(SubmissionFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    @submission_file.file = fixture_file('test_file.txt', 'txt')
    @submission.save!
    expect @submission_file.url.should =~ /.*\/uploads\/submission_file\/file\/#{@submission_file.id}\/\d+_test_file\.txt/
  end

  it "accepts multiple files" do
    @submission.submission_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    @submission.save!
    @submission.submission_files.count.should equal 2
  end

  it "has an accessible url" do
    @submission.save!
    expect @submission_file.url.should =~ /.*\/uploads\/submission_file\/file\/#{@submission_file.id}\/\d+_test_image\.jpg/
  end

  it "shortens and removes non-word characters from file names on save" do
    @submission_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    @submission.save!
    expect @submission_file.url.should =~ /.*\/uploads\/submission_file\/file\/#{@submission_file.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/
  end
end
