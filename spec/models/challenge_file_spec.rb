require 'spec_helper'

describe ChallengeFile do

  before do
    @challenge = build(:challenge)
    @challenge_file = @challenge.challenge_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
  end

  subject { @challenge_file }

  it { should respond_to("filename")}
  it { should respond_to("challenge_id")}
  it { should respond_to("file")}
  it { should respond_to("file_processing")}
  it { should respond_to("created_at")}
  it { should respond_to("updated_at")}

  it { should be_valid }

  describe "when filename is not present" do
    before { @challenge_file.filename = nil }
    it { should_not be_valid }
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      @challenge.save!
      @challenge_file.challenge_id.should equal @challenge.id
      @challenge_file.new_record?.should be_false
    end

    it "is deleted when the parent submission is destroyed" do
      @challenge.save!
      expect {@challenge.destroy}.to change(ChallengeFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    @challenge_file.file = fixture_file('test_file.txt', 'txt')
    @challenge.save!
    expect @challenge_file.url.should =~ /.*\/uploads\/challenge_file\/file\/#{@challenge_file.id}\/\d+_test_file\.txt/
  end

  it "accepts multiple files" do
    @challenge.challenge_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    @challenge.save!
    @challenge.challenge_files.count.should equal 2
  end

  it "has an accessible url" do
    @challenge.save!
    expect @challenge_file.url.should =~ /.*\/uploads\/challenge_file\/file\/#{@challenge_file.id}\/\d+_test_image\.jpg/
  end

  it "shortens and removes non-word characters from file names on save" do
    @challenge_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    @challenge.save!
    expect @challenge_file.url.should =~ /.*\/uploads\/challenge_file\/file\/#{@challenge_file.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/
  end
end
