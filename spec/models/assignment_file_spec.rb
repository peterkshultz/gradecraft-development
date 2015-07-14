require 'spec_helper'

describe AssignmentFile do

  before do
    @assignment = build(:assignment)
    @assignment_file = @assignment.assignment_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
  end

  subject { @assignment_file }

  it { should respond_to("filename")}
  it { should respond_to("assignment_id")}
  it { should respond_to("file")}
  it { should respond_to("file_processing")}
  it { should respond_to("created_at")}
  it { should respond_to("updated_at")}

  it { should be_valid }

  describe "when filename is not present" do
    before { @assignment_file.filename = nil }
    it { should_not be_valid }
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      @assignment.save!
      @assignment_file.assignment_id.should equal @assignment.id
      @assignment_file.new_record?.should be_false
    end

    it "is deleted when the parent submission is destroyed" do
      @assignment.save!
      expect {@assignment.destroy}.to change(AssignmentFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    @assignment_file.file = fixture_file('test_file.txt', 'txt')
    @assignment.save!
    expect @assignment_file.url.should =~ /.*\/uploads\/assignment_file\/file\/#{@assignment_file.id}\/\d+_test_file\.txt/
  end

  it "accepts multiple files" do
    @assignment.assignment_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    @assignment.save!
    @assignment.assignment_files.count.should equal 2
  end

  it "has an accessible url" do
    @assignment.save!
    expect @assignment_file.url.should =~ /.*\/uploads\/assignment_file\/file\/#{@assignment_file.id}\/\d+_test_image\.jpg/
  end

  it "shortens and removes non-word characters from file names on save" do
    @assignment_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    @assignment.save!
    expect @assignment_file.url.should =~ /.*\/uploads\/assignment_file\/file\/#{@assignment_file.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/
  end
end
