FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.user_name }
    email { Faker::Internet.email }
    password { "secret" }

    after(:create) { |user| user.activate! }

    factory :student do
      role { "student" }
    end

    factory :auditing_student do
      auditing { true }
    end
  end
end
