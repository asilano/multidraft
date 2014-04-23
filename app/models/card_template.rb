class CardTemplate < ActiveRecord::Base
  attr_accessible :card_set, :fields, :name, :rarity
  belongs_to :card_set
  serialize :fields

  validates_presence_of :name
  validates_presence_of :rarity

end
