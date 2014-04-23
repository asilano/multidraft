require 'spec_helper'

describe CardTemplate do
  describe "validations" do
    before(:each) { FactoryGirl.create(:card_template) }

    it { should validate_presence_of :name }
    it { should validate_presence_of :rarity }
    it { should_not validate_uniqueness_of(:name).scoped_to :card_set_id }
  end

  describe "relations" do
    before(:each) { FactoryGirl.create(:card_template) }

    it { should belong_to :card_set }
  end
end
