class Draft < ActiveRecord::Base
  module States
    WAITING = 1
    RUNNING = 2
    DECK_BUILDING = 3
    ENDED = 4

    AllStates = [WAITING, RUNNING, DECK_BUILDING, ENDED]
  end

  validates :name, presence: true, uniqueness: true
  validates :state, presence: true, numericality: true, inclusion: { in: States::AllStates }

  before_validation :init_state, on: :create

private
  def init_state
    self.state = States::WAITING
  end
end
