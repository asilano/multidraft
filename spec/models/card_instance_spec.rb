require 'rails_helper'

describe CardInstance do
  describe "relations" do
    before(:each) { FactoryGirl.create(:card_instance) }

    it { should belong_to :card_template }
  end

  describe "delegations" do
    it "should delegate each field" do
      card = FactoryGirl.create(:card_instance)
      template = card.card_template

      [:name, :slot, :layout, :fields, :field_keys_ordered_for_text].each do |method|
        expect(template).to receive(method).and_return(method.to_s)
        expect(card.send method).to eq method.to_s
      end
    end
  end
end
