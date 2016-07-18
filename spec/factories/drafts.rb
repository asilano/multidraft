FactoryGirl.define do
  factory :draft do
    sequence(:name) { |n| "Draft number #{n}" }
  end

  factory :bad_draft, class: Draft do
    name nil
  end
end
