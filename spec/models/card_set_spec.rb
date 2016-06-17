# encoding: utf-8
require 'rails_helper'

describe CardSet do
  let(:academy_raider_params) {{name: 'Academy Raider',
                        slot: 'Common',
                        layout: 'normal',
                        fields: {
                          'rarity' => 'Common',
                          "type" => 'Creature — Human Warrior',
                          "manaCost" => '{2}{R}',
                          "text" => "Intimidate (This creature can't be blocked except by artifact creatures and/or creatures that share a color with it.)\n\nWhenever Academy Raider deals combat damage to a player, you may discard a card. If you do, draw a card.",
                          "power" => '1',
                          "toughness" => '1',
                          'multiverseid' => 12345,
                          "cardCode" => 'CR01',
                          "editURL" => 'http://multiverse.example.com/cards/12345'
                    }}}
  let(:glimpse_params) {{name: 'Glimpse the Future',
                         slot: 'Uncommon',
                        layout: 'normal',
                         fields: {
                          'rarity' => 'Uncommon',
                          "type" => 'Sorcery',
                          "manaCost" => '{2}{U}',
                          "text" => "Look at the top three cards of your library. Put one of them into your hand and the rest into your graveyard.",
                          "flavor"=> "\"No simple coin toss can solve this riddle. You must think and choose wisely.\"—Shai Fusan, archmage",
                          "multiverseid" => 370774,
                          "cardCode" => 'UU10',
                          "editURL" => 'http://multiverse.example.com/cards/54300'
                    }}}
  let!(:academy_raider) { CardTemplate.new(academy_raider_params)}
  let!(:glimpse) { CardTemplate.new(glimpse_params)}

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

    it "with local set" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params).and_return glimpse

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
      expect(card_set.card_templates(true).map(&:name).sort).to eq ['Academy Raider', 'Glimpse the Future']
    end

    it "with remote set" do
      card_set.remote_dictionary = true
      card_set.dictionary_location = 'http://www.example.com/magicSets/awesome.json'
      card_set.save!

      expect(card_set).to receive(:open).with(card_set.dictionary_location).
                          and_return open File.join(File.dirname(__FILE__), '../data/awesome.json')

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params).and_return glimpse

      expect(card_set.prepare_for_draft).to be_truthy
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

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "with bugged JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_bugged.json'))

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.warnings).to include("2 cards in '#{card_set.name}' were received without names. They have been named 'Unnamed Card 1' etc.")
      expect(card_set.warnings).to include("The following cards in '#{card_set.name}' were received without rarities. They have been defaulted to Common: 'Gnawing Zombie', 'Unnamed Card 2'")

      # Check that each bugged card has been guessed at, and has the known fields set.
      bugged_card = CardTemplate.where(name: 'Unnamed Card 1').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Creature — Goblin"

      bugged_card = CardTemplate.where(name: 'Gnawing Zombie').first
      expect(bugged_card.slot).to eq 'Common'

      bugged_card = CardTemplate.where(name: 'Unnamed Card 2').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Instant"
      expect(bugged_card.slot).to eq 'Common'
    end

    it "with unparseable JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_broken.json'))

      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :unparseable)
    end

    it "with unavailable local file" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location) do
        raise Errno::ENOENT.new("No such file")
      end

      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :unavailable)
    end

    it "with unavailable remote JSON" do
      card_set.remote_dictionary = true
      card_set.dictionary_location = 'http://www.example.com/magicSets/awesome.json'
      card_set.save!

      expect(card_set).to receive(:open).with(card_set.dictionary_location) do
        raise Errno::ENOENT.new("No such file")
      end

      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :unavailable)
    end

    it "fails with no booster distribution" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_no_booster.json'))

      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :no_booster)
    end

    it "should correctly handle split cards" do
      turn_burn_params = {name: 'Turn',
                           slot: 'Uncommon',
                           layout: 'split',
                           fields: {
                            'rarity' => 'Uncommon',
                            "names" => ['Turn', 'Burn'],
                            "type" => ['Instant', 'Instant'],
                            "manaCost" => ['{2}{U}','{1}{R}'],
                            "text" => ["Target creature loses all abilities and becomes a 0/1 red Weird until end of turn.\n\nFuse (You may cast one or both halves of this card from your hand.)",
                                        "Burn deals 2 damage to target creature or player.\n\nFuse (You may cast one or both halves of this card from your hand.)"],
                            "multiverseid" => [369080, 369080]}
                          }
      alive_well_params = {name: 'Alive',
                           slot: 'Uncommon',
                           layout: 'split',
                           fields: {
                            'rarity' => 'Uncommon',
                            "names" => ['Alive', 'Well'],
                            "type" => ['Sorcery', 'Sorcery'],
                            "manaCost" => ['{3}{G}','{W}'],
                            "text" => ["Put a 3/3 green Centaur creature token onto the battlefield.\n\nFuse (You may cast one or both halves of this card from your hand.)",
                                       "You gain 2 life for each creature you control.\n\nFuse (You may cast one or both halves of this card from your hand.)"],
                            'multiverseid' => [369041, 369041]}
                          }
      turn_burn = CardTemplate.new(turn_burn_params)
      alive_well = CardTemplate.new(alive_well_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/splits_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(alive_well_params).and_return alive_well
      expect(CardTemplate).to receive(:new).with(turn_burn_params).and_return turn_burn

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle multiple-art cards" do
      plains_params = {name: 'Plains',
                        slot: 'Basic',
                        layout: 'normal',
                        fields: {
                          'rarity' => 'Basic',
                          "type" => ['Basic Land — Plains'] * 4,
                          "text" => ["W"] * 4,
                          'multiverseid' => [370615, 370754, 370679, 370669]}
                      }
      plains = CardTemplate.new(plains_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/multi_art.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(plains_params).and_return plains

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle flip cards" do
      erayo_params = {name: 'Erayo, Soratami Ascendant',
                      slot: 'Rare',
                      layout: 'flip',
                      fields: {
                        'rarity' => 'Rare',
                        "names" => ['Erayo, Soratami Ascendant', "Erayo's Essence"],
                        "type" => ["Legendary Creature — Moonfolk Monk", 'Legendary Enchantment'],
                        "power" => ['1', nil],
                        "toughness" => ['1', nil],
                        "manaCost" => ['{1}{U}', '{1}{U}'],
                        "text" => ["Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.",
                                    "Whenever an opponent casts a spell for the first time in a turn, counter that spell."],
                        'multiverseid' => [87599, 87599]
                        }}
      bushi_params = {name: 'Bushi Tenderfoot',
                      slot: 'Uncommon',
                      layout: 'flip',
                      fields: {
                        'rarity' => 'Uncommon',
                        "names" => ['Bushi Tenderfoot', 'Kenzo the Hardhearted'],
                        "type" => ["Creature — Human Soldier", 'Legendary Creature — Human Samurai'],
                        "power" => ['1', '3'],
                        "toughness" => ['1', '4'],
                        "manaCost" => ['{W}', '{W}'],
                        "text" => ["When a creature dealt damage by Bushi Tenderfoot this turn dies, flip Bushi Tenderfoot.",
                                    "Double strike; bushido 2 (When this blocks or becomes blocked, it gets +2/+2 until end of turn.)"],
                        'multiverseid' => [78600, 78600]
                        }}
      erayo = CardTemplate.new(erayo_params)
      bushi = CardTemplate.new(bushi_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/flips_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(bushi_params).and_return bushi
      expect(CardTemplate).to receive(:new).with(erayo_params).and_return erayo

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle double-faced cards" do
      hanweir_params = {name: 'Hanweir Watchkeep',
                        slot: 'Double Faced',
                        layout: 'double-faced',
                        fields: {
                          'rarity' => 'Uncommon',
                          "names" => ['Hanweir Watchkeep', 'Bane of Hanweir'],
                          "type" => ["Creature — Human Warrior Werewolf", 'Creature — Werewolf'],
                          "power" => ['1', '5'],
                          "toughness" => ['5', '5'],
                          "manaCost" => ['{2}{R}', nil],
                          "text" => ["Defender\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Hanweir Watchkeep.",
                                      "Bane of Hanweir attacks each turn if able.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Bane of Hanweir."],
                          "flavor" => ["He scans for wolves, knowing there's one he can never anticipate.",
                                        "Technically he never left his post. He looks after the wolf wherever it goes."],
                          'multiverseid' => [244683, 244687]
                        }}
      hanweir = CardTemplate.new(hanweir_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/dfc_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(hanweir_params).and_return hanweir

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "with non-unique card names" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_duplicates.json'))

      # Expect: 3 Academy Raiders, 2 Turns, Glimpse, Zephyr
      expect(CardTemplate).to receive(:new).exactly(7).times.and_call_original

      expect(card_set.prepare_for_draft).to be_truthy

      sorted_card_names = CardTemplate.pluck(:name).sort
      expect(sorted_card_names).to eq ['Academy Raider', 'Academy Raider', 'Academy Raider', 'Glimpse the Future', 'Turn', 'Turn', 'Zephyr Charge']
      expect(card_set.warnings).to include "The following names appear on two or more cards in '#{card_set.name}': 'Academy Raider', 'Turn'"
      expect(card_set.errors).to be_empty
    end
  end

  describe "prepare brand new set for draft" do
    let(:card_set) { FactoryGirl.build(:card_set) }

    it "succeeds" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params).and_return glimpse

      expect(card_set).to receive(:save!).and_call_original

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
      expect(card_set.warnings).to be_empty
      expect(card_set).to be_persisted
    end

    it "with bugged JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_bugged.json'))

      expect(card_set).to receive(:save!).and_call_original
      expect(card_set.prepare_for_draft).to be_truthy

      bugged_card = CardTemplate.where(name: 'Unnamed Card 1').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Creature — Goblin"

      bugged_card = CardTemplate.where(name: 'Gnawing Zombie').first
      expect(bugged_card.slot).to eq 'Common'

      bugged_card = CardTemplate.where(name: 'Unnamed Card 2').first
      expect(bugged_card).to_not be_nil
      expect(bugged_card.fields['type']).to eq "Instant"
      expect(bugged_card.slot).to eq 'Common'

      expect(card_set.errors).to be_empty
      expect(card_set.warnings).to include("2 cards in '#{card_set.name}' were received without names. They have been named 'Unnamed Card 1' etc.")
      expect(card_set.warnings).to include("The following cards in '#{card_set.name}' were received without rarities. They have been defaulted to Common: 'Gnawing Zombie', 'Unnamed Card 2'")

      expect(card_set).to be_persisted
    end

    it "with unparseable JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/awesome_broken.json'))

      expect(card_set).not_to receive(:save!)
      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :unparseable)

      expect(card_set).not_to be_persisted
    end

    it "with unavailable JSON" do
      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location) do
        raise Errno::ENOENT.new("No such file")
      end

      expect(card_set).not_to receive(:save!)
      expect(card_set.prepare_for_draft).to be_falsey
      expect(card_set.errors).to be_added(:dictionary_location, :unavailable)

      expect(card_set).not_to be_persisted
    end
  end

  describe "create boosters" do
    it "should work with a Magic set (no mythics)" do
      ravnica = FactoryGirl.create(:card_set, name: 'Ravnica, City of Guilds', dictionary_location: 'spec/data/RAV.json')
      expect(ravnica.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = ravnica.generate_booster }.to change{ CardInstance.count }.by ravnica.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name).uniq.length).to eq booster.length
      expect(booster.map(&:slot)).to match_array ravnica.booster_distr

      # Repeat the test to make sure we get a different, valid, booster
      booster2 = nil
      expect { booster2 = ravnica.generate_booster }.to change{ CardInstance.count }.by ravnica.booster_distr.length

      expect(booster2).to all(be_a CardInstance)
      expect(booster2.map(&:name).uniq.length).to eq booster.length
      expect(booster2.map(&:slot)).to match_array ravnica.booster_distr
      expect(booster2).to_not eq booster
    end

    it "should work with a Magic set (mythics)" do
      expect(CardSet.count).to eq 0
      khans = FactoryGirl.create(:card_set, name: 'Khans of Tarkir', dictionary_location: 'spec/data/KTK.json')
      expect(khans.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = khans.generate_booster }.to change{ CardInstance.count }.by khans.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name).uniq.length).to eq booster.length
      expect(booster.length).to eq khans.booster_distr.length
      expect(booster.map(&:slot)).to satisfy("match distribution") do |slots|
        slots.each_with_index.all? { |slot, ix| Array(khans.booster_distr[ix]).include? slot }
      end
    end

    it "should produce roughly the right number of mythics" do
      khans = FactoryGirl.create(:card_set, name: 'Khans of Tarkir', dictionary_location: 'spec/data/KTK.json')
      expect(khans.prepare_for_draft).to be_truthy

      # A sample of 1200 boosters should contain 150 Mythics, Poisson-distributed (sd = sqrt 150)
      expected = 1200/8.0
      1200.times { khans.generate_booster }
      expect(CardInstance.joins { card_template }
                          .where { card_template.slot == 'Mythic'}
                          .count).to be_between(expected - 2 * Math.sqrt(expected), expected + 2 * Math.sqrt(expected))
    end

    it "should work with an unusual Magic set (Innistrad)" do
      innistrad = FactoryGirl.create(:card_set, name: 'Innistrad', dictionary_location: "data/local_sets/ISD.json")
      expect(innistrad.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = innistrad.generate_booster }.to change{ CardInstance.count }.by innistrad.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name).uniq.length).to eq booster.length
      expect(booster.length).to eq innistrad.booster_distr.length
      expect(booster.map(&:slot)).to satisfy("match distribution") do |slots|
        slots.each_with_index.all? { |slot, ix| Array(innistrad.booster_distr[ix]).include? slot }
      end
    end

    it "should produce roughly the right ratio of unusual card rarities (Innistrad)" do
      innistrad = FactoryGirl.create(:card_set, name: 'Innistrad', dictionary_location: "data/local_sets/ISD.json")
      expect(innistrad.prepare_for_draft).to be_truthy

      # A sample of 1120 boosters should, by multidraft's rule-of-thumb calculation, contain among its DFCs
      # * 10 Mythics
      # * 70 Rares
      # * 240 Uncommons
      # * 800 Commons
      # all Poisson distributed
      expected = {"Mythic" => 10, "Rare" => 70, "Uncommon" => 240, "Common" => 800}
      1120.times { innistrad.generate_booster }
      cards_by_rarity = CardInstance.joins { card_template }
                                    .where { card_template.slot == 'Double Faced'}
                                    .group_by { |c| c.card_template.fields['rarity'] }
      expected.each do |rarity, number|
        expect(cards_by_rarity[rarity].length).to be_between(number - 2 * Math.sqrt(number), number + 2 * Math.sqrt(number))
      end
    end

    it "should work with a uniform set (like Cube)" do
      # Fake it - fake_cube has KTK cards, all marked rare
      cube = FactoryGirl.create(:card_set, name: 'Cube', dictionary_location: "spec/data/fake_cube.json")
      expect(cube.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = cube.generate_booster }.to change{ CardInstance.count }.by cube.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name).uniq.length).to eq booster.length
      expect(booster.map(&:slot)).to match_array cube.booster_distr
    end

    it "should work with a set of non-Magic rarities (like Agricola)" do
      # Fake it - fake_non_magic has KTK cards each with a reversed rarity
      non_magic = FactoryGirl.create(:card_set, name: 'Fake Agricola', dictionary_location: "spec/data/fake_non_magic.json")
      expect(non_magic.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = non_magic.generate_booster }.to change{ CardInstance.count }.by non_magic.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name).uniq.length).to eq booster.length
      expect(booster.map(&:slot)).to match_array non_magic.booster_distr
    end

    it "should work with a set with non-Magic multi-rarity slots" do
      # Fake it - fake_multi_rarity has KTK cards, but Mythic and Rare are reversed
      multi_rarity = FactoryGirl.create(:card_set, name: 'Non Magic Multi Rarity', dictionary_location: 'spec/data/fake_multi_rarity.json')
      expect(multi_rarity.prepare_for_draft).to be_truthy

      # A sample of 1200 boosters should contain 600 Cihtyms and 600 Erars, Poisson-distributed, in the Double Faced slot
      # (since the set contains only those rarities in that slot)
      expected = 1200/2.0
      1200.times { multi_rarity.generate_booster }
      cards_by_rarity = CardInstance.joins { card_template }
                                    .where { card_template.slot == 'Double Faced'}
                                    .group_by { |c| c.card_template.fields['rarity'] }
      expect(cards_by_rarity['Cihtym'].length).to be_between(expected - 2 * Math.sqrt(expected), expected + 2 * Math.sqrt(expected))
      expect(cards_by_rarity['Erar'].length).to be_between(expected - 2 * Math.sqrt(expected), expected + 2 * Math.sqrt(expected))
    end

    it "should work with a Multiverse set (Sienira's Facets)" do
      sienira = FactoryGirl.create(:card_set, name: "Sienira's Facets", dictionary_location: 'spec/data/sienira.json')
      expect(sienira.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = sienira.generate_booster }.to change{ CardInstance.count }.by sienira.booster_distr.length

      expect(booster).to all(be_a CardInstance)

      # We know Sienira asks for a Basic and a Token, neither of which we have.
      expect(booster.map(&:missing_slot).compact).to match_array %w<Basic Token>
      expect(booster.reject { |c| c.missing_slot }.map(&:name).uniq.length).to eq (booster.length - %w<Basic Token>.length)
      expect(booster.length).to eq sienira.booster_distr.length
      expect(booster.map(&:slot)).to satisfy("match distribution") do |slots|
        slots.each_with_index.all? { |slot, ix| slot.nil? || Array(sienira.booster_distr[ix]).include?(slot) }
      end
    end

    it "should not fail if set is missing rarities" do
      no_uncommons = FactoryGirl.create(:card_set, name: 'No Uncommons', dictionary_location: "spec/data/no_uncommons.json")
      expect(no_uncommons.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = no_uncommons.generate_booster }.to change{ CardInstance.count }.by no_uncommons.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map{|c| c.name.nil? }).to eq [false, true, true, true] + ([false] * 11)

      expected_missing = [nil, 'Uncommon', 'Uncommon', 'Uncommon'] + ([nil] * 11)
      expect(booster.map(&:missing_slot)).to eq expected_missing
    end

    it "should never pick a missing rarity for a multi-rarity slot" do
      no_rares = FactoryGirl.create(:card_set, name: 'No Rares', dictionary_location: "spec/data/no_rares.json")
      expect(no_rares.prepare_for_draft).to be_truthy

      100.times { no_rares.generate_booster }
      expect(CardInstance.joins { card_template }
                          .where { card_template.slot == 'Mythic'}
                          .count).to eq 100
    end

    it "should not fail if set is missing rarities from a multi-rarity slot" do
      bad_multi = FactoryGirl.create(:card_set, name: 'Bad Multi', dictionary_location: "spec/data/bad_multi.json")
      expect(bad_multi.prepare_for_draft).to be_truthy

      booster = nil
      expect { booster = bad_multi.generate_booster }.to change{ CardInstance.count }.by bad_multi.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)[0]).to be_nil

      expected_missing = ['Odd Rare'] + ([nil] * 14)
      expect(booster.map(&:missing_slot)).to satisfy('be missing just an Odd Rare or Mythic') do |missing|
        missing.each_with_index.all? { |slot, ix| ix == 0 ? slot =~ /^Odd (Mythic )?Rare$/ : slot.nil? }
      end
    end
  end
end
