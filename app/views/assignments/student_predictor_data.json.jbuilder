json.assignments @assignments do |assignment|
  json.cache! ['v1', assignment] do
    next unless assignment.point_total > 0 || assignment.pass_fail?
    next unless assignment.visible_for_student?(@student)
    json.merge! assignment.attributes
    json.score_levels assignment.assignment_score_levels.map {|asl| {name: asl.name, value: asl.value}}
    json.fixed assignment.fixed?
    json.info ! assignment.description.blank?

    if assignment.current_student_grade
      assignment.current_student_grade.tap do |grade|
        json.cache! ['v1', grade] do
          json.grade do
            json.id grade.id
            json.predicted_score grade.predicted_score
            json.score grade.score
            json.pass_fail_status grade.pass_fail_status if assignment.pass_fail
          end
        end
      end
    end

    json.late assignment.past? && assignment.accepts_submissions && ! @student.submission_for_assignment(assignment).present? ? true : false
    json.locked ! assignment.is_unlocked_for_student?(@student)
    json.unlocked assignment.is_unlockable? && assignment.is_unlocked_for_student?(@student)
    if assignment.is_unlockable?
      json.unlock_conditions assignment.unlock_conditions.map{ |condition|
        "#{condition.name} must be #{condition.condition_state}"
      }
    end
    json.condition assignment.is_a_condition?
    if assignment.is_a_condition?
      json.unlock_keys assignment.unlock_keys.map{ |key|
        "#{key.unlockable.name} is unlocked by #{key.condition_state} #{key.condition.name}"
      }
    end
  end
end

json.term_for_assignment term_for :assignment
json.term_for_pass current_course.pass_term
json.term_for_fail current_course.fail_term
json.update_assignments @update_assignments

json.student current_user.is_student?(current_course)
