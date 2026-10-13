import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
from "%ui/ui_library.nut" import *

let enlisted_ussr_ger_low_BR  = [ "berlin_garden_assault", "volokolamsk_voskhod_bomb", "stalingrad_station_dom", "rzhev_city_dom", ]
let enlisted_ussr_ger_high_BR = [ "berlin_garden_assault", "stalingrad_station_dom", "rzhev_city_dom", ]
let enlisted_usa_jap_low_BR   = [ "pacific_new_georgia_conf", "burma_heartlands_inv", ]
let enlisted_usa_jap_high_BR   = [ "pacific_new_georgia_conf", "burma_heartlands_inv", ]
let enlisted_usa_ger_low_BR   = [ "tunisia_oasis_dom", "normandy_city_dom", "ardennes_forest_dom", ]
let enlisted_usa_ger_high_BR  = [ "normandy_city_dom", "ardennes_forest_dom", ]
let enlisted_ussr_jap_low_BR   = [ "manchuria_city_inv", ]
let enlisted_ussr_jap_high_BR  = [ "manchuria_city_inv", ]


let missionsByQueue = {
  enlisted_ussr_ger_low_BR
  enlisted_ussr_ger_low_BR_1_2 = enlisted_ussr_ger_low_BR
  enlisted_ussr_ger_low_BR_2_3 = enlisted_ussr_ger_low_BR

  enlisted_ussr_ger_high_BR
  enlisted_ussr_ger_high_BR_3_4 = enlisted_ussr_ger_high_BR
  enlisted_ussr_ger_high_BR_4_5 = enlisted_ussr_ger_high_BR

  enlisted_usa_jap_low_BR
  enlisted_usa_jap_low_BR_1_2 = enlisted_usa_jap_low_BR
  enlisted_usa_jap_low_BR_2_3 = enlisted_usa_jap_low_BR

  enlisted_usa_jap_high_BR
  enlisted_usa_jap_high_BR_3_4 = enlisted_usa_jap_high_BR
  enlisted_usa_jap_high_BR_4_5 = enlisted_usa_jap_high_BR

  enlisted_usa_ger_low_BR
  enlisted_usa_ger_low_BR_1_2 = enlisted_usa_ger_low_BR
  enlisted_usa_ger_low_BR_2_3 = enlisted_usa_ger_low_BR

  enlisted_usa_ger_high_BR
  enlisted_usa_ger_high_BR_3_4 = enlisted_usa_ger_high_BR
  enlisted_usa_ger_high_BR_4_5 = enlisted_usa_ger_high_BR

  enlisted_ussr_jap_low_BR
  enlisted_ussr_jap_low_BR_1_2 = enlisted_ussr_jap_low_BR
  enlisted_ussr_jap_low_BR_2_3 = enlisted_ussr_jap_low_BR

  enlisted_ussr_jap_high_BR
  enlisted_ussr_jap_high_BR_3_4 = enlisted_ussr_jap_high_BR
  enlisted_ussr_jap_high_BR_4_5 = enlisted_ussr_jap_high_BR

  enlisted_ussr_ger_newbies = enlisted_ussr_ger_low_BR
  enlisted_usa_jap_newbies = enlisted_usa_jap_low_BR
  enlisted_usa_ger_newbies = enlisted_usa_ger_low_BR
  enlisted_ussr_jap_newbies = enlisted_ussr_jap_low_BR
}

function mkCampaignsByMissions() {
  let missions = {}
  foreach (queueMissions in missionsByQueue) {
    queueMissions.each(function(blk) {
      let { id, campaign } = getMissionInfo(blk)
      missions[id] <- campaign
    })
  }

  return missions
}

return {
  missionsByQueue   
                    
  campaignsByMissions = mkCampaignsByMissions()
}