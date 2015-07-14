require 'spec_helper'

describe BadgeFile do

  before do
    @badge = build(:badge)
    @badge_file = @badge.badge_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg'))
  end

  subject { @badge_file }

  it { should respond_to("filename")}
  it { should respond_to("badge_id")}
  it { should respond_to("file")}
  it { should respond_to("file_processing")}
  it { should respond_to("created_at")}
  it { should respond_to("updated_at")}

  it { should be_valid }

  describe "when filename is not present" do
    before { @badge_file.filename = nil }
    it { should_not be_valid }
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      @badge.save!
      @badge_file.badge_id.should equal @badge.id
      @badge_file.new_record?.should be_false
    end

    it "is deleted when the parent submission is destroyed" do
      @badge.save!
      expect {@badge.destroy}.to change(BadgeFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    @badge_file.file = fixture_file('test_file.txt', 'txt')
    @badge.save!
    expect @badge_file.url.should =~ /.*\/uploads\/badge_file\/file\/#{@badge_file.id}\/\d+_test_file\.txt/
  end

  it "accepts multiple files" do
    @badge.badge_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    @badge.save!
    @badge.badge_files.count.should equal 2
  end

  it "has an accessible url" do
    @badge.save!
    expect @badge_file.url.should =~ /.*\/uploads\/badge_file\/file\/#{@badge_file.id}\/\d+_test_image\.jpg/
  end

  it "shortens and removes non-word characters from file names on save" do
    @badge_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    @badge.save!
    expect @badge_file.url.should =~ /.*\/uploads\/badge_file\/file\/#{@badge_file.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/
  end
end
