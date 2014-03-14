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
      return :file_not_found
    rescue JSON::ParserError
      # Parsing the JSON failed. Stop now.
      return :parse_error
    rescue
      # Some other error
      return :failure
    end

    # Read the cards out of the set info.
    #
    # Split, DFC etc. have a "names" field which is an array of all the names on
    # the card. We need to treat e.g. "Fire//Ice" as a single card with both sets
    # of characteristics, so group by "names" and combine any entries that match
    cards = get_valid_cards(set_info).group_by { |c| c['names'].andand.sort || c['name'] }.map do |names, group|
      if group.size == 1
        # If the card isn't a multi-card, just use it as-is
        group[0]
      else
        # First, make sure the card parts are ordered to match the order of their respective
        # names (so Turn is first in Turn//Burn)
        if group[0]['names']
          group.sort! { |a,b| a['names'].index(a['name']) <=> a['names'].index(b['name']) }
        end

        # Pivot the parts - which is an array of hashes - into a single card containing
        # a hash of arrays - each field is an array with the parts' values.
        field_keys = group.inject(Set.new) { |memo, part| memo.union part.keys }
        card = Hash[field_keys.map { |k| [k, group.map { |part| part[k] }] } ]

        # Replace those fields which should only have 1 value.
        card['name'] = group[0]['name']
        card['rarity'] = group[0]['rarity']
        card['layout'] = group[0]['layout'] if group[0]['layout']
        card['names'] = group[0]['names'] if group[0]['names']
        card
      end
    end

    # Filter keeping only those fields which might interest us, and create a
    # card template for each card.
    cards.map! do |c|
      c.keep_if { |key, value| fields_whitelist.include? key }
    end
    cards.each do |c|
      card_templates.create(:name => c.delete('name'),
                            :rarity => c.delete('rarity'),
                            :fields => c)
    end
  end

private

  def get_json_dictionary
    if remote_dictionary
      open(dictionary_location)
    else
      File.read(Rails.root + dictionary_location)
    end
  end

  # Make sure the cards are minimally valid - they need a unique name and a
  # defined rarity.
  def get_valid_cards(set_info)
    unknown_name_index = 1
    set_info['cards'].each do |c|
      (c['name'] = "Unnamed Card #{unknown_name_index}" and unknown_name_index += 1) unless c['name']
      c['rarity'] ||= 'Common'
    end
  end

  def fields_whitelist
    %w<layout name names manaCost type rarity text flavor power toughness loyalty imageName hand life>
  end
end
