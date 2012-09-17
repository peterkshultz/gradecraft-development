class AssignmentType < ActiveRecord::Base
  attr_accessible :due_date_present, :levels, :max_value, :name, :percentage_course, :point_setting, :points_predictor_display, :predictor_description, :resubmission, :universal_point_value, :course_id, :order_placement, :user_percentage_set, :mass_grade, :score_levels_attributes, :score_level, :mass_grade_type
  
  belongs_to :course
  belongs_to :grade_scheme
  has_many :assignments
  has_many :grades, :through => :assignments
  has_many :user_assignment_type_weights
  has_many :score_levels
  accepts_nested_attributes_for :score_levels, allow_destroy: true
  
  default_scope :order => 'order_placement ASC'
  
  def weight 
    if percentage_course?
      percentage_course.to_s << "%"
    elsif max_value?
      max_value.to_s << " possible points"
    elsif student_choice?
      "You decide!"
    else
      possible_score.to_s << " possible points"
    end
  end
  
  def student_choice?
    user_percentage_set == "true"
  end
  
  def possible_score
    self.assignments.sum(:point_total) || 0
  end

  def slider?
    points_predictor_display == "Slider"
  end
  
  def fixed?
    points_predictor_display == "Fixed"
  end
  
  def select?
    points_predictor_display == "Select List"
  end
  
  def has_level? 
    levels == 1
  end
  
  def grade_checkboxes?
    mass_grade_type == "Checkbox"
  end 
  
  def grade_select? 
    mass_grade_type == "Select List"
  end 
  
  def grade_radio?
    mass_grade_type =="Radio Buttons"
  end

end
