require 'spec_helper'

describe Course do

  before do
    @course = build(:course)
  end

  subject { @course }

  it { should respond_to("academic_history_visible")}
  it { should respond_to("accepts_submissions")}
  it { should respond_to("add_team_score_to_student")}
  it { should respond_to("assignment_term")}
  it { should respond_to("assignment_weight_close_at")}
  it { should respond_to("assignment_weight_type")}
  it { should respond_to("badge_set_id")}
  it { should respond_to("badge_setting")}
  it { should respond_to("badge_term")}
  it { should respond_to("badge_use_scope")}
  it { should respond_to("badges_value")}
  it { should respond_to("challenge_term")}
  it { should respond_to("character_profiles")}
  it { should respond_to("check_final_grade")}
  it { should respond_to("class_email")}
  it { should respond_to("courseno")}
  it { should respond_to("created_at")}
  it { should respond_to("default_assignment_weight")}
  it { should respond_to("end_date")}
  it { should respond_to("fail_term")}
  it { should respond_to("grade_scheme_id")}
  it { should respond_to("grading_philosophy")}
  it { should respond_to("graph_display")}
  it { should respond_to("group_setting")}
  it { should respond_to("group_term")}
  it { should respond_to("homepage_message")}
  it { should respond_to("in_team_leaderboard")}
  it { should respond_to("location")}
  it { should respond_to("lti_uid")}
  it { should respond_to("max_assignment_types_weighted")}
  it { should respond_to("max_assignment_weight")}
  it { should respond_to("max_group_size")}
  it { should respond_to("media_caption")}
  it { should respond_to("media_credit")}
  it { should respond_to("media_file")}
  it { should respond_to("meeting_times")}
  it { should respond_to("min_group_size")}
  it { should respond_to("name")}
  it { should respond_to("office")}
  it { should respond_to("office_hours")}
  it { should respond_to("pass_term")}
  it { should respond_to("phone")}
  it { should respond_to("point_total")}
  it { should respond_to("predictor_setting")}
  it { should respond_to("semester")}
  it { should respond_to("start_date")}
  it { should respond_to("status")}
  it { should respond_to("tagline")}
  it { should respond_to("team_challenges")}
  it { should respond_to("team_leader_term")}
  it { should respond_to("team_roles")}
  it { should respond_to("team_score_average")}
  it { should respond_to("team_setting")}
  it { should respond_to("team_term")}
  it { should respond_to("teams_visible")}
  it { should respond_to("total_assignment_weight")}
  it { should respond_to("twitter_handle")}
  it { should respond_to("twitter_hashtag")}
  it { should respond_to("updated_at")}
  it { should respond_to("use_timeline")}
  it { should respond_to("user_term")}
  it { should respond_to("weight_term")}
  it { should respond_to("year")}

  it { should be_valid }

  it "is valid with an assignment, student, assignment_type, and course" do
    expect(build(:course)).to be_valid
  end

  it "returns an alphabetical list of students being graded" do
    student = create(:user, last_name: 'Zed')
    student.courses << @course
    student2 = create(:user, last_name: 'Alpha')
    student2.courses << @course
    @course.students_being_graded.should eq([student2,student])
  end

  it "returns Pass and Fail as defaults for pass_term and fail_term" do
    @course.pass_term.should eq("Pass")
    @course.fail_term.should eq("Fail")
  end

  describe "#instructors_of_record" do
    it "returns all the staff who are instructors of record for the course" do
      membership = create :staff_course_membership, course: subject, instructor_of_record: true
      expect(subject.instructors_of_record).to eq [membership.user]
    end
  end

  describe "#instructors_of_record_ids=" do
    it "adds the instructors of record if they were not there before" do
      membership = create :staff_course_membership, course: subject
      subject.instructors_of_record_ids = [membership.user_id]
      expect(subject.instructors_of_record).to eq [membership.user]
    end

    it "removes the instructors of record that are not present" do
      membership = create :staff_course_membership, course: subject, instructor_of_record: true
      subject.instructors_of_record_ids = []
      expect(subject.instructors_of_record).to be_empty
    end
  end

  describe "#enroll_students", working: true do
    before(:each) do
      @course = create(:course)
      @student1 = create(:student)
      @student2 = create(:student)
    end

    context "multiple unenrolled students are enrolled" do
      before(:each) do
        @course_memberships = @course.enroll_students(@student1, @student2)
      end

      it "should enroll both students" do
        @total_valid = @course_memberships.collect(&:valid?).count(true)
        expect(@total_valid).to eq(2)
      end

      it "should return valid course memberships" do
        @total_course_memberships = @course_memberships.collect(&:class).count(CourseMembership)
        expect(@total_course_memberships).to eq(2)
      end

      it "should associate the student with the course memberships", broken: true do
        @course_membership_user_ids = @course_memberships.collect(&:user_id)
        expect(@course_membership_user_ids.count(@student1[:id])).to eq(1)
        expect(@course_membership_user_ids.count(@student2[:id])).to eq(1)
      end
    end

    context "one unenrolled student is enrolled" do
      before do
        @course_memberships = @course.enroll_students(@student1)
        @course_membership = @course_memberships.first
      end

      it "should return a single course membership" do
        expect(@course_memberships.count).to eq(1)
      end

      it "should be a course membership objec" do
        expect(@course_membership.class).to eq(CourseMembership)
      end

      it "should return a valid course membership" do
        expect(@course_membership.valid?).to eq(true)
      end
    end

    context "no students are enrolled" do
      before(:each) do
        @course_memberships = @course.enroll_students()
      end

      it "should not create any new enrollments" do
        expect(@course_memberships).to eq([])
      end
    end

    context "one student is already enrolled and one is not" do
      before(:each) do
        @course.enroll_students(@student1)
        @course_memberships = @course.enroll_students(@student1, @student2)
      end

      it "should only enroll one student" do
        @total_valid = @course_memberships.collect(&:valid?).count(true)
        expect(@total_valid).to eq(1)
      end

      it "should return a course membership for each student" do
        @total_course_memberships = @course_memberships.collect(&:class).count(CourseMembership)
        expect(@total_course_memberships).to eq(2)
      end

      it "should associate the student with the course memberships" do
        @course_membership_user_ids = @course_memberships.collect(&:user_id)
        expect(@course_membership_user_ids.count(@student1[:id])).to eq(1)
        expect(@course_membership_user_ids.count(@student2[:id])).to eq(1)
      end

      it "should enroll the unenrolled student" do
        pending
      end

      it "should not enroll the enrolled student" do
        pending
      end
    end

    context "one student is submitted and is already enrolled" do
      it "should not re-enroll the enrolled student" do
        pending
      end
    end
  end
end
