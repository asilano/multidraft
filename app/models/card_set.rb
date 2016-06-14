# Model representing a card-set - that is, a collection of cards which are selected from
# to make a pack for drafting
require 'open-uri'

class CardSet < ActiveRecord::Base
  serialize :booster_distr, Array
  has_many :card_templates, dependent: :destroy

  validates_presence_of :name, :last_modified, :dictionary_location
  validates_uniqueness_of :dictionary_location
  validates_uniqueness_of :last_modified, :scope => :name

  scope :with_no_card_instances, -> {
    joins("LEFT JOIN card_templates ON card_templates.card_set_id = card_sets.id
             LEFT JOIN card_instances ON card_instances.card_template_id = card_templates.id").
    group('card_sets.id').
    having('COUNT(card_instances.id) = 0 AND COUNT(card_templates.id) > 0')
  }

  attr_reader :warnings

  include MagicSets

  # Read the set dictionary pointed to, and create card templates from it
  def prepare_for_draft
    @warnings = []

    # Only need to parse the set if the card templates aren't already set up
    if card_templates.empty?
      ret = prepare_from_dictionary
      return false unless ret
    end

    # Check for warnable problems with the cards
    check_cards_for_warnings

    return true
  end

  # Paying attention to the stored :booster_distr, generate a random booster from among
  # the set's templates.
  def generate_booster
    prepare_for_draft or return nil
    BoosterGenerator.generate(card_templates, booster_distr)
  end

private

  # Set up the set's card templates from its dictionary
  def prepare_from_dictionary
    # Read the JSON. It starts with general info about the set, and contains
    # a entry "cards" which is an array of hashes descrbing each card
    set_info = parse_set_dictionary
    return false if set_info.nil?

    # Store off the booster distribution, adjusting it for common M:tG ideosyncracies
    set_booster_distr set_info['booster'] or return false

    # Read the cards out of the set info and create a CardTemplate for each
    normaliser = CardNormaliser.new(name, set_info['cards'])
    normaliser.normalise.each do |c|
      record = card_templates.build(name: c.delete('name'),
                                    slot: (c.delete('slot') || c['rarity']).titleize,
                                    layout: c.delete('layout'),
                                    fields: c)

      return false if record.invalid?
    end

    # All card templates valid - save the set, which will both create it if
    # it doesn't already exist, and save the card templates
    @warnings += normaliser.warnings
    save!
  end

  # Retrieve and parse the set's JSON. Handle any errors thrown from file opening or parsing
  def parse_set_dictionary
    begin
      JSON.parse(get_json_dictionary)
    rescue Exception => e
      Rails.logger.info("Exception: #{e}")
      error_type = {Errno::ENOENT => :unavailable, JSON::ParserError => :unparseable}[e.class]
      error_type ||= :invalid

      errors.add(:dictionary_location, error_type)
      return nil
    end
  end

  def set_booster_distr(distr_array)
    if !distr_array
      errors.add(:dictionary_location, :no_booster)
      return false
    end

    self.booster_distr = distr_array.recursive_map(&:titleize).recursive_map do |slot|
      case slot
      when /^(Basic )?Land$/
        'Basic'
      when 'Mythic Rare'
        'Mythic'
      else
        slot
      end
    end
    self.booster_distr.delete('Marketing')
    true
  end

  # See if the card templates for this set need to be warned about.
  def check_cards_for_warnings
    # Check for two or more cards with the same name
    duplicate_names = card_templates.select(:name).group(:name).count.select { |name, count| count > 1 }.map(&:first)
    add_warning_on_cards('duplicate_cards', duplicate_names.sort)
  end

  def get_json_dictionary
    if remote_dictionary
      open(dictionary_location).read
    else
      File.read(Rails.root + dictionary_location)
    end
  end

  def add_warning_on_cards(warning_type, card_names)
    if card_names.present?
      @warnings << I18n.t("activerecord.card_set.warnings.#{warning_type}", card_set_name: self.name, card_names: card_names.map { |n| "'#{n}'" }.join(', '))
    end
  end
end
