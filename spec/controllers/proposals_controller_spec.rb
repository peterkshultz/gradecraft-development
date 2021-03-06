require 'spec_helper'

describe ProposalsController do

  context "as a professor" do
    before do
      @course = create(:course)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @student = create(:user)
      @student.courses << @course

      @assignment = create(:assignment)
      @group = create(:group)
      @proposal = create(:proposal)

      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET destroy" do
      it "destroys the proposal" do
        expect{ delete :destroy, :group_id => @group.id, :id => @proposal.id }.to change(Proposal,:count).by(-1)
      end
    end

  end

  context "as a student" do

    before do
      @course = create(:course)
      @student = create(:user)
      @student.courses << @course

      @assignment = create(:assignment)
      @group = create(:group)
      @proposal = create(:proposal)

      login_user(@student)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET destroy" do
      it "destroys the proposal" do
        expect{ delete :destroy, :group_id => @group.id, :id => @proposal.id }.to change(Proposal,:count).by(-1)
      end
    end

  end

end
