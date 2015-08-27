require 'spec_helper'
 
feature 'Professor awards badges to multiple students at once' do
  scenario 'professor awards earnable badges' do
    given_a_course_with_a_badge_and_some_students
    given_i_am_logged_in_as_a_professor
    when_i_visit_the_mass_award_page_for_the_badge
    and_i_click_the_checkboxes_for_two_students
    then_i_should_be_redirected_to_the_badge_page
    and_i_should_see_a_notification_that_earned_badges_were_created
  end

  scenario 'professor cannot award unearnable badges' do
    given_a_course_with_a_badge_and_a_student_named_("jeffrey caruthers")
    given_i_am_logged_in_as_a_professor
  end

  scenario 'professor can see other student earned badges for current badge' do
  end

  scenario 'professor decides not to award badges and cancels' do
  end

  def given_a_course_with_a_badge_and_a_student_named_(student_name)
  end

  def given_a_course
    @course = create(:course)
  end

  def given_i_am_logged_in_as_a_professor
    @professor = create(:user)
    @professor.courses << @course
    @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
    login_user(@professor)
  end

  def when_i_visit_the_mass_award_page_for_the_badge
    visit mass_earn_badges_path(badge)
  end
end
