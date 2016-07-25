class Drafter < ActiveRecord::Base
  belongs_to :user
  belongs_to :draft

  validates :user, presence: true
  validates :draft, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, -> (for_user_id) { where(user_id: for_user_id) }
  scope :for_draft, -> (for_draft_id) { where(draft_id: for_draft_id) }
end
