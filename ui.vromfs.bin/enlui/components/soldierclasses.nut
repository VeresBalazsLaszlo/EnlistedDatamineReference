import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/style/fontsStyle.nut" import fontTactical
from "%ui/ui_library.nut" import *

let { rankIcons, rankGlyphs } = require("%ui/components/rankIcons.nut")

let mkRankIcon = @(rank) @(armyId) rankIcons?[armyId][rank]
let mkRankGlyph = @(rank) @(armyId) rankGlyphs?[armyId][rank]

let premiumCfg = freeze({
  isPremium = true
  rank = 10
  getGlyph = @(_) null
  getIcon = @(armyId) armiesPresentation?[armyId].premIcon
})

let eventCfg = freeze({
  isEvent = true
  rank = 10
  getGlyph = @(_) null
  getIcon = @(_armyId) "ui/skin#icons/event_squad_icon.svg"
})

let mkRankCfg = @(rank) freeze({
  rank
  getIcon = mkRankIcon(rank)
  getGlyph = mkRankGlyph(rank)
})

let rank1Cfg = mkRankCfg(1)
let rank2Cfg = mkRankCfg(2)
let rank3Cfg = mkRankCfg(3)
let rank4Cfg = mkRankCfg(4)

let mkKind = @(data, sClass) freeze({
  locId = $"soldierClass/{sClass}"
}.__update(data))

let soldierKinds = freeze({
  unknown = {
    icon = "unknown.svg"
    locId = "Unknown"
  }
  rifle = {
    icon = "rifle.svg"
  }
  mgun = {
    icon = "machine_gun.svg"
  }
  assault = {
    icon = "submachine_gun.svg"
  }
  sniper = {
    icon = "sniper_rifle.svg"
  }
  anti_tank = {
    icon = "launcher.svg"
  }
  tanker = {
    icon = "driver_tank.svg"
  }
  radioman = {
    icon = "radioman.svg"
  }
  mortarman = {
    icon = "mortarman.svg"
  }
  pilot_fighter = {
    icon = "pilot_fighter.svg"
  }
  pilot_assaulter = {
    icon = "pilot_assaulter.svg"
  }
  flametrooper = {
    icon = "flametrooper.svg"
  }
  engineer = {
    icon = "engineer.svg"
  }
  biker = {
    icon = "biker.svg"
  }
  medic = {
    icon = "medic.svg"
  }
  paratrooper = {
    icon = "paratrooper.svg"
  }
  apc_driver = {
    icon = "apc_driver.svg"
  }
  partisan = {
    icon = "partisan.svg"
  }
  saboteur = {
    icon = "explosion_pack_icon.svg"
  }
}.map(mkKind))

function mkClass(data, key) {
  local { sClass = key, kind } = data
  return freeze({
    perksId = key
    locId = $"soldierClass/{sClass}"
    shortLocId = $"squadPromo/{kind}/shortDesc"
    sClass
  }.__update(data))
}

let soldierClasses = freeze({
  unknown = {
    perksId = ""
    locId = ""
    descLocId = ""
    shortLocId = ""
    getIcon = @(_) null
    getGlyph = @(_) null
    rank = 0
    kind = "unknown"
  }
  rifle = {
    kind = "rifle"
  }.__update(rank1Cfg)
  tutorial_rifle = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(rank1Cfg)
  rifle_2 = {
    kind = "rifle"
  }.__update(rank2Cfg)
  rifle_3 = {
    kind = "rifle"
  }.__update(rank3Cfg)
  mgun = {
    kind = "mgun"
  }.__update(rank1Cfg)
  mgun_2 = {
    kind = "mgun"
  }.__update(rank2Cfg)
  mgun_3 = {
    kind = "mgun"
  }.__update(rank3Cfg)
  assault = {
    kind = "assault"
  }.__update(rank1Cfg)
  assault_2 = {
    kind = "assault"
  }.__update(rank2Cfg)
  assault_3 = {
    kind = "assault"
  }.__update(rank3Cfg)
  assault_4 = {
    kind = "assault"
  }.__update(rank4Cfg)
  sniper = {
    kind = "sniper"
  }.__update(rank1Cfg)
  sniper_2 = {
    kind = "sniper"
  }.__update(rank2Cfg)
  sniper_3 = {
    kind = "sniper"
  }.__update(rank3Cfg)
  anti_tank = {
    kind = "anti_tank"
  }.__update(rank1Cfg)
  anti_tank_2 = {
    kind = "anti_tank"
  }.__update(rank2Cfg)
  tanker = {
    kind = "tanker"
  }.__update(rank1Cfg)
  tanker_2 = {
    kind = "tanker"
  }.__update(rank2Cfg)
  tanker_3 = {
    kind = "tanker"
  }.__update(rank3Cfg)
  radioman = {
    kind = "radioman"
  }.__update(rank1Cfg)
  radioman_2 = {
    kind = "radioman"
  }.__update(rank2Cfg)
  mortarman = {
    kind = "mortarman"
  }.__update(rank1Cfg)
  mortarman_2 = {
    kind = "mortarman"
  }.__update(rank2Cfg)
  pilot_fighter = {
    kind = "pilot_fighter"
  }.__update(rank1Cfg)
  pilot_fighter_2 = {
    kind = "pilot_fighter"
  }.__update(rank2Cfg)
  pilot_fighter_3 = {
    kind = "pilot_fighter"
  }.__update(rank3Cfg)
  pilot_assaulter = {
    kind = "pilot_assaulter"
  }.__update(rank1Cfg)
  pilot_assaulter_2 = {
    kind = "pilot_assaulter"
  }.__update(rank2Cfg)
  pilot_assaulter_3 = {
    kind = "pilot_assaulter"
  }.__update(rank3Cfg)
  flametrooper = {
    kind = "flametrooper"
  }.__update(rank1Cfg)
  flametrooper_2 = {
    kind = "flametrooper"
  }.__update(rank2Cfg)
  engineer = {
    kind = "engineer"
  }.__update(rank1Cfg)
  tutorial_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(rank1Cfg)
  engineer_2 = {
    kind = "engineer"
  }.__update(rank2Cfg)
  biker = {
    kind = "biker"
  }.__update(rank1Cfg)
  medic = {
    kind = "medic"
  }.__update(rank1Cfg)
  paratrooper = {
    kind = "paratrooper"
  }.__update(rank1Cfg)
  paratrooper_2 = {
    kind = "paratrooper"
  }.__update(rank2Cfg)
  paratrooper_3 = {
    kind = "paratrooper"
  }.__update(rank3Cfg)
  apc_driver = {
    kind = "apc_driver"
  }.__update(rank1Cfg)
  apc_driver_2 = {
    kind = "apc_driver"
  }.__update(rank2Cfg)
  apc_driver_3 = {
    kind = "apc_driver"
  }.__update(rank3Cfg)
  partisan = {
    kind = "partisan"
  }.__update(rank1Cfg)
  partisan_2 = {
    kind = "partisan"
  }.__update(rank2Cfg)
  partisan_3 = {
    kind = "partisan"
  }.__update(rank3Cfg)



  uk_tutorial_rifle = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(rank1Cfg)
  uk_rifle = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(rank1Cfg)
  uk_rifle_2 = {
    sClass = "rifle_2"
    kind = "rifle"
  }.__update(rank2Cfg)
  uk_rifle_3 = {
    sClass = "rifle_3"
    kind = "rifle"
  }.__update(rank3Cfg)
  uk_mgun = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(rank1Cfg)
  uk_mgun_2 = {
    sClass = "mgun_2"
    kind = "mgun"
  }.__update(rank2Cfg)
  uk_mgun_3 = {
    sClass = "mgun_3"
    kind = "mgun"
  }.__update(rank3Cfg)
  uk_assault = {
    sClass = "assault"
    kind = "assault"
  }.__update(rank1Cfg)
  uk_assault_2 = {
    sClass = "assault_2"
    kind = "assault"
  }.__update(rank2Cfg)
  uk_assault_3 = {
    sClass = "assault_3"
    kind = "assault"
  }.__update(rank3Cfg)
  uk_assault_4 = {
    sClass = "assault_4"
    kind = "assault"
  }.__update(rank4Cfg)
  uk_sniper = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(rank1Cfg)
  uk_sniper_2 = {
    sClass = "sniper_2"
    kind = "sniper"
  }.__update(rank2Cfg)
  uk_sniper_3 = {
    sClass = "sniper_3"
    kind = "sniper"
  }.__update(rank3Cfg)
  uk_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(rank1Cfg)
  uk_anti_tank_2 = {
    sClass = "anti_tank_2"
    kind = "anti_tank"
  }.__update(rank2Cfg)
  uk_tanker = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(rank1Cfg)
  uk_tanker_2 = {
    sClass = "tanker_2"
    kind = "tanker"
  }.__update(rank2Cfg)
  uk_tanker_3 = {
    sClass = "tanker_3"
    kind = "tanker"
  }.__update(rank3Cfg)
  uk_radioman = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(rank1Cfg)
  uk_radioman_2 = {
    sClass = "radioman_2"
    kind = "radioman"
  }.__update(rank2Cfg)
  uk_mortarman = {
    sClass = "mortarman"
    kind = "mortarman"
  }.__update(rank1Cfg)
  uk_mortarman_2 = {
    sClass = "mortarman_2"
    kind = "mortarman"
  }.__update(rank2Cfg)
  uk_pilot_fighter = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(rank1Cfg)
  uk_pilot_fighter_2 = {
    sClass = "pilot_fighter_2"
    kind = "pilot_fighter"
  }.__update(rank2Cfg)
  uk_pilot_fighter_3 = {
    sClass = "pilot_fighter_3"
    kind = "pilot_fighter"
  }.__update(rank3Cfg)
  uk_pilot_assaulter = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(rank1Cfg)
  uk_pilot_assaulter_2 = {
    sClass = "pilot_assaulter_2"
    kind = "pilot_assaulter"
  }.__update(rank2Cfg)
  uk_pilot_assaulter_3 = {
    sClass = "pilot_assaulter_3"
    kind = "pilot_assaulter"
  }.__update(rank3Cfg)
  uk_flametrooper = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(rank1Cfg)
  uk_flametrooper_2 = {
    sClass = "flametrooper_2"
    kind = "flametrooper"
  }.__update(rank2Cfg)
  uk_tutorial_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(rank1Cfg)
  uk_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(rank1Cfg)
  uk_engineer_2 = {
    sClass = "engineer_2"
    kind = "engineer"
  }.__update(rank2Cfg)
  uk_biker = {
    sClass = "biker"
    kind = "biker"
  }.__update(rank1Cfg)
  uk_medic = {
    sClass = "medic"
    kind = "medic"
  }.__update(rank1Cfg)
  uk_apc_driver_2 = {
    sClass = "apc_driver_2"
    kind = "apc_driver"
  }.__update(rank2Cfg)
  uk_partisan_2 = {
    sClass = "partisan_2"
    kind = "partisan"
  }.__update(rank2Cfg)



  it_tutorial_rifle = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(rank1Cfg)
  it_rifle = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(rank1Cfg)
  it_rifle_2 = {
    sClass = "rifle_2"
    kind = "rifle"
  }.__update(rank2Cfg)
  it_rifle_3 = {
    sClass = "rifle_3"
    kind = "rifle"
  }.__update(rank3Cfg)
  it_mgun = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(rank1Cfg)
  it_mgun_2 = {
    sClass = "mgun_2"
    kind = "mgun"
  }.__update(rank2Cfg)
  it_mgun_3 = {
    sClass = "mgun_3"
    kind = "mgun"
  }.__update(rank3Cfg)
  it_assault = {
    sClass = "assault"
    kind = "assault"
  }.__update(rank1Cfg)
  it_assault_2 = {
    sClass = "assault_2"
    kind = "assault"
  }.__update(rank2Cfg)
  it_assault_3 = {
    sClass = "assault_3"
    kind = "assault"
  }.__update(rank3Cfg)
  it_assault_4 = {
    sClass = "assault_4"
    kind = "assault"
  }.__update(rank4Cfg)
  it_sniper = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(rank1Cfg)
  it_sniper_2 = {
    sClass = "sniper_2"
    kind = "sniper"
  }.__update(rank2Cfg)
  it_sniper_3 = {
    sClass = "sniper_3"
    kind = "sniper"
  }.__update(rank3Cfg)
  it_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(rank1Cfg)
  it_anti_tank_2 = {
    sClass = "anti_tank_2"
    kind = "anti_tank"
  }.__update(rank2Cfg)
  it_tanker = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(rank1Cfg)
  it_tanker_2 = {
    sClass = "tanker_2"
    kind = "tanker"
  }.__update(rank2Cfg)
  it_tanker_3 = {
    sClass = "tanker_3"
    kind = "tanker"
  }.__update(rank3Cfg)
  it_radioman = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(rank1Cfg)
  it_radioman_2 = {
    sClass = "radioman_2"
    kind = "radioman"
  }.__update(rank2Cfg)
  it_mortarman = {
    sClass = "mortarman"
    kind = "mortarman"
  }.__update(rank1Cfg)
  it_mortarman_2 = {
    sClass = "mortarman_2"
    kind = "mortarman"
  }.__update(rank2Cfg)
  it_pilot_fighter = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(rank1Cfg)
  it_pilot_fighter_2 = {
    sClass = "pilot_fighter_2"
    kind = "pilot_fighter"
  }.__update(rank2Cfg)
  it_pilot_fighter_3 = {
    sClass = "pilot_fighter_3"
    kind = "pilot_fighter"
  }.__update(rank3Cfg)
  it_pilot_assaulter = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(rank1Cfg)
  it_pilot_assaulter_2 = {
    sClass = "pilot_assaulter_2"
    kind = "pilot_assaulter"
  }.__update(rank2Cfg)
  it_pilot_assaulter_3 = {
    sClass = "pilot_assaulter_3"
    kind = "pilot_assaulter"
  }.__update(rank3Cfg)
  it_flametrooper = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(rank1Cfg)
  it_flametrooper_2 = {
    sClass = "flametrooper_2"
    kind = "flametrooper"
  }.__update(rank2Cfg)
  it_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(rank1Cfg)
  it_tutorial_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(rank1Cfg)
  it_engineer_2 = {
    sClass = "engineer_2"
    kind = "engineer"
  }.__update(rank2Cfg)
  it_biker = {
    sClass = "biker"
    kind = "biker"
  }.__update(rank1Cfg)
  it_medic = {
    sClass = "medic"
    kind = "medic"
  }.__update(rank1Cfg)
  it_apc_driver_2 = {
    sClass = "apc_driver_2"
    kind = "apc_driver"
  }.__update(rank2Cfg)
  it_partisan_2 = {
    sClass = "partisan_2"
    kind = "partisan"
  }.__update(rank2Cfg)




 

  rifle_3_premium_1 = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_3_premium_1_ch = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_3_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  rifle_3_premium_2 = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  radioman_2_premium_1 = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  radioman_2_premium_1_ch = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  radioman_2_premium_2 = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  radioman_2_event_1 = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(eventCfg)
  radioman_2_event_1_ch = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  radioman_2_event_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_2 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_2_engineer_normandy = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_2_engineer_moscow = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_3 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_3_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_1_premium_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_1_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_3 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_3_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_3_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(premiumCfg)
  assault_2_event_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_2_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  assault_2_event_1_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(eventCfg)
  assault_2_premium_2 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_2_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_2_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_2_event = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_2_premium_2_event_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  assault_2_premium_2_event_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(eventCfg)
  assault_3_premium_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_1_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_2 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_2_event = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_3_premium_2_event_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_2_event_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  assault_3_premium_2_event_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_3 = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_3_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_3_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(premiumCfg)
  mgun_premium_1 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_premium_1_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_premium_1_legacy = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_2_premium_1 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_2_engineer_premium_1 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_2_premium_1_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_2_engineer_premium_1_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_2_event_1 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(eventCfg)
  mgun_3_premium_1 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_1_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_2 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_2_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_2_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_event_1 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(eventCfg)
  mgun_3_event_1_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  mgun_3_event_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_3 = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_3_ch = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_3_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_3_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  sniper_2_premium_1 = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(premiumCfg)
  sniper_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  sniper_2_premium_1_ch = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(premiumCfg)
  sniper_2_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  sniper_2_premium_2 = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(premiumCfg)
  sniper_2_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  sniper_2_premium_2_ch = {
    sClass = "sniper"
    kind = "sniper"
  }.__update(premiumCfg)
  sniper_2_premium_2_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_1 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_1_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_2 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_2_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_2_event_1 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  engineer_2_event_1_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_2_premium_1 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_2_premium_1_radioman = {
    sClass = "radioman"
    kind = "radioman"
  }.__update(premiumCfg)
  medic_1_premium_1 = {
    sClass = "medic"
    kind = "medic"
  }.__update(premiumCfg)
  medic_1_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  medic_2_premium_1 = {
    sClass = "medic"
    kind = "medic"
  }.__update(premiumCfg)
  medic_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_premium_2 = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_premium_2_ch = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_premium_2_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_premium_1 = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_event_1 = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(eventCfg)
  flametrooper_2_event_1_ch = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  flametrooper_2_event_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_premium_1_ch = {
    sClass = "flametrooper"
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  tanker_premium_1 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_1_premium_1 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_2 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_2_flametrooper = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_2_premium_1 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_2_premium_2 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_2_event_1 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(eventCfg)
  tanker_3_premium_1 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_2 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_3 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_4 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_5 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_6 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_7 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_8 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_9 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_2_premium_3 = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  pilot_fighter_premium_1 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_premium_2 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_2_premium_1 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_1 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_1_event = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(eventCfg)
  pilot_fighter_3_premium_2 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_3 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_4 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_5 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_assaulter_premium_1 = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_2_premium_1 = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_2_premium_2 = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_fighter_2_event_1 = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(eventCfg)
  pilot_assaulter_3_premium_1 = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_3_premium_2 = {
    sClass = "pilot_assaulter"
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  rifle_premium_1 = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_2_event_1 = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(eventCfg)
  rifle_2_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  rifle_2_event_1_anti_tank = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(eventCfg)
  anti_tank_1_premium_1 = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(eventCfg)
  anti_tank_1_premium_1_ch = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(premiumCfg)
  anti_tank_1_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  anti_tank_1_premium_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  anti_tank_2_premium_1 = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(premiumCfg)
  anti_tank_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_event_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_1_event_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_1_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  biker_premium_1 = {
    sClass = "biker"
    kind = "biker"
  }.__update(premiumCfg)
  biker_engineer_premium_1 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  biker_2_premium_2_medic = {
    sClass = "biker"
    kind = "biker"
  }.__update(premiumCfg)
  biker_2_premium_2_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  biker_2_premium_1 = {
    sClass = "biker"
    kind = "biker"
  }.__update(premiumCfg)
  biker_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  biker_2_event_1 = {
    sClass = "biker"
    kind = "biker"
  }.__update(eventCfg)
  biker_2_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  paratrooper_1_event_1 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(eventCfg)
  paratrooper_2_premium_1 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(premiumCfg)
  paratrooper_2_premium_1_ch = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(premiumCfg)
  paratrooper_2_premium_2 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(premiumCfg)
  paratrooper_2_event_1 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(eventCfg)
  paratrooper_2_event_1_ch = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(premiumCfg)
  paratrooper_2_event_2 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(eventCfg)
  paratrooper_2_event_2_ch = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(premiumCfg)
  paratrooper_2_event_3 = {
    sClass = "paratrooper"
    kind = "paratrooper"
  }.__update(eventCfg)
  assault_2_premium_1_normandy = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_1_engineer_normandy = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_1_engineer_normandy_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_1_normandy = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_1_normandy_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1_ch_normandy = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1_engineer_ch_normandy = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_1_normandy = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_2_moscow = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_2_normandy = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  engineer_premium_1_normandy = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_event_1 = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  assault_3_event_1_ch = {
    sClass = "assault"
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_event_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  assault_3_event_1_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)

  mortarman_2_premium_1 = {
    sClass = "mortarman"
    kind = "mortarman"
  }.__update(premiumCfg)
  mortarman_2_premium_1_engineer = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)

  mgun_premium_1_ch_normandy = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_premium_1_engineer_ch_normandy = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_premium_1_normandy = {
    sClass = "mgun"
    kind = "mgun"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_3_normandy = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_premium_1_normandy = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_premium_2_tunisia = {
    sClass = "pilot_fighter"
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  rifle_3_premium_1_berlin = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_3_premium_1_berlin_ch = {
    sClass = "rifle"
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_3_premium_1_berlin_engineer_ch = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(premiumCfg)
  tanker_3_premium_1_normandy = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_1_tunisia = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_2_normandy = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_3_berlin = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_3_normandy = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_5_moscow = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_1_berlin = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_1_tunisia = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_2_normandy = {
    sClass = "tanker"
    kind = "tanker"
  }.__update(premiumCfg)
  apc_driver_2_premium_2 = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(premiumCfg)
  apc_driver_2_premium_2_ch = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(premiumCfg)
  apc_driver_2_premium_1 = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(premiumCfg)
  apc_driver_2_premium_3 = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(premiumCfg)
  apc_driver_2_event_1 = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(eventCfg)
  apc_driver_2_event_2 = {
    sClass = "apc_driver"
    kind = "apc_driver"
  }.__update(eventCfg)
  saboteur_5_event_1 = {
    sClass = "saboteur"
    kind = "saboteur"
  }.__update(eventCfg)
  partisan_2_premium_1 = {
    sClass = "partisan"
    kind = "partisan"
  }.__update(premiumCfg)
  partisan_2_premium_2 = {
    sClass = "partisan"
    kind = "partisan"
  }.__update(premiumCfg)
  partisan_2_premium_2_ch = {
    sClass = "partisan"
    kind = "partisan"
  }.__update(premiumCfg)
  partisan_2_event_1 = {
    sClass = "partisan"
    kind = "partisan"
  }.__update(eventCfg)
  assault_2_event_halloween_2024 = {
    sClass = "assault"
    kind = "assault"
  }.__update(eventCfg)
  medic_2_event_halloween_2024 = {
    sClass = "medic"
    kind = "medic"
  }.__update(eventCfg)
  engineer_2_event_halloween_2024 = {
    sClass = "engineer"
    kind = "engineer"
  }.__update(eventCfg)
  anti_tank_2_event_halloween_2024 = {
    sClass = "anti_tank"
    kind = "anti_tank"
  }.__update(eventCfg)

}.map(mkClass))

const GLYPHS_TAG = "t"

let mkGlyphsStyle = @(params = hdpx(16)) {
  [GLYPHS_TAG] = {}.__update(fontTactical, typeof params == "table" ? params : { fontSize = params })
}

let getClassCfg = @(sClass) soldierClasses?[sClass] ?? soldierClasses.unknown

let getKindCfg = @(sKind) soldierKinds?[sKind] ?? soldierKinds.unknown

let formatGlyph = @(glyph) glyph == null ? null : $"<{GLYPHS_TAG}>{glyph}</{GLYPHS_TAG}>"

function getClassNameWithGlyph(sClass, armyId){
  let { getGlyph, locId } = getClassCfg(sClass)
  let glyph = formatGlyph(getGlyph(armyId))
  let className = loc(locId)
  return glyph ? $"{glyph} {className}" : className
}

let soldierKindsList = soldierKinds.keys()
  .filter(@(k) k != "unknown")
  .sort(@(a, b) a <=> b)

return freeze({
  soldierClasses
  soldierKinds
  soldierKindsList
  getClassCfg
  getKindCfg
  mkGlyphsStyle
  formatGlyph
  getClassNameWithGlyph
})
