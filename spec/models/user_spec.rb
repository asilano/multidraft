require 'rails_helper'

describe User do
  describe "validations" do
    subject { FactoryGirl.build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).ignoring_case_sensitivity.allow_blank }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).ignoring_case_sensitivity }
    it { should validate_presence_of :password }
    it { should validate_confirmation_of :password }
    it { should validate_length_of(:password).is_at_least 5 }
  end

  describe "relations" do
    it { should have_many(:authentications).dependent(:destroy) }
    it { should have_many(:drafters).dependent(:destroy) }
    it { should have_many(:drafts).through(:drafters) }
  end
end
