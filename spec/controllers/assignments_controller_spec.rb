require 'spec_helper'

describe AssignmentsController do

  context "as a professor" do
    before do
      @course = create(:course_accepting_groups)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @assignment_type = create(:assignment_type, course: @course)
      @assignment = create(:assignment, assignment_type: @assignment_type)
      @course.assignments << @assignment
      @student = create(:user)
      @student.courses << @course

      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET index" do
      it "returns assignments for the current course" do
        get :index
        expect(assigns(:title)).to eq("assignments")
        expect(assigns(:assignment_types)).to eq([@assignment_type])
        expect(assigns(:assignments)).to eq([@assignment])
        expect(response).to render_template(:index)
      end
    end

    describe "GET settings" do
      it "returns title and assignments" do
        get :settings
        # TODO: notice, lib/course_terms.rb downcases the term_for assignments
        expect(assigns(:title)).to eq("Review assignment Settings")
        # TODO: confirm multiple assignments are chronological and alphabetical
        expect(assigns(:assignments)).to eq([@assignment])
        expect(response).to render_template(:settings)
      end
    end

    describe "GET show" do

      it "returns the assignment show page"do
        get :show, :id => @assignment.id
        expect(assigns(:assignment)).to eq(@assignment)
        expect(assigns(:assignment_type)).to eq(@assignment.assignment_type)
        expect(assigns(:title)).to eq(@assignment.name)
        expect(response).to render_template(:show)
      end

      it "assigns groups" do
        group = create(:group, course: @course)
        group.assignments << @assignment
        get :show, :id => @assignment.id
        expect(assigns(:groups)).to eq([group])
      end

      it "assigns grades" do
        grade = create(:grade, assignment: @assignment, student: @student)
        get :show, :id => @assignment.id
        expect(assigns(:grades)).to eq(@assignment.grades)
      end

      describe "with team id in params" do
        it "assigns team and students for team" do
          # we verify only students on team assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :show, {:id => @assignment.id, :team_id => team.id}
          expect(assigns(:team)).to eq(team)
          expect(assigns(:students)).to eq([@student])
        end

      end

      describe "with no team id in params" do
        it "assigns all students if no team supplied" do
          # we verify non-team members also assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :show, :id => @assignment.id
          expect(assigns(:students)).to include(@student)
          expect(assigns(:students)).to include(other_student)
        end

      end

      it "assigns the rubric as rubric" do
        rubric = create(:rubric_with_metrics, assignment: @assignment)
        get :show, :id => @assignment.id
        expect(assigns(:rubric)).to eq(rubric)
      end

      it "assigns course badges as JSON using CourseBadgeSerializer" do
        badge = create(:badge, course: @course)
        get :show, :id => @assignment.id
        expect(assigns(:course_badges)).to eq(ActiveModel::ArraySerializer.new([badge], each_serializer: CourseBadgeSerializer).to_json)
      end

      it "assigns assignment score levels ordered by value" do
        assignment_score_level_second = create(:assignment_score_level, assignment: @assignment, value: "1000")
        assignment_score_level_first = create(:assignment_score_level, assignment: @assignment, value: "100")
        get :show, :id => @assignment.id
        expect(assigns(:assignment_score_levels)).to eq([assignment_score_level_first,assignment_score_level_second])
      end

      it "assigns student ids" do
        get :show, :id => @assignment.id
        expect(assigns(:course_student_ids)).to eq([@student.id])
      end

      it "assigns data for displaying student grading distribution" do
        skip "need to create a scored grade"
        ungraded_submission = create(:submission, assignment: @assignment)
        student_submission = create(:graded_submission, assignment: @assignment, student: @student)
        @assignment.submissions << [student_submission, ungraded_submission]
        get :show, :id => @assignment.id
        expect(assigns(:submissions_count)).to eq(2)
        expect(assigns(:ungraded_submissions_count)).to eq(1)
        expect(assigns(:ungraded_percentage)).to eq(1/2)
        expect(assigns(:graded_count)).to eq(1)
      end

      # GET show, professor specific:

      it "assigns grades for assignment" do
        grade = create(:grade, student: @student, assignment: @assignment)
        get :show, :id => @assignment.id
        expect(assigns(:grades_for_assignment)).to eq(@assignment.all_grades_for_assignment)
      end
    end

    describe "GET new" do
      it "assigns title and assignments" do
        get :new
        expect(assigns(:title)).to eq("Create a New assignment")
        expect(assigns(:assignment)).to be_a_new(Assignment)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "assigns title and assignments" do
        get :edit, :id => @assignment.id
        expect(assigns(:title)).to eq("Editing #{@assignment.name}")
        expect(assigns(:assignment)).to eq(@assignment)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST copy" do
      it "duplicates an assignment" do
        post :copy, :id => @assignment.id
        expect expect(@course.assignments.count).to eq(2)
      end
    end

    describe "POST create" do
      it "creates the assignment with valid attributes"  do
        params = attributes_for(:assignment)
        params[:assignment_type_id] = @assignment_type
        expect{ post :create, :assignment => params }.to change(Assignment,:count).by(1)
      end

      it "manages file uploads" do
        Assignment.delete_all
        params = attributes_for(:assignment)
        params[:assignment_type_id] = @assignment_type
        params.merge! :assignment_files_attributes => {"0" => {"file" => [fixture_file('test_file.txt', 'txt')]}}
        post :create, :assignment => params
        assignment = Assignment.where(name: params[:name]).last
        expect expect(assignment.assignment_files.count).to eq(1)
      end

      it "redirects to new from with invalid attributes" do
        expect{ post :create, assignment: attributes_for(:assignment, name: nil) }.to_not change(Assignment,:count)
      end
    end

    describe "POST update" do
      it "updates the assignment" do
        params = { name: "new name" }
        post :update, id: @assignment.id, :assignment => params
        @assignment.reload
        expect(response).to redirect_to(assignments_path)
        expect(@assignment.name).to eq("new name")
      end

      it "manages file uploads" do
        params = {:assignment_files_attributes => {"0" => {"file" => [fixture_file('test_file.txt', 'txt')]}}}
        post :update, id: @assignment.id, :assignment => params
        expect expect(@assignment.assignment_files.count).to eq(1)
      end
    end

    describe "GET sort" do
      it "sorts the assignments by params" do
        @second_assignment = create(:assignment, assignment_type: @assignment_type)
        @course.assignments << @second_assignment
        params = [@second_assignment.id, @assignment.id]
        post :sort, :assignment => params

        @assignment.reload
        @second_assignment.reload
        expect(@assignment.position).to eq(2)
        expect(@second_assignment.position).to eq(1)
      end
    end

    describe "GET update_rubrics" do
      it "assigns true or false to assignment use_rubric" do
        @assignment.update(:use_rubric => false)
        post :update_rubrics, :id => @assignment, :use_rubric => true
        @assignment.reload
        expect(@assignment.use_rubric).to be_truthy
      end
    end

    describe "GET rubric_grades_review" do
      it "assigns attributes for display" do
        group = create(:group, course: @course)
        group.assignments << @assignment

        get :rubric_grades_review, :id => @assignment
        expect(assigns(:title)).to eq(@assignment.name)
        expect(assigns(:assignment)).to eq(@assignment)
        expect(assigns(:groups)).to eq([group])
        expect(response).to render_template(:rubric_grades_review)
      end

      it "assigns the rubric as rubric" do
        rubric = create(:rubric_with_metrics, assignment: @assignment)
        get :rubric_grades_review, :id => @assignment.id
        expect(assigns(:rubric)).to eq(rubric)
      end

      it "assigns assignment score levels ordered by value" do
        assignment_score_level_second = create(:assignment_score_level, assignment: @assignment, value: "1000")
        assignment_score_level_first = create(:assignment_score_level, assignment: @assignment, value: "100")
        get :rubric_grades_review, :id => @assignment.id
        expect(assigns(:assignment_score_levels)).to eq([assignment_score_level_first,assignment_score_level_second])
      end

      it "assigns student ids" do
        get :rubric_grades_review, :id => @assignment.id
        expect(assigns(:course_student_ids)).to eq([@student.id])
      end

      it "assigns rubric grades" do
        skip "implement"
        rubric = create(:rubric_with_metrics, assignment: @assignment)
        # TODO: Test for these lines:
        # @rubric_grades = serialized_rubric_grades
        # @viewable_rubric_grades = RubricGrade.where(assignment_id: @assignment.id)
        get :rubric_grades_review, :id => @assignment.id
        expect(assigns(:rubric_grades)).to eq("?")
        expect(assigns(:viewable_rubric_grades)).to eq("?")
      end

      it "assigns comments by metric id" do
        skip "implement"
        get :rubric_grades_review, :id => @assignment.id
        expect(assigns(:comments_by_metric_id)).to eq("?")
      end

      describe "with team id in params" do
        it "assigns team and students for team" do
          # we verify only students on team assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :rubric_grades_review, {:id => @assignment.id, :team_id => team.id}
          expect(assigns(:team)).to eq(team)
          expect(assigns(:students)).to eq([@student])
        end

      end

      describe "with no team id in params" do
        it "assigns all students if no team supplied" do
          # we verify non-team members also assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :rubric_grades_review, :id => @assignment.id
          expect(assigns(:students)).to include(@student)
          expect(assigns(:students)).to include(other_student)
        end
      end
    end

    describe "GET destroy" do
      it "destroys the assignment" do
        expect{ get :destroy, :id => @assignment }.to change(Assignment,:count).by(-1)
      end
    end

    describe "GET grade_import" do
      context "with CSV format" do
        it "returns sample csv data" do
          get :grade_import, :id => @assignment, :format => :csv
          expect(response.body).to include("First Name,Last Name,Email,Score,Feedback")
        end
      end
    end

    describe "GET export_grades" do
      context "with CSV format" do
        it "returns sample csv data" do
          grade = create(:grade, assignment: @assignment, student: @student, feedback: "good jorb!")
          submission = create(:submission, grade: grade, student: @student, assignment: @assignment)
          get :export_grades, :id => @assignment, :format => :csv
          expect(response.body).to include("First Name,Last Name,Uniqname,Score,Raw Score,Statement,Feedback")
        end
      end
    end

    describe "GET export_submissions" do
      context "with ZIP format" do
        it "returns a zip directory" do
          get :export_submissions, :id => @assignment, :format => :zip
          expect(response.content_type).to eq("application/zip")
        end
      end
    end
  end

  context "as a student" do
    before do
      @course = create(:course_accepting_groups)
      @student = create(:user)
      @student.courses << @course
      login_user(@student)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET index" do
      it "redirects to syllabus path" do
        expect(get :index).to redirect_to("/syllabus")
      end
    end

    describe "GET show" do
      before do
        assignment_type = create(:assignment_type, course: @course)
        @assignment = create(:assignment)
        @course.assignments << @assignment
      end

      it "returns the assignment show page" do
        get :show, :id => @assignment.id
        expect(assigns(:assignment)).to eq(@assignment)
        expect(assigns(:assignment_type)).to eq(@assignment.assignment_type)
        expect(assigns(:title)).to eq(@assignment.name)
        expect(response).to render_template(:show)
      end

      it "assigns groups" do
        group = create(:group, course: @course)
        group.assignments << @assignment
        get :show, :id => @assignment.id
        expect(assigns(:groups)).to eq([group])
      end

      it "assigns grades" do
        grade = create(:grade, assignment: @assignment, student: @student)
        get :show, :id => @assignment.id
        expect(assigns(:grades)).to eq(@assignment.grades)
      end

      it "marks the grade as reviewed" do
        grade = create :grade, assignment: @assignment, student: @student, status: "Graded"
        get :show, :id => @assignment.id
        expect(grade.reload).to be_feedback_reviewed
      end

      describe "with team id in params" do
        it "assigns team and students for team" do
          # we verify only students on team assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :show, {:id => @assignment.id, :team_id => team.id}
          expect(assigns(:team)).to eq(team)
          expect(assigns(:students)).to eq([@student])
        end

      end

      describe "with no team id in params" do
        it "assigns all students if no team supplied" do
          # we verify non-team members also assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :show, :id => @assignment.id
          expect(assigns(:students)).to include(@student)
          expect(assigns(:students)).to include(other_student)
        end
      end

      it "assigns the rubric as rubric" do
        rubric = create(:rubric_with_metrics, assignment: @assignment)
        get :show, :id => @assignment.id
        expect(assigns(:rubric)).to eq(rubric)
      end

      it "assigns course badges as JSON using CourseBadgeSerializer" do
        badge = create(:badge, course: @course)
        get :show, :id => @assignment.id
        expect(assigns(:course_badges)).to eq(ActiveModel::ArraySerializer.new([badge], each_serializer: CourseBadgeSerializer).to_json)
      end

      it "assigns assignment score levels ordered by value" do
        assignment_score_level_second = create(:assignment_score_level, assignment: @assignment, value: "1000")
        assignment_score_level_first = create(:assignment_score_level, assignment: @assignment, value: "100")
        get :show, :id => @assignment.id
        expect(assigns(:assignment_score_levels)).to eq([assignment_score_level_first,assignment_score_level_second])
      end

      it "assigns student ids" do
        get :show, :id => @assignment.id
        expect(assigns(:course_student_ids)).to eq([@student.id])
      end

      it "assigns data for displaying student grading distribution" do
        skip "need to create a scored grade"
        ungraded_submission = create(:submission, assignment: @assignment)
        student_submission = create(:graded_submission, assignment: @assignment, student: @student)
        @assignment.submissions << [student_submission, ungraded_submission]
        get :show, :id => @assignment.id
        expect(assigns(:submissions_count)).to eq(2)
        expect(assigns(:ungraded_submissions_count)).to eq(1)
        expect(assigns(:ungraded_percentage)).to eq(1/2)
        expect(assigns(:graded_count)).to eq(1)
      end

      # GET show, student specific specs:

      it "assigns grades for assignment" do
        grade = create(:grade, student: @student, assignment: @assignment)
        get :show, :id => @assignment.id
        expect(assigns(:grades_for_assignment)).to eq(@assignment.grades_for_assignment(@student))
      end

      it "assigns rubric grades" do
        skip "implement"
        rubric = create(:rubric_with_metrics, assignment: @assignment)
        # TODO: Test for this line:
        # @rubric_grades = RubricGrade.joins("left outer join submissions on submissions.id = rubric_grades.submission_id").where(student_id: current_user[:id]).where(assignment_id: params[:id])
        get :show, :id => @assignment.id
        expect(assigns(:rubric_grades)).to eq("?")
      end

      it "assigns comments by metric id" do
        skip "implement"
        get :show, :id => @assignment.id
        expect(assigns(:comments_by_metric_id)).to eq("?")
      end

      it "assigns group if student is in a group" do
        @assignment.update(grade_scope: "Group")
        group = create(:group, course: @course)
        group.assignments << @assignment
        group.students << @student
        get :show, :id => @assignment.id
        expect(assigns(:group)).to eq(group)
      end
    end

    describe "protected routes" do
      [
        :new,
        :copy,
        :create,
        :sort

      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route).to redirect_to(:root)
        end
      end
    end

    describe "protected routes requiring id in params" do
      [
        :edit,
        :update,
        :destroy,
        :export_grades,
        :grade_import,
        :update_rubrics,
        :rubric_grades_review

      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {:id => "1"}).to redirect_to(:root)
        end
      end
    end
  end
end
