#spec/controllers/staff_controller_spec.rb
require 'spec_helper'

describe StaffController do

	context "as a professor" do

    before do
      @course = create(:course)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @challenge = create(:challenge, course: @course)
      @course.challenges << @challenge
      @challenges = @course.challenges
      @student = create(:user)
      @student.courses << @course
      @team = create(:team, course: @course)
      @team.students << @student
      @teams = @course.teams

      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

		describe "GET index" do
      it "returns all staff for the current course" do
        get :index
        expect(assigns(:title)).to eq("Staff Index")
        expect(assigns(:staff)).to eq([@professor])
        expect(response).to render_template(:index)
      end
    end

		describe "GET show" do
      it "displays a single staff member's page" do
        get :show, :id => @professor.id
        expect(assigns(:staff)).to eq(@professor)
        expect(response).to render_template(:show)
      end
    end

	end

	context "as a student" do
		describe "protected routes" do
      [
        :index
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :show
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {:id => "1"}).to redirect_to(:root)
        end
      end
    end

	end
end
