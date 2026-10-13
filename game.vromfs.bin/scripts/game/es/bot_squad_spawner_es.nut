import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let { logerr } = require("dagor.debug")
let {TEAM_UNASSIGNED} = require("team")
let { loadJson } = require("%sqstd/json.nut")
let {floor, clamp, min} = require("math")
let {INVALID_CONNECTION_ID, get_sync_time} = require("net")
let Rand = require("%sqstd/rand.nut")
let {generatedNames, botSuffix} = require("%scripts/game/utils/generated_names.nut")
let pickword = require("%sqstd/random_pick.nut")
let {date} = require("datetime")
let {INVALID_USER_ID} = require("matching.errors")
let {CmdSpawnSquad, EventTeamMemberJoined, EventAutoRoutesRequestSquads, EventAutoRoutesResponseSquads} = require("dasevents")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let { applyModsToArmies } = require("%scripts/game/utils/profile_init.nut")
let logBS = with_prefix("[BOT_SPAWNER] ")
let { get_matching_invite_data } = require("app")

let { getBotsProfile, possibleBotsArmies } = require("%enlSqGlob/data/bots_profile.nut")
let customProfile = {armies = null}
let customWaveSpawnProfile = {armies = null}

local usedNames = {}

function genName(seed) {
  const allow_cache = true
  local name
  do {
    name = $"{pickword(generatedNames, seed++, allow_cache)}{botSuffix}"
  } while (name in usedNames)
  usedNames[name] <- true
  return name
}

let availableTeamsQuery = ecs.SqQuery("availableTeamsQuery", {
  comps_ro=[
    ["team__id", ecs.TYPE_INT],
    ["team__maxBotsToSpawn", ecs.TYPE_INT, -1],
    ["team__autoRouteBotSquads", ecs.TYPE_ARRAY, []],
    ["team__autoRouteBotSquadsMode", ecs.TYPE_STRING, ""]
  ]
  comps_rw=[
    ["team__autoRouteBotSquadLast", ecs.TYPE_INT, -1]
  ]
})

let playerQuery = ecs.SqQuery("playerQuery", {
  comps_ro=[
    ["team", ecs.TYPE_INT],
    ["disconnected", ecs.TYPE_BOOL],
    ["disconnectedAtTime", ecs.TYPE_FLOAT],
    ["possessed", ecs.TYPE_EID]
  ],
  comps_rq=["countAsAlive", "player"]
  comps_no=["waveSpawnBot"]
})

let havePlayersQuery = ecs.SqQuery("havePlayersQuery", {
  comps_ro=[["possessed", ecs.TYPE_EID]],
  comps_rq=["countAsAlive", "player"]
})
let botPlayerQuery = ecs.SqQuery("botPlayerQuery", {comps_ro=[["team", ecs.TYPE_INT]], comps_rq=["countAsAlive", "player", "playerIsBot"], comps_no=["waveSpawnBot"]})

let allowToSpawnVehiclesQuery = ecs.SqQuery("allowToSpawnVehiclesQuery", {comps_rq=["botInitialVehicleSpawnEnabled"]})

let doHavePlayers = @() havePlayersQuery.perform( @(_eid, comp) comp.possessed ? true : null) 

let areVehiclesAllowedToSpawn = @() allowToSpawnVehiclesQuery.perform(@(_eid, _comp) true) == true

let isVehicleSquad = @(squad) squad?.vehicleType != null && squad?.vehicleType != ""

let paratroopersBotSpawnQuery = ecs.SqQuery("paratroopersBotSpawnQuery", {comps_ro=[["paratroopers_bots_mode__team", ecs.TYPE_INT]]})
let spawnParatroopersBot = @(team) paratroopersBotSpawnQuery.perform(@(_eid, comp) comp.paratroopers_bots_mode__team == team)


enum SquadPriority {
  FORBIDDEN
  NORMAL
  FORCED
}

function getSquadPriority(squad, team, comp) {
  if (!isVehicleSquad(squad))
    return SquadPriority.NORMAL
  if (!areVehiclesAllowedToSpawn())
    return SquadPriority.FORBIDDEN
  return (comp.numBotVehicleSquadsSpawned?[$"{team}"] ?? 0) == 0 ? SquadPriority.FORCED : SquadPriority.FORBIDDEN
}

function getBotArmyForTeam(team, wave_bots = false) {
  let teamEid = get_team_eid(team)
  let teamArmies = ecs.obsolete_dbg_get_comp_val(teamEid, "team__armies")?.getAll() ?? []
  let teamSpawnBotArmy = ecs.obsolete_dbg_get_comp_val(teamEid, "team__spawnBotArmy")
  let profile = (wave_bots && customWaveSpawnProfile?.armies != null) ? customWaveSpawnProfile : customProfile
  let useCustomProfile = profile.armies != null

  logBS($"Use custom profile: {useCustomProfile}")
  let armiesIds = profile.armies ?? possibleBotsArmies
  local armyId = [teamSpawnBotArmy].findvalue(@(a) a in armiesIds)
  if (armyId == null) {
    logBS($"Could not find army team__spawnBotArmy={teamSpawnBotArmy} in the profile. Falling back to team__armies.")
    armyId = teamArmies.findvalue(@(a) a in armiesIds)
  }

  if (armyId == null)
    return { army = null, armyId = null, armies = null, teamArmies }
  let armies = profile.armies ?? applyModsToArmies({[armyId] = getBotsProfile(armyId)})
  let army = armies[armyId]
  return { army, armyId, armies, teamArmies }
}

function getAutoRouteSquad(team, rand) {
  local autoRouteIdx = -1
  local autoRouteSquadId = ""
  availableTeamsQuery(function(_eid, teamComp) {
    let teamId = teamComp["team__id"]
    if (team != teamId)
      return
    let routeSquads = teamComp?["team__autoRouteBotSquads"] ?? []
    if (routeSquads.len() > 0) {
      let routeMode = teamComp?["team__autoRouteBotSquadsMode"] ?? ""
      let routeLast = teamComp?["team__autoRouteBotSquadLast"] ?? -1

      if (routeMode == "")
        autoRouteIdx = routeLast + 1
      else if (routeMode == "once")
        autoRouteIdx = routeLast + 1
      else if (routeMode == "repeat")
        autoRouteIdx = (routeLast + 1) % routeSquads.len()
      else if (routeMode == "random") {
        autoRouteIdx = rand.rint(0, routeSquads.len() - 1)
        if (autoRouteIdx == routeLast)
          autoRouteIdx = (routeLast + 1) % routeSquads.len()
      }

      if (autoRouteIdx < 0 || autoRouteIdx >= routeSquads.len())
        autoRouteIdx = -1
      else {
        autoRouteSquadId = routeSquads[autoRouteIdx]?.squadId
        teamComp["team__autoRouteBotSquadLast"] = autoRouteIdx
      }
    }
  })
  return { autoRouteIdx, autoRouteSquadId }
}



function onTimer(_evt, _eid, comp) {
  
  if (comp.numBotSquadsSpawned < 1
      && !doHavePlayers() && !comp.bot_spawner__allowSpawnBeforePlayer) {
    return
  }

  let playersByTeam = {}
  let numTeams = get_matching_invite_data()?.mode_info.numTeams ?? -1

  availableTeamsQuery(function(eid, teamComp) {
    let teamId = teamComp["team__id"]
    let teamMaxBotsToSpawn = teamComp?["team__maxBotsToSpawn"] ?? -1
    if (teamMaxBotsToSpawn == 0 || (numTeams == 1 && teamId == 2 && teamMaxBotsToSpawn < 0))
      return

    let routeSquads = teamComp?["team__autoRouteBotSquads"] ?? []
    if (routeSquads.len() > 0) {
      let routeMode = teamComp?["team__autoRouteBotSquadsMode"] ?? ""
      let routeLast = teamComp?["team__autoRouteBotSquadLast"] ?? -1
      if (routeMode == "" && routeLast == routeSquads.len() - 1)
        return 
    }

    playersByTeam[teamId] <- { eid = eid, botsCount = 0, totalCount = 0, maxBots = teamMaxBotsToSpawn }
  })

  botPlayerQuery(function(_eid, botComp) {
    if (playersByTeam?[botComp.team] != null)
      playersByTeam[botComp.team].botsCount++
  })

  playerQuery(function(_eid, plrComp) {
    if (playersByTeam?[plrComp.team] != null && (!plrComp.disconnected || plrComp.disconnectedAtTime <= 0 || get_sync_time() - plrComp.disconnectedAtTime <= 60.0))
      playersByTeam[plrComp.team].totalCount++
  })

  local addPlayerToTeam = TEAM_UNASSIGNED

  let maxPlayersCountPerTeam = floor(comp.targetPopulation / 2).tointeger()
  local minTeamPlayersCount = -1
  foreach (teamId, team in playersByTeam) {
    local needBots = clamp(team.botsCount + maxPlayersCountPerTeam - team.totalCount, 0, maxPlayersCountPerTeam)
    if (team.maxBots >= 0)
      needBots = min(needBots, team.maxBots)

    if (team.botsCount < needBots) {
      if (minTeamPlayersCount < 0 || team.totalCount < minTeamPlayersCount) {
        minTeamPlayersCount = team.totalCount
        addPlayerToTeam = teamId
      }
    }

    let shouldReduceBotsCount = team.botsCount > 0 && team.botsCount > needBots
    ecs.obsolete_dbg_set_comp_val(team.eid, "team__shouldReduceBotsCount", shouldReduceBotsCount)
  }

  if (addPlayerToTeam == TEAM_UNASSIGNED)
    return

  let team = addPlayerToTeam

  let time = date()
  let rand = Rand(time.min * 60 + time.sec)

  let botArmy = getBotArmyForTeam(team)
  if (botArmy.armyId == null) {
    logerr($"[BOT_SPAWNER] Unable to spawn bots because of not found army in botArmies. team armies: /*{", ".join(botArmy.teamArmies)}*/")
    return
  }
  let army = botArmy.army

  let squadsCount = army.squads.len()
  let forcedSquadIds = []
  let allowedSquadIds = []

  local squadRouteIdx = -1
  let { autoRouteIdx, autoRouteSquadId } = getAutoRouteSquad(team, rand)
  if (autoRouteSquadId != "") {
    logBS($"Auto route squad: team={team} routeIdx={autoRouteIdx} squadId={autoRouteSquadId}")
    for (local squadId = 0; squadId < squadsCount; ++squadId) {
      let squad = army.squads[squadId]
      if (squad?.squadId == autoRouteSquadId || autoRouteSquadId == "random")
        forcedSquadIds.append(squadId)
      else if (!isVehicleSquad(squad))
        allowedSquadIds.append(squadId)
    }
    if (forcedSquadIds.len() > 0)
    squadRouteIdx = autoRouteIdx
    else
      logerr($"[BOT SPAWNER] Auto route squad not found in bot army: squadId={autoRouteSquadId}")
  }

  if (forcedSquadIds.len() == 0) {
    for (local squadId = 0; squadId < squadsCount; ++squadId) {
      let priority = getSquadPriority(army.squads[squadId], team, comp)
      if (priority == SquadPriority.NORMAL)
        allowedSquadIds.append(squadId)
      else if (priority == SquadPriority.FORCED)
        forcedSquadIds.append(squadId)
    }
  }
  if (forcedSquadIds.len() == 0 && allowedSquadIds.len() == 0) {
    for (local squadId = 0; squadId < squadsCount; ++squadId)
      allowedSquadIds.append(squadId)
  }
  logBS($"Spawn bot for team {team} army {botArmy.armyId}. (team armies = [{", ".join(botArmy.teamArmies)}], squadsCount = {squadsCount})")

  
  let playerComps = {
    "connid" : [INVALID_CONNECTION_ID, ecs.TYPE_INT],
    "canBeLocal" : [false, ecs.TYPE_BOOL],
    "userid" : [INVALID_USER_ID, ecs.TYPE_UINT64],
    "isFirstSpawn" : [false, ecs.TYPE_BOOL],
    "army" : botArmy.armyId,
    "armies" : botArmy.armies,
    "isArmiesReceived" : [true, ecs.TYPE_BOOL],
    "armiesReceivedTime" : get_sync_time(),
    "team": [team, ecs.TYPE_INT]
    "armiesReceivedTeam": [team, ecs.TYPE_INT],
    "squads__count": [squadsCount, ecs.TYPE_INT],
    "shouldValidateSpawnRules" : [false, ecs.TYPE_BOOL],
  }

  local squadId = -1
  if (forcedSquadIds.len() != 0)
    squadId = forcedSquadIds[rand.rint(0, forcedSquadIds.len() - 1)]
  else
    squadId = allowedSquadIds[rand.rint(0, allowedSquadIds.len() - 1)]

  if (isVehicleSquad(army.squads[squadId])) {
    let prevValue = comp.numBotVehicleSquadsSpawned?[$"{team}"] ?? 0
    comp.numBotVehicleSquadsSpawned[$"{team}"] = prevValue + 1
  }

  ecs.g_entity_mgr.createEntity("enlisted_bot_player", playerComps,
      function(plr_eid) {
        ecs.obsolete_dbg_set_comp_val(plr_eid, "name", genName(plr_eid + time.sec + time.min * 60))
        ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=plr_eid, team=team}));
        if (!spawnParatroopersBot(team))
          ecs.g_entity_mgr.sendEvent(plr_eid,
          CmdSpawnSquad({
            team
            squadId
            squadRoute = (squadRouteIdx >= 0) ? (1 + squadRouteIdx) : 0
            possessed = ecs.INVALID_ENTITY_ID
            memberId = 0
            respawnGroupId = -1
          })
          )
        else
          ecs.obsolete_dbg_set_comp_val(plr_eid, "respawner__enabled", true)
      })

  comp.numBotSquadsSpawned++
}

ecs.register_es(
  "bot_squad_spawner_es",
  {
    onInit = function(_evt, spawn_eid, comp) {


      ecs.clear_timer({eid=spawn_eid, id="bot_squad_spawner"})
      ecs.set_timer({eid=spawn_eid, id="bot_squad_spawner", interval=comp.spawnPeriod, repeat=true})
    },
    Timer = onTimer
  },
  {
    comps_rw = [
      ["numBotSquadsSpawned", ecs.TYPE_INT],
      ["numBotVehicleSquadsSpawned", ecs.TYPE_OBJECT]
    ],
    comps_ro = [
      ["targetPopulation", ecs.TYPE_INT],
      ["spawnPeriod", ecs.TYPE_FLOAT],
      ["bot_spawner__allowSpawnBeforePlayer", ecs.TYPE_BOOL, false]
    ]
  },
  {tags="server"}
)

ecs.register_es(
  "wave_spawn_bot_squad_spawner_es",
  {
    onInit = function(_, _, comp) {
      let botArmy = getBotArmyForTeam(comp.team, true)
      let time = date()
      let team = comp.team
      for (local i = 0; i < comp.wave_bot_spawner__botsCount; ++i){
        let playerComps = {
          "connid" : [INVALID_CONNECTION_ID, ecs.TYPE_INT],
          "canBeLocal" : [false, ecs.TYPE_BOOL],
          "userid" : [INVALID_USER_ID, ecs.TYPE_UINT64],
          "isFirstSpawn" : [false, ecs.TYPE_BOOL],
          "army" : botArmy.armyId,
          "armies" : botArmy.armies,
          "isArmiesReceived" : [true, ecs.TYPE_BOOL],
          "armiesReceivedTime" : get_sync_time(),
          "team": [comp.team, ecs.TYPE_INT]
          "armiesReceivedTeam": [comp.team, ecs.TYPE_INT],
          "squads__count": [botArmy.army.squads.len(), ecs.TYPE_INT],
          "shouldValidateSpawnRules" : [false, ecs.TYPE_BOOL],
        }

        ecs.g_entity_mgr.createEntity("wave_spawn_bot_player", playerComps,
          function(plr_eid) {
            ecs.obsolete_dbg_set_comp_val(plr_eid, "name", genName(plr_eid + time.sec + time.min * 60 + i))
            ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=plr_eid, team=team}))
            ecs.obsolete_dbg_set_comp_val(plr_eid, "respawner__enabled", true)
        })
      }
      comp.wave_bot_spawner__botsCount = 0
    }
  },
  {
    comps_ro = [["team", ecs.TYPE_INT]]
    comps_rw = [["wave_bot_spawner__botsCount", ecs.TYPE_INT]]
  },
  {tags="server"}
)

ecs.register_es(
  "wave_spawn_bots_custom_profile_init",
  {
    onInit = function(_eid, comp) {
      let path = comp["customWaveSpawnBotProfile"]
      let profile = loadJson(path)
      logBS($"Loaded wave spawn bots profile: {path}, armies: {profile?.keys()}")
      customWaveSpawnProfile.armies <- applyModsToArmies(profile)
    }
  },
  { comps_ro = [["customWaveSpawnBotProfile", ecs.TYPE_STRING]] },
  {tags="server"}
)


ecs.register_es(
  "bots_custom_profile_init",
  {
    onInit = function(_eid, comp) {
      let path = comp["customBotProfile"]
      let profile = loadJson(path)
      logBS($"Loaded bots profile: {path}, armies: {profile?.keys()}")
      customProfile.armies <- applyModsToArmies(profile)
    }
  },
  { comps_ro = [["customBotProfile", ecs.TYPE_STRING]] },
  {tags="server"}
)

ecs.register_es(
  "on_request_auto_routes_team_armies_squads",
  {
    [EventAutoRoutesRequestSquads] = function(evt, _eid, _comp) {
      local ids = ""
      let botArmy = getBotArmyForTeam(evt.team)
      if (botArmy.armyId != null) {
        let army = botArmy.army
        let squadsCount = army.squads.len()
        for (local squadIdx = 0; squadIdx < squadsCount; ++squadIdx) {
          let squad = army.squads[squadIdx]
          if (!isVehicleSquad(squad)) {
            let squadTextId = squad?.squadId ?? ""
            if (squadTextId != "") {
              if (ids != "")
                ids = $"{ids},{squadTextId}"
              else
                ids = squadTextId
            }
          }
        }
      }
      ecs.g_entity_mgr.broadcastEvent(EventAutoRoutesResponseSquads({team=evt.team, squadsIds=ids}));
    }
  }
)

ecs.register_es("rename_incognito_es",
  {
    function onChange(eid, comp) {
      if (comp?.fakeName ?? false) {
        comp.name = genName(eid)
        comp.fakeName = false
      }
    }
  },
  {
    comps_rw = [
      ["name", ecs.TYPE_STRING],
      ["fakeName", ecs.TYPE_BOOL],
    ],
    comps_rq = ["player"],
    comps_track = [["fakeName", ecs.TYPE_BOOL]],
    comps_no = ["playerIsBot"]
  },
  { tags = "server" })
