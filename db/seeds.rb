# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
def mtgJson_url(set_code)
  "http://mtgjson.com/json/#{set_code}.json"
end

[
  {name: "Khans of Tarkir", remote_dictionary: true, dictionary_location: mtgJson_url('KTK')},
  {name: "Fate Reforged", remote_dictionary: false, dictionary_location: 'data/local_sets/FRF.json'},
  {name: "Dragons of Tarkir", remote_dictionary: true, dictionary_location: mtgJson_url('DTK')},

  {name: "Theros", remote_dictionary: true, dictionary_location: mtgJson_url('THS')},
  {name: "Born of the Gods", remote_dictionary: true, dictionary_location: mtgJson_url('BNG')},
  {name: "Journey into Nyx", remote_dictionary: true, dictionary_location: mtgJson_url('JOU')},

  {name: "Return to Ravnica", remote_dictionary: true, dictionary_location: mtgJson_url('RTR')},
  {name: "Gatecrash", remote_dictionary: true, dictionary_location: mtgJson_url('GTC')},
  {name: "Dragon's Maze", remote_dictionary: false, dictionary_location: 'data/local_sets/DGM.json'},

  {name: "Innistrad", remote_dictionary: false, dictionary_location: 'data/local_sets/ISD.json'},
  {name: "Dark Ascension", remote_dictionary: false, dictionary_location: 'data/local_sets/DKA.json'},
  {name: "Avacyn Restored", remote_dictionary: true, dictionary_location: mtgJson_url('AVR')},

  {name: "Scars of Mirrodin", remote_dictionary: true, dictionary_location: mtgJson_url('SOM')},
  {name: "Mirrodin Besieged", remote_dictionary: true, dictionary_location: mtgJson_url('MBS')},
  {name: "New Phyrexia", remote_dictionary: true, dictionary_location: mtgJson_url('NPH')},

  {name: "Zendikar", remote_dictionary: true, dictionary_location: mtgJson_url('ZEN')},
  {name: "Worldwake", remote_dictionary: true, dictionary_location: mtgJson_url('WWK')},
  {name: "Rise of the Eldrazi", remote_dictionary: true, dictionary_location: mtgJson_url('ROE')},

  {name: "Shards of Alara", remote_dictionary: true, dictionary_location: mtgJson_url('ALA')},
  {name: "Conflux", remote_dictionary: true, dictionary_location: mtgJson_url('CON')},
  {name: "Alara Reborn", remote_dictionary: true, dictionary_location: mtgJson_url('ARB')},

  {name: "Shadowmoor", remote_dictionary: true, dictionary_location: mtgJson_url('SHM')},
  {name: "Eventide", remote_dictionary: true, dictionary_location: mtgJson_url('EVE')},

  {name: "Lorwyn", remote_dictionary: true, dictionary_location: mtgJson_url('LRW')},
  {name: "Morningtide", remote_dictionary: true, dictionary_location: mtgJson_url('MOR')},

  {name: "Time Spiral", remote_dictionary: false, dictionary_location: 'data/local_sets/TSP.json'},
  {name: "Planar Chaos", remote_dictionary: false, dictionary_location: 'data/local_sets/PLC.json'},
  {name: "Future Sight", remote_dictionary: true, dictionary_location: mtgJson_url('FUT')},

  {name: "Ravnica: City of Guilds", remote_dictionary: true, dictionary_location: mtgJson_url('RAV')},
  {name: "Guildpact", remote_dictionary: true, dictionary_location: mtgJson_url('GPT')},
  {name: "Dissension", remote_dictionary: true, dictionary_location: mtgJson_url('DIS')},

  {name: "Champions of Kamigawa", remote_dictionary: true, dictionary_location: mtgJson_url('CHK')},
  {name: "Betrayers of Kamigawa", remote_dictionary: true, dictionary_location: mtgJson_url('BOK')},
  {name: "Saviors of Kamigawa", remote_dictionary: true, dictionary_location: mtgJson_url('SOK')},

  {name: "Mirrodin", remote_dictionary: true, dictionary_location: mtgJson_url('MRD')},
  {name: "Darksteel", remote_dictionary: true, dictionary_location: mtgJson_url('DST')},
  {name: "Fifth Dawn", remote_dictionary: true, dictionary_location: mtgJson_url('5DN')},

  {name: "Onslaught", remote_dictionary: true, dictionary_location: mtgJson_url('ONS')},
  {name: "Legions", remote_dictionary: true, dictionary_location: mtgJson_url('LGN')},
  {name: "Scourge", remote_dictionary: true, dictionary_location: mtgJson_url('SGC')},

  {name: "Odyssey", remote_dictionary: true, dictionary_location: mtgJson_url('ODY')},
  {name: "Torment", remote_dictionary: true, dictionary_location: mtgJson_url('TOR')},
  {name: "Judgment", remote_dictionary: true, dictionary_location: mtgJson_url('JUD')},

  {name: "Invasion", remote_dictionary: true, dictionary_location: mtgJson_url('INV')},
  {name: "Planeshift", remote_dictionary: true, dictionary_location: mtgJson_url('PLS')},
  {name: "Apocalypse", remote_dictionary: true, dictionary_location: mtgJson_url('APC')},

  {name: "Mercadian Masques", remote_dictionary: true, dictionary_location: mtgJson_url('MMQ')},
  {name: "Nemesis", remote_dictionary: true, dictionary_location: mtgJson_url('NMS')},
  {name: "Prophecy", remote_dictionary: true, dictionary_location: mtgJson_url('PCY')},

  {name: "Urza's Saga", remote_dictionary: true, dictionary_location: mtgJson_url('USG')},
  {name: "Urza's Legacy", remote_dictionary: true, dictionary_location: mtgJson_url('ULG')},
  {name: "Urza's Destiny", remote_dictionary: true, dictionary_location: mtgJson_url('UDS')},

  {name: "Tempest", remote_dictionary: true, dictionary_location: mtgJson_url('TMP')},
  {name: "Stronghold", remote_dictionary: true, dictionary_location: mtgJson_url('STH')},
  {name: "Exodus", remote_dictionary: true, dictionary_location: mtgJson_url('EXO')},

  {name: "Mirage", remote_dictionary: true, dictionary_location: mtgJson_url('MIR')},
  {name: "Visions", remote_dictionary: true, dictionary_location: mtgJson_url('VIS')},
  {name: "Weatherlight", remote_dictionary: true, dictionary_location: mtgJson_url('WTH')},

  {name: "Ice Age", remote_dictionary: true, dictionary_location: mtgJson_url('ICE')},
  {name: "Alliances", remote_dictionary: true, dictionary_location: mtgJson_url('ALL')},
  {name: "Coldsnap", remote_dictionary: true, dictionary_location: mtgJson_url('CSP')},

  {name: "Arabian Nights", remote_dictionary: true, dictionary_location: mtgJson_url('ARN')},
  {name: "Antiquities", remote_dictionary: true, dictionary_location: mtgJson_url('ATQ')},
  {name: "Legends", remote_dictionary: true, dictionary_location: mtgJson_url('LEG')},
  {name: "The Dark", remote_dictionary: true, dictionary_location: mtgJson_url('DRK')},
  {name: "Fallen Empires", remote_dictionary: true, dictionary_location: mtgJson_url('FEM')},
  {name: "Homelands", remote_dictionary: true, dictionary_location: mtgJson_url('HML')},

  {name: "Alpha", remote_dictionary: true, dictionary_location: mtgJson_url('LEA')},
  {name: "Beta", remote_dictionary: true, dictionary_location: mtgJson_url('LEB')},
  {name: "Unlimited", remote_dictionary: true, dictionary_location: mtgJson_url('2ED')},
  {name: "Revised", remote_dictionary: true, dictionary_location: mtgJson_url('3ED')},
  {name: "Fourth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('4ED')},
  {name: "Fifth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('5ED')},
  {name: "Sixth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('6ED')},
  {name: "Seventh Edition", remote_dictionary: true, dictionary_location: mtgJson_url('7ED')},
  {name: "Eighth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('8ED')},
  {name: "Ninth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('9ED')},
  {name: "Tenth Edition", remote_dictionary: true, dictionary_location: mtgJson_url('10E')},
  {name: "Magic 2010", remote_dictionary: true, dictionary_location: mtgJson_url('M10')},
  {name: "Magic 2011", remote_dictionary: true, dictionary_location: mtgJson_url('M11')},
  {name: "Magic 2012", remote_dictionary: true, dictionary_location: mtgJson_url('M12')},
  {name: "Magic 2013", remote_dictionary: true, dictionary_location: mtgJson_url('M13')},
  {name: "Magic 2014", remote_dictionary: true, dictionary_location: mtgJson_url('M14')},
  {name: "Magic 2015", remote_dictionary: true, dictionary_location: mtgJson_url('M15')},

  {name: "Masters Edition", remote_dictionary: true, dictionary_location: mtgJson_url('MED')},
  {name: "Masters Edition II", remote_dictionary: true, dictionary_location: mtgJson_url('ME2')},
  {name: "Masters Edition III", remote_dictionary: true, dictionary_location: mtgJson_url('ME3')},
  {name: "Masters Edition IV", remote_dictionary: true, dictionary_location: mtgJson_url('ME4')},
  {name: "Modern Masters", remote_dictionary: true, dictionary_location: mtgJson_url('MMA')},
  {name: "Vintage Masters", remote_dictionary: true, dictionary_location: mtgJson_url('VMA')},

  {name: "Unglued", remote_dictionary: true, dictionary_location: mtgJson_url('UGL')},
  {name: "Unhinged", remote_dictionary: true, dictionary_location: mtgJson_url('UNH')},
].each { |details| CardSet.create(details) unless CardSet.where { name == details[:name] }.present? }
