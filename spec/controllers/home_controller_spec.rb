# spec/controllers/home_controller_spec.rb

require 'spec_helper'

describe HomeController do

  before do
    allow(Resque).to receive(:enqueue).and_return(true)
  end

	context "as professor" do

		before do
      @course = create(:course)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")

      login_user(@professor)
      session[:course_id] = @course.id
    end

		describe "GET index" do
			it "redirects to the dashboard path" do
        get :index
        expect(response).to redirect_to(dashboard_path)
      end
		end

	end

	context "as student" do

		before do
      @course = create(:course)
      @student = create(:user)
      @student.courses << @course

      login_user(@student)
      session[:course_id] = @course.id
    end

		describe "GET index" do
			it "redirects to the dashboard path" do
				assigns(:current_user_id => @student.id)
        get :index
        expect(response).to redirect_to(dashboard_path)
      end
		end

	end
end
