json.assignment_types @assignment_types do |assignment_type|
  json.cache! ['v1', assignment_type] do
    json.merge! assignment_type.attributes
    json.total_points assignment_type.total_points
    if assignment_type.student_weightable?
      json.student_weight  @student.weight_for_assignment_type(assignment_type)
    end
    json.is_capped assignment_type.is_capped?
  end
end

json.term_for_assignment_type term_for :assignment_type
