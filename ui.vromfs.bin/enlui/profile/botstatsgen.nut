from "%sqstd/math.nut" import round_by_value
from "%ui/meta/curCampaign.nut" import allCampaigns, allArmies
from "%ui/profile/rankState.nut" import rankUnlock
from "%ui/ui_library.nut" import *

let Rand = require("%sqstd/rand.nut")

const TOTAL_KILLS_RAND = 0.4
const KILL_RAND = 0.3
const STATS_RAND = 0.3

let baseStats = {
  battles = 0.01
  kills = 0.1
  deaths = 0.06
  victories = 0.006
  defeats = 0.004
  battle_time = 6.0
}

let killWeights = {
  rifle_kills = 0.25
  submachine_gun_kills = 0.2
  machine_gun_kills = 0.14
  grenade_kills = 0.05
  kills_using_tank = 0.05
  kills_using_apc = 0.03
  kills_using_bike = 0.01
  kills_using_aircraft = 0.05
  artillery_kills = 0.02
  flamethrower_kills = 0.01
  shotgun_kills = 0.01
  pistol_kills = 0.05
  mortar_kills = 0.01
  melee_kills = 0.1
  launcher_kills = 0.01
  tank_kills = 0.05
  apc_kills = 0.03
  bike_kills = 0.01
  aircraft_kills = 0.01
}

function makeBotData(botData){
  let { name, rank } = botData.player
  let seed = "".concat(name, rank).hash()
  let rand = Rand(seed)

  let curRating = rankUnlock.get().findvalue(@(v) v.index == rank)?.progress ?? 0
  let nextRating = rankUnlock.get().findvalue(@(v) v.index == rank + 1)?.progress ?? 1
  local rating = rand.rint(curRating, nextRating - 1) * 100
  botData.player.rating = rating
  rating = max(100, rating)
  let res = {}
  let main_game = {}

  let campArmies = []
  let baseKills = baseStats["kills"] * rating
  foreach (campId in allCampaigns.get())
    campArmies.extend(allArmies.get()?[campId] ?? [])
  campArmies.sort()
  foreach (armyId in campArmies){
    let armyData = {}
    let baseArmyKills = rand.rint(
      baseKills * (1.0 - TOTAL_KILLS_RAND), baseKills * (1.0 + TOTAL_KILLS_RAND))
    local armyKills = 0
    killWeights.keys().sort().each(function(killType){
      let killWeight = killWeights[killType]
      let r = rand.rfloat(killWeight*(1.0 - KILL_RAND), killWeight*(1.0 + KILL_RAND))
      let kills = round_by_value(baseArmyKills * r, 1).tointeger()
      armyData[killType] <- kills
      main_game[killType] <- kills + (main_game?[killType] ?? 0)
      armyKills += kills
    })
    armyData["kills"] <- armyKills
    baseStats.keys().sort().each(function(stat){
      let baseStatVal = baseStats[stat] * rating
      local statVal = rand.rint(baseStatVal*(1.0-STATS_RAND), baseStatVal*(1.0+STATS_RAND))
      if (stat == "battles")
        statVal = max(1, statVal)
      armyData[stat] <- statVal
      main_game[stat] <- statVal + (main_game?[stat] ?? 0)
    })
    res[armyId] <- armyData
  }
  res.__update({main_game})
  return botData.__merge({stats = { ["global"] = res}})
}

return makeBotData