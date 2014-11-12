require 'spec_helper'

describe CardInstance do
  describe "relations" do
    before(:each) { FactoryGirl.create(:card_instance) }

    it { should belong_to :card_template }
  end
end
