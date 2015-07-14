require 'spec_helper'

describe GradeFile do

  before do
    @grade = build(:grade)
    @grade_file = @grade.grade_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
  end

  subject { @grade_file }

  it { should respond_to("filename")}
  it { should respond_to("grade_id")}
  it { should respond_to("file")}
  it { should respond_to("file_processing")}
  it { should respond_to("created_at")}
  it { should respond_to("updated_at")}

  it { should be_valid }

  describe "when filename is not present" do
    before { @grade_file.filename = nil }
    it { should_not be_valid }
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      @grade.save!
      @grade_file.grade_id.should equal @grade.id
      @grade_file.new_record?.should be_false
    end

    it "is deleted when the parent submission is destroyed" do
      @grade.save!
      expect {@grade.destroy}.to change(GradeFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    @grade_file.file = fixture_file('test_file.txt', 'txt')
    @grade.save!
    expect @grade_file.url.should =~ /.*\/uploads\/grade_file\/file\/#{@grade_file.id}\/\d+_test_file\.txt/
  end

  it "accepts multiple files" do
    @grade.grade_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    @grade.save!
    @grade.grade_files.count.should equal 2
  end

  it "has an accessible url" do
    @grade.save!
    expect @grade_file.url.should =~ /.*\/uploads\/grade_file\/file\/#{@grade_file.id}\/\d+_test_image\.jpg/
  end

  it "shortens and removes non-word characters from file names on save" do
    @grade_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    @grade.save!
    expect @grade_file.url.should =~ /.*\/uploads\/grade_file\/file\/#{@grade_file.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/
  end
end
