require 'spec_helper'

describe MultiverseInterface do
  let(:dummy_class) { Class.new { include MultiverseInterface } }
  describe "#multiverse_sets" do
    it "should parse Multiverse's JSON" do
      expect_any_instance_of(dummy_class).to receive(:open).and_return StringIO.new '[
  {
    "name"         : "Eragon",
    "code"         : "MV772",
    "multiverseID" : 772,
    "sourceURL"    : "http://www.magicmultiverse.net/cardsets/772.json",
    "owner"        : "Samuel"
  }
  ,
  {
    "name"         : "Okundwa",
    "code"         : "MV740",
    "multiverseID" : 740,
    "sourceURL"    : "http://www.magicmultiverse.net/cardsets/740.json",
    "owner"        : "Sorrow"
  }
  ,
  {
    "name"         : "Cards With No Home",
    "code"         : "MV74",
    "multiverseID" : 74,
    "sourceURL"    : "http://www.magicmultiverse.net/cardsets/74.json",
    "owner"        : "Alex"
  }
  ,
  {
    "name"         : "Arcunda",
    "code"         : "MV14",
    "multiverseID" : 14,
    "sourceURL"    : "http://www.magicmultiverse.net/cardsets/14.json",
    "owner"        : "Chris"
  }
]'
      sets = dummy_class.new.multiverse_sets
      expect(sets.length).to eq 4
      expect(sets[0]).to eq MultiverseInterface::RemoteSetStub.new('Eragon', 'http://www.magicmultiverse.net/cardsets/772.json', 'Samuel')
      expect(sets[1]).to eq MultiverseInterface::RemoteSetStub.new('Okundwa', 'http://www.magicmultiverse.net/cardsets/740.json', 'Sorrow')
      expect(sets[2]).to eq MultiverseInterface::RemoteSetStub.new('Cards With No Home', 'http://www.magicmultiverse.net/cardsets/74.json', 'Alex')
      expect(sets[3]).to eq MultiverseInterface::RemoteSetStub.new('Arcunda', 'http://www.magicmultiverse.net/cardsets/14.json', 'Chris')
    end
  end
end