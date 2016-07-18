class Draft < ActiveRecord::Base
  module States
    WAITING = 1
    DRAFTING = 2
    DECK_BUILDING = 3
    ENDED = 4

    AllStates = [WAITING, DRAFTING, DECK_BUILDING, ENDED]
  end

  validates :name, presence: true, uniqueness: true
  validates :state, presence: true, numericality: true, inclusion: { in: States::AllStates }

  has_many :drafters, dependent: :destroy
  has_many :users, -> { uniq }, through: :drafters

  scope :waiting, -> { where(state: States::WAITING) }
  scope :drafting, -> { where(state: States::DRAFTING) }
  scope :building, -> { where(state: States::DECK_BUILDING) }
  scope :running, -> { where(state: [States::DRAFTING, States::DECK_BUILDING])}
  scope :ended, -> { where(state: States::ENDED) }

  scope :without_user, -> (user_id) { includes{drafters}.where{(drafters.user_id != user_id) | (drafters.user_id.eq nil)}.references(:all) }

  before_validation :init_state, on: :create

private
  def init_state
    self.state = States::WAITING
  end
end
