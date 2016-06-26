require 'rails_helper'

RSpec.describe Draft, type: :model do
  describe "validations" do
    let!(:draft) { FactoryGirl.create(:draft) }

    it { should validate_presence_of :name }
    it { should validate_uniqueness_of :name }

    describe "of state, manually" do
      it "validate_presence_of" do
        expect{ draft.state = nil }.to change{ draft.valid? }.to false
      end
      it "validate_numericality_of" do
        expect{ draft.state = 'abcd' }.to change{ draft.valid? }.to false
      end
      it "validate_inclusion_of" do
        expect{ draft.state = Draft::States::AllStates.max + 1 }.to change{ draft.valid? }.to false
      end
    end
  end
end
