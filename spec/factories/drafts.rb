FactoryGirl.define do
  factory :draft do
    name "MyString"
  end

  factory :bad_draft, class: Draft do
    name nil
  end
end
