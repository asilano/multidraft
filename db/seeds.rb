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
  {name: "Mirrodin Beseiged", remote_dictionary: true, dictionary_location: mtgJson_url('MBS')},
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

  {name: "Time Spiral", remote_dictionary: true, dictionary_location: 'data/local_sets/TSP.json'},
  {name: "Planar Chaos", remote_dictionary: true, dictionary_location: 'data/local_sets/PLC.json'},
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
].each { |details| CardSet.create(details) unless CardSet.where { name == details[:name] }.present? }
