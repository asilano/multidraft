class BoosterGenerator
  def self.generate(templates, distribution)
    # Split the templates by slot. Doing this now makes it easier to avoid picking the
    # same card twice later.
    templates_by_slot = templates.group_by(&:slot)

    # Split each slot further by the rarities in it. In most cases, there will be one
    # entry in this second-level grouping, matching the slot name. But some slots - for
    # instance, DFCs - have multiple rarities.
    templates_by_slot.each do |slot, cards|
      templates_by_slot[slot] = cards.group_by { |c| c.fields['rarity'] }
    end

    # Pick a card for each slot in the set's booster distribution
    distribution.map do |slot|
      create_card_for_booster(templates_by_slot, slot)
    end
  end

private
  def self.create_card_for_booster(templates_by_slot, slot)
    # First, make sure we have a single slot type
    slot = flatten_slot(slot, templates_by_slot.keys) if slot.kind_of? Array

    # Check we actually have any cards that go in this slot
    unless templates_by_slot.include? slot
      # We don't. Return a flag object instead of a CardInstance
      return CardInstance.create(missing_slot: slot)
    end

    # Now determine the list of cards we can choose from
    rarity = pick_rarity(templates_by_slot, slot)
    cards = templates_by_slot[slot][rarity]

    # Remove and return a random card from that list
    cards.delete_at(rand(cards.length)).instantiate
  end

  def self.flatten_slot(slot, valid_values)
    # Make sure we don't choose a value we have none of
    slot.reject! { |s| !valid_values.include? s }

    # If the slot has different rarities in it, pick one
    # In the specific case of the Mythic/Rare slot, weight the choice
    if slot.sort == ['Mythic', 'Rare']
      rand(8) == 0 ? 'Mythic' : 'Rare'
    else
      slot.sample
    end
  end

  def self.pick_rarity(templates_by_slot, slot)
    if templates_by_slot[slot].length == 1
      # Only one rarity in the slot
      templates_by_slot[slot].keys.first
    elsif templates_by_slot[slot].keys.all? { |rarity| %w<Mythic Rare Uncommon Common>.include? rarity}
      # All rarities present are Magic rarities. Pick one, adhering to the booster-pack
      # ratios: 1/8MR:7/8R:3U:10C == 1:7:24:80
      # Obviously, if the slot never has one of these types, then the rarities skew, but
      # hopefully that shouldn't happen
      rarity = nil
      until templates_by_slot[slot].keys.include? rarity
        num = rand(1 + 7 + 24 + 80)
        rarity = case num
        when 0
          "Mythic"
        when 1...(1 + 7)
          "Rare"
        when (1 + 7)...(1 + 7 + 24)
          "Uncommon"
        else
          "Common"
        end
      end
      rarity
    else
      # Rarities aren't Magic rarities. Pick at random
      templates_by_slot[slot].keys.sample
    end
  end
end