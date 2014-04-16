# Model representing a card-set - that is, a collection of cards which are selected from
# to make a pack for drafting
require 'open-uri'

class CardSet < ActiveRecord::Base
  attr_accessible :dictionary_location, :last_modified, :name, :remote_dictionary
  has_many :card_templates, dependent: :destroy

  validates_presence_of :name, :last_modified, :dictionary_location
  validates_uniqueness_of :dictionary_location
  validates_uniqueness_of :last_modified, :scope => :name

  # Read the set dictionary pointed to, and create card templates from it
  def prepare_for_draft
    # Only need to do anything if the card templates aren't already set up
    return true unless card_templates.empty?

    # Read the JSON. It starts with general info about the set, and contains
    # a entry "cards" which is an array of hashes descrbing each card
    set_info = nil
    begin
      set_info = JSON.parse(get_json_dictionary)
    rescue Errno::ENOENT
      # Couldn't open the file
      errors.add(:dictionary_location, :unavailable)
      return false
    rescue JSON::ParserError
      # Parsing the JSON failed. Stop now.
      errors.add(:dictionary_location, :unparseable)
      return false
    rescue
      # Some other error
      errors.add(:dictionary_location, :invalid)
      return false
    end

    # Read the cards out of the set info and create a CardTemplate for each
    duplicate_base_cards = []
    cards_from_set_info(set_info).each do |c|
      name = c.delete('name')
      rarity = c.delete('rarity')
      record = card_templates.create(:name => name,
                            :rarity => rarity,
                            :fields => c)

      if record.invalid?
        # Failed to save record. If it's because the name is a duplicate,
        # produce a unique name and try again. Otherwise, fail.
        if record.errors.added? :name, :taken
          c['name'] = CardTemplate.suggest(:name, name, :pattern => '{base} ({num})')
          c['rarity'] = rarity

          # Store off the base conflicting card, so we can rename it to "(1)" later
          duplicate_base_cards << CardTemplate.where(name: name).first
          redo
        else
          return false
        end
      end
    end

    duplicate_base_cards.each { |c| c.update_attribute(:name, c.name + ' (1)') }
    true
  end

private

  def cards_from_set_info(set_info)
    card_details = get_valid_cards(set_info)

    # Combine any cards with multiple arts.
    cards = combine_multi_art_cards(card_details)

    # Split, DFC etc. have a "names" field which is an array of all the names on
    # the card. We need to treat e.g. "Fire//Ice" as a single card with both sets
    # of characteristics, so group by "names" and combine any entries that match
    with_names, without_names = cards.partition { |c| c.has_key? 'names' }
    grouped_cards = with_names.group_by { |c| c['names'] }
    with_names = grouped_cards.map { |names, group| combine_multi_cards(names, group) }

    # Join the cards back into a single array, sorted by "name"
    (with_names + without_names).sort_by { |c| c['name'] }
  end

  # Make sure the cards are minimally valid - they need a unique name and a
  # defined rarity.
  def get_valid_cards(set_info)
    unknown_name_index = 1
    set_info['cards'].each do |c|
      if c['name'].blank?
        (c['name'] = "Unnamed Card #{unknown_name_index}" and unknown_name_index += 1)
        errors.add(:card_templates, :missing_name) unless errors.added?(:card_templates, :missing_name)
      end

      if c['rarity'].blank?
        c['rarity'] ||= 'Common'
        errors.add(:card_templates, :missing_rarity) unless errors.added?(:card_templates, :missing_rarity)
      end

      # Keep only those fields that interest us.
      c.keep_if { |key,_| CardSet.fields_whitelist.include? key }
    end
  end

  # Cards with the same "name" should be exactly the same card, modulo art and/or flavor
  # Combine any such cards together; but leave separate any cards with differences in
  # other fields.
  def combine_multi_art_cards(all_cards)
    all_cards.group_by { |c| c['name'] }.inject([]) do |memo, group|
      # Note - group is a two-element array [name, [cards]]
      parts = group[1]
      exemplar = parts[0].reject { |key,_| %w<flavor imageName>.include? key }
      fields_match = parts.size > 1 && parts.all? do |e|
        exemplar == e.reject { |key,_| %w<flavor imageName>.include? key }
      end

      if fields_match
        memo << make_one_card_from_array(parts)
      else
        memo += parts
      end

      memo
    end
  end

  def combine_multi_cards(names, parts)
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

  # Pivot the parts of a card - which is an array of hashes - into a single card containing
  # a hash of arrays - each field is an array with the parts' values.
  def make_one_card_from_array(parts)
    field_keys = parts.inject(Set.new) { |memo, part| memo.union part.keys }
    card = Hash[field_keys.map { |k| [k, parts.map { |part| part[k] }] } ]

    # Replace those fields which should only have 1 value.
    dominant_part = parts[0]
    %w<name rarity layout names>.each { |field| card[field] = dominant_part[field] if dominant_part[field] }
    card
  end

  def self.fields_whitelist
    %w<layout name names manaCost type rarity text flavor power toughness loyalty imageName hand life>
  end

  def get_json_dictionary
    if remote_dictionary
      open(dictionary_location)
    else
      File.read(Rails.root + dictionary_location)
    end
  end
end
