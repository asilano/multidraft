# encoding: utf-8
require 'spec_helper'

describe CardSet do

  describe "validations" do
    before(:each) { FactoryGirl.create(:card_set) }

    it { should validate_presence_of :name }
    it { should validate_presence_of :last_modified }
    it { should validate_presence_of :dictionary_location }
    it { should validate_uniqueness_of(:last_modified).scoped_to :name }
    it { should validate_uniqueness_of :dictionary_location }
  end

  describe "relations" do
    before(:each) { FactoryGirl.create(:card_set) }

    it { should have_many :card_templates }
  end

  describe "prepare known set for draft" do
    let(:card_set) { FactoryGirl.create(:card_set) }
    let(:academy_raider_params) {{name: 'Academy Raider',
                          rarity: 'Common',
                          fields: {
                            "layout" => 'normal',
                            "type" => 'Creature — Human Warrior',
                            "manaCost" => '{2}{R}',
                            "text" => "Intimidate (This creature can't be blocked except by artifact creatures and/or creatures that share a color with it.)\n\nWhenever Academy Raider deals combat damage to a player, you may discard a card. If you do, draw a card.",
                            "power" => '1',
                            "toughness" => '1',
                            "imageName" => 'academy raider'
                      }}}
    let(:glimpse_params) {{name: 'Glimpse the Future',
                           rarity: 'Uncommon',
                           fields: {
                            "layout" => 'normal',
                            "type" => 'Sorcery',
                            "manaCost" => '{2}{U}',
                            "text" => "Look at the top three cards of your library. Put one of them into your hand and the rest into your graveyard.",
                            "flavor"=> "\"No simple coin toss can solve this riddle. You must think and choose wisely.\"—Shai Fusan, archmage",
                            "imageName" => 'glimpse the future'
                      }}}
    let!(:academy_raider) { CardTemplate.new(academy_raider_params)}
    let!(:glimpse) { CardTemplate.new(glimpse_params)}

    it "with local set" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params, {}).and_return glimpse

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    # From a unit-testing point of view, this is identical to creating with a local set,
    # since _open_ returns a temporary file.
    it "with remote set" do
      card_set.remote_dictionary = true
      card_set.dictionary_location = 'http://www.example.com/magicSets/awesome.json'
      card_set.save!

      expect(card_set).to receive(:open).with(card_set.dictionary_location).
                          and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params, {}).and_return glimpse

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "when already set up" do
      academy_raider.card_set = card_set
      glimpse.card_set = card_set
      academy_raider.save!
      glimpse.save!

      expect(File).not_to receive(:open)
      expect(card_set).not_to receive(:open)
      expect(CardTemplate).not_to receive(:new)

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "with bugged JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_bugged.json'))

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_added(:card_templates, :missing_name)
      expect(card_set.errors).to be_added(:card_templates, :missing_rarity)

      # Check that each bugged card has been guessed at, and has the known fields set.
      bugged_card = CardTemplate.where(name: 'Unnamed Card 1').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Creature — Goblin"

      bugged_card = CardTemplate.where(name: 'Gnawing Zombie').first
      expect(bugged_card.rarity).to eq 'Common'

      bugged_card = CardTemplate.where(name: 'Unnamed Card 2').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Instant"
      expect(bugged_card.rarity).to eq 'Common'
    end

    it "with unparseable JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_broken.json'))

      expect(card_set.prepare_for_draft).to be_false
      expect(card_set.errors).to be_added(:dictionary_location, :unparseable)
    end

    it "with unavailable local file" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location) do
        raise Errno::ENOENT.new("No such file")
      end

      expect(card_set.prepare_for_draft).to be_false
      expect(card_set.errors).to be_added(:dictionary_location, :unavailable)
    end

    it "with unavailable remote JSON" do
      card_set.remote_dictionary = true
      card_set.dictionary_location = 'http://www.example.com/magicSets/awesome.json'
      card_set.save!

      expect(card_set).to receive(:open).with(card_set.dictionary_location) do
        raise Errno::ENOENT.new("No such file")
      end

      expect(card_set.prepare_for_draft).to be_false
      expect(card_set.errors).to be_added(:dictionary_location, :unavailable)
    end

    it "should correctly handle split cards" do
      turn_burn_params = {name: 'Turn',
                           rarity: 'Uncommon',
                           fields: {
                            "layout" => 'split',
                            "names" => ['Turn', 'Burn'],
                            "type" => ['Instant', 'Instant'],
                            "manaCost" => ['{2}{U}','{1}{R}'],
                            "text" => ["Target creature loses all abilities and becomes a 0/1 red Weird until end of turn.\n\nFuse (You may cast one or both halves of this card from your hand.)",
                                        "Burn deals 2 damage to target creature or player.\n\nFuse (You may cast one or both halves of this card from your hand.)"],
                            "imageName" => ['turnburn', 'turnburn']}
                          }
      alive_well_params = {name: 'Alive',
                           rarity: 'Uncommon',
                           fields: {
                            "layout" => 'split',
                            "names" => ['Alive', 'Well'],
                            "type" => ['Sorcery', 'Sorcery'],
                            "manaCost" => ['{3}{G}','{W}'],
                            "text" => ["Put a 3/3 green Centaur creature token onto the battlefield.\n\nFuse (You may cast one or both halves of this card from your hand.)",
                                       "You gain 2 life for each creature you control.\n\nFuse (You may cast one or both halves of this card from your hand.)"],
                            "imageName" => ['alivewell', 'alivewell']}
                          }
      turn_burn = CardTemplate.new(turn_burn_params)
      alive_well = CardTemplate.new(alive_well_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/splits_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(alive_well_params, {}).and_return alive_well
      expect(CardTemplate).to receive(:new).with(turn_burn_params, {}).and_return turn_burn

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle multiple-art cards" do
      plains_params = {name: 'Plains',
                        rarity: 'Basic Land',
                        fields: {
                          "layout" => 'normal',
                          "type" => ['Basic Land — Plains'] * 4,
                          "text" => ["W"] * 4,
                          "imageName" => %w<plains1 plains2 plains3 plains4>}
                      }
      plains = CardTemplate.new(plains_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/multi_art.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(plains_params, {}).and_return plains

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle flip cards" do
      erayo_params = {name: 'Erayo, Soratami Ascendant',
                      rarity: 'Rare',
                      fields: {
                        "layout" => 'flip',
                        "names" => ['Erayo, Soratami Ascendant', "Erayo's Essence"],
                        "type" => ["Legendary Creature — Moonfolk Monk", 'Legendary Enchantment'],
                        "power" => ['1', nil],
                        "toughness" => ['1', nil],
                        "manaCost" => ['{1}{U}', '{1}{U}'],
                        "text" => ["Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.",
                                    "Whenever an opponent casts a spell for the first time in a turn, counter that spell."],
                        "imageName" => ["erayo, soratami ascendant", "erayo's essence"]
                        }}
      bushi_params = {name: 'Bushi Tenderfoot',
                      rarity: 'Uncommon',
                      fields: {
                        "layout" => 'flip',
                        "names" => ['Bushi Tenderfoot', 'Kenzo the Hardhearted'],
                        "type" => ["Creature — Human Soldier", 'Legendary Creature — Human Samurai'],
                        "power" => ['1', '3'],
                        "toughness" => ['1', '4'],
                        "manaCost" => ['{W}', '{W}'],
                        "text" => ["When a creature dealt damage by Bushi Tenderfoot this turn dies, flip Bushi Tenderfoot.",
                                    "Double strike; bushido 2 (When this blocks or becomes blocked, it gets +2/+2 until end of turn.)"],
                        "imageName" => ["bushi tenderfoot", "kenzo the hardhearted"]
                        }}
      erayo = CardTemplate.new(erayo_params)
      bushi = CardTemplate.new(bushi_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/flips_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(bushi_params, {}).and_return bushi
      expect(CardTemplate).to receive(:new).with(erayo_params, {}).and_return erayo

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle double-faced cards" do
      hanweir_params = {name: 'Hanweir Watchkeep',
                        rarity: 'Uncommon',
                        fields: {
                          "layout" => 'double-faced',
                          "names" => ['Hanweir Watchkeep', 'Bane of Hanweir'],
                          "type" => ["Creature — Human Warrior Werewolf", 'Creature — Werewolf'],
                          "power" => ['1', '5'],
                          "toughness" => ['5', '5'],
                          "manaCost" => ['{2}{R}', nil],
                          "text" => ["Defender\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Hanweir Watchkeep.",
                                      "Bane of Hanweir attacks each turn if able.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Bane of Hanweir."],
                          "flavor" => ["He scans for wolves, knowing there's one he can never anticipate.",
                                        "Technically he never left his post. He looks after the wolf wherever it goes."],
                          "imageName" => ["hanweir watchkeep", "bane of hanweir"]
                        }}
      hanweir = CardTemplate.new(hanweir_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/dfc_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(hanweir_params, {}).and_return hanweir

      expect(card_set.prepare_for_draft).to be_true
      expect(card_set.errors).to be_empty
    end

    it "with non-unique card names" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_duplicates.json'))

      # Expect: 3 Academy Raiders, 2 Turns, Glimpse, Zephyr
      expect(CardTemplate).to receive(:new).exactly(7).times.and_call_original

      expect(card_set.prepare_for_draft).to be_true

      sorted_card_names = CardTemplate.pluck(:name).sort
      expect(sorted_card_names).to eq ['Academy Raider', 'Academy Raider', 'Academy Raider', 'Glimpse the Future', 'Turn', 'Turn', 'Zephyr Charge']
      expect(card_set.warnings).to include "The following names appear on two or more cards in '#{card_set.name}': 'Academy Raider', 'Turn'"
    end

  end

  describe "prepare brand new set for draft" do
    it "succeeds"
    it "with bugged JSON"
    it "with unparseable JSON"
    it "with unavailable JSON"
  end
end
