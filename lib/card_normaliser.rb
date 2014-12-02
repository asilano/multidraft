# Utility class that munges card data freshly-parsed from JSON into its canonical form
class CardNormaliser
  attr_reader :warnings

  def initialize(set_name, cards)
    @cards = cards
    @set_name = set_name
  end

  def normalise
    @warnings = []

    # Tweak any cards that aren't valid
    ensure_cards_valid

    # Combine any cards with multiple arts.
    combine_multi_art_cards

    # Combine any multipart cards
    combine_multipart_cards

    @cards.each do |c|
      # Force the rarity field to be as we expect wrt certain Magic values
      c['rarity'] = self.class.canonical_rarity(c['rarity'])
    end

    # Return the cards, sorted by name
    @cards.sort_by { |c| c['name'] }
  end

private
  # Make sure the cards are minimally valid - they need a unique name and a
  # defined rarity.
  def ensure_cards_valid
    unknown_name_index = 0
    missing_rarity_cards = []

    @cards.each do |c|
      if c['name'].blank?
        unknown_name_index += 1
        c['name'] = "Unnamed Card #{unknown_name_index}"
      end

      if c['rarity'].blank?
        c['rarity'] ||= 'common'
        missing_rarity_cards << c['name']
      end

      # Keep only those fields that interest us.
      c.keep_if { |key,_| CardSet.fields_whitelist.include? key }
    end

    if unknown_name_index > 0
      @warnings << I18n.t('activerecord.card_set.warnings.cards_without_names', card_set_name: @set_name, count: unknown_name_index)
    end
    add_warning_on_cards('cards_without_rarity', missing_rarity_cards)
  end

  # Cards with the same "name" should be exactly the same card, modulo art and/or flavor
  # Combine any such cards together; but leave separate any cards with differences in
  # other fields.
  def combine_multi_art_cards
    combined = @cards.group_by { |c| c['name'] }.inject([]) do |memo, group|
      # Note - group is a two-element array [name, [cards]]
      memo += combine_cards_if_match(group[1])
      memo
    end
    @cards.replace(combined)
  end

  def combine_cards_if_match(parts)
    exemplar = parts[0].reject { |key,_| %w<flavor imageName>.include? key }
      fields_match = parts.size > 1 && parts.all? do |e|
        exemplar == e.reject { |key,_| %w<flavor imageName>.include? key }
      end

      if fields_match
        [make_one_card_from_array(parts)]
      else
        parts
      end
  end

  # Pivot the parts of a card - which is an array of hashes - into a single card containing
  # a hash of arrays - each field is an array with the parts' values.
  def make_one_card_from_array(parts)
    field_keys = parts.inject(Set.new) { |memo, part| memo.union part.keys }
    card = Hash[field_keys.map { |k| [k, parts.map { |part| part[k] }] } ]

    # Replace those fields which should only have 1 value.
    dominant_part = parts[0]
    %w<name slot rarity layout names>.each { |field| card[field] = dominant_part[field] if dominant_part[field] }

    card
  end

  def combine_multipart_cards
    # Split, DFC etc. have a "names" field which is an array of all the names on
    # the card. We need to treat e.g. "Fire//Ice" as a single card with both sets
    # of characteristics, so group by "names" and combine any entries that match
    with_names, without_names = @cards.partition { |c| c.has_key? 'names' }
    grouped_cards = with_names.group_by { |c| c['names'] }
    with_names = grouped_cards.map { |names, group| combine_multi_card(names, group) }

    # Join the cards back into a single array
    @cards.replace(with_names + without_names)
  end

  def combine_multi_card(names, parts)
    # If the card isn't a multi-card, just use it as-is
    return parts[0] if parts.size == 1

    # First, make sure the card parts are ordered to match the order of their respective
    # names (so Turn is first in Turn//Burn)
    if parts[0]['names']
      ordering_index = ->(card_part) { parts[0]['names'].index card_part['name'] }
      parts.sort! { |a,b| ordering_index[a] <=> ordering_index[b] }
    end

    # Combine the multiple part-cards into a single multipart card
    make_one_card_from_array(parts)
  end

  def add_warning_on_cards(warning_type, card_names)
    if card_names.present?
      @warnings << I18n.t("activerecord.card_set.warnings.#{warning_type}", card_set_name: @set_name, card_names: card_names.map { |n| "'#{n}'" }.join(', '))
    end
  end

  # Return a card's rarity in its canonical form
  def self.canonical_rarity(rarity)
    case rarity.downcase
    when 'mythic rare'
      'Mythic'
    when 'basic land'
      'Basic'
    else
      rarity.titleize
    end
  end
end