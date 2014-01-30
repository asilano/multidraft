# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Person#{n}" }
    email { "#{name}@example.com" }
    password 'secret'

    factory :confirmed_user do
      confirmed_at Time.now

      factory :open_id_user do
        provider 'open_id'
        uid 'http://pretend.openid.example.com?id=12345'
      end
    end
  end
end
