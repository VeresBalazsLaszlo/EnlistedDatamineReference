import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
from "math" import max

let { mkEventOnSpawnError } = require("%enlSqGlob/sqevents.nut")

let {TEAM_UNASSIGNED} = require("team")
let debug = with_prefix("[SPAWN]")
let {logerr} = require("dagor.debug")
let {sendNetEvent, CmdSpawnSquad, CmdSpawnEntityForPlayer, CmdHeroLogEvent} = require("dasevents")
let {get_sync_time} = require("net")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {spawnVehicleSquad, spawnSquad, calcBotCountInVehicleSquad} = require("%scripts/game/utils/squad_spawn.nut")
let {
  find_respawn_base_for_team_with_type, find_respawn_base_for_team_with_type_of_group, is_vehicle_spawn_allowed_by_limit,
  get_can_use_respawnbase_type, get_priority_spawn_group, mk_spawn_params_by_team_ex, validate_spawn_rotation,
  on_player_awaiting_vehicle_spawn, update_team_score, can_spawn_player_squads, can_spawn_team_squads
} = require("das.respawn")

let kamikazePenaltyQuery = ecs.SqQuery("kamikazePenaltyQuery", { comps_ro=[["squads__kamikazePenalty", ecs.TYPE_BOOL]]})
let teamAliveSpySquadsQuery = ecs.SqQuery("teamAliveSpySquadsQuery", { comps_rw=[["team__aliveSpySquads", ecs.TYPE_INT]]})

let kamikazePenaltyActive = @(playerEid) kamikazePenaltyQuery.perform(playerEid, @(_, comp) comp.squads__kamikazePenalty)

function initPlayerRespawner(comp) {
  comp["respawner__enabled"] = true
  comp["respawner__respToBot"] = false
  comp["respawner__isFirstSpawn"] = true
  comp["respawner__respEndTime"] = 300 + get_sync_time() 
  comp["respawner__canRespawnTime"] = 10 + get_sync_time() 
  comp["respawner__canRespawnWaitNumber"] = -1
}

function rejectSpawn(reason, team, playerEid, comp, needCooldown = true) {
  debug($"RejectSpawn: '{reason}' for team {team} and player {playerEid}")
  ecs.server_send_event(playerEid, mkEventOnSpawnError({reason=reason}), [ecs.obsolete_dbg_get_comp_val(playerEid, "connid", -1)])

  let time = get_sync_time()
  comp["respawner__enabled"] = true
  comp["respawner__respStartTime"] = needCooldown ? time : time - comp["respawner__respTime"]
  comp["respawner__respEndTime"] = needCooldown ? 300 + time : time 
  comp["respawner__canRespawnTime"] = needCooldown ? 10 + time : time 
  comp["respawner__canRespawnWaitNumber"] = -1
}

function onSuccessfulSpawn(comp, spawnCostTeamMult, spawnCostPersonal, hasVehicle, playerEid, squadId) {
  update_team_score(comp.team, comp.squads__spawnCount, spawnCostTeamMult, hasVehicle, playerEid, squadId)
  comp.respawner__spawnScore = comp.respawner__spawnScore - spawnCostPersonal
  comp["squads__spawnCount"]++
  comp["squads__squadsCanSpawn"] = can_spawn_player_squads(comp.team, comp["squads__spawnCount"])
  if (comp["scoring_player__firstSpawnTime"] <= 0.0)
    comp["scoring_player__firstSpawnTime"] = get_sync_time()
}

function spawnGroupError(template, team, eid, comp) {
  logerr($"'canUseRespawnbaseType' component is not set for /*{template}*/")
  rejectSpawn($"No respawn base for {template} by type", team, eid, comp)
  return false
}

function avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType, canUseRespawnbaseSubtypes = []) {
  let respawnGroupId = ctx.respawnGroupId
  let team = ctx.team
  if (respawnGroupId >= 0) {
    let groupId = find_respawn_base_for_team_with_type_of_group(team, canUseRespawnbaseType, canUseRespawnbaseSubtypes, respawnGroupId)
    return [groupId, mk_spawn_params_by_team_ex(team, groupId).getAll()]
  }
  else {
    let groupId = find_respawn_base_for_team_with_type(team, canUseRespawnbaseType, canUseRespawnbaseSubtypes)
    return [groupId, mk_spawn_params_by_team_ex(team, groupId).getAll()]
  }
}

let debugAllRespawnbasesQuery = ecs.SqQuery("debugAllRespawnbasesQuery", {
  comps_ro=[
    ["active", ecs.TYPE_BOOL],
    ["transform", ecs.TYPE_MATRIX],
    ["team", ecs.TYPE_INT],
    ["lastSpawnOnTime", ecs.TYPE_FLOAT],
    ["respawnbaseType", ecs.TYPE_STRING],
    ["respawnbaseSubtype", ecs.TYPE_STRING, ""],
    ["respTime", ecs.TYPE_INT, 0],
    ["maxVehicleOnSpawn", ecs.TYPE_INT, -1]
  ]
  comps_rq=["respbase"]
})

function debugDumpRespawnbases(ctx, canUseRespawnbaseType, canUseRespawnbaseSubtypes = []) {
  debugTableData(ctx)
  let subtypes = ", ".join(canUseRespawnbaseSubtypes)
  debug($"canUseRespawnbaseType = {canUseRespawnbaseType}, canUseRespawnbaseSubtypes = [{subtypes}]")

  debugAllRespawnbasesQuery(function(eid, comp) {
    debug($"eid = {eid}")
    debugTableData(comp)
  })
}

let botsOnlySpawnQuery = ecs.SqQuery("botsOnlySpawnQuery", {comps_rq=["noBotsMode"], comps_ro=[["respawnBaseGroup", ecs.TYPE_INT]]})
let checkIsBotOnlySpawn = @(group) botsOnlySpawnQuery.perform(@(_, comp) comp.respawnBaseGroup == group)

function trySpawnSquad(ctx, comp) {
  let eid                      = ctx.eid;
  let team                     = ctx.team;
  let squadId                  = ctx.squadId;
  let memberId                 = ctx.memberId;
  let botCount                 = ctx.botCount;
  let squadParams              = ctx.squadParams;
  let shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;

  let templateName = squadParams.squad[memberId].gametemplate
  let { canUseRespawnbaseType = null } = get_can_use_respawnbase_type(templateName)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(templateName, team, eid, comp)

  if (ctx.respawnGroupId < 0 || (!ctx.squadParams.isBot && checkIsBotOnlySpawn(ctx.respawnGroupId)))
    ctx.respawnGroupId = get_priority_spawn_group(canUseRespawnbaseType, team, ctx.squadParams.isBot)

  let [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType)
  squadParams.mkSpawnParamsCb <- cb
  if (baseEid == ecs.INVALID_ENTITY_ID) {
    if (ctx.respawnGroupId < 0)
      logerr($"Spawn squad playr {eid}, squad - {squadId}, memberId - {memberId}, team - {team}, canUseRespawnbaseType - {canUseRespawnbaseType}, is not possible. See log for more details.")
    else {
      debug($"Spawn squad [{squadId}, {memberId}] for team {team} for chosen group {ctx.respawnGroupId} is not possible.")
      sendNetEvent(eid, CmdHeroLogEvent({event="group_is_no_longer_active", text="respawn/group_is_no_longer_active", sound="", ttl=0}))
    }
    rejectSpawn("No respawn base for squad", team, eid, comp)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType)
    return false
  }

  debug($"Spawn squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid, comp)
    }
    return false
  }

  return true
}

function trySpawnVehicleSquad(ctx, comp) {
  let eid                      = ctx.eid;
  let team                     = ctx.team;
  let squadId                  = ctx.squadId;
  let memberId                 = ctx.memberId;
  let botCount                 = ctx.botCount;
  let vehicle                  = ctx.vehicle;
  let squadParams              = ctx.squadParams;
  let shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;
  let nextSpawnTimeBySquad     = ctx.nextSpawnTimeBySquad;

  let { canUseRespawnbaseType = null, canUseRespawnbaseSubtypes = [] } = get_can_use_respawnbase_type(vehicle)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(vehicle, team, eid, comp)

  if (ctx.respawnGroupId < 0)
    ctx.respawnGroupId = get_priority_spawn_group(canUseRespawnbaseType, team, ctx.squadParams.isBot)

  let [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType, canUseRespawnbaseSubtypes)
  ctx.canUseRespawnbaseType <- canUseRespawnbaseType
  squadParams.mkSpawnParamsCb <- cb
  let nextSpawnOnVehicleInTime = nextSpawnTimeBySquad?[squadId] ?? 0
  if (baseEid == ecs.INVALID_ENTITY_ID) {
    debug($"Spawn {vehicle} on base {baseEid} squad [{squadId}, {memberId}] for team {team} is not possible")
    rejectSpawn("No respawn base for vehicle", team, eid, comp)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType, canUseRespawnbaseSubtypes)
    return false
  }
  if (shouldValidateSpawnRules && (!is_vehicle_spawn_allowed_by_limit(team, canUseRespawnbaseType, eid) || nextSpawnOnVehicleInTime > get_sync_time())) {
    
    
    debug($"Spawn {vehicle} squad [{squadId}, {memberId}] for team {team} is forbidden by limit")
    rejectSpawn("The vehicle is not ready for this squad", team, eid, comp, false)
    let teamEid = get_team_eid(team) ?? ecs.INVALID_ENTITY_ID
    debugTableData(ecs.obsolete_dbg_get_comp_val(teamEid, "team__spawnPending")?.getAll() ?? {})
    return false
  }

  debug($"Spawn vehicle squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnVehicleSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid, comp)
    }
    return false
  }
  on_player_awaiting_vehicle_spawn(team, squadParams.playerEid, canUseRespawnbaseType)

  return true
}

let validateSpawnCost = @(score, cost) cost <= 0 || score >= cost

let noBotsModeQuery = ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})

let isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

let freeTankSpawnCheckQuery = ecs.SqQuery("freeTankSpawnCheckQuery", {comps_ro=[["respawnBaseGroup", ecs.TYPE_INT], ["team", ecs.TYPE_INT]], comps_rq=["freeTankRespawnTag"]})

function isFreeTankSpawn(spawnGroup, team) {
  local freeTankSpawn = false
  freeTankSpawnCheckQuery.perform(function(_, comp) {
    if (comp.respawnBaseGroup == spawnGroup && comp.team == team)
      freeTankSpawn = true
  })
  return freeTankSpawn
}

let freeTankSpawnAvailableQuery = ecs.SqQuery("freeTankSpawnAvailableQuery", {comps_ro=[["respawner__freeTankSpawnAvailable", ecs.TYPE_BOOL]]})

let isFreeTankSpawnAvailable = @(playerEid) freeTankSpawnAvailableQuery.perform(playerEid, @(_, comp) comp.respawner__freeTankSpawnAvailable)

let freeTankTemplateQuery = ecs.SqQuery("freeTankTemplateQuery", {comps_ro=[["team__id", ecs.TYPE_INT], ["team__freeTankTemplate", ecs.TYPE_STRING]]})

function getFreeTankTemplate(team){
  local templ = ""
  freeTankTemplateQuery.perform(function(_, comps){
    if (comps.team__id == team)
      templ = comps.team__freeTankTemplate
  })
  return templ
}

function spawnSquadImpl(eid, comp, team, squadId, squadRoute, memberId, respawnGroupId, existedVehicleEid, withoutVehicle) {
  if (team == TEAM_UNASSIGNED) {
    debug($"Cannot create player possessed entity for team {team}")
    return
  }

  let teamEid = get_team_eid(team) ?? ecs.INVALID_ENTITY_ID
  debug($"Spaw team {team} squad")

  if (teamEid == ecs.INVALID_ENTITY_ID) {
    logerr($"Cannot create player possessed entity for team /*{team}*/ because of teamEid is invalid")
    return
  }

  let squadParams = {
    squadId    = squadId
    squadRoute = squadRoute
    memberId   = memberId
    team       = team
  }

  if (comp.armiesReceivedTime < 0.0 || (comp.armiesReceivedTime > 0 && comp.armiesReceivedTeam != team)) {
    debug($"Armies is not received yet for player {eid}, team {team}")
    comp.delayedSpawnSquad.append(squadParams)
    return
  }

  let playerSpawnCount = comp["squads__spawnCount"]

  if (!can_spawn_team_squads(team, playerSpawnCount)) {
    debug($"Squad spawn is disabled by mission for team {team}")
    return
  }

  if (comp.isFirstSpawn) {
    debug($"The first spawn. Initialize respawner.")
    comp.isFirstSpawn = false
    initPlayerRespawner(comp)
    return
  }

  local squadInfo = comp.armies?[comp.army].squads[squadId]
  if (squadInfo == null) {
    debug($"Squad {squadId} not found. Fallback to 0 squad.")
    squadId = 0
    squadParams.squadId = 0
    squadInfo = comp.armies?[comp.army].squads[0]
  }

  let squadType = squadInfo?.squadType ?? ""
  let isSpySquad = squadType == "saboteur"
  if (isSpySquad) {
    let aliveSpySquads = ecs.obsolete_dbg_get_comp_val(teamEid, "team__aliveSpySquads", 0)
    let maxSpySquads = ecs.obsolete_dbg_get_comp_val(teamEid, "team__maxSpySquads", -1)
    if (maxSpySquads >= 0 && aliveSpySquads >= maxSpySquads) {
      rejectSpawn($"Spawn squad {squadId} is not allowed: spy squad limit reached ({aliveSpySquads}/{maxSpySquads})", team, eid, comp, false)
      return
    }
  }

  local vehicle = withoutVehicle && (squadInfo?.spawnWithoutVehicleAvailable ?? false) ?
    null : squadInfo?.curVehicle.gametemplate
  let vehicleComps = squadInfo?.curVehicle?.comps?.getAll() ?? {}
  local squad = squadInfo?.squad.getAll() ?? []
  let squadProfileId = squadInfo?.squadId
  let squadMaxLen = squad.len()
  local botCount = isNoBotsMode() ? 0 : max(0, squadMaxLen - 1)

  if (vehicle != null) { 
    botCount = calcBotCountInVehicleSquad(vehicle, squadMaxLen)
    if (ecs.g_entity_mgr.getTemplateDB().getTemplateByName(vehicle)?.getCompValNullable("airplane") != null && kamikazePenaltyActive(eid)){
      rejectSpawn($"Spawn squad {squadId} is not allowed because of kamikaze penalty", team, eid, comp)
      return
    }
    else if (isFreeTankSpawn(respawnGroupId, team)){
      if (isFreeTankSpawnAvailable(eid)){
        let freeTankTempl = getFreeTankTemplate(team)
        if (freeTankTempl == "")
          rejectSpawn($"Spawn squad {squadId} is not allowed becuase free tank template is empty", team, eid, comp)
        else {
          vehicle = freeTankTempl
          botCount = calcBotCountInVehicleSquad(vehicle, squadMaxLen)
        }
      }
      else {
        rejectSpawn($"Spawn squad {squadId} is not allowed on free tank for {eid} player", team, eid, comp)
        return
      }
    }
  }

  comp["squads__botCount"] = botCount

  
  
  if (botCount == 0 && squad?[memberId] != null) {
    
    squad = [squad[memberId]]
    memberId = 0
    squadParams.memberId = 0
  }
  else
    squad = squad.slice(0, botCount + 1)

  let member = squad?[memberId]
  if (member == null) {
    debug($"Squad member {memberId} not found. Fallback to 0 squad member.")
    memberId = 0
    squadParams.memberId = memberId
  }

  squadParams.__update({
    playerEid = eid
    existedVehicleEid = existedVehicleEid
    isBot     = comp.playerIsBot != null
    squad     = squad
    vehicle   = vehicle
    vehicleComps = vehicleComps
    squadProfileId = squadProfileId
    disableSquadRotation = squadInfo?.disableSquadRotation
  })

  let spawnCtx = {
    eid                      = eid
    team                     = team
    squadId                  = squadId
    memberId                 = memberId
    botCount                 = botCount
    squadParams              = squadParams
    shouldValidateSpawnRules = comp.shouldValidateSpawnRules
    respawnGroupId           = respawnGroupId
  }

  let soldierId = squad?[memberId]?.id ?? -1
  let spawnCostPersonalScore = comp.respawner__scorePricePerSquad?[squadId] ?? 0
  let personalScore = comp.respawner__spawnScore

  if (comp.shouldValidateSpawnRules) {
    if (!validate_spawn_rotation(eid, squadId, soldierId)) {
      rejectSpawn($"Spawn squad {squadId} member {soldierId} is not allowed by spawn rotation rules", team, eid, comp)
      return
    } else if (!validateSpawnCost(personalScore, spawnCostPersonalScore)) {
      rejectSpawn($"Spawn squad {squadId} member {soldierId} is not allowed by score: cost {spawnCostPersonalScore} / score {personalScore}", team, eid, comp)
      return
    }
  }

  local spawned = false
  if (vehicle) {
    spawnCtx.__update({
      vehicle
      nextSpawnTimeBySquad = comp.respawner__nextSpawnOnVehicleTimeBySquad
    })
    if (trySpawnVehicleSquad(spawnCtx, comp)) {
      onSuccessfulSpawn(comp, squadInfo?.spawnCostTeamScoreMult, spawnCostPersonalScore, true, eid, squadId)
      spawned = true
    }
  }
  else if (trySpawnSquad(spawnCtx, comp)) {
    onSuccessfulSpawn(comp, squadInfo?.spawnCostTeamScoreMult, spawnCostPersonalScore, false, eid, squadId)
    spawned = true
  }

  if (spawned && isSpySquad) {
    teamAliveSpySquadsQuery(teamEid, @(_, teamComp) teamComp.team__aliveSpySquads++)
  }
}

let comps = {
  comps_rw = [
    ["isFirstSpawn", ecs.TYPE_BOOL],
    ["squads__botCount", ecs.TYPE_INT],
    ["squads__spawnCount", ecs.TYPE_INT],
    ["squads__squadsCanSpawn", ecs.TYPE_BOOL],
    ["delayedSpawnSquad", ecs.TYPE_ARRAY],
    ["respawner__nextSpawnOnVehicleTimeBySquad", ecs.TYPE_INT_LIST],
    ["respawner__respToBot", ecs.TYPE_BOOL],
    ["respawner__isFirstSpawn", ecs.TYPE_BOOL],
    ["respawner__respStartTime", ecs.TYPE_FLOAT],
    ["respawner__respEndTime", ecs.TYPE_FLOAT],
    ["respawner__canRespawnTime", ecs.TYPE_FLOAT],
    ["respawner__canRespawnWaitNumber", ecs.TYPE_INT],
    ["respawner__enabled", ecs.TYPE_BOOL],
    ["respawner__spawnScore", ecs.TYPE_INT],
  ]

  comps_ro = [
    ["team", ecs.TYPE_INT],
    ["armiesReceivedTime", ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ecs.TYPE_INT],
    ["armies" ecs.TYPE_OBJECT],
    ["army", ecs.TYPE_STRING],
    ["scoring_player__firstSpawnTime", ecs.TYPE_FLOAT],
    ["shouldValidateSpawnRules", ecs.TYPE_BOOL],
    ["playerIsBot", ecs.TYPE_TAG, null],
    ["respawner__scorePricePerSquad", ecs.TYPE_INT_LIST, null],
    ["respawner__respTime", ecs.TYPE_FLOAT, 10.0],
  ]
}

ecs.register_es("spawn_squad_es", {
  [CmdSpawnSquad] = @(evt, eid, comp) spawnSquadImpl(eid, comp, evt.team, evt.squadId, evt.squadRoute, evt.memberId, evt.respawnGroupId, evt.existedVehicleEid, evt.withoutVehicle),
  [CmdSpawnEntityForPlayer] = function(evt, eid, comp) {
    if (comp.isFirstSpawn)
      spawnSquadImpl(eid, comp, evt.team, 0, 0, 0, -1, ecs.INVALID_ENTITY_ID, false )
  }
}, comps)
