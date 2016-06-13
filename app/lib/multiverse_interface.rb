require 'open-uri'

module MultiverseInterface
  MULTIVERSE_SETLIST_URI = "http://www.magicmultiverse.net/cardsets/list.json"

  class RemoteSetStub < Struct.new(:name, :uri, :owner)
    def descr
      "#{name}, by #{owner}"
    end

    def dump
      JSON.dump self
    end
  end

  # Controller helper methods

  # This method may throw.
  def multiverse_sets
    sets_json = open(MULTIVERSE_SETLIST_URI).read
    sets_objs = JSON.parse(sets_json)

    sets_objs.map do |obj|
      RemoteSetStub.new(obj['name'].andand.strip, obj['sourceURL'].andand.strip, obj['owner'].andand.strip)
    end
  end
end