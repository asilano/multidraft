# encoding: utf-8
require 'rails_helper'
require 'unique_suggestion'

describe UniqueSuggestion do
  describe "default" do
    it "gives next after a complete run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (3)', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name (4)'
    end

    it "gives the base if none exist" do
      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name'
    end

    it "gives the base if base absent but others present" do
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (3)', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name'
    end

    it "gives the missing element in a broken run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (4)', :dictionary_location => 'My Name 4')

      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name (3)'
    end
  end

  describe "next-highest" do
    it "gives next after a complete run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (3)', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (4)'
    end

    it "gives next after just base" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')

      expect(CardSet.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (2)'
    end

    it "gives the base if none exist" do
      expect(CardSet.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name'
    end

    it "gives next if base absent but others present" do
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (3)', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (4)'
    end

    it "ignores missing elements in a broken run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (4)', :dictionary_location => 'My Name 4')

      expect(CardSet.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (5)'
    end
  end

  describe "custom pattern, default strategy" do
    it "gives next after a complete run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name2', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name3', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name', :pattern => '{base}{num}')).to eq 'My Name4'
    end

    it "gives the missing element in a broken run" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => '#2 My Name', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => '#4 My Name', :dictionary_location => 'My Name 4')

      expect(CardSet.suggest(:name, 'My Name', :pattern => '#{num} {base}')).to eq '#3 My Name'
    end
  end

  describe "errors and corner cases" do
    it "fails on invalid strategy" do
      expect{ CardSet.suggest(:name, 'My Name', :strategy => :bad_strat) }.to raise_error(ArgumentError, /strategy/)
    end

    it "fails on a numberless pattern" do
      expect{ CardSet.suggest(:name, 'My Name', :pattern => '{base} and other {stuff} but no num') }.to raise_error(ArgumentError, /pattern/)
    end

    it "fails on a baseless pattern" do
      expect{ CardSet.suggest(:name, 'My Name', :pattern => '{num} and other {stuff} but no base') }.to raise_error(ArgumentError, /pattern/)
    end

    it "handles a pattern with two numbers" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => '2. My Name - 2', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => '3. My Name - 3', :dictionary_location => 'My Name 3')

      expect(CardSet.suggest(:name, 'My Name', :pattern => '{num}. {base} - {num}')).to eq '4. My Name - 4'
    end

    it "handles a spurious database match" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'My Name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'My Name (3)', :dictionary_location => 'My Name 3')
      FactoryGirl.create(:card_set, :name => 'My Name is Bob', :dictionary_location => 'Bob')
      FactoryGirl.create(:card_set, :name => 'Fred is My Name', :dictionary_location => 'Fred')

      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name (4)'
    end

    it "is case insensitive" do
      FactoryGirl.create(:card_set, :name => 'My Name', :dictionary_location => 'My Name')
      FactoryGirl.create(:card_set, :name => 'my name (2)', :dictionary_location => 'My Name 2')
      FactoryGirl.create(:card_set, :name => 'MY NAME (3)', :dictionary_location => 'My Name 3')
      FactoryGirl.create(:card_set, :name => 'mY NaME (4)', :dictionary_location => 'My Name 4')
      FactoryGirl.create(:card_set, :name => 'My Name [5]', :dictionary_location => 'My Name 5')

      expect(CardSet.suggest(:name, 'My Name')).to eq 'My Name (5)'
    end

  end
end