FactoryGirl.define do
  factory :grade_file do
    association :grade
    filename "test_file.rb"
    file { fixture_file('test_image.jpg', 'img/jpg') }
  end
end
