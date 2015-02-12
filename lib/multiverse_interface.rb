module MultiverseInterface
  MULTIVERSE_SETLIST_URI = "http://www.magicmultiverse.net/cardsets/list.json"

  RemoteSetStub = Struct.new(:name, :uri, :owner)

  # Controller helper methods

  # This method may throw.
  def multiverse_sets
    sets_json = open(MULTIVERSE_SETLIST_URI).read
    sets_objs = JSON.parse(sets_json)

    sets_objs.map do |obj|
      RemoteSetStub.new(name: obj['name'], uri: obj['sourceURL'], owner: obj['owner'])
    end
  end
end