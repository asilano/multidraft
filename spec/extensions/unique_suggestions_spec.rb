# encoding: utf-8
require 'spec_helper'

describe UniqueSuggestion do
  describe "default" do
    it "gives next after a complete run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (2)'])

      expect(User.suggest(:name, 'My Name')).to eq 'My Name (3)'
    end

    it "gives the base if none exist" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return false

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return([])

      expect(User.suggest(:name, 'My Name')).to eq 'My Name'
    end

    it "gives the base if base absent but others present" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return false

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (2)'])

      expect(User.suggest(:name, 'My Name')).to eq 'My Name'
    end

    it "gives the missing element in a broken run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (3)'])

      expect(User.suggest(:name, 'My Name')).to eq 'My Name (2)'
    end
  end

  describe "next-highest" do
    it "gives next after a complete run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (2)'])

      expect(User.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (3)'
    end

    it "gives the base if none exist" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return false

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return([])

      expect(User.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name'
    end

    it "gives next if base absent but others present" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return false

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (2)'])

      expect(User.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (3)'
    end

    it "ignores missing elements in a broken run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name (%)').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name (1)', 'My Name (3)'])

      expect(User.suggest(:name, 'My Name', :strategy => :next_highest)).to eq 'My Name (4)'
    end
  end

  describe "custom pattern, default strategy" do
    it "gives next after a complete run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', 'My Name%').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['My Name1', 'My Name2'])

      expect(User.suggest(:name, 'My Name', :pattern => '{base}{num}')).to eq 'My Name3'
    end

    it "gives the missing element in a broken run" do
      expect(User).to receive(:exists?).with(:name => 'My Name').and_return true

      arel_obj = double

      expect(User).to receive(:where).with('name LIKE ?', '#% My Name').and_return arel_obj
      expect(arel_obj).to receive(:pluck).with(:name).and_return(['#1 My Name', '#3 My Name'])

      expect(User.suggest(:name, 'My Name', :pattern => '#{num} {base}')).to eq '#2 My Name'
    end
  end

  describe "errors and corners" do
    it "fails on invalid strategy" do
      expect{ User.suggest(:name, 'My Name', :strategy => :bad_strat) }.to raise(ArgumentError)
    end

    it "fails on a numberless pattern"
    it "handles a pattern with two numbers"
    it "handles a spurious match"
  end
end