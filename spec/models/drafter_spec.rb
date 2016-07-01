require 'rails_helper'

RSpec.describe Drafter, type: :model do
  describe "relations" do
    it { should belong_to :user }
    it { should belong_to :draft }
  end

  describe "validations" do
    it { should validate_presence_of :user }
    it { should validate_presence_of :draft }
  end
end
