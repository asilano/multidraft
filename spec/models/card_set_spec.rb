# encoding: utf-8
require 'spec_helper'

describe CardSet do
  let(:academy_raider_params) {{name: 'Academy Raider',
                        slot: 'Common',
                        fields: {
                          "layout" => 'normal',
                          'rarity' => 'Common',
                          "type" => 'Creature — Human Warrior',
                          "manaCost" => '{2}{R}',
                          "text" => "Intimidate (This creature can't be blocked except by artifact creatures and/or creatures that share a color with it.)\n\nWhenever Academy Raider deals combat damage to a player, you may discard a card. If you do, draw a card.",
                          "power" => '1',
                          "toughness" => '1',
                          "imageName" => 'academy raider',
                          "cardCode" => 'CR01',
                          "editURL" => 'http://multiverse.example.com/cards/12345'
                    }}}
  let(:glimpse_params) {{name: 'Glimpse the Future',
                         slot: 'Uncommon',
                         fields: {
                          "layout" => 'normal',
                          'rarity' => 'Uncommon',
                          "type" => 'Sorcery',
                          "manaCost" => '{2}{U}',
                          "text" => "Look at the top three cards of your library. Put one of them into your hand and the rest into your graveyard.",
                          "flavor"=> "\"No simple coin toss can solve this riddle. You must think and choose wisely.\"—Shai Fusan, archmage",
                          "imageName" => 'glimpse the future',
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

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params, {}).and_return glimpse

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
      expect(card_set.card_templates(true).map(&:name).sort).to eq ['Academy Raider', 'Glimpse the Future']
    end

    # From a unit-testing point of view, this is identical to creating with a local set,
    # since _open_ returns a temporary file.
    it "with remote set" do
      card_set.remote_dictionary = true
      card_set.dictionary_location = 'http://www.example.com/magicSets/awesome.json'
      card_set.save!

      expect(card_set).to receive(:open).with(card_set.dictionary_location).
                          and_return File.join(File.dirname(__FILE__), '../data/awesome.json')

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params, {}).and_return glimpse

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
                           fields: {
                            "layout" => 'split',
                            'rarity' => 'Uncommon',
                            "names" => ['Turn', 'Burn'],
                            "type" => ['Instant', 'Instant'],
                            "manaCost" => ['{2}{U}','{1}{R}'],
                            "text" => ["Target creature loses all abilities and becomes a 0/1 red Weird until end of turn.\n\nFuse (You may cast one or both halves of this card from your hand.)",
                                        "Burn deals 2 damage to target creature or player.\n\nFuse (You may cast one or both halves of this card from your hand.)"],
                            "imageName" => ['turnburn', 'turnburn']}
                          }
      alive_well_params = {name: 'Alive',
                           slot: 'Uncommon',
                           fields: {
                            "layout" => 'split',
                            'rarity' => 'Uncommon',
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

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle multiple-art cards" do
      plains_params = {name: 'Plains',
                        slot: 'Basic',
                        fields: {
                          "layout" => 'normal',
                          'rarity' => 'Basic',
                          "type" => ['Basic Land — Plains'] * 4,
                          "text" => ["W"] * 4,
                          "imageName" => %w<plains1 plains2 plains3 plains4>}
                      }
      plains = CardTemplate.new(plains_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/multi_art.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(plains_params, {}).and_return plains

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle flip cards" do
      erayo_params = {name: 'Erayo, Soratami Ascendant',
                      slot: 'Rare',
                      fields: {
                        "layout" => 'flip',
                        'rarity' => 'Rare',
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
                      slot: 'Uncommon',
                      fields: {
                        "layout" => 'flip',
                        'rarity' => 'Uncommon',
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

      expect(card_set.prepare_for_draft).to be_truthy
      expect(card_set.errors).to be_empty
    end

    it "should correctly handle double-faced cards" do
      hanweir_params = {name: 'Hanweir Watchkeep',
                        slot: 'Double Faced',
                        fields: {
                          "layout" => 'double-faced',
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
                          "imageName" => ["hanweir watchkeep", "bane of hanweir"]
                        }}
      hanweir = CardTemplate.new(hanweir_params)

      expect(File).to receive(:read).with(Rails.root + card_set.dictionary_location).
                        and_return File.read(File.join(File.dirname(__FILE__), '../data/dfc_set.json'))

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(hanweir_params, {}).and_return hanweir

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

      expect(CardTemplate).to receive(:new).with(academy_raider_params, {}).and_return academy_raider
      expect(CardTemplate).to receive(:new).with(glimpse_params, {}).and_return glimpse

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

      # Expected booster contents is determined, portably, by srand
      srand(20051007)
      expected_contents = ["Woodwraith Corrupter", "Peregrine Mask", "Spectral Searchlight", "Auratouched Mage",
                          "Conclave's Blessing", "Elves of Deep Shadow", "Goblin Spelunkers", "Vedalken Entrancer",
                          "Quickchange", "Torpid Moloch", "Gaze of the Gorgon", "Perplex", "Seeds of Strength",
                          "Strands of Undeath", "Consult the Necrosages"]
      booster = nil
      expect { booster = ravnica.generate_booster }.to change{ CardInstance.count }.by ravnica.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to match_array expected_contents
      expect(booster.map(&:slot)).to match_array ravnica.booster_distr

      # Repeat the test to make sure we get a different, valid, booster
      expected_contents = ["Razia, Boros Archangel", "Halcyon Glaze", "Trophy Hunter", "Sunhome, Fortress of the Legion",
                          "Sabertooth Alley Cat", "Muddle the Mixture", "Woodwraith Strangler", "Veteran Armorer",
                          "Transluminant", "Centaur Safeguard", "Surveilling Sprite", "Boros Recruit", "Golgari Rotwurm",
                          "Necromantic Thirst","Golgari Rot Farm"]
      expect { booster = ravnica.generate_booster }.to change{ CardInstance.count }.by ravnica.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
      expect(booster.map(&:slot)).to match_array ravnica.booster_distr
    end

    it "should work with a Magic set (mythics)" do
      khans = FactoryGirl.create(:card_set, name: 'Khans of Tarkir', dictionary_location: 'spec/data/KTK.json')
      expect(khans.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(20140926)
      expected_contents = ["Meandering Towershell", "Heir of the Wilds", "Scion of Glaciers", "Mystic Monastery",
                          "Archers' Parapet", "Temur Banner", "Bitter Revelation", "Arrow Storm", "Molting Snakeskin",
                          "Siegecraft", "Efreet Weaponmaster", "Kill Shot", "Shambling Attendants", "Jungle Hollow", 'Mountain']
      booster = nil
      expect { booster = khans.generate_booster }.to change{ CardInstance.count }.by khans.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
    end

    it "should produce roughly the right number of mythics" do
      khans = FactoryGirl.create(:card_set, name: 'Khans of Tarkir', dictionary_location: 'spec/data/KTK.json')
      expect(khans.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(2014)

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

      # Expected booster contents is determined, portably, by srand
      srand(20110930)
      expected_contents = ["Gavony Township", "Village Cannibals", "Memory's Journey", "Murder of Crows", "Naturalize",
                          "Cobbled Wings", "Feral Ridgewolf", "Grave Bramble", "Avacyn's Pilgrim", "Silent Departure",
                          "Mulch", "One-Eyed Scarecrow", "Festerhide Boar", 'Swamp', "Screeching Bat"]
      booster = nil
      expect { booster = innistrad.generate_booster }.to change{ CardInstance.count }.by innistrad.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
    end

    it "should produce roughly the right ratio of unusual card rarities (Innistrad)" do
      innistrad = FactoryGirl.create(:card_set, name: 'Innistrad', dictionary_location: "data/local_sets/ISD.json")
      expect(innistrad.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(2011)

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

      # Expected booster contents is determined, portably, by srand
      srand(20141120)
      expected_contents = ["Act of Treason", "Surrak Dragonclaw", "Kin-Tree Invocation", "Leaping Master",
                          "Butcher of the Horde", "Mindswipe", "Scout the Borders", "Meandering Towershell",
                          "Dragon's Eye Savants", "Alpine Grizzly", "Smite the Monstrous", "Raiders' Spoils",
                          "Jeskai Student", "Feat of Resistance", "Sage of the Inward Eye"]
      booster = nil
      expect { booster = cube.generate_booster }.to change{ CardInstance.count }.by cube.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
    end

    it "should work with a set of non-Magic rarities (like Agricola)" do
      # Fake it - fake_non_magic has KTK cards each with a reversed rarity
      non_magic = FactoryGirl.create(:card_set, name: 'Fake Agricola', dictionary_location: "spec/data/fake_non_magic.json")
      expect(non_magic.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(20141121)
      expected_contents = ["Savage Knuckleblade", "Altar of the Brood", "Howl of the Horde", "Armament Corps",
                          "Watcher of the Roost", "Sultai Charm", "Archers' Parapet", "Monastery Flock", "Wind-Scarred Crag"]
      booster = nil
      expect { booster = non_magic.generate_booster }.to change{ CardInstance.count }.by non_magic.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
      expect(booster.map(&:slot)).to match_array non_magic.booster_distr
    end

    it "should work with a set with non-Magic multi-rarity slots" do
      # Fake it - fake_multi_rarity has KTK cards, but Mythic and Rare are reversed
      multi_rarity = FactoryGirl.create(:card_set, name: 'multi_rarity of Tarkir', dictionary_location: 'spec/data/fake_multi_rarity.json')
      expect(multi_rarity.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(2014)

      # A sample of 1200 boosters should contain 600 Cihtyms and 600 Erars, Poisson-distributed
      expected = 1200/2.0
      1200.times { multi_rarity.generate_booster }
      expect(CardInstance.joins { card_template }
                          .where { card_template.slot == 'Cihtym'}
                          .count).to be_between(expected - 2 * Math.sqrt(expected), expected + 2 * Math.sqrt(expected))
      expect(CardInstance.joins { card_template }
                          .where { card_template.slot == 'Erar'}
                          .count).to be_between(expected - 2 * Math.sqrt(expected), expected + 2 * Math.sqrt(expected))
    end

    it "should work with a Multiverse set (Sienira's Facets)" do
      sienira = FactoryGirl.create(:card_set, name: "Sienira's Facets", dictionary_location: 'spec/data/sienira.json')
      expect(sienira.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(20140926)
      expected_contents = ["Infiltration Raid", "Infiltrator's Cape", "Sanctify", "Ominous Toll", "Challenge", "Watcher of Secrets",
                          "Cloak in Terror", "Chapel-Roof Creeper", "Ralatine Sentinel", "Terina Borderguard", "Frantic Cleansing",
                          "Khert Armodon", "Surprise Stab", "Jewelled Prism", nil, nil]
      booster = nil
      expect { booster = sienira.generate_booster }.to change{ CardInstance.count }.by sienira.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
    end

    it "should not fail if set is missing rarities" do
      no_uncommons = FactoryGirl.create(:card_set, name: 'No Uncommons', dictionary_location: "spec/data/no_uncommons.json")
      expect(no_uncommons.prepare_for_draft).to be_truthy

      # Expected booster contents is determined, portably, by srand
      srand(20141122)
      expected_contents = ["Mardu Ascendancy", nil, nil, nil, "Abomination of Gudul", "Snowhorn Rider",
                          "Dragonscale Boon", "Bloodfell Caves", "Shatter", "Efreet Weaponmaster",
                          "Swift Kick", "Jungle Hollow", "Awaken the Bear", "Wetland Sambar", 'Mountain']
      booster = nil
      expect { booster = no_uncommons.generate_booster }.to change{ CardInstance.count }.by no_uncommons.booster_distr.length

      expect(booster).to all(be_a CardInstance)
      expect(booster.map(&:name)).to eq expected_contents
    end

    it "should never pick a missing rarity for a multi-rarity slot" do
      no_rares = FactoryGirl.create(:card_set, name: 'No Uncommons', dictionary_location: "spec/data/no_rares.json")
      expect(no_rares.prepare_for_draft).to be_truthy

      srand(20141127)

      # Generate lots of boosters, and check that each one contains a Mythic
      100.times { no_rares.generate_booster }
      expect(CardInstance.joins { card_template }
                          .where { card_template.slot == 'Mythic'}
                          .count).to eq 100
    end
  end
end
