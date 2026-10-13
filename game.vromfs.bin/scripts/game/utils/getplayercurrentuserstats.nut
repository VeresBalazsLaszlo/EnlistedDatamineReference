import "%dngscripts/ecs.nut" as ecs
from "math" import max, abs

let {TEAM_UNASSIGNED} = require("team")
let {INVALID_SQUAD_ID} = require("matching.errors")
let {get_matching_invite_data} = require("app")

function getScorePlaceStats(roundResult, team, score) {
  let stats = {}
  roundResult.scoreStats?[team]?.each(function(requiredScore, stat) {
    if (score >= requiredScore)
      stats[stat] <- 1
  })
  return stats
}

let groupScoreQuery = ecs.SqQuery("groupScoreQuery", {
  comps_rq = ["player"]
  comps_ro = [["groupId", ecs.TYPE_INT64], ["scoring_player__score", ecs.TYPE_INT], ["scoring_player__battleTime", ecs.TYPE_FLOAT]]
})
function getGroupStats(groupId) {
  if (groupId == null || groupId == INVALID_SQUAD_ID)
    return {}
  local score = 0
  local time = 0
  local scorePerMin = 0.0
  groupScoreQuery(function(_, comp) {
    if (comp.groupId == groupId) {
      score += comp.scoring_player__score
      time += comp.scoring_player__battleTime.tointeger()
      scorePerMin += comp.scoring_player__score / max(comp.scoring_player__battleTime, 300.0) * 60.0
    }
  })
  return {
    groupScore = score
    groupScorePerMin = scorePerMin
    groupTime = time
  }
}

let playerTokensQuery = ecs.SqQuery("playerTokensQuery", {
  comps_rq = ["player"]
  comps_ro = [["player__tokens", ecs.TYPE_INT], ["possessed", ecs.TYPE_EID]]
})

let getVehicleQuery     = ecs.SqQuery("getVehicleQuery",     {comps_ro = [["human_anim__vehicleSelected", ecs.TYPE_EID]]})
let getVehicleTypeQuery = ecs.SqQuery("getVehicleTypeQuery", {comps_ro = [["zombie_evacuation", ecs.TYPE_TAG, null]]})

function getTeamTokens() {
  local totalTokens = 0
  playerTokensQuery(function(_, playerComp) {
    let vehicleEid = getVehicleQuery(playerComp.possessed, @(_, humanComp) humanComp["human_anim__vehicleSelected"]) ?? ecs.INVALID_ENTITY_ID
    getVehicleTypeQuery(vehicleEid, function(_, vehComp) {
      if (vehComp.zombie_evacuation != null)
        totalTokens += playerComp.player__tokens
    })
  })
  return totalTokens
}

function isInGameMods() {
  let matchingInviteData = get_matching_invite_data()
  let modId = matchingInviteData?.mode_info.modId ?? ""
  return modId != "" ? true : false
}

let userStatFfaQueryQuery = ecs.SqQuery("userStatFfaQueryQuery", {
  comps_ro = [["chars_gun_game__winnerTeam", ecs.TYPE_INT]]
})

function isTeamWon(roundResult, team) {
  local res = team != TEAM_UNASSIGNED && (roundResult.team == team) == roundResult.isWon
  userStatFfaQueryQuery.perform(function(_eid, comp) {
    if (comp.chars_gun_game__winnerTeam != -1)
      res = comp.chars_gun_game__winnerTeam == team
  })
  return res
}

let isGameWithDeveloperQuery = ecs.SqQuery("isGameWithDeveloperQuery", { comps_rq = ["gameWithDeveloper"] })
let isGameWithDeveloper = @() isGameWithDeveloperQuery(@(...) true) ?? false

let isZombieModeQuery = ecs.SqQuery("isZombieModeQuery", { comps_rq = ["zombieSpawnMode"] })
let isZombieMode = @() isZombieModeQuery(@(...) true) ?? false


let isTokensQuery = ecs.SqQuery("isTokensQuery", { comps_rq = ["zombie_mode__tokenParams"] })
let isTokensEntity = @() isTokensQuery(@(...) true) ?? false

function addStatValue(stats, value, addName) {
  if (value > 0)
    stats[addName] <- value
}

function addStat(stats, comp, name, addName) {
  addStatValue(stats, comp[name], addName)
}

let playerUserstatComps = [
  ["groupId", ecs.TYPE_INT64, null],
  ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ["userstats", ecs.TYPE_OBJECT, null],
  ["userstats__bestWeaponKillStreak", ecs.TYPE_OBJECT, null],
  ["userstatsFilter", ecs.TYPE_SHARED_OBJECT, null],
  ["scoring_player__isGameFinished", ecs.TYPE_BOOL, true],
  ["scoring_player__kills", ecs.TYPE_INT, 0],
  ["scoring_player__killsByPlayer", ecs.TYPE_INT, 0],
  ["scoring_player__bestPossessedInfantryKillstreak", ecs.TYPE_INT, 0],
  ["scoring_player__tankKills", ecs.TYPE_INT, 0],
  ["scoring_player__bikeKills", ecs.TYPE_INT, 0],
  ["scoring_player__apcKills", ecs.TYPE_INT, 0],
  ["scoring_player__planeKills", ecs.TYPE_INT, 0],
  ["scoring_player__aiPlaneKills", ecs.TYPE_INT, 0],
  ["scoring_player__battleTime", ecs.TYPE_FLOAT, 0.0],
  ["scoring_player__soldierDeaths", ecs.TYPE_INT, 0],
  ["scoring_player__squadDeaths", ecs.TYPE_INT, 0],
  ["scoring_player__assists", ecs.TYPE_INT, 0],
  ["scoring_player__attackKills", ecs.TYPE_INT, 0],
  ["scoring_player__defenseKills", ecs.TYPE_INT, 0],
  ["scoring_player__longRangeKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT, 0],
  ["scoring_player__builtRallyPointUses", ecs.TYPE_INT, 0],
  ["scoring_player__ownedMobileSpawnUses", ecs.TYPE_INT, 0],
  ["scoring_player__killByThrowable", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunTankKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunBikeKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunBikeKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunApcKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunApcKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunAiPlaneKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunAiPlaneKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT, 0],
  ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__friendlyFirePenalty", ecs.TYPE_INT, 0],
  ["squads__spawnCount", ecs.TYPE_INT, 0],
  ["scoring_player__score", ecs.TYPE_INT, 0],
  ["scoring_player__isBattleHero", ecs.TYPE_BOOL, false],
  ["scoring_player__zombieKills", ecs.TYPE_INT, 0],
  ["scoring_player__zombieHeadshots", ecs.TYPE_INT, 0],
  ["scoring_player__zombieWaves", ecs.TYPE_INT, 0],
  ["scoring_player__zombieDoorsScore", ecs.TYPE_INT, 0],
  ["scoring_player__zombieTotalScore", ecs.TYPE_INT, 0],
  ["scoring_player__apcSpot", ecs.TYPE_INT, 0],
  ["scoring_player__apcSpotSpy", ecs.TYPE_INT, 0],
  ["scoring_player__buildingSpot", ecs.TYPE_INT, 0],
  ["scoring_player__buildingSpotSpy", ecs.TYPE_INT, 0],
  ["scoring_player__tankSpot", ecs.TYPE_INT, 0],
  ["scoring_player__tankSpotSpy", ecs.TYPE_INT, 0],
  ["scoring_player__plantBomb", ecs.TYPE_FLOAT, 0.0],
  ["scoring_player__defuseBomb", ecs.TYPE_FLOAT, 0.0],
]

let getEngineerBuildingUsages = @(comp)
  comp["scoring_player__builtAmmoBoxRefills"]
  + comp["scoring_player__builtRallyPointUses"]
  + comp["scoring_player__builtGunKills"]
  + comp["scoring_player__builtGunKillAssists"]
  + comp["scoring_player__builtGunTankKills"]
  + comp["scoring_player__builtGunTankKillAssists"]
  + comp["scoring_player__builtGunBikeKills"]
  + comp["scoring_player__builtGunBikeKillAssists"]
  + comp["scoring_player__builtGunApcKills"]
  + comp["scoring_player__builtGunApcKillAssists"]
  + comp["scoring_player__builtGunPlaneKills"]
  + comp["scoring_player__builtGunAiPlaneKills"]
  + comp["scoring_player__builtGunPlaneKillAssists"]
  + comp["scoring_player__builtGunAiPlaneKillAssists"]
  + comp["scoring_player__builtBarbwireActivations"]
  + comp["scoring_player__builtCapzoneFortificationActivations"]
  + comp["scoring_player__ownedMobileSpawnUses"]

let getBuildingDestroyed = @(comp)
  comp["scoring_player__enemyBuiltFortificationDestructions"]
  + comp["scoring_player__enemyBuiltGunDestructions"]
  + comp["scoring_player__enemyBuiltUtilityDestructions"]

function getPlayerCurrentUserstats(comp, roundResult = null) {
  local stats = {}

  stats.__update(comp?.userstats?.getAll() ?? {})
  stats.__update(comp?["userstats__bestWeaponKillStreak"]?.getAll() ?? {})
  addStat(stats, comp, "scoring_player__score", "battle_score")
  addStat(stats, comp, "scoring_player__attackKills", "kills_while_attacking_point")
  addStat(stats, comp, "scoring_player__defenseKills", "kills_while_defending_point")
  addStat(stats, comp, "scoring_player__kills", "kills")
  addStat(stats, comp, "scoring_player__killsByPlayer", "kills_by_player")
  addStat(stats, comp, "scoring_player__longRangeKills", "long_range_kills")
  addStat(stats, comp, "scoring_player__bestPossessedInfantryKillstreak", "best_possessed_infantry_killstreak")
  if (comp.scoring_player__bestPossessedInfantryKillstreak >= 10)
    addStatValue(stats, 1, "best_possessed_infantry_killstreak_10")
  addStat(stats, comp, "scoring_player__tankKills", "tank_kills")
  addStat(stats, comp, "scoring_player__bikeKills", "bike_kills")
  addStat(stats, comp, "scoring_player__apcKills", "apc_kills")
  addStatValue(stats, comp.scoring_player__planeKills + comp.scoring_player__aiPlaneKills, "aircraft_kills")
  addStat(stats, comp, "scoring_player__soldierDeaths", "deaths")
  addStat(stats, comp, "scoring_player__squadDeaths", "squad_deaths")
  addStat(stats, comp, "scoring_player__assists", "assists")
  addStat(stats, comp, "squads__spawnCount", "friendly_fire_squad_spawns")
  addStat(stats, comp, "scoring_player__builtRallyPointUses", "engineer_rally_point_usage")
  addStat(stats, comp, "scoring_player__ownedMobileSpawnUses", "owned_mobile_spawn_usage")
  addStat(stats, comp, "scoring_player__killByThrowable", "kill_by_throwable")
  addStat(stats, comp, "scoring_player__builtAmmoBoxRefills", "engineer_ammo_box_usage")
  addStat(stats, comp, "scoring_player__apcSpot", "apc_spots")
  addStat(stats, comp, "scoring_player__tankSpot", "tank_spots")
  addStatValue(stats, abs(comp["scoring_player__friendlyFirePenalty"]), "friendly_fire_score")
  addStatValue(stats, getEngineerBuildingUsages(comp), "engineer_building_usage")
  addStatValue(stats, getBuildingDestroyed(comp), "fortification_destoyed")
  addStatValue(stats, comp["scoring_player__battleTime"].tointeger(), "battle_time")
  if (roundResult != null) {
    let isGameFinished = comp["scoring_player__isGameFinished"]
    let isVictory = isTeamWon(roundResult, comp.team)
    if (isZombieMode()) {
      if (isGameFinished){
        addStatValue(stats, 1, "zombie_batlles")
        if (isVictory)
          addStatValue(stats, 1, "zombie_victories")
      }
      else
        addStatValue(stats, 1, "zombie_early_quits")
    }
    else {
      if (isGameFinished) {
        addStatValue(stats, 1, "battles")
        addStatValue(stats, 1, isVictory ? "victories" : "defeats")
        if (comp.scoring_player__isBattleHero)
          addStatValue(stats, 1, isVictory ? "hero_wins" : "hero_loses")
        if (isGameWithDeveloper())
          addStatValue(stats, 1, "game_with_developers")
        if (isTokensEntity() && !isInGameMods()) {
          local tokensTotal = comp["player__objectiveTokens"]
          if (isVictory)
            tokensTotal += getTeamTokens()
          addStatValue(stats, tokensTotal, "halloween_battle_tokens")
        }
      } else {
        addStatValue(stats, 1, "early_quits")
        addStatValue(stats, 1, isVictory ? "victories_early_quit" : "defeats_early_quit")
        if (comp.scoring_player__isBattleHero)
          addStatValue(stats, 1, isVictory ? "hero_wins_deserted" : "hero_loses_deserted")
      }
    }
    stats.__update(getScorePlaceStats(roundResult, comp.team, comp["scoring_player__score"]))
    let {
      groupScore = comp.scoring_player__score,
      groupTime = comp.scoring_player__battleTime,
      groupScorePerMin = comp.scoring_player__score / max(comp.scoring_player__battleTime, 300.0) * 60.0
    } = getGroupStats(comp?.groupId)
    addStatValue(stats, groupScore, "battle_group_battle_score")
    addStatValue(stats, groupTime.tointeger(), "battle_group_battle_time")
    addStatValue(stats, groupScorePerMin.tointeger(), "battle_group_sum_score_per_minute")
  }
  addStat(stats, comp, "scoring_player__zombieWaves", "zombie_waves")
  addStat(stats, comp, "scoring_player__zombieDoorsScore", "zombie_doors_score")
  addStat(stats, comp, "scoring_player__zombieTotalScore", "zombie_score")
  addStat(stats, comp, "scoring_player__zombieKills", "zombie_kills")
  addStat(stats, comp, "scoring_player__zombieHeadshots", "zombie_headshots")
  addStat(stats, comp, "scoring_player__plantBomb", "plant_bomb")
  addStat(stats, comp, "scoring_player__defuseBomb", "defuse_bomb")

  if (comp.userstatsFilter != null)
    stats = stats.filter(@(_,stat) stat in comp.userstatsFilter)

  return stats
}

return {
  playerUserstatComps
  getPlayerCurrentUserstats
}