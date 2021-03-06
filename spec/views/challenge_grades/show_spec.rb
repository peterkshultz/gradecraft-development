# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "challenge_grades/show" do

  before(:all) do
    clean_models
    @course = create(:course)
    @challenge = create(:challenge, course: @course)
    @team = create(:team, course: @course)
    @challenge_grade = create(:challenge_grade, challenge: @challenge)
  end

  before(:each) do
    assign(:title, "#{@team.name}'s #{@challenge_grade.name} Grade")
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "#{@team.name}'s #{@challenge_grade.name} Grade", :count => 1
  end

  it "renders the breadcrumbs" do
    render
    assert_select ".content-nav", :count => 1
    assert_select ".breadcrumbs" do
      assert_select "a", :count => 4
    end
  end
end
