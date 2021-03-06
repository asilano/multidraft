class CardTemplate < ActiveRecord::Base
  belongs_to :card_set
  has_many :card_instances, dependent: :destroy
  serialize :fields

  validates_presence_of :name
  validates_presence_of :slot
  validates :layout, presence: true

  scope :day_old, -> {
    where { updated_at < 24.hours.ago }
  }

  def instantiate
    card_instances.create
  end

  # Produce temporary CardTemplates, each of which is one part of a multipart card
  def text_parts
    # First, see if this is actually a multipart card we can process. That means that:
    # - the layout is not "normal"
    # - at least one field other than flavor is an array
    # - each field that is an array is the same size
    field_keys = field_keys_ordered_for_text
    text_fields = fields.select { |k| field_keys.include? k }.reject { |k| k == 'flavor' }
    multipart_field = text_fields.find { |_,value| value.kind_of? Array }
    multipart = multipart_field &&
                text_fields.all? { |_,value| !value.kind_of?(Array) || value.length == multipart_field[1].length}

    if multipart
      if layout == 'normal'
        # A "normal", but multipart, card we assume to have all its parts the same.
        # Return a single card taken from the first of each field
        [CardTemplate.new(name: name,
                          slot: slot,
                          layout: layout,
                          fields: Hash[fields.map { |k,v| [k, [*v][0]] }])
        ]
      else
        (0...multipart_field[1].length).map do |ix|
          part_fields = Hash[fields.map {|k,v| [k, Array(v)[ix]]}].reject { |_,v| v.blank? }
          CardTemplate.new(name: part_fields['names'] || name,
                              slot: slot,
                              fields: part_fields)
        end
      end
    else
      [self]
    end
  end

  def field_keys_ordered_for_text
    all_keys = fields.keys.reject { |k| fields[k].blank? }
    ordered_keys = []

    # Remove fields we know we don't want to display
    %w<layout slot names multiverseid imageURL cardCode editURL>.each { |f| all_keys.delete f }

    # Canonical order for Magic cards
    %w<manaCost type text flavor power toughness loyalty rarity>.each { |f| ordered_keys << all_keys.delete(f) }

    (ordered_keys + all_keys).compact
  end

  def text_lines_for_field(key)
    [*fields[key]].map { |val| val.to_s.split /\n+/ }.flatten
  end

  def self.fields_whitelist
    %w<layout slot name names manaCost type rarity text flavor power toughness loyalty multiverseid imageURL hand life cardCode editURL>
  end

end