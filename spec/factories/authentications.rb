# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :authentication do
    provider "open_id"
    uid 'http://pretend.openid.example.com?id=12345'
    nickname 'http://pretend.openid.example.com'
    user
  end

  factory :second_openid, :class => Authentication do
    provider "open_id"
    uid 'http://fake.openid.example.com?uid=deadbeef'
    nickname 'Fake OpenID'
    user
  end
end
