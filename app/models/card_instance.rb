class CardInstance < ActiveRecord::Base
  attr_accessible :card_template, :missing_slot
  belongs_to :card_template
  delegate :name, :slot, :fields, to: :card_template, allow_nil: true
end
