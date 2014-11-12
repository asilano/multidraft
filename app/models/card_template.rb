class CardTemplate < ActiveRecord::Base
  attr_accessible :card_set, :fields, :name, :slot
  belongs_to :card_set
  has_many :card_instances, dependent: :destroy
  serialize :fields

  validates_presence_of :name
  validates_presence_of :slot

  def instantiate
    card_instances.create
  end

end
