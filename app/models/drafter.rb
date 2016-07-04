class Drafter < ActiveRecord::Base
  belongs_to :user
  belongs_to :draft

  validates :user, presence: true
  validates :draft, presence: true, uniqueness: { scope: :user_id }
end
