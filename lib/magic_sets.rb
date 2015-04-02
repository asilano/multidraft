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
    ["Khans of Tarkir", ["Khans of Tarkir", "Fate Reforged", "Dragons of Tarkir"]],
    ["Theros", ["Theros", "Born of the Gods", "Journey into Nyx"]],
    ["Return to Ravnica", ["Return to Ravnica", "Gatecrash", "Dragon's Maze"]],
    ["Innistrad", ["Innistrad", "Dark Ascension", "Avacyn Restored"]],
    ["Scars of Mirrodin", ["Scars of Mirrodin", "Mirrodin Besieged", "New Phyrexia"]],
    ["Zendikar", ["Zendikar", "Worldwake", "Rise of the Eldrazi"]],
    ["Alara", ["Shards of Alara", "Conflux", "Alara Reborn"]],
    ["Shadowmoor", ["Shadowmoor", "Eventide"]],
    ["Lorwyn", ["Lorwyn", "Morningtide"]],
    ["Time Spiral", ["Time Spiral", "Planar Chaos", "Future Sight"]],
    ["Ravnica", ["Ravnica: City of Guilds", "Guildpact", "Dissension"]],
    ["Kamigawa", ["Champions of Kamigawa", "Betrayers of Kamigawa", "Saviors of Kamigawa"]],
    ["Mirrodin", ["Mirrodin", "Darksteel", "Fifth Dawn"]],
    ["Onslaught", ["Onslaught", "Legions", "Scourge"]],
    ["Odyssey", ["Odyssey", "Torment", "Judgment"]],
    ["Invasion", ["Invasion", "Planeshift", "Apocalypse"]],
    ["Masques", ["Mercadian Masques", "Nemesis", "Prophecy"]],
    ["Urza's", ["Urza's Saga", "Urza's Legacy", "Urza's Destiny"]],
    ["Rath", ["Tempest", "Stronghold", "Exodus"]],
    ["Mirage", ["Mirage", "Visions", "Weatherlight"]],
    ["Ice Age", ["Ice Age", "Alliances", "Coldsnap"]],
    ["Early Sets", ["Arabian Nights", "Antiquities", "Legends", "The Dark", "Fallen Empires", "Homelands"]], #...
    ["Core Sets", ["Alpha", "Beta", "Unlimited", "Revised", "Fourth Edition", "Fifth Edition", "Sixth Edition",
                    "Seventh Edition", "Eighth Edition", "Ninth Edition", "Tenth Edition",
                    "Magic 2010", "Magic 2011", "Magic 2012", "Magic 2013", "Magic 2014", "Magic 2015"]],
    ["'Masters' Sets", ["Masters Edition", "Masters Edition II", "Masters Edition III", "Masters Edition IV",
                        "Modern Masters", "Vintage Masters"]],
    ["Un-Sets", ["Unglued", "Unhinged"]]
  ].map do |cycle|
    [cycle[0], cycle[1].map { |n| LazyCardSet.new n }]
  end
end