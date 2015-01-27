class CardInstance < ActiveRecord::Base
  attr_accessible :card_template, :missing_slot
  belongs_to :card_template
  delegate :name, :slot, :fields, :field_keys_ordered_for_text, :text_lines_for_field, to: :card_template, allow_nil: true
end
