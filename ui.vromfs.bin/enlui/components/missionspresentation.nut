from "%enlSqGlob/missionType.nut" import MissionType
from "%ui/ui_library.nut" import *




const defImage = "ui/skin#moveto.svg"

let typeToLocId = {
  [MissionType.ASSAULT] = "missionType/assault",
  [MissionType.DOMINATION] = "missionType/domination",
  [MissionType.INVASION] = "missionType/invasion",
  [MissionType.DESTRUCTION] = "missionType/destruction",
  [MissionType.ESCORT] = "missionType/escort",
  [MissionType.CONFRONTATION] = "missionType/confrontation",
  [MissionType.TUTORIAL] = "missionType/tutorial",
  [MissionType.PRACTICE] = "missionType/practice",
  [MissionType.WW1] = "missionType/WW1"
}

let missionTypeOrder = [
  MissionType.INVASION
  MissionType.CONFRONTATION
  MissionType.DESTRUCTION
  MissionType.ASSAULT
  MissionType.DOMINATION
  MissionType.ESCORT
  MissionType.GUN_GAME
  MissionType.ZOMBIE_MODE
  MissionType.TUTORIAL
  MissionType.PRACTICE
]

enum MissionArmy {
  NONE = 0
  ALLIES = 1
  AXIS = 2
}

function mkMission(cfg, id) {
  let desc = {
    id
    locId = $"lobbies/{id}"
    type = MissionType.INVASION
    army = MissionArmy.NONE
    image = defImage
  }.__update(cfg)
  desc.typeLocId <- typeToLocId?[desc.type] ?? desc.type
  return desc
}

let missions = {
  volokolamsk_city_assault_ussr = {
    image = "ui/volokolamsk_city_02.avif"
    locId = "lobbies/volokolamsk_city_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_city_assault = {
    image = "ui/volokolamsk_city_02.avif"
    locId = "lobbies/volokolamsk_city_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_city_bomb = {
    image = "ui/volokolamsk_city_03.avif"
    locId = "lobbies/volokolamsk_city_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_city_bomb_ussr = {
    image = "ui/volokolamsk_city_03.avif"
    locId = "lobbies/volokolamsk_city_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_city_dom = {
    image = "ui/volokolamsk_city_01.avif"
    locId = "lobbies/volokolamsk_city_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_city_dom_big = {
    image = "ui/volokolamsk_city_02.avif"
    locId = "lobbies/volokolamsk_city_dom_big"
    type = MissionType.DOMINATION
  }

  volokolamsk_farm_dom = {
    image = "ui/volokolamsk_farm_01.avif"
    locId = "lobbies/volokolamsk_farm_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_forestry_dom = {
    image = "ui/volokolamsk_forestery_03.avif"
    locId = "lobbies/volokolamsk_forestry_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_forestry_inv_ussr = {
    image = "ui/volokolamsk_forestery_01.avif"
    locId = "lobbies/volokolamsk_forestry_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_forestry_inv = {
    image = "ui/volokolamsk_forestery_01.avif"
    locId = "lobbies/volokolamsk_forestry_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_inv_counter_ussr = {
    image = "ui/volokolamsk_forestery_02.avif"
    locId = "lobbies/volokolamsk_forestry_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_forestry_inv_counter = {
    image = "ui/volokolamsk_forestery_02.avif"
    locId = "lobbies/volokolamsk_forestry_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_bomb = {
    image = "ui/volokolamsk_forestery_04.avif"
    locId = "lobbies/volokolamsk_forestry_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_bomb_ussr = {
    image = "ui/volokolamsk_forestery_04.avif"
    locId = "lobbies/volokolamsk_forestry_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_fortification_dom = {
    image = "ui/volokolamsk_fortification_02.avif"
    locId = "lobbies/volokolamsk_fortification_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_fortification_inv_ussr = {
    image = "ui/volokolamsk_fortification_01.avif"
    locId = "lobbies/volokolamsk_fortification_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_fortification_inv = {
    image = "ui/volokolamsk_fortification_01.avif"
    locId = "lobbies/volokolamsk_fortification_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_dom = {
    image = "ui/volokolamsk_grove_03.avif"
    locId = "lobbies/volokolamsk_grove_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_grove_inv = {
    image = "ui/volokolamsk_grove_01.avif"
    locId = "lobbies/volokolamsk_grove_inv"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_inv_ussr = {
    image = "ui/volokolamsk_grove_01.avif"
    locId = "lobbies/volokolamsk_grove_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_grove_inv_counter = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_02.avif"
    locId = "lobbies/volokolamsk_grove_inv_counter"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_inv_counter_ussr = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_02.avif"
    locId = "lobbies/volokolamsk_grove_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_grove_conf = {
    image = "ui/volokolamsk_grove_02.avif"
    locId = "lobbies/volokolamsk_grove_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_conf_ussr = {
    image = "ui/volokolamsk_grove_02.avif"
    locId = "lobbies/volokolamsk_grove_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  volokolamsk_grove_assault = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_03.avif"
    locId = "lobbies/volokolamsk_grove_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_assault_ussr = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_03.avif"
    locId = "lobbies/volokolamsk_grove_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_lake_dom = {
    image = "ui/volokolamsk_lake_03.avif"
    locId = "lobbies/volokolamsk_lake_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_lake_inv_ussr = {
    image = "ui/volokolamsk_lake_01.avif"
    locId = "lobbies/volokolamsk_lake_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_lake_inv = {
    image = "ui/volokolamsk_lake_01.avif"
    locId = "lobbies/volokolamsk_lake_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_lake_inv_counter = {
    image = "ui/volokolamsk_lake_02.avif"
    locId = "lobbies/volokolamsk_lake_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_lake_inv_counter_ussr = {
    image = "ui/volokolamsk_lake_02.avif"
    locId = "lobbies/volokolamsk_lake_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_lake_conf_ussr = {
    image = "ui/volokolamsk_lake_03.avif"
    locId = "lobbies/volokolamsk_lake_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  volokolamsk_lake_conf = {
    image = "ui/volokolamsk_lake_03.avif"
    locId = "lobbies/volokolamsk_lake_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  volokolamsk_manor_assault_ussr = {
    image = "ui/volokolamsk_manor_02.avif"
    locId = "lobbies/volokolamsk_manor_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_manor_assault = {
    image = "ui/volokolamsk_manor_02.avif"
    locId = "lobbies/volokolamsk_manor_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_manor_dom = {
    image = "ui/volokolamsk_manor_03.avif"
    locId = "lobbies/volokolamsk_manor_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_monastery_dom = {
    image = "ui/volokolamsk_monastery_03.avif"
    locId = "lobbies/volokolamsk_monastery_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_monastery_inv_ussr = {
    image = "ui/volokolamsk_monastery_01.avif"
    locId = "lobbies/volokolamsk_monastery_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_monastery_inv = {
    image = "ui/volokolamsk_monastery_01.avif"
    locId = "lobbies/volokolamsk_monastery_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_monastery_bomb_ussr = {
    image = "ui/volokolamsk_monastery_02.avif"
    locId = "lobbies/volokolamsk_monastery_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_monastery_bomb = {
    image = "ui/volokolamsk_monastery_02.avif"
    locId = "lobbies/volokolamsk_monastery_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_quarry_inv_ussr = {
    image = "ui/volokolamsk_quarry_1.avif"
    locId = "lobbies/volokolamsk_quarry_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_quarry_inv = {
    image = "ui/volokolamsk_quarry_1.avif"
    locId = "lobbies/volokolamsk_quarry_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_quarry_inv_counter_ussr = {
    image = "ui/volokolamsk_quarry_2.avif"
    locId = "lobbies/volokolamsk_quarry_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_quarry_inv_counter = {
    image = "ui/volokolamsk_quarry_2.avif"
    locId = "lobbies/volokolamsk_quarry_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_river_dom = {
    image = "ui/volokolamsk_river_01.avif"
    locId = "lobbies/volokolamsk_river_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_village_assault_ussr = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_assault = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_village_bomb_ussr = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_bomb = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_ussr = {
    image = "ui/volokolamsk_village_01.avif"
    locId = "lobbies/volokolamsk_village_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_inv = {
    image = "ui/volokolamsk_village_01.avif"
    locId = "lobbies/volokolamsk_village_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_village_conf_ussr = {
    image = "ui/volokolamsk_village_04.avif"
    locId = "lobbies/volokolamsk_village_conf_ussr"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_conf = {
    image = "ui/volokolamsk_village_04.avif"
    locId = "lobbies/volokolamsk_village_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_counter = {
    image = "ui/volokolamsk_village_03.avif"
    locId = "lobbies/volokolamsk_village_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_counter_ussr = {
    image = "ui/volokolamsk_village_03.avif"
    locId = "lobbies/volokolamsk_village_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_inv = {
    image = "ui/volokolamsk_voskhod_inv_01.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_inv_ussr = {
    image = "ui/volokolamsk_voskhod_inv_01.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_inv_counter = {
    image = "ui/volokolamsk_voskhod_inv_03.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_inv_counter_ussr = {
    image = "ui/volokolamsk_voskhod_inv_03.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_conf = {
    image = "ui/volokolamsk_voskhod_inv_02.avif"
    locId = "lobbies/volokolamsk_voskhod_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_conf_ussr = {
    image = "ui/volokolamsk_voskhod_inv_02.avif"
    locId = "lobbies/volokolamsk_voskhod_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_bomb = {
    image = "ui/volokolamsk_voskhod_inv_04.avif"
    locId = "lobbies/volokolamsk_voskhod_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_bomb_ussr = {
    image = "ui/volokolamsk_voskhod_inv_04.avif"
    locId = "lobbies/volokolamsk_voskhod_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  rzhev_city_inv = {
    image = "ui/battle_of_rzhev_kholynka_02.avif"
    locId = "lobbies/rzhev_city_inv_axis"
    army = MissionArmy.AXIS
  }

  rzhev_city_inv_allies = {
    image = "ui/battle_of_rzhev_kholynka_02.avif"
    locId = "lobbies/rzhev_city_inv_allies"
    army = MissionArmy.ALLIES
  }

  rzhev_city_inv_counter = {
    image = "ui/battle_of_rzhev_elevator_01.avif"
    locId = "lobbies/rzhev_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  rzhev_city_inv_counter_allies = {
    image = "ui/battle_of_rzhev_elevator_01.avif"
    locId = "lobbies/rzhev_city_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  rzhev_city_conf = {
    image = "ui/battle_of_rzhev_cathedral_01.avif"
    locId = "lobbies/rzhev_city_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  rzhev_city_conf_allies = {
    image = "ui/battle_of_rzhev_cathedral_01.avif"
    locId = "lobbies/rzhev_city_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  rzhev_city_bomb = {
    image = "ui/battle_of_rzhev_market_02.avif"
    locId = "lobbies/rzhev_city_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  rzhev_city_bomb_allies = {
    image = "ui/battle_of_rzhev_market_02.avif"
    locId = "lobbies/rzhev_city_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  rzhev_city_assault = {
    image = "ui/battle_of_rzhev_market_01.avif"
    locId = "lobbies/rzhev_city_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  rzhev_city_assault_allies = {
    image = "ui/battle_of_rzhev_market_01.avif"
    locId = "lobbies/rzhev_city_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  rzhev_city_dom = {
    image = "ui/battle_of_rzhev_market_03.avif"
    locId = "lobbies/rzhev_city_dom"
    type = MissionType.DOMINATION
  }

  rzhev_city_dom_big = {
    image = "ui/battle_of_rzhev_administration_01.avif"
    locId = "lobbies/rzhev_city_dom_big"
    type = MissionType.DOMINATION
  }

  normandy_aerodrome_inv = {
    image = "ui/normandy_airfield_01.avif"
    locId = "lobbies/normandy_aerodrome_inv"
    army = MissionArmy.ALLIES
  }

  normandy_aerodrome_inv_axis = {
    image = "ui/normandy_airfield_01.avif"
    locId = "lobbies/normandy_aerodrome_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_aerodrome_inv_counter = {
    image = "ui/normandy_airfield_03.avif"
    locId = "lobbies/normandy_aerodrome_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_aerodrome_inv_counter_axis = {
    image = "ui/normandy_airfield_03.avif"
    locId = "lobbies/normandy_aerodrome_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_aerodrome_bomb = {
    image = "ui/normandy_airfield_02.avif"
    locId = "lobbies/normandy_aerodrome_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_beach_inv = {
    image = "ui/normandy_beach_inv_01.avif"
    locId = "lobbies/normandy_beach_inv"
    army = MissionArmy.ALLIES
  }

  normandy_beach_inv_counter = {
    image = "ui/normandy_beach_inv_03.avif"
    locId = "lobbies/normandy_beach_inv_counter"
    army = MissionArmy.AXIS
  }

  normandy_city_dom = {
    image = "ui/normandy_city_dom_01.avif"
    locId = "lobbies/normandy_city_dom"
    type = MissionType.DOMINATION
  }

  normandy_city_dom_big = {
    image = "ui/normandy_city_dom_01.avif"
    locId = "lobbies/normandy_city_dom_big"
    type = MissionType.DOMINATION
  }

  normandy_city_inv_allies = {
    image = "ui/normandy_city_dom_03.avif"
    locId = "lobbies/normandy_city_inv_allies"
    army = MissionArmy.ALLIES
  }

  normandy_city_inv = {
    image = "ui/normandy_city_dom_03.avif"
    locId = "lobbies/normandy_city_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_city_inv_counter_allies = {
    image = "ui/normandy_city_dom_02.avif"
    locId = "lobbies/normandy_city_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_city_inv_counter = {
    image = "ui/normandy_city_dom_02.avif"
    locId = "lobbies/normandy_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_city_assault = {
    image = "ui/normandy_coast_city_02.avif"
    locId = "lobbies/normandy_coast_city_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  normandy_coast_city_dom = {
    image = "ui/normandy_coast_city_01.avif"
    locId = "lobbies/normandy_coast_city_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_city_inv = {
    image = "ui/normandy_coast_city_01.avif"
    locId = "lobbies/normandy_coast_city_inv"
    army = MissionArmy.ALLIES
  }

  normandy_coast_city_inv_counter = {
    image = "ui/normandy_coast_city_03.avif"
    locId = "lobbies/normandy_coast_city_inv_counter"
    army = MissionArmy.AXIS
  }

  normandy_coast_farm_dom = {
    image = "ui/normandy_coast_farm_01.avif"
    locId = "lobbies/normandy_coast_farm_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_ruins_inv = {
    image = "ui/normandy_coast_ruins_02.avif"
    locId = "lobbies/normandy_coast_ruins_inv"
    army = MissionArmy.ALLIES
  }

  normandy_coast_ruins_inv_axis = {
    image = "ui/normandy_coast_ruins_02.avif"
    locId = "lobbies/normandy_coast_ruins_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_ruins_inv_counter = {
    image = "ui/normandy_coast_ruins_01.avif"
    locId = "lobbies/normandy_coast_ruins_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_coast_ruins_inv_counter_axis = {
    image = "ui/normandy_coast_ruins_01.avif"
    locId = "lobbies/normandy_coast_ruins_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_ruins_dom = {
    image = "ui/normandy_coast_ruins_03.avif"
    locId = "lobbies/normandy_coast_ruins_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_ruins_dom_big = {
    image = "ui/normandy_coast_ruins_02.avif"
    locId = "lobbies/normandy_coast_ruins_dom_big"
    type = MissionType.DOMINATION
  }

  normandy_coast_swamp_dom = {
    image = "ui/normandy_coast_swamp_03.avif"
    locId = "lobbies/normandy_coast_swamp_dom"
    type = MissionType.DOMINATION
  }

  normandy_field_dom = {
    image = "ui/normandy_field_01.avif"
    locId = "lobbies/normandy_field_dom"
    type = MissionType.DOMINATION
  }

  normandy_omer_inv = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_inv_allies"
    army = MissionArmy.ALLIES
  }

  normandy_omer_inv_axis = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_omer_inv_counter = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_omer_inv_counter_axis = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_omer_bomb = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_omer_bomb_axis = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_omer_conf = {
    image = "ui/normandy_urban_omer_03.avif"
    locId = "lobbies/normandy_omer_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_omer_conf_axis = {
    image = "ui/normandy_urban_omer_03.avif"
    locId = "lobbies/normandy_omer_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  normandy_omer_dom = {
    image = "ui/normandy_urban_omer_03.avif"
    locId = "lobbies/normandy_omer_dom"
    type = MissionType.DOMINATION
  }

  normandy_omer_dom_big = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_dom_big"
    type = MissionType.DOMINATION
  }

  normandy_station_inv = {
    image = "ui/normandy_station_inv_01.avif"
    locId = "lobbies/normandy_station_inv"
    army = MissionArmy.ALLIES
  }

  normandy_station_inv_axis = {
    image = "ui/normandy_station_inv_01.avif"
    locId = "lobbies/normandy_station_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_station_inv_counter = {
    image = "ui/normandy_station_inv_02.avif"
    locId = "lobbies/normandy_station_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_station_inv_counter_axis = {
    image = "ui/normandy_station_inv_02.avif"
    locId = "lobbies/normandy_station_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_station_conf = {
    image = "ui/normandy_station_inv_03.avif"
    locId = "lobbies/normandy_station_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_station_conf_axis = {
    image = "ui/normandy_station_inv_03.avif"
    locId = "lobbies/normandy_station_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  normandy_station_bomb = {
    image = "ui/normandy_station_inv_04.avif"
    locId = "lobbies/normandy_station_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_station_bomb_axis = {
    image = "ui/normandy_station_inv_04.avif"
    locId = "lobbies/normandy_station_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_village_inv = {
    image = "ui/normandy_village_01.avif"
    locId = "lobbies/normandy_village_inv"
    army = MissionArmy.ALLIES
  }

  normandy_village_inv_axis = {
    image = "ui/normandy_village_01.avif"
    locId = "lobbies/normandy_village_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_village_inv_counter = {
    image = "ui/normandy_village_03.avif"
    locId = "lobbies/normandy_village_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_village_inv_counter_axis = {
    image = "ui/normandy_village_03.avif"
    locId = "lobbies/normandy_village_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_village_bomb = {
    image = "ui/normandy_village_04.avif"
    locId = "lobbies/normandy_village_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_village_bomb_axis = {
    image = "ui/normandy_village_04.avif"
    locId = "lobbies/normandy_village_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_village_conf = {
    image = "ui/normandy_village_05.avif"
    locId = "lobbies/normandy_village_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_village_conf_axis = {
    image = "ui/normandy_village_05.avif"
    locId = "lobbies/normandy_village_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  normandy_factory_inv = {
    image = "ui/normandy_smn_10_result.avif"
    locId = "lobbies/normandy_factory_inv"
    army = MissionArmy.ALLIES
  }

  normandy_factory_inv_axis = {
    image = "ui/normandy_smn_10_result.avif"
    locId = "lobbies/normandy_factory_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_factory_inv_counter = {
    image = "ui/normandy_smn_02_result.avif"
    locId = "lobbies/normandy_factory_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_factory_inv_counter_axis = {
    image = "ui/normandy_smn_02_result.avif"
    locId = "lobbies/normandy_factory_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_factory_conf = {
    image = "ui/normandy_smn_09_result.avif"
    locId = "lobbies/normandy_factory_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_factory_conf_axis = {
    image = "ui/normandy_smn_09_result.avif"
    locId = "lobbies/normandy_factory_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  normandy_factory_bomb = {
    image = "ui/normandy_smn_01_result.avif"
    locId = "lobbies/normandy_factory_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_factory_bomb_axis = {
    image = "ui/normandy_smn_01_result.avif"
    locId = "lobbies/normandy_factory_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_power_inv = {
    image = "ui/normandy_smn_05_result.avif"
    locId = "lobbies/normandy_power_inv"
    army = MissionArmy.ALLIES
  }

  normandy_power_inv_axis = {
    image = "ui/normandy_smn_05_result.avif"
    locId = "lobbies/normandy_power_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_power_inv_counter = {
    image = "ui/normandy_smn_07_result.avif"
    locId = "lobbies/normandy_power_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_power_inv_counter_axis = {
    image = "ui/normandy_smn_07_result.avif"
    locId = "lobbies/normandy_power_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_power_conf = {
    image = "ui/normandy_smn_03_result.avif"
    locId = "lobbies/normandy_power_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_power_conf_axis = {
    image = "ui/normandy_smn_03_result.avif"
    locId = "lobbies/normandy_power_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  ardennes_height_inv = {
    image = "ui/normandy_ardennes_inv_03.avif"
    locId = "lobbies/ardennes_height_inv"
    army = MissionArmy.ALLIES
  }

  ardennes_height_inv_axis = {
    image = "ui/normandy_ardennes_inv_03.avif"
    locId = "lobbies/ardennes_height_inv_axis"
    army = MissionArmy.AXIS
  }

  ardennes_height_inv_counter = {
    image = "ui/normandy_ardennes_inv_02.avif"
    locId = "lobbies/ardennes_height_inv_counter"
    army = MissionArmy.ALLIES
  }

  ardennes_height_inv_counter_axis = {
    image = "ui/normandy_ardennes_inv_02.avif"
    locId = "lobbies/ardennes_height_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  ardennes_height_assault = {
    image = "ui/normandy_ardennes_inv_04.avif"
    locId = "lobbies/ardennes_height_assault"
    army = MissionArmy.ALLIES
    type = MissionType.ASSAULT
  }

  ardennes_height_assault_axis = {
    image = "ui/normandy_ardennes_inv_04.avif"
    locId = "lobbies/ardennes_height_assault_axis"
    army = MissionArmy.AXIS
    type = MissionType.ASSAULT
  }

  ardennes_height_bomb = {
    image = "ui/normandy_ardennes_inv_06.avif"
    locId = "lobbies/ardennes_height_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  ardennes_height_bomb_axis = {
    image = "ui/normandy_ardennes_inv_06.avif"
    locId = "lobbies/ardennes_height_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  ardennes_height_conf = {
    image = "ui/normandy_ardennes_inv_01.avif"
    locId = "lobbies/ardennes_height_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  ardennes_height_conf_axis = {
    image = "ui/normandy_ardennes_inv_01.avif"
    locId = "lobbies/ardennes_height_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  ardennes_height_dom = {
    image = "ui/normandy_ardennes_inv_05.avif"
    locId = "lobbies/ardennes_height_dom"
    type = MissionType.DOMINATION
  }

  ardennes_forest_inv = {
    image = "ui/normandy_hills_inv_01.avif"
    locId = "lobbies/ardennes_forest_inv"
    army = MissionArmy.ALLIES
  }

  ardennes_forest_inv_axis = {
    image = "ui/normandy_hills_inv_01.avif"
    locId = "lobbies/ardennes_forest_inv_axis"
    army = MissionArmy.AXIS
  }

  ardennes_forest_inv_counter = {
    image = "ui/normandy_hills_inv_05.avif"
    locId = "lobbies/ardennes_forest_inv_counter"
    army = MissionArmy.ALLIES
  }

  ardennes_forest_inv_counter_axis = {
    image = "ui/normandy_hills_inv_05.avif"
    locId = "lobbies/ardennes_forest_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  ardennes_forest_assault = {
    image = "ui/normandy_hills_inv_02.avif"
    locId = "lobbies/ardennes_forest_assault"
    army = MissionArmy.ALLIES
    type = MissionType.ASSAULT
  }

  ardennes_forest_assault_axis = {
    image = "ui/normandy_hills_inv_02.avif"
    locId = "lobbies/ardennes_forest_assault_axis"
    army = MissionArmy.AXIS
    type = MissionType.ASSAULT
  }

  ardennes_forest_bomb = {
    image = "ui/normandy_hills_inv_06.avif"
    locId = "lobbies/ardennes_forest_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  ardennes_forest_bomb_axis = {
    image = "ui/normandy_hills_inv_06.avif"
    locId = "lobbies/ardennes_forest_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  ardennes_forest_conf = {
    image = "ui/normandy_hills_inv_03.avif"
    locId = "lobbies/ardennes_forest_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  ardennes_forest_conf_axis = {
    image = "ui/normandy_hills_inv_03.avif"
    locId = "lobbies/ardennes_forest_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  ardennes_forest_dom = {
    image = "ui/normandy_hills_inv_04.avif"
    locId = "lobbies/ardennes_forest_dom"
    type = MissionType.DOMINATION
  }

  ardennes_winter_inv = {
    image = "ui/ardennes_winter_06.avif"
    locId = "lobbies/ardennes_winter_inv"
    army = MissionArmy.ALLIES
  }

  ardennes_winter_inv_axis = {
    image = "ui/ardennes_winter_06.avif"
    locId = "lobbies/ardennes_winter_inv_axis"
    army = MissionArmy.AXIS
  }

  ardennes_winter_inv_counter = {
    image = "ui/ardennes_winter_09.avif"
    locId = "lobbies/ardennes_winter_inv_counter"
    army = MissionArmy.ALLIES
  }

  ardennes_winter_inv_counter_axis = {
    image = "ui/ardennes_winter_09.avif"
    locId = "lobbies/ardennes_winter_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  ardennes_winter_assault = {
    image = "ui/ardennes_winter_04.avif"
    locId = "lobbies/ardennes_winter_assault"
    army = MissionArmy.ALLIES
    type = MissionType.ASSAULT
  }

  ardennes_winter_assault_axis = {
    image = "ui/ardennes_winter_04.avif"
    locId = "lobbies/ardennes_winter_assault_axis"
    army = MissionArmy.AXIS
    type = MissionType.ASSAULT
  }

  ardennes_winter_bomb = {
    image = "ui/ardennes_winter_05.avif"
    locId = "lobbies/ardennes_winter_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  ardennes_winter_bomb_axis = {
    image = "ui/ardennes_winter_05.avif"
    locId = "lobbies/ardennes_winter_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  ardennes_winter_conf = {
    image = "ui/ardennes_winter_12.avif"
    locId = "lobbies/ardennes_winter_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  ardennes_winter_conf_axis = {
    image = "ui/ardennes_winter_12.avif"
    locId = "lobbies/ardennes_winter_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  ardennes_winter_dom = {
    image = "ui/ardennes_winter_02.avif"
    locId = "lobbies/ardennes_winter_dom"
    type = MissionType.DOMINATION
  }

  ardennes_winter_dom_big = {
    image = "ui/ardennes_winter_10.avif"
    locId = "lobbies/ardennes_winter_dom_big"
    type = MissionType.DOMINATION
  }

  berlin_chancellery_dom = {
    image = "ui/berlin_chancellery_dom_01.avif"
    locId = "lobbies/berlin_chancellery_dom"
    type = MissionType.DOMINATION
  }

  berlin_chancellery_conf = {
    image = "ui/berlin_chancellery_dom_04.avif"
    locId = "lobbies/berlin_chancellery_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  berlin_chancellery_conf_axis = {
    image = "ui/berlin_chancellery_dom_04.avif"
    locId = "lobbies/berlin_chancellery_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  berlin_chancellery_inv = {
    image = "ui/berlin_chancellery_dom_05.avif"
    locId = "lobbies/berlin_chancellery_inv"
    army = MissionArmy.ALLIES
  }

  berlin_chancellery_inv_axis = {
    image = "ui/berlin_chancellery_dom_05.avif"
    locId = "lobbies/berlin_chancellery_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_chancellery_inv_counter = {
    image = "ui/berlin_chancellery_dom_03.avif"
    locId = "lobbies/berlin_chancellery_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_chancellery_inv_counter_axis = {
    image = "ui/berlin_chancellery_dom_03.avif"
    locId = "lobbies/berlin_chancellery_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_garden_conf = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  berlin_garden_conf_axis = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  berlin_garden_assault = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  berlin_garden_assault_axis = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  berlin_garden_bomb = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  berlin_garden_bomb_axis = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  berlin_garden_inv = {
    image = "ui/berlin_garden_inv_01.avif"
    locId = "lobbies/berlin_garden_inv"
    army = MissionArmy.ALLIES
  }

  berlin_garden_inv_axis = {
    image = "ui/berlin_garden_inv_01.avif"
    locId = "lobbies/berlin_garden_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_garden_inv_counter = {
    image = "ui/berlin_garden_inv_03.avif"
    locId = "lobbies/berlin_garden_inv_counter"
    army = MissionArmy.AXIS
  }

  berlin_garden_inv_counter_allies = {
    image = "ui/berlin_garden_inv_03.avif"
    locId = "lobbies/berlin_garden_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  berlin_goering_dom = {
    image = "ui/berlin_goering_dom_02.avif"
    locId = "lobbies/berlin_goering_dom"
    type = MissionType.DOMINATION
  }

  berlin_goering_dom_big = {
    image = "ui/berlin_goering_dom_01.avif"
    locId = "lobbies/berlin_goering_dom_big"
    type = MissionType.DOMINATION
  }

  berlin_goering_inv = {
    image = "ui/berlin_goering_dom_01.avif"
    locId = "lobbies/berlin_goering_inv"
    army = MissionArmy.ALLIES
  }

  berlin_goering_inv_axis = {
    image = "ui/berlin_goering_dom_01.avif"
    locId = "lobbies/berlin_goering_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_goering_inv_counter = {
    image = "ui/berlin_goering_inv_01.avif"
    locId = "lobbies/berlin_goering_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_goering_inv_counter_axis = {
    image = "ui/berlin_goering_inv_01.avif"
    locId = "lobbies/berlin_goering_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_ministry_inv = {
    image = "ui/berlin_moat_02.avif"
    locId = "lobbies/berlin_ministry_inv"
  }

  berlin_ministry_inv_counter = {
    image = "ui/berlin_opera_inv_03.avif"
    locId = "lobbies/berlin_ministry_inv_counter"
  }

  berlin_ministry_conf = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_ministry_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  berlin_ministry_conf_axis = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_ministry_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  berlin_moat_inv_axis = {
    image = "ui/berlin_moat_01.avif"
    locId = "lobbies/berlin_moat_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_moat_inv_counter = {
    image = "ui/berlin_moat_02.avif"
    locId = "lobbies/berlin_moat_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_opera_assault = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_opera_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  berlin_opera_inv = {
    image = "ui/berlin_opera_inv_01.avif"
    locId = "lobbies/berlin_opera_inv"
    army = MissionArmy.ALLIES
  }

  berlin_opera_inv_axis = {
    image = "ui/berlin_opera_inv_01.avif"
    locId = "lobbies/berlin_opera_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_opera_dom = {
    image = "ui/berlin_opera_inv_01.avif"
    locId = "lobbies/berlin_opera_dom"
    type = MissionType.DOMINATION
  }

  berlin_station_dom = {
    image = "ui/berlin_station_01.avif"
    locId = "lobbies/berlin_station_dom"
    type = MissionType.DOMINATION
  }

  berlin_station_inv = {
    image = "ui/berlin_station_03.avif"
    locId = "lobbies/berlin_station_inv"
    army = MissionArmy.AXIS
  }

  berlin_station_inv_allies = {
    image = "ui/berlin_station_03.avif"
    locId = "lobbies/berlin_station_inv_allies"
    army = MissionArmy.ALLIES
  }

  berlin_station_inv_counter = {
    image = "ui/berlin_station_02.avif"
    locId = "lobbies/berlin_station_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_river_inv = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_inv"
    army = MissionArmy.ALLIES
  }

  berlin_river_inv_axis = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_river_inv_counter = {
    image = "ui/berlin_river_crossing_03.avif"
    locId = "lobbies/berlin_river_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_river_inv_counter_axis = {
    image = "ui/berlin_river_crossing_03.avif"
    locId = "lobbies/berlin_river_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_river_bomb = {
    image = "ui/berlin_river_crossing_02.avif"
    locId = "lobbies/berlin_river_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  berlin_river_bomb_axis = {
    image = "ui/berlin_river_crossing_02.avif"
    locId = "lobbies/berlin_river_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  berlin_station_bomb = {
    image = "ui/berlin_station_04.avif"
    locId = "lobbies/berlin_station_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  berlin_station_bomb_axis = {
    image = "ui/berlin_station_04.avif"
    locId = "lobbies/berlin_station_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  berlin_village_escort_allies = {
    image = "ui/berlin_escort_01.avif"
    locId = "lobbies/berlin_village_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_village_escort = {
    image = "ui/berlin_escort_01.avif"
    locId = "lobbies/berlin_village_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_river_dom = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_dom"
    type = MissionType.DOMINATION
  }

  berlin_river_dom_big = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_dom_big"
    type = MissionType.DOMINATION
  }

  berlin_railway_escort_allies = {
    image = "ui/berlin_escort_05.avif"
    locId = "lobbies/berlin_railway_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_railway_escort = {
    image = "ui/berlin_escort_05.avif"
    locId = "lobbies/berlin_railway_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_bridge_escort_allies = {
    image = "ui/berlin_escort_07.avif"
    locId = "lobbies/berlin_bridge_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_bridge_escort = {
    image = "ui/berlin_escort_07.avif"
    locId = "lobbies/berlin_bridge_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_bridge_inv = {
    image = "ui/berlin_bridge_inv_03.avif"
    locId = "lobbies/berlin_bridge_inv"
    army = MissionArmy.ALLIES
  }

  berlin_bridge_inv_axis = {
    image = "ui/berlin_bridge_inv_03.avif"
    locId = "lobbies/berlin_bridge_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_bridge_inv_counter = {
    image = "ui/berlin_bridge_inv_02.avif"
    locId = "lobbies/berlin_bridge_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_bridge_inv_counter_axis = {
    image = "ui/berlin_bridge_inv_02.avif"
    locId = "lobbies/berlin_bridge_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_railway_conf = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

    berlin_railway_conf_axis = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  berlin_railway_inv = {
    image = "ui/berlin_railway_inv_02.avif"
    locId = "lobbies/berlin_railway_inv"
    army = MissionArmy.ALLIES
  }

  berlin_railway_inv_axis = {
    image = "ui/berlin_railway_inv_02.avif"
    locId = "lobbies/berlin_railway_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_railway_inv_counter = {
    image = "ui/berlin_railway_inv_01.avif"
    locId = "lobbies/berlin_railway_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_railway_inv_counter_axis = {
    image = "ui/berlin_railway_inv_01.avif"
    locId = "lobbies/berlin_railway_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_railway_bomb = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  berlin_railway_bomb_axis = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  berlin_wilhelm_dom = {
    image = "ui/berlin_wilhelm_01.avif"
    locId = "lobbies/berlin_wilhelm_dom"
    type = MissionType.DOMINATION
  }

  berlin_wilhelm_inv = {
    image = "ui/berlin_wilhelm_02.avif"
    locId = "lobbies/berlin_wilhelm_inv"
    army = MissionArmy.ALLIES
  }

  berlin_wald_inv = {
    image = "ui/berlin_wald_08.avif"
    locId = "lobbies/berlin_wald_inv"
    army = MissionArmy.ALLIES
  }

  berlin_wald_inv_axis = {
    image = "ui/berlin_wald_08.avif"
    locId = "lobbies/berlin_wald_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_wald_inv_counter = {
    image = "ui/berlin_wald_03.avif"
    locId = "lobbies/berlin_wald_inv_counter"
    army = MissionArmy.ALLIES
  }

  berlin_wald_inv_counter_axis = {
    image = "ui/berlin_wald_03.avif"
    locId = "lobbies/berlin_wald_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  berlin_wald_conf = {
    image = "ui/berlin_wald_01.avif"
    locId = "lobbies/berlin_wald_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

    berlin_wald_conf_axis = {
    image = "ui/berlin_wald_01.avif"
    locId = "lobbies/berlin_wald_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  berlin_wald_bomb = {
    image = "ui/berlin_wald_06.avif"
    locId = "lobbies/berlin_wald_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  berlin_wald_bomb_axis = {
    image = "ui/berlin_wald_06.avif"
    locId = "lobbies/berlin_wald_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  berlin_wald_dom = {
    image = "ui/berlin_wald_07.avif"
    locId = "lobbies/berlin_wald_dom"
    type = MissionType.DOMINATION
  }

  berlin_wald_dom_big = {
    image = "ui/berlin_wald_07.avif"
    locId = "lobbies/berlin_wald_dom_big"
    type = MissionType.DOMINATION
  }

  tunisia_city_bomb = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_city_bomb_axis = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_city_dom = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_dom"
    type = MissionType.DOMINATION
  }

  tunisia_city_dom_big = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_dom_big"
    type = MissionType.DOMINATION
  }

  tunisia_city_conf = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  tunisia_city_conf_axis = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  tunisia_cave_conf = {
    image = "ui/tunisia_cahif_inv_08.avif"
    locId = "lobbies/tunisia_cave_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  tunisia_cave_conf_axis = {
    image = "ui/tunisia_cahif_inv_08.avif"
    locId = "lobbies/tunisia_cave_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  tunisia_cave_inv = {
    image = "ui/tunisia_cahif_inv_09.avif"
    locId = "lobbies/tunisia_cave_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_cave_inv_axis = {
    image = "ui/tunisia_cahif_inv_09.avif"
    locId = "lobbies/tunisia_cave_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_cave_inv_counter = {
    image = "ui/tunisia_cahif_inv_05.avif"
    locId = "lobbies/tunisia_cave_inv_counter"
    army = MissionArmy.ALLIES
  }

  tunisia_cave_inv_counter_axis = {
    image = "ui/tunisia_cahif_inv_05.avif"
    locId = "lobbies/tunisia_cave_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_cave_dom_big = {
    image = "ui/tunisia_cahif_inv_07.avif"
    locId = "lobbies/tunisia_cave_dom_big"
    type = MissionType.DOMINATION
  }

  tunisia_cave_dom = {
    image = "ui/tunisia_cahif_inv_01.avif"
    locId = "lobbies/tunisia_cave_dom"
    type = MissionType.DOMINATION
  }

  tunisia_city_assault = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  tunisia_city_assault_axis = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  tunisia_city_assault_counter = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_assault_counter"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  tunisia_city_assault_counter_axis = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_assault_counter_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  tunisia_city_inv = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_city_inv_axis = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_city_inv_counter = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_inv_counter"
    army = MissionArmy.ALLIES
  }

  tunisia_city_inv_counter_axis = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_assault = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  tunisia_farm_assault_axis = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  tunisia_farm_dom = {
    image = "ui/tunisia_farm_inv_04.avif"
    locId = "lobbies/tunisia_farm_dom"
    type = MissionType.DOMINATION
  }

  tunisia_farm_bomb = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_farm_bomb_axis = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_farm_inv = {
    image = "ui/tunisia_farm_inv_01.avif"
    locId = "lobbies/tunisia_farm_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_farm_inv_axis = {
    image = "ui/tunisia_farm_inv_01.avif"
    locId = "lobbies/tunisia_farm_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_inv_counter = {
    image = "ui/tunisia_farm_inv_02.avif"
    locId = "lobbies/tunisia_farm_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_farm_inv_counter_axis = {
    image = "ui/tunisia_farm_inv_02.avif"
    locId = "lobbies/tunisia_farm_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_conf = {
    image = "ui/tunisia_farm_inv_04.avif"
    locId = "lobbies/tunisia_farm_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  tunisia_farm_conf_axis = {
    image = "ui/tunisia_farm_inv_04.avif"
    locId = "lobbies/tunisia_farm_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  tunisia_fortress_inv = {
    image = "ui/tunisia_fortress_inv_02.avif"
    locId = "lobbies/tunisia_fortress_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_fortress_inv_axis = {
    image = "ui/tunisia_fortress_inv_02.avif"
    locId = "lobbies/tunisia_fortress_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_fortress_inv_counter = {
    image = "ui/tunisia_fortress_inv_03.avif"
    locId = "lobbies/tunisia_fortress_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_fortress_inv_counter_axis = {
    image = "ui/tunisia_fortress_inv_03.avif"
    locId = "lobbies/tunisia_fortress_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_gorge_assault = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_assault_axis = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  tunisia_gorge_bomb = {
    image = "ui/tunisia_gorge_inv_01.avif"
    locId = "lobbies/tunisia_gorge_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_bomb_axis = {
    image = "ui/tunisia_gorge_inv_01.avif"
    locId = "lobbies/tunisia_gorge_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_gorge_inv = {
    image = "ui/tunisia_gorge_inv_02.avif"
    locId = "lobbies/tunisia_gorge_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_inv_axis = {
    image = "ui/tunisia_gorge_inv_02.avif"
    locId = "lobbies/tunisia_gorge_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_gorge_inv_counter = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_inv_counter_axis = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_inv = {
    image = "ui/Tunisia_Oasis_Inv_01.avif"
    locId = "lobbies/tunisia_oasis_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_oasis_inv_axis = {
    image = "ui/Tunisia_Oasis_Inv_01.avif"
    locId = "lobbies/tunisia_oasis_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_inv_counter = {
    image = "ui/Tunisia_Oasis_Inv_02.avif"
    locId = "lobbies/tunisia_oasis_inv_counter"
    army = MissionArmy.ALLIES
  }

  tunisia_oasis_inv_counter_axis = {
    image = "ui/Tunisia_Oasis_Inv_02.avif"
    locId = "lobbies/tunisia_oasis_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_dom = {
    image = "ui/Tunisia_Oasis_Inv_03.avif"
    locId = "lobbies/tunisia_oasis_dom"
    type = MissionType.DOMINATION
  }

  stalingrad_gogol_inv = {
    image = "ui/stalingrad_inv_02.avif"
    locId = "lobbies/stalingrad_gogol_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_inv_allies = {
    image = "ui/stalingrad_inv_02.avif"
    locId = "lobbies/stalingrad_gogol_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_inv_counter = {
    image = "ui/stalingrad_inv_11.avif"
    locId = "lobbies/stalingrad_gogol_inv_counter"
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_inv_counter_axis = {
    image = "ui/stalingrad_inv_11.avif"
    locId = "lobbies/stalingrad_gogol_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_conf = {
    image = "ui/stalingrad_inv_12.avif"
    locId = "lobbies/stalingrad_gogol_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_conf_allies = {
    image = "ui/stalingrad_inv_12.avif"
    locId = "lobbies/stalingrad_gogol_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_assault_allies = {
    image = "ui/stalingrad_inv_05.avif"
    locId = "lobbies/stalingrad_gogol_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_assault = {
    image = "ui/stalingrad_inv_05.avif"
    locId = "lobbies/stalingrad_gogol_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_assault_counter_axis = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_gogol_assault_counter_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_assault_counter_allies = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_gogol_assault_counter_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  stalingrad_univermag_inv = {
    image = "ui/stalingrad_inv_04.avif"
    locId = "lobbies/stalingrad_univermag_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_univermag_inv_axis = {
    image = "ui/stalingrad_inv_04.avif"
    locId = "lobbies/stalingrad_univermag_inv_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_univermag_conf = {
    image = "ui/stalingrad_inv_06.avif"
    locId = "lobbies/stalingrad_univermag_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  stalingrad_univermag_conf_axis = {
    image = "ui/stalingrad_inv_06.avif"
    locId = "lobbies/stalingrad_univermag_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  stalingrad_univermag_inv_counter = {
    image = "ui/stalingrad_inv_01.avif"
    locId = "lobbies/stalingrad_univermag_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_univermag_inv_counter_allies = {
    image = "ui/stalingrad_inv_01.avif"
    locId = "lobbies/stalingrad_univermag_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv = {
    image = "ui/stalingrad_inv_09.avif"
    locId = "lobbies/stalingrad_communist_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_communist_inv_allies = {
    image = "ui/stalingrad_inv_09.avif"
    locId = "lobbies/stalingrad_communist_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv_counter = {
    image = "ui/stalingrad_inv_10.avif"
    locId = "lobbies/stalingrad_communist_inv_counter"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv_counter_axis = {
    image = "ui/stalingrad_inv_10.avif"
    locId = "lobbies/stalingrad_communist_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_communist_bomb = {
    image = "ui/stalingrad_inv_03.avif"
    locId = "lobbies/stalingrad_communist_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_communist_bomb_allies = {
    image = "ui/stalingrad_inv_03.avif"
    locId = "lobbies/stalingrad_communist_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_conf = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_communist_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  stalingrad_communist_conf_allies = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_communist_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_inv = {
    image = "ui/stalingrad_tractor_plant_04.avif"
    locId = "lobbies/stalingrad_entrance_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_inv_allies = {
    image = "ui/stalingrad_tractor_plant_04.avif"
    locId = "lobbies/stalingrad_entrance_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_inv_counter = {
    image = "ui/stalingrad_tractor_plant_07.avif"
    locId = "lobbies/stalingrad_entrance_inv_counter"
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_inv_counter_allies = {
    image = "ui/stalingrad_tractor_plant_07.avif"
    locId = "lobbies/stalingrad_entrance_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_conf = {
    image = "ui/stalingrad_tractor_plant_02.avif"
    locId = "lobbies/stalingrad_entrance_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_conf_allies = {
    image = "ui/stalingrad_tractor_plant_02.avif"
    locId = "lobbies/stalingrad_entrance_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_bomb = {
    image = "ui/stalingrad_tractor_plant_03.avif"
    locId = "lobbies/stalingrad_entrance_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_bomb_allies = {
    image = "ui/stalingrad_tractor_plant_03.avif"
    locId = "lobbies/stalingrad_entrance_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_bomb_counter = {
    image = "ui/stalingrad_tractor_plant_08.avif"
    locId = "lobbies/stalingrad_entrance_bomb_counter"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_bomb_counter_allies = {
    image = "ui/stalingrad_tractor_plant_08.avif"
    locId = "lobbies/stalingrad_entrance_bomb_counter_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_dom = {
    image = "ui/stalingrad_tractor_plant_01.avif"
    locId = "lobbies/stalingrad_entrance_dom"
    type = MissionType.DOMINATION
  }

  stalingrad_station_dom = {
    image = "ui/stalingrad_inv_05.avif"
    locId = "lobbies/stalingrad_station_dom"
    type = MissionType.DOMINATION
  }

  pacific_gavutu_assault = {
    image = "ui/pacific_gavutu_inv_05.avif"
    locId = "lobbies/pacific_gavutu_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_assault_axis = {
    image = "ui/pacific_gavutu_inv_05.avif"
    locId = "lobbies/pacific_gavutu_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  pacific_gavutu_inv = {
    image = "ui/pacific_gavutu_inv_04.avif"
    locId = "lobbies/pacific_gavutu_inv"
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_inv_axis = {
    image = "ui/pacific_gavutu_inv_04.avif"
    locId = "lobbies/pacific_gavutu_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_gavutu_inv_counter = {
    image = "ui/pacific_gavutu_inv_03.avif"
    locId = "lobbies/pacific_gavutu_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_inv_counter_axis = {
    image = "ui/pacific_gavutu_inv_03.avif"
    locId = "lobbies/pacific_gavutu_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_gavutu_bomb_aerodrome = {
    image = "ui/pacific_gavutu_inv_07.avif"
    locId = "lobbies/pacific_gavutu_bomb_aerodrome"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb_aerodrome_axis = {
    image = "ui/pacific_gavutu_inv_07.avif"
    locId = "lobbies/pacific_gavutu_bomb_aerodrome_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_bomb = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb_axis = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_bomb_counter = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_bomb_counter"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb_counter_axis = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_bomb_counter_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_bomb_aerodrome_counter = {
    image = "ui/pacific_gavutu_inv_07.avif"
    locId = "lobbies/pacific_gavutu_bomb_aerodrome_counter"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb_aerodrome_counter_axis = {
    image = "ui/pacific_gavutu_inv_07.avif"
    locId = "lobbies/pacific_gavutu_bomb_aerodrome_counter_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_conf = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_conf_axis = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_dom = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_dom"
    type = MissionType.DOMINATION
  }

  pacific_guadalcanal_inv = {
    image = "ui/pacific_guadalcanal_inv_08.avif"
    locId = "lobbies/pacific_guadalcanal_inv"
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_inv_axis = {
    image = "ui/pacific_guadalcanal_inv_08.avif"
    locId = "lobbies/pacific_guadalcanal_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_guadalcanal_inv_counter = {
    image = "ui/pacific_guadalcanal_inv_09.avif"
    locId = "lobbies/pacific_guadalcanal_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_inv_counter_axis = {
    image = "ui/pacific_guadalcanal_inv_09.avif"
    locId = "lobbies/pacific_guadalcanal_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_guadalcanal_conf = {
    image = "ui/pacific_guadalcanal_inv_11.avif"
    locId = "lobbies/pacific_guadalcanal_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_dom = {
    image = "ui/pacific_guadalcanal_inv_01.avif"
    locId = "lobbies/pacific_guadalcanal_dom"
    type = MissionType.DOMINATION
  }

  pacific_guadalcanal_conf_axis = {
    image = "ui/pacific_guadalcanal_inv_11.avif"
    locId = "lobbies/pacific_guadalcanal_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  pacific_vertical_conf = {
    image = "ui/pacific_guadalcanal_inv_14.avif"
    locId = "lobbies/pacific_vertical_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  pacific_vertical_conf_axis = {
    image = "ui/pacific_guadalcanal_inv_14.avif"
    locId = "lobbies/pacific_vertical_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  pacific_vertical_inv = {
    image = "ui/pacific_guadalcanal_inv_07.avif"
    locId = "lobbies/pacific_vertical_inv"
    army = MissionArmy.ALLIES
  }

  pacific_vertical_inv_counter = {
    image = "ui/pacific_guadalcanal_inv_13.avif"
    locId = "lobbies/pacific_vertical_inv_counter"
    army = MissionArmy.AXIS
  }

  pacific_vertical_assault = {
    image = "ui/pacific_guadalcanal_inv_10.avif"
    locId = "lobbies/pacific_vertical_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  pacific_vertical_assault_axis = {
    image = "ui/pacific_guadalcanal_inv_10.avif"
    locId = "lobbies/pacific_vertical_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  pacific_vertical_bomb = {
    image = "ui/pacific_guadalcanal_inv_12.avif"
    locId = "lobbies/pacific_vertical_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_vertical_bomb_axis = {
    image = "ui/pacific_guadalcanal_inv_12.avif"
    locId = "lobbies/pacific_vertical_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_vertical_dom = {
    image = "ui/pacific_guadalcanal_inv_04.avif"
    locId = "lobbies/pacific_vertical_dom"
    type = MissionType.DOMINATION
  }

  pacific_vertical_dom_big = {
    image = "ui/pacific_guadalcanal_inv_03.avif"
    locId = "lobbies/pacific_vertical_dom_big"
    type = MissionType.DOMINATION
  }

  pacific_native_conf = {
    image = "ui/pacific_guadalcanal_inv_16.avif"
    locId = "lobbies/pacific_native_conf"
    army = MissionArmy.ALLIES
    type = MissionType.CONFRONTATION
  }

  pacific_native_conf_axis = {
    image = "ui/pacific_guadalcanal_inv_16.avif"
    locId = "lobbies/pacific_native_conf_axis"
    army = MissionArmy.AXIS
    type = MissionType.CONFRONTATION
  }

  pacific_native_inv = {
    image = "ui/pacific_guadalcanal_inv_06.avif"
    locId = "lobbies/pacific_native_inv"
    army = MissionArmy.ALLIES
  }

  pacific_native_inv_axis = {
    image = "ui/pacific_guadalcanal_inv_06.avif"
    locId = "lobbies/pacific_native_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_native_inv_counter = {
    image = "ui/pacific_guadalcanal_inv_02.avif"
    locId = "lobbies/pacific_native_inv_counter"
    army = MissionArmy.AXIS
  }

  pacific_native_inv_counter_allies = {
    image = "ui/pacific_guadalcanal_inv_02.avif"
    locId = "lobbies/pacific_native_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  pacific_native_bomb = {
    image = "ui/pacific_guadalcanal_inv_18.avif"
    locId = "lobbies/pacific_native_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_native_bomb_axis = {
    image = "ui/pacific_guadalcanal_inv_18.avif"
    locId = "lobbies/pacific_native_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_coast_assault = {
    image = "ui/pacific_new_georgia_ship_02.avif"
    locId = "lobbies/pacific_new_georgia_coast_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  pacific_new_georgia_coast_assault_axis = {
    image = "ui/pacific_new_georgia_ship_02.avif"
    locId = "lobbies/pacific_new_georgia_coast_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_coast_inv = {
    image = "ui/pacific_new_georgia_ship_01.avif"
    locId = "lobbies/pacific_new_georgia_coast_inv"
    army = MissionArmy.ALLIES
  }

  pacific_new_georgia_coast_inv_axis = {
    image = "ui/pacific_new_georgia_ship_01.avif"
    locId = "lobbies/pacific_new_georgia_coast_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_coast_inv_counter = {
    image = "ui/pacific_new_georgia_munda_point_01.avif"
    locId = "lobbies/pacific_new_georgia_coast_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_new_georgia_coast_inv_counter_axis = {
    image = "ui/pacific_new_georgia_munda_point_01.avif"
    locId = "lobbies/pacific_new_georgia_coast_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_caves_inv = {
    image = "ui/pacific_new_georgia_cave_a_01.avif"
    locId = "lobbies/pacific_new_georgia_caves_inv"
    army = MissionArmy.ALLIES
  }

  pacific_new_georgia_caves_inv_axis = {
    image = "ui/pacific_new_georgia_cave_a_01.avif"
    locId = "lobbies/pacific_new_georgia_caves_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_caves_inv_counter = {
    image = "ui/pacific_new_georgia_cave_a_02.avif"
    locId = "lobbies/pacific_new_georgia_caves_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_new_georgia_caves_inv_counter_axis = {
    image = "ui/pacific_new_georgia_cave_a_02.avif"
    locId = "lobbies/pacific_new_georgia_caves_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_new_georgia_bomb = {
    image = "ui/pacific_new_georgia_native_village_01.avif"
    locId = "lobbies/pacific_new_georgia_bomb"
    army = MissionArmy.ALLIES
    type = MissionType.DESTRUCTION
  }

  pacific_new_georgia_bomb_axis = {
    image = "ui/pacific_new_georgia_native_village_01.avif"
    locId = "lobbies/pacific_new_georgia_bomb_axis"
    army = MissionArmy.AXIS
    type = MissionType.DESTRUCTION
  }

  pacific_new_georgia_dom = {
    image = "ui/pacific_new_georgia_colonial_village_a_01.avif"
    locId = "lobbies/pacific_new_georgia_dom"
    type = MissionType.DOMINATION
  }

  pacific_new_georgia_caves_dom = {
    image = "ui/pacific_new_georgia_cave_b_02.avif"
    locId = "lobbies/pacific_new_georgia_caves_dom"
    type = MissionType.DOMINATION
  }

  pacific_new_georgia_conf = {
    image = "ui/pacific_new_georgia_japan_fortification_01.avif"
    locId = "lobbies/pacific_new_georgia_conf"
    army = MissionArmy.ALLIES
    type = MissionType.CONFRONTATION
  }

  pacific_new_georgia_conf_axis = {
    image = "ui/pacific_new_georgia_japan_fortification_01.avif"
    locId = "lobbies/pacific_new_georgia_conf_axis"
    army = MissionArmy.AXIS
    type = MissionType.CONFRONTATION
  }

  burma_heartlands_inv = {
    image = "ui/burma_heartlands_rice_farm_02.avif"
    locId = "lobbies/burma_heartlands_inv"
    army = MissionArmy.ALLIES
  }

  burma_heartlands_inv_axis = {
    image = "ui/burma_heartlands_rice_farm_02.avif"
    locId = "lobbies/burma_heartlands_inv_axis"
    army = MissionArmy.AXIS
  }

  burma_heartlands_inv_counter = {
    image = "ui/burma_heartlands_big_bell_01.avif"
    locId = "lobbies/burma_heartlands_inv_counter"
    army = MissionArmy.ALLIES
  }

  burma_heartlands_inv_counter_axis = {
    image = "ui/burma_heartlands_big_bell_01.avif"
    locId = "lobbies/burma_heartlands_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  burma_heartlands_conf = {
    image = "ui/burma_heartlands_city_gateway_01.avif"
    locId = "lobbies/burma_heartlands_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  burma_heartlands_conf_axis = {
    image = "ui/burma_heartlands_city_gateway_01.avif"
    locId = "lobbies/burma_heartlands_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  burma_heartlands_bomb = {
    image = "ui/burma_heartlands_hotel_02.avif"
    locId = "lobbies/burma_heartlands_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  burma_heartlands_bomb_axis = {
    image = "ui/burma_heartlands_hotel_02.avif"
    locId = "lobbies/burma_heartlands_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  burma_heartlands_bomb_counter = {
    image = "ui/burma_heartlands_tower_01.avif"
    locId = "lobbies/burma_heartlands_bomb_counter"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  burma_heartlands_bomb_counter_axis = {
    image = "ui/burma_heartlands_tower_01.avif"
    locId = "lobbies/burma_heartlands_bomb_counter_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  burma_heartlands_assault = {
    image = "ui/burma_heartlands_monastery_03.avif"
    locId = "lobbies/burma_heartlands_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  burma_heartlands_assault_axis = {
    image = "ui/burma_heartlands_monastery_03.avif"
    locId = "lobbies/burma_heartlands_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  burma_heartlands_dom = {
    image = "ui/burma_heartlands_monastery_01.avif"
    locId = "lobbies/burma_heartlands_dom"
    type = MissionType.DOMINATION
  }

  burma_heartlands_dom_big = {
    image = "ui/burma_heartlands_monastery_01.avif"
    locId = "lobbies/burma_heartlands_dom_big"
    type = MissionType.DOMINATION
  }

  manchuria_city_inv = {
    image = "ui/manchuria_mountains_04.avif"
    locId = "lobbies/manchuria_city_inv"
    army = MissionArmy.ALLIES
  }

  manchuria_city_inv_axis = {
    image = "ui/manchuria_mountains_04.avif"
    locId = "lobbies/manchuria_city_inv_axis"
    army = MissionArmy.AXIS
  }

  manchuria_city_inv_counter = {
    image = "ui/manchuria_mountains_06.avif"
    locId = "lobbies/manchuria_city_inv_counter"
    army = MissionArmy.ALLIES
  }

  manchuria_city_inv_counter_axis = {
    image = "ui/manchuria_mountains_06.avif"
    locId = "lobbies/manchuria_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  manchuria_city_conf = {
    image = "ui/manchuria_mountains_08.avif"
    locId = "lobbies/manchuria_city_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  manchuria_city_conf_axis = {
    image = "ui/manchuria_mountains_08.avif"
    locId = "lobbies/manchuria_city_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  manchuria_city_bomb = {
    image = "ui/manchuria_mountains_07.avif"
    locId = "lobbies/manchuria_city_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  manchuria_city_bomb_axis = {
    image = "ui/manchuria_mountains_07.avif"
    locId = "lobbies/manchuria_city_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  manchuria_city_assault = {
    image = "ui/manchuria_mountains_05.avif"
    locId = "lobbies/manchuria_city_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  manchuria_city_assault_axis = {
    image = "ui/manchuria_mountains_05.avif"
    locId = "lobbies/manchuria_city_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  manchuria_city_dom = {
    image = "ui/manchuria_radiotower_06.avif"
    locId = "lobbies/manchuria_city_dom"
    type = MissionType.DOMINATION
  }

  manchuria_city_dom_big = {
    image = "ui/manchuria_mountains_01.avif"
    locId = "lobbies/manchuria_city_dom_big"
    type = MissionType.DOMINATION
  }

  manchuria_radio_inv = {
    image = "ui/manchuria_radiotower_01.avif"
    locId = "lobbies/manchuria_radio_inv"
    army = MissionArmy.ALLIES
  }

  manchuria_radio_inv_axis = {
    image = "ui/manchuria_radiotower_01.avif"
    locId = "lobbies/manchuria_radio_inv_axis"
    army = MissionArmy.AXIS
  }

  manchuria_radio_inv_counter = {
    image = "ui/manchuria_radiotower_04.avif"
    locId = "lobbies/manchuria_radio_inv_counter"
    army = MissionArmy.ALLIES
  }

  manchuria_radio_inv_counter_axis = {
    image = "ui/manchuria_radiotower_04.avif"
    locId = "lobbies/manchuria_radio_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  manchuria_radio_conf = {
    image = "ui/manchuria_radiotower_07.avif"
    locId = "lobbies/manchuria_radio_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  manchuria_radio_conf_axis = {
    image = "ui/manchuria_radiotower_07.avif"
    locId = "lobbies/manchuria_radio_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  manchuria_radio_bomb = {
    image = "ui/manchuria_radiotower_05.avif"
    locId = "lobbies/manchuria_radio_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  manchuria_radio_bomb_axis = {
    image = "ui/manchuria_radiotower_05.avif"
    locId = "lobbies/manchuria_radio_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  manchuria_radio_assault = {
    image = "ui/manchuria_radiotower_03.avif"
    locId = "lobbies/manchuria_radio_assault"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  manchuria_radio_assault_axis = {
    image = "ui/manchuria_radiotower_03.avif"
    locId = "lobbies/manchuria_radio_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  manchuria_radio_dom = {
    image = "ui/manchuria_radiotower_02.avif"
    locId = "lobbies/manchuria_radio_dom"
    type = MissionType.DOMINATION
  }

  manchuria_radio_dom_big = {
    image = "ui/manchuria_mountains_02.avif"
    locId = "lobbies/manchuria_radio_dom_big"
    type = MissionType.DOMINATION
  }

  normandy_omaha_inv = {
    image = "ui/normandy_omaha_02.avif"
    locId = "lobbies/normandy_omaha_inv"
    army = MissionArmy.ALLIES
  }

  normandy_omaha_inv_counter = {
    image = "ui/normandy_omaha_09.avif"
    locId = "lobbies/normandy_omaha_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_omaha_inv_counter_axis = {
    image = "ui/normandy_omaha_09.avif"
    locId = "lobbies/normandy_omaha_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_omaha_conf = {
    image = "ui/normandy_omaha_07.avif"
    locId = "lobbies/normandy_omaha_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_omaha_bomb = {
    image = "ui/normandy_omaha_04.avif"
    locId = "lobbies/normandy_omaha_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_sword_inv = {
    image = "ui/normandy_sword_03.avif"
    locId = "lobbies/normandy_sword_inv"
    army = MissionArmy.ALLIES
  }

  normandy_sword_inv_counter = {
    image = "ui/normandy_sword_01.avif"
    locId = "lobbies/normandy_sword_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_sword_inv_counter_axis = {
    image = "ui/normandy_sword_01.avif"
    locId = "lobbies/normandy_sword_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_sword_conf = {
    image = "ui/normandy_sword_06.avif"
    locId = "lobbies/normandy_sword_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  normandy_sword_bomb = {
    image = "ui/normandy_sword_02.avif"
    locId = "lobbies/normandy_sword_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_omer_paratrooper = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_paratrooper"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  passchendaele_2_points_allies = {
    image = "ui/passchendaele_01.avif"
    locId = "lobbies/passchendaele"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  passchendaele_2_points_axis = {
    image = "ui/passchendaele_01.avif"
    locId = "lobbies/passchendaele"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  passchendaele_2_points_2_allies = {
    image = "ui/passchendaele_02.avif"
    locId = "lobbies/passchendaele"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  passchendaele_2_points_2_axis = {
    image = "ui/passchendaele_02.avif"
    locId = "lobbies/passchendaele"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  common_training_ground_germany = {
    image = "ui/game_mode_practice.avif"
    locId = "lobbies/practice"
    type = MissionType.PRACTICE
  }

  common_training_ground_usa = {
    image = "ui/game_mode_practice.avif"
    locId = "lobbies/practice"
    type = MissionType.PRACTICE
  }

  common_training_ground_japan = {
    image = "ui/game_mode_practice.avif"
    locId = "lobbies/practice"
    type = MissionType.PRACTICE
  }

  common_training_ground_ussr = {
    image = "ui/game_mode_practice.avif"
    locId = "lobbies/practice"
    type = MissionType.PRACTICE
  }

  tutorial_training_ground_moscow_allies = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  tutorial_training_ground_berlin_axis = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  tutorial_training_ground_pacific_axis = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  tutorial_training_ground_normandy_allies  = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  _tutorial_training_ground_tank = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  _tutorial_training_ground_engineer = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

  _tutorial_training_ground_aircraft = {
    image = "ui/volokolamsk_tutorial_01.avif"
    locId = "lobbies/tutorial"
    type = MissionType.TUTORIAL
  }

}
  .map(mkMission)

let getImagesFromMissions = @() missions.values()
  .filter(@(v) v.image != null)
  .map(@(v) v.image)

let getMissionPresentation = @(id) missions?[id]
  
  ?? missions.reduce(@(res, m)
    id.startswith(m.id) && (res?.id.len() ?? 0) < m.id.len() ? m : res, null)
  ?? mkMission({}, id)


function mkMissionTypes() {
  let missionTypes = {}
  foreach (mission in missions)
    missionTypes[mission.type] <- mission.type

  return missionTypeOrder.map(@(missionType) missionTypes?[missionType]).filter(@(v) v != null)
}
let missionTypes = mkMissionTypes()

return freeze({
  getMissionPresentation
  getImagesFromMissions
  typeToLocId
  missionTypes
})
