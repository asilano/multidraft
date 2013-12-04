# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Person#{n}" }
    email { "#{name}@example.com" }
    password 'secret'
  end
end
