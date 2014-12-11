class LazyCardSet
  def initialize(name)
    @name = name
    @card_set = nil
  end

  def method_missing(meth, *args, &block)
    if !@card_set
      @card_set = CardSet.where { name =~ my{@name} }.first
    end

    @card_set.send(meth, *args, &block)
  end
end

module MagicSets
  RealMagicSets = [
    ["Khans of Tarkir", ["Khans of Tarkir"]],
    ["Theros", ["Theros", "Born of the Gods", "Journey into Nyx"]],
    ["Return to Ravnica", ["Return to Ravnica", "Gatecrash", "Dragon's Maze"]],
    ["Innistrad", ["Innistrad", "Dark Ascension", "Avacyn Restored"]],
    ["Scars of Mirrodin", ["Scars of Mirrodin", "Mirrodin Beseiged", "New Phyrexia"]],
    ["Zendikar", ["Zendikar", "Worldwake", "Rise of the Eldrazi"]],
    ["Alara", ["Shards of Alara", "Conflux", "Alara Reborn"]],
    ["Shadowmoor", ["Shadowmoor", "Eventide"]],
    ["Lorwyn", ["Lorwyn", "Morningtide"]],
    ["Time Spiral", ["Time Spiral", "Planar Chaos", "Future Sight"]],
    ["Ravnica", ["Ravnica: City of Guilds", "Guildpact", "Dissension"]],
    ["Kamigawa", ["Champions of Kamigawa", "Betrayers of Kamigawa", "Saviors of Kamigawa"]],
    ["Mirrodin", ["Mirrodin", "Darksteel", "Fifth Dawn"]],
    ["Onslaught", []],
    ["Odyssey", []],
    ["Invasion", []],
    ["Masques", []],
    ["Urza's", []],
    ["Rath", []],
    ["Mirage", []],
    ["Ice Age", []],
    ["Early Sets", []],
    ["Core Sets", []],
    ["'Masters' Sets", []],
    ["Un-Sets", []]
  ].map do |cycle|
    [cycle[0], cycle[1].map { |n| LazyCardSet.new n }]
  end
end