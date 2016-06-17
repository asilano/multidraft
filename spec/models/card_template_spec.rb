# encoding: utf-8
require 'rails_helper'

describe CardTemplate do
  describe "validations" do
    before(:each) { FactoryGirl.create(:card_template) }

    it { should validate_presence_of :name }
    it { should validate_presence_of :slot }
    it { should validate_presence_of :layout }
    it { should_not validate_uniqueness_of(:name).scoped_to :card_set_id }
  end

  describe "relations" do
    before(:each) { FactoryGirl.create(:card_template) }

    it { should belong_to :card_set }
    it { should have_many :card_instances }
  end

  describe "part splitting function" do
    it "should work on a single-part card" do
      card = FactoryGirl.create(:card_template)
      parts = nil
      expect { parts = card.text_parts }.not_to change { CardTemplate.count }
      expect(parts).to eq [card]
    end

    it "should work on a single-part card with multiple flavors and images" do
      card = build_card name: 'Island',
                        slot: 'Basic',
                        fields: {'text' => '{U}',
                                  'flavor' => ['Splosh!', 'Glug!'],
                                  'multiverseid' => [12345, 67890]
                        }
      parts = nil
      expect { parts = card.text_parts }.not_to change { CardTemplate.count }
      expect(parts).to eq [card.card_template]
    end

    it "should work on a single-part card with 'normal' layout" do
      card = build_card name: 'Island',
                        slot: 'Basic',
                        fields: {'text' => ['{U}', '{U}'],
                                  'flavor' => ['Splosh!', 'Glug!'],
                                  'multiverseid' => [14916, 253649]
                        }
      parts = nil
      expect { parts = card.text_parts }.not_to change { CardTemplate.count }
      expect(parts.length).to eq 1
      expect(parts[0].fields).to eq({'text' => '{U}', 'flavor' => 'Splosh!', 'multiverseid' => 14916})
    end

    it "should work on a double-faced card" do
      watchkeep = build_card name: 'Hanweir Watchkeep',
                              slot: 'Double Faced',
                              layout: 'double-faced',
                              fields: {
                                'rarity' => 'Uncommon',
                                "names" => ['Hanweir Watchkeep', 'Bane of Hanweir'],
                                "type" => ['Creature — Human Warrior Werewolf', 'Creature — Werewolf'],
                                "power" => ['1', '5'],
                                "toughness" => ['5', '5'],
                                "manaCost" => ['{2}{R}', nil],
                                "text" => ["Defender\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Hanweir Watchkeep.",
                                            "Bane of Hanweir attacks each turn if able.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Bane of Hanweir."],
                                "flavor" => ["He scans for wolves, knowing there's one he can never anticipate.",
                                              "Technically he never left his post. He looks after the wolf wherever it goes."]
                              }

      parts = nil
      expect { parts = watchkeep.text_parts }.not_to change { CardTemplate.count }
      expect(parts.length).to eq 2
      expect(parts[0].name).to eq 'Hanweir Watchkeep'
      expect(parts[0].fields).to eq ({'rarity' => 'Uncommon',
                                      "type" => 'Creature — Human Warrior Werewolf',
                                      'names' => 'Hanweir Watchkeep',
                                      "power" => '1',
                                      "toughness" => '5',
                                      "manaCost" => '{2}{R}',
                                      "text" => "Defender\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Hanweir Watchkeep.",
                                      "flavor" => "He scans for wolves, knowing there's one he can never anticipate."
                                    })
      expect(parts[1].name).to eq 'Bane of Hanweir'
      expect(parts[1].fields).to eq ({"type" => 'Creature — Werewolf',
                                      'names' => 'Bane of Hanweir',
                                      "power" => '5',
                                      "toughness" => '5',
                                      "text" => "Bane of Hanweir attacks each turn if able.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Bane of Hanweir.",
                                      "flavor" => "Technically he never left his post. He looks after the wolf wherever it goes."
                                    })

    end

    it "should work on a three-part card" do
      rps = build_card name: 'Rock, Paper, Scissors',
                        slot: 'Any',
                        layout: 'three',
                        fields: {
                          'rarity' => 'Any',
                          'names' => ['Rock', 'Paper', 'Scissors'],
                          'text' => ['Beats Scissors; loses to Paper', 'Beats Rock; loses to Scissors', 'Beats Paper; loses to Rock']
                        }

      parts = nil
      expect { parts = rps.text_parts }.not_to change { CardTemplate.count }
      expect(parts.length).to eq 3
      expect(parts[0].name).to eq 'Rock'
      expect(parts[0].fields).to eq ({'rarity' => 'Any',
                                      'names' => 'Rock',
                                      'text' => 'Beats Scissors; loses to Paper'})
      expect(parts[1].name).to eq 'Paper'
      expect(parts[1].fields).to eq ({'names' => 'Paper',
                                      'text' => 'Beats Rock; loses to Scissors'})
      expect(parts[2].name).to eq 'Scissors'
      expect(parts[2].fields).to eq ({'names' => 'Scissors',
                                      'text' => 'Beats Paper; loses to Rock'})
    end

    it "should not work on a confused card" do
      confused = build_card name: 'Confused',
                            slot: 'Common',
                            layout: 'confusing',
                            fields: {
                              'text' => ['Two', 'parts'],
                              'cost' => ['or', 'three', 'parts?']
                            }
      parts = nil
      expect { parts = confused.text_parts }.not_to change { CardTemplate.count }
      expect(parts).to eq [confused.card_template]
    end
  end
end
