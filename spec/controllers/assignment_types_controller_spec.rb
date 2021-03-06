#spec/controllers/assignment_types_controller_spec.rb
require 'spec_helper'

describe AssignmentTypesController do

	context "as professor" do

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
      it "returns assignment types for the current course" do
        get :index
        expect(assigns(:title)).to eq("assignment types")
        expect(assigns(:assignment_types)).to eq([@assignment_type])
        expect(response).to render_template(:index)
      end
    end

		describe "GET show" do
      it "returns the assignment type show page" do
        get :show, :id => @assignment_type.id
        expect(assigns(:title)).to eq(@assignment_type.name)
        expect(assigns(:assignment_type)).to eq(@assignment_type)
        expect(response).to render_template(:show)
      end
    end

		describe "GET new" do
      it "assigns title and assignment types" do
        get :new
        expect(assigns(:title)).to eq("Create a New assignment type")
        expect(assigns(:assignment_type)).to be_a_new(AssignmentType)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "assigns title and assignment types" do
        get :edit, :id => @assignment_type.id
        expect(assigns(:title)).to eq("Editing #{@assignment_type.name}")
        expect(assigns(:assignment_type)).to eq(@assignment_type)
        expect(response).to render_template(:edit)
      end
    end

		describe "POST create" do
      it "creates the assignment type with valid attributes"  do
        params = attributes_for(:assignment_type)
        params[:assignment_type_id] = @assignment_type
        expect{ post :create, :assignment_type => params }.to change(AssignmentType,:count).by(1)
      end

      it "redirects to new from with invalid attributes" do
        expect{ post :create, assignment_type: attributes_for(:assignment_type, name: nil) }.to_not change(AssignmentType,:count)
      end
    end

		describe "POST update" do
      it "updates the assignment" do
        params = { name: "new name" }
        post :update, id: @assignment_type.id, :assignment_type => params
        @assignment_type.reload
        expect(response).to redirect_to(assignment_types_path)
        expect(@assignment_type.name).to eq("new name")
      end
    end

		describe "GET sort" do
      it "sorts the assignment types by params" do
        @second_assignment_type = create(:assignment_type, course: @course)
        @course.assignment_types << @second_assignment_type
        params = [@second_assignment_type.id, @assignment_type.id]
        post :sort, "assignment-type" => params

        @assignment_type.reload
        @second_assignment_type.reload
        expect(@assignment_type.position).to eq(2)
        expect(@second_assignment_type.position).to eq(1)
      end
    end

		describe "GET export_scores" do
      context "with CSV format" do
        it "returns scores in csv form" do
          grade = create(:grade, assignment: @assignment, student: @student, feedback: "good jorb!")
          get :export_scores, :id => @assignment_type, :format => :csv
          expect(response.body).to include("First Name,Last Name,Username,Raw Score")
        end
      end
    end

		describe "GET export_all_scores" do
      context "with CSV format" do
        it "returns all scores in csv form" do
          grade = create(:grade, assignment: @assignment, student: @student, feedback: "good jorb!")
          get :export_all_scores, :id => @assignment_type, :format => :csv
          expect(response.body).to include("First Name,Last Name,Email,Username,Team")
        end
      end
    end

		describe "GET all_grades" do
      it "displays all grades for an assignment type" do
        get :all_grades, :id => @assignment_type.id
        expect(assigns(:title)).to eq("#{@assignment_type.name} Grade Patterns")
        expect(assigns(:assignment_type)).to eq(@assignment_type)
        expect(response).to render_template(:all_grades)
      end
    end

		describe "GET destroy" do
      it "destroys the assignment type" do
        expect{ get :destroy, :id => @assignment_type }.to change(AssignmentType,:count).by(-1)
      end
    end

	end

	context "as student" do

		describe "protected routes" do
      [
        :index,
        :new,
        :create,
        :sort,
        :export_all_scores

      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end


    describe "protected routes requiring id in params" do
      [
        :edit,
        :show,
        :update,
        :destroy,
        :export_scores,
        :all_grades
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {:id => "1"}).to redirect_to(:root)
        end
      end
    end

	end

end
