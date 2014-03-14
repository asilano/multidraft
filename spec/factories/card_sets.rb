# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :card_set do
    name "Awesome Card Set"
    remote_dictionary false
    dictionary_location "sets/awesome.json"
  end
end
