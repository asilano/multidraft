# Model representing a card-set - that is, a collection of cards which are selected from
# to make a pack for drafting
require 'open-uri'

class CardSet < ActiveRecord::Base
  attr_accessible :dictionary_location, :last_modified, :name, :remote_dictionary
  has_many :card_templates, dependent: :destroy

  validates_presence_of :name, :last_modified, :dictionary_location
  validates_uniqueness_of :dictionary_location
  validates_uniqueness_of :last_modified, :scope => :name

  attr_reader :warnings

  # Read the set dictionary pointed to, and create card templates from it
  def prepare_for_draft
    @warnings = []

    # Only need to parse the set if the card templates aren't already set up
    if card_templates.empty?

      # Read the JSON. It starts with general info about the set, and contains
      # a entry "cards" which is an array of hashes descrbing each card
      set_info = parse_set_dictionary
      return false if set_info.nil?

      # Read the cards out of the set info and create a CardTemplate for each
      cards_from_set_info(set_info).each do |c|
        record = card_templates.build(:name => c.delete('name'),
                                        :rarity => c.delete('rarity'),
                                        :fields => c)

        return false if record.invalid?
      end

      # All card templates valid - save the set, which will both create it if
      # it doesn't already exist, and save the card templates
      save!
    end

    # Check for warnable problems with the cards
    check_cards_for_warnings

    return true
  end

private

  # Retrieve and parse the set's JSON. Handle any errors thrown from file opening or parsing
  def parse_set_dictionary
    begin
      JSON.parse(get_json_dictionary)
    rescue Exception => e
      error_type = {Errno::ENOENT => :unavailable, JSON::ParserError => :unparseable}[e.class]
      error_type ||= :invalid

      errors.add(:dictionary_location, error_type)
      return nil
    end
  end

  # See if the card templates for this set need to be warned about.
  def check_cards_for_warnings
    # Check for two or more cards with the same name
    duplicate_names = card_templates.select(:name).group(:name).count.select { |name, count| count > 1 }.map(&:first)
    if duplicate_names.present?
      @warnings << I18n.t('activerecord.card_set.warnings.duplicate_cards', card_set_name: self.name, card_names: duplicate_names.map { |n| "'#{n}'" }.join(', '))
    end
  end

  def cards_from_set_info(set_info)
    get_valid_cards(set_info)

    # Combine any cards with multiple arts.
    cards = combine_multi_art_cards(set_info['cards'])

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
    missing_rarity_cards = []
    set_info['cards'].each do |c|
      if c['name'].blank?
        c['name'] = "Unnamed Card #{unknown_name_index}"
        unknown_name_index += 1
      end

      if c['rarity'].blank?
        c['rarity'] ||= 'Common'
        missing_rarity_cards << c['name']
      end

      # Keep only those fields that interest us.
      c.keep_if { |key,_| CardSet.fields_whitelist.include? key }
    end

    if unknown_name_index > 1
      @warnings << I18n.t('activerecord.card_set.warnings.cards_without_names', card_set_name: self.name, count: unknown_name_index - 1)
    end
    if missing_rarity_cards.present?
      @warnings << I18n.t('activerecord.card_set.warnings.cards_without_rarity', card_set_name: self.name, card_names: missing_rarity_cards.map { |n| "'#{n}'" }.join(', '))
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
