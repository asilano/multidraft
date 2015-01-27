# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :card_template do
    card_set
    name "Shock"
    slot 'Common'
    fields({'rarity' => 'Common',
            'type' => 'Instant',
            'manaCost' => '{R}',
            'text' => 'Shock deals 2 damage to target creature or player.',
            'imageName' => 'shock'})
  end
end
