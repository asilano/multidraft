# encoding: utf-8
require 'spec_helper'

describe 'card_instance partial' do
  it 'should just display the missing slot if present' do
    card = double(:card, missing_slot: 'Rare')
    render 'shared/card_instance', card: card

    expect(rendered).to have_css('.card', text: 'Rare')
  end

  describe "should display the plain-text if no image is available" do
    it "for a one-line flavourless instant" do
      shock = FactoryGirl.build(:card_instance)
      shock.fields['imageURL'] = ''
      shock.fields['imageName'] = ''
      render 'shared/card_instance', card: shock

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Shock')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{R}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Instant')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Shock deals 2 damage to target creature or player.')
      expect(rendered).to have_css('.card-text + .card-rarity:last-child', text: 'Common')
    end

    it "for a two-line flavourless instant" do
      spray = build_card  name: 'Crystal Spray',
                          slot: 'Rare',
                          fields: {'rarity' => 'Rare',
                                    'manaCost' => '{2}{U}',
                                    'text' => "Change the text of target spell or permanent by replacing all instances of one color word with another or one basic land type with another until end of turn.\nDraw a card.",
                                    'type' => 'Instant'
                                  }
      render 'shared/card_instance', card: spray

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Crystal Spray')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{2}{U}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Instant')
      expect(rendered).to have_css('.card-type + .card-text',
          text: 'Change the text of target spell or permanent by replacing all instances of one color word with another or one basic land type with another until end of turn.')
      expect(rendered).to have_css('.card-text + .card-text', text: 'Draw a card.')
      expect(rendered).to have_css('.card-text + .card-rarity:last-child', text: 'Rare')
    end

    it "for a multi-line flavourless sorcery" do
      fasc = build_card name: 'Fascination',
                        slot: 'Uncommon',
                        fields: {'manaCost' => '{X}{U}{U}',
                                  'rarity' => 'Uncommon',
                                  'type' => 'Sorcery',
                                  'text' => "Choose one —\n• Each player draws X cards.\n• Each player puts the top X cards of his or her library into his or her graveyard."
                                }
      render 'shared/card_instance', card: fasc

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Fascination')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{X}{U}{U}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Sorcery')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Choose one —')
      expect(rendered).to have_css('.card-text + .card-text', text: '• Each player draws X cards.')
      expect(rendered).to have_css('.card-text + .card-text + .card-text', text: '• Each player puts the top X cards of his or her library into his or her graveyard.')
      expect(rendered).to have_css('.card-text + .card-rarity:last-child', text: 'Uncommon')
    end

    it "for a flavourless vanilla creature" do
      mass = build_card name: 'Mass of Ghouls',
                        slot: 'Common',
                        fields: {'rarity' => 'Common',
                                  'type' => 'Creature — Zombie Warrior',
                                  'toughness' => '3',
                                  'manaCost' => '{3}{B}{B}',
                                  'power' => '5'}
      render 'shared/card_instance', card: mass

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Mass of Ghouls')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{3}{B}{B}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Creature — Zombie Warrior')
      expect(rendered).to have_css('.card-type + .card-power', text: '5')
      expect(rendered).to have_css('.card-power + .card-toughness', text: '3')
      expect(rendered).to have_css('.card-toughness + .card-rarity:last-child', text: 'Common')
    end

    it "for a flavourless non-vanilla creature" do
      nighthawk = build_card name: 'Vampire Nighthawk',
                              slot: 'Common',
                              fields: {'rarity' => 'Common',
                                        'toughness' => '3',
                                        'manaCost' => '{1}{B}{B}',
                                        'text' => 'Flying, deathtouch, lifelink.',
                                        'power' => '2',
                                        'type' => 'Creature — Vampire Shaman'}
      render 'shared/card_instance', card: nighthawk

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Vampire Nighthawk')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{1}{B}{B}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Creature — Vampire Shaman')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Flying, deathtouch, lifelink.')
      expect(rendered).to have_css('.card-text + .card-power', text: '2')
      expect(rendered).to have_css('.card-power + .card-toughness', text: '3')
      expect(rendered).to have_css('.card-toughness + .card-rarity:last-child', text: 'Common')
    end

    it "for a flavoured one-line sorcery" do
      rampant = build_card name: 'Rampant Growth',
                              slot: 'Common',
                              fields: {'manaCost' => '{1}{G}',
                                        'flavor' => 'Nature grows solutions to its problems.',
                                        'type' => 'Sorcery',
                                        'text' => "Search your library for a basic land card and put that card onto the battlefield tapped. Then shuffle your library.",
                                        'rarity' => 'Common'
                                      }
      render 'shared/card_instance', card: rampant

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Rampant Growth')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{1}{G}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Sorcery')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Search your library for a basic land card and put that card onto the battlefield tapped. Then shuffle your library.')
      expect(rendered).to have_css('.card-text + .card-flavor', text: 'Nature grows solutions to its problems.')
      expect(rendered).to have_css('.card-flavor + .card-rarity:last-child', text: 'Common')
    end

    it "for a flavoured two-line aura" do
      strength = build_card name: 'Holy Strength',
                              slot: 'Common',
                              fields: {'manaCost' => '{W}',
                                        'flavor' => "\"Born under the sun, the first child will seek the foundation of honor and be fortified by its righteousness.\"\n—Codex of the Constellari'",
                                        'type' => 'Enchantment — Aura',
                                        'text' => "Enchant creature\nEnchanted creature gets +1/+2.",
                                        'rarity' => 'Common'
                                      }
      render 'shared/card_instance', card: strength

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Holy Strength')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{W}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Enchantment — Aura')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Enchant creature')
      expect(rendered).to have_css('.card-type + .card-text + .card-text', text: 'Enchanted creature gets +1/+2.')
      expect(rendered).to have_css('.card-text + .card-text + .card-flavor', text: '"Born under the sun, the first child will seek the foundation of honor and be fortified by its righteousness."')
      expect(rendered).to have_css('.card-text + .card-flavor + .card-flavor', text: '—Codex of the Constellari')
      expect(rendered).to have_css('.card-flavor + .card-rarity:last-child', text: 'Common')
    end

    it "for a flavoured vanilla creature" do
      mass = build_card name: 'Mass of Ghouls',
                        slot: 'Common',
                        fields: {'flavor' => "\"An army has filled the valley, but it's not like any army I've ever seen. There are no tents, no fires, no horses . . . just a sea of bodies, writhing and moaning, as if a pestilent village were sent to invade us.\"\n—Onean scout",
                                  'rarity' => 'Common',
                                  'type' => 'Creature — Zombie Warrior',
                                  'toughness' => '3',
                                  'manaCost' => '{3}{B}{B}',
                                  'power' => '5'}
      render 'shared/card_instance', card: mass

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Mass of Ghouls')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{3}{B}{B}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Creature — Zombie Warrior')
      expect(rendered).to have_css('.card-type + .card-flavor', text: '"An army has filled the valley, but it\'s not like any army I\'ve ever seen. There are no tents, no fires, no horses . . . just a sea of bodies, writhing and moaning, as if a pestilent village were sent to invade us."')
      expect(rendered).to have_css('.card-type + .card-flavor + .card-flavor', text: '—Onean scout')
      expect(rendered).to have_css('.card-flavor + .card-power', text: '5')
      expect(rendered).to have_css('.card-power + .card-toughness', text: '3')
      expect(rendered).to have_css('.card-toughness + .card-rarity:last-child', text: 'Common')
    end

    it "for a flavoured non-vanilla creature" do
      hawk = build_card name: 'Suntail Hawk',
                        slot: 'Common',
                        fields: {'rarity' => 'Common',
                                  'power' => '1',
                                  'type' => 'Creature — Bird',
                                  'flavor' => "Its eye the glaring sun, its cry the keening wind.",
                                  'toughness' => '1',
                                  'manaCost' => '{W}',
                                  'text' => 'Flying'}
      render 'shared/card_instance', card: hawk

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Suntail Hawk')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{W}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Creature — Bird')
      expect(rendered).to have_css('.card-type + .card-text', text: 'Flying')
      expect(rendered).to have_css('.card-text + .card-flavor', text: 'Its eye the glaring sun, its cry the keening wind.')
      expect(rendered).to have_css('.card-flavor + .card-power', text: '1')
      expect(rendered).to have_css('.card-power + .card-toughness', text: '1')
      expect(rendered).to have_css('.card-toughness + .card-rarity:last-child', text: 'Common')
    end

    it "for a Planeswalker" do
      jace = build_card name: 'Jace Beleren',
                        slot: 'Rare',
                        fields: {'rarity' => 'Rare',
                                  'type' => 'Planeswalker — Jace',
                                  'loyalty' => '3',
                                  'text' => "+2: Each player draws a card.\n−1: Target player draws a card.\n−10: Target player puts the top twenty cards of his or her library into his or her graveyard.",
                                  'manaCost' => '{1}{U}{U}'}
      render 'shared/card_instance', card: jace

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Jace Beleren')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{1}{U}{U}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Planeswalker — Jace')
      expect(rendered).to have_css('.card-type + .card-text', text: '+2: Each player draws a card.')
      expect(rendered).to have_css('.card-type + .card-text + .card-text', text: '−1: Target player draws a card.')
      expect(rendered).to have_css('.card-type + .card-text + .card-text + .card-text', text: '−10: Target player puts the top twenty cards of his or her library into his or her graveyard.')
      expect(rendered).to have_css('.card-text + .card-loyalty', text: '3')
      expect(rendered).to have_css('.card-loyalty + .card-rarity:last-child', text: 'Rare')
    end

    it "for a Planeswalker-commander" do
      freya = build_card name: 'Freyalise, Llanowar\'s Fury',
                          slot: 'Mythic Rare',
                          fields: {'rarity' => 'Mythic Rare',
                                    'type' => 'Planeswalker — Freyalise',
                                    'loyalty' => '3',
                                    'text' => "+2: Put a 1/1 green Elf Druid creature token onto the battlefield with \"{T}: Add {G} to your mana pool.\"\n−2: Destroy target artifact or enchantment.\n−6: Draw a card for each creature you control.\nFreyalise, Llanowar's Fury can be your commander.",
                                    'manaCost' => '{3}{G}{G}'}
      render 'shared/card_instance', card: freya

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Freyalise, Llanowar\'s Fury')
      expect(rendered).to have_css('.card-name + .card-manaCost', text: '{3}{G}{G}')
      expect(rendered).to have_css('.card-manaCost + .card-type', text: 'Planeswalker — Freyalise')
      expect(rendered).to have_css('.card-type + .card-text', text: '+2: Put a 1/1 green Elf Druid creature token onto the battlefield with "{T}: Add {G} to your mana pool."')
      expect(rendered).to have_css('.card-type + .card-text + .card-text', text: '−2: Destroy target artifact or enchantment.')
      expect(rendered).to have_css('.card-type + .card-text + .card-text + .card-text', text: '−6: Draw a card for each creature you control.')
      expect(rendered).to have_css('.card-type + .card-text + .card-text + .card-text + .card-text', text: 'Freyalise, Llanowar\'s Fury can be your commander.')
      expect(rendered).to have_css('.card-text + .card-loyalty', text: '3')
      expect(rendered).to have_css('.card-loyalty + .card-rarity:last-child', text: 'Mythic Rare')
    end

    it "for something that isn't a Magic card" do
      # A 7 Wonders card. Fields will be in order, where they're not matching Magic fields
      temple = build_card name: 'Temple',
                          slot: 'Age II',
                          fields: {'cost' => 'Wood, Brick, Glass',
                                    'upgradeFrom' => 'Altar ->',
                                    'effect' => '3VP',
                                    'upgradeTo' => '-> Pantheon'}
      render 'shared/card_instance', card: temple

      expect(rendered).to have_css('.card')
      expect(rendered).to have_css('.card > .card-name:first-child', text: 'Temple')
      expect(rendered).to have_css('.card-name + .card-cost', text: 'Wood, Brick, Glass')
      expect(rendered).to have_css('.card-cost + .card-upgradeFrom', text: 'Altar ->')
      expect(rendered).to have_css('.card-upgradeFrom + .card-effect', text: '3VP')
      expect(rendered).to have_css('.card-effect + .card-upgradeTo', text: '-> Pantheon')

      puts rendered
    end
  end

  #it "should pass several other tests"
end
