import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/hud/state/vehiclesData.nut" as vehiclesData
import "%ui/hud/state/armyData.nut" as armyData
import "%ui/hud/state/soldiersData.nut" as soldiersData
import "%ui/hud/state/vehicleRespawnBases.nut" as vehicleRespawnBases
import "%ui/hud/state/humanCanRespawn.nut" as humanCanRespawn
import "net" as app
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%enlSqGlob/sqevents.nut" import EventOnSpawnError
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "dasevents" import sendNetEvent, CmdRequestRespawn, CmdCancelRequestRespawn,
  RequestNextRespawnEntity, EventZoneCaptured, EventZoneIsAboutToBeCaptured
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid
from "%ui/hud/state/teams.nut" import canSpawnSpySquad
from "das.respawn" import get_can_use_respawnbase_type
from "%ui/hud/state/spawn_zones_markers.nut" import spawnZonesState, isFreeTankSpawnsAvailable
from "%ui/hud/state/gun_game_state.nut" import isGunGameMode
from "%ui/ui_library.nut" import *
from "gameevents" import EventLevelLoaded
from "%sqstd/frp.nut" import subscribeAndInit, subscribeList
from "types" import Function









let logHR = with_prefix("[HERO_RESPAWN]")

let respEndTime = mkWatched(persist, "respEndTime", -1)
let canRespawnTime = mkWatched(persist, "canRespawnTime", -1)
let canRespawnWaitNumber = mkWatched(persist, "canRespawnWaitNumber", -1)
let respawnerEid = mkWatched(persist, "respawnerEid", ecs.INVALID_ENTITY_ID)
let canChangeRespawnParams = Computed(@() respEndTime.get() > 0 || canRespawnTime.get() > 0 || canRespawnWaitNumber.get() > 0)

let spawnedSquadsStorage = mkOnlineSaveData("spawnedSquads")
let setSpawnedSquads = spawnedSquadsStorage.setValue
let curSpawnedSquads = spawnedSquadsStorage.watch
console_register_command(@() setSpawnedSquads(null), "ui.resetSpawnedSquads")



let mkSticky = @(src, defVal) Computed(function(prev) {
  let v = src.get()
  return v ?? (prev != FRP_INITIAL ? prev : defVal)
})

let squadsCanSpawnSrc = mkEcsComputed({
  comps = [["squads__squadsCanSpawn", ecs.TYPE_BOOL]]
  comps_rq = ["localPlayer"]
})
let squadsCanSpawn = mkSticky(squadsCanSpawnSrc, true)
let respawnsInBot = mkWatched(persist, "respawnsInBot", false)
let respawnLastActiveTime = mkWatched(persist, "respawnLastActiveTime", -1)
let respawnInactiveTimeout = mkWatched(persist, "respawnInactiveTimeout", -1)
let curSoldierIdx = mkWatched(persist, "curSoldierIdx", 0)
let squadIndexForSpawn = Watched(-1)
let selectedRespawnGroupId = Watched({})

let queuedRespawnGroupId = Watched(-1)
let queueRespawnGroupId = Watched(-1)

let vehicleInfo = Computed(function() {
  let { guid = null, skin = null } = armyData.get()?.squads[squadIndexForSpawn.get()].curVehicle
  let vehicle = vehiclesData.get()?[guid]
  if (vehicle == null)
    return null

  let override = skin == null ? {} : { skin }
  return vehicle.__merge(override)
})

let squadMemberIdForSpawn = mkWatched(persist, "squadMemberIdForSpawn", 0)
let squadsRevivePointsSrc = mkEcsComputed({
  comps = [["squads__revivePointsList", ecs.TYPE_INT_LIST]]
  comps_rq = ["localPlayer"]
})
let squadsRevivePoints = mkSticky(squadsRevivePointsSrc, [])
let squadsAffordability = mkEcsComputed({
  comps = [["squads__affordabilityList", ecs.TYPE_BOOL_LIST]]
  comps_rq = ["localPlayer"]
  defVal = []
})
let squadsScorePrice = mkEcsComputed({
  comps = [["respawner__scorePricePerSquad", ecs.TYPE_INT_LIST]]
  comps_rq = ["localPlayer"]
  defVal = []
})
let soldierRevivePoints = mkEcsComputed({
  comps = [["soldier_revive_points__points", ecs.TYPE_ARRAY]]
  comps_filter = [["is_local", ecs.TYPE_BOOL]] 
  filter = "is_local"
  defVal = []
})
let isSpectatorEnabled = mkWatched(persist, "isSpectatorEnabled", false)
let maxSpawnVehiclesOnPointBySquad = mkWatched(persist, "maxSpawnVehiclesOnPointBySquad", [])
let curLimitVehiclesOnPointBySquad = mkWatched(persist, "curLimitVehiclesOnPointBySquad", [])
let squadsRespawnTypes = Computed(@() (armyData.get()?.squads ?? []).map(@(squad) get_can_use_respawnbase_type(squad?.curVehicle?.gametemplate ?? "")?.canUseRespawnbaseType ?? ""))
let nextSpawnOnVehicleInTimeBySquad = mkWatched(persist, "nextSpawnOnVehicleInTimeBySquad", [])
let spawnSquadId = mkWatched(persist, "spawnSquadId")
let spawnCount = mkEcsComputed({
  comps = [["squads__spawnCount", ecs.TYPE_INT]]
  comps_rq = ["localPlayer"]
  defVal = 0
})
let isFirstSpawn = mkWatched(persist, "isFirstSpawn", false)


let respRequested = mkWatched(persist, "respRequested", false)

let kamikazePenaltyActive = mkEcsComputed({
  comps = [["squads__kamikazePenalty", ecs.TYPE_BOOL]]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = false
})
let fuelLoadPct = mkWatched(persist, "fuelLoadPct", 100)
let needSpawnMenu = Computed(@() (respawnsInBot.get() || squadsCanSpawn.get())
  && canChangeRespawnParams.get() && !isGunGameMode.get())
let mobileRespawnOwners = mkEcsComputedEidMap({
  comps = [["ownedByPlayer", ecs.TYPE_EID], ["isAlive", ecs.TYPE_BOOL]]
  comps_rq = ["mobileRespawnTag"]
})

let localPlayerHasActiveApc = Computed(@() mobileRespawnOwners.get()
  .findvalue(@(row) row.isAlive && row.ownedByPlayer == localPlayerEid.get()) != null)
let showSquadSpawn = Computed(@() needSpawnMenu.get() && !respawnsInBot.get())
let timeToCanRespawn = mkCountdownTimerPerSec(canRespawnTime)
let isSquadAvailableByTime = Watched([])
let canSpawnOnVehicleBySquad = Computed(@() curLimitVehiclesOnPointBySquad.get().map(@(maxVehicles, k) maxVehicles > 0 && (isSquadAvailableByTime.get()?[k] ?? true)))
let spawnScoreActual = mkEcsComputed({
  comps = [["respawner__spawnScore", ecs.TYPE_INT]]
  comps_rq = ["localPlayer"]
  defVal = 0
})
let spawnScore = Computed(@() needSpawnMenu.get() ? spawnScoreActual.get() : 0) 

let DB = ecs.g_entity_mgr.getTemplateDB()

let spawnWithoutVehicleAvailable = Computed(@() armyData.get()?.squads[squadIndexForSpawn.get()]?.spawnWithoutVehicleAvailable ?? false)
let spawnWithVehicleRequested = Watched(true)

ecs.register_es("reset_without_vehicle_spawn", {
  [["onInit"]] = @() spawnWithVehicleRequested.set(true)
},
{
  comps_rq = ["hero"]
})

let freeTankSpawnCheckQuery = ecs.SqQuery("freeTankSpawnCheckQuery", {comps_ro=[["respawnBaseGroup", ecs.TYPE_INT], ["team", ecs.TYPE_INT]], comps_rq=["freeTankRespawnTag"]})

function isFreeTankSpawn(spawnGroup) {
  local freeTankSpawn = false
  freeTankSpawnCheckQuery.perform(function(_, comp) {
    if (comp.respawnBaseGroup == spawnGroup && comp.team == localPlayerTeam.get())
      freeTankSpawn = true
  })
  return freeTankSpawn
}



let teamFreeTanks = mkEcsComputedEidMap({
  comps = [
    ["team__freeTankTemplate", ecs.TYPE_STRING],
    ["team__id", ecs.TYPE_INT],
  ]
})

let localTeamFreeTankTemplate = Computed(function() {
  let team = localPlayerTeam.get()
  foreach (row in teamFreeTanks.get())
    if (row.team__id == team)
      return row.team__freeTankTemplate
  return ""
})

let freeTankInfo = Computed(@() { gametemplate = localTeamFreeTankTemplate.get() })
let freeTankSeatsCount = Computed(@() DB.getTemplateByName(localTeamFreeTankTemplate.get())
  ?.getCompValNullable("vehicle_seats__seats")?.len() ?? -1)

let squadsList = Computed(function(prev) {
  if (!needSpawnMenu.get()) 
    return prev != FRP_INITIAL ? prev : []

  let { armyId = null } = armyData.get()
  let canSpawnSpy = canSpawnSpySquad.get()
  return (armyData.get()?.squads ?? [])
    .map(function(squad, idx) {
      let { squadId, squadType = "unknown", level = 0, curVehicle = null, vehicleType = null,
        sign = SIGN_NONE } = squad
      local { premIcon = null, icon = null } = getSquadPresentation(squadId, armyId)
      if (sign == SIGN_PREMIUM)
        premIcon = premIcon ?? armiesPresentation?[armyId].premIcon
      let readinessPercent = squadsRevivePoints.get()?[idx] ?? -1
      let isAffordable = squadsAffordability.get()?[idx] ?? true
      let scorePrice = squadsScorePrice.get()?[idx] ?? 0
      local canSpawn = readinessPercent == 100 && isAffordable
      local forcedSpawnWithoutVehicle = false
      if (canSpawn) {
        if (curVehicle != null) {
          let { gametemplate = null } = curVehicle
          let { canUseRespawnbaseType = null, canUseRespawnbaseSubtypes = [] } = get_can_use_respawnbase_type(gametemplate)
          let availableRespSubtypes = vehicleRespawnBases.get()?[canUseRespawnbaseType] ?? {}
          let kamimazePenaltyInactive = (DB.getTemplateByName(gametemplate)?.getCompValNullable("airplane") == null || !kamikazePenaltyActive.get())
          local hasRepawnBaseByType = canUseRespawnbaseSubtypes.len() == 0
          foreach (subtype in canUseRespawnbaseSubtypes)
            hasRepawnBaseByType = hasRepawnBaseByType || (availableRespSubtypes?[subtype] ?? false)
          let hasRespawnbase = availableRespSubtypes.findindex(@(v) v) != null && hasRepawnBaseByType
          let canSpawnOnVehicle = canSpawnOnVehicleBySquad.get()?[idx] ?? false
          forcedSpawnWithoutVehicle = !canSpawnOnVehicle && humanCanRespawn.get() && (squad?.spawnWithoutVehicleAvailable ?? false)
          canSpawn = hasRespawnbase && (canSpawnOnVehicle || forcedSpawnWithoutVehicle) && readinessPercent == 100 && kamimazePenaltyInactive
        } else {
          canSpawn = humanCanRespawn.get()
        }
      }
      canSpawn = canSpawn && (squadType != "saboteur" || canSpawnSpy)

      return {
        squadId
        icon
        premIcon
        name = squad?.locId ? loc(squad.locId) : "---"
        squadType
        level
        squadSize = squad.squad.len()
        vehicle = curVehicle
        vehicleType
        isFaded = !canSpawn

        canSpawn
        readinessPercent
        isAffordable
        scorePrice
        forcedSpawnWithoutVehicle
      }
    })
  }
)

let curSquadData = Computed(@()
  squadsList.get().findvalue(@(val) val?.squadId == spawnSquadId.get()))

let curVehicle = Computed(@() curSquadData.get()?.vehicle)

let paratroopersPointSelectorRequested = Watched(false)
let paratroopersOn = Watched(false)
let isParatroopersSquad = Computed(@()
  armyData.get()?.squads[squadIndexForSpawn.get()].isParatroopers && curSquadData.get()?.canSpawn)

let spawnWithoutVehicleForced = Computed(@() (curSquadData.get()?.forcedSpawnWithoutVehicle ?? false))
let spawnWithoutVehicle = Computed(@() spawnWithoutVehicleAvailable.get() && (!spawnWithVehicleRequested.get() || spawnWithoutVehicleForced.get()))

let paratroopersPointSelectorOn = Computed(@()
  showSquadSpawn.get() && isParatroopersSquad.get() && paratroopersPointSelectorRequested.get())

isParatroopersSquad.subscribe(@(v) paratroopersPointSelectorRequested.set(v))

let canUseRespawnbaseByType = Computed(function() {
  if (spawnWithoutVehicleAvailable.get() && (!spawnWithVehicleRequested.get() || spawnWithoutVehicleForced.get()))
    return "human"
  let templ = vehicleInfo.get()?.gametemplate
  let HUMAN = paratroopersPointSelectorOn.get() ? "paratroopers" : "human"
  if (templ==null)
    return HUMAN
  let baseType = get_can_use_respawnbase_type(vehicleInfo.get().gametemplate)?.canUseRespawnbaseType ?? HUMAN
  return baseType
})

let currentRespawnGroup = Computed(@()
  selectedRespawnGroupId.get()?[canUseRespawnbaseByType.get()] ?? -1)

let freeTankSpawnInfoShow = Computed(@()vehicleInfo.get() != null && isFreeTankSpawn(currentRespawnGroup.get()))

function updateVehicleSpawnAvailableTimer(...) {
  let curTime = app.get_sync_time()
  isSquadAvailableByTime.set(nextSpawnOnVehicleInTimeBySquad.get().map(@(v) v <= curTime))
  let nextEndTime = nextSpawnOnVehicleInTimeBySquad.get()
    .filter(@(it) it > curTime)
    .reduce(@(a,b) min(a,b)) ?? -1.0
  let minDelay = nextEndTime - curTime
  if (minDelay > 0) {
    gui_scene.resetTimeout(minDelay, updateVehicleSpawnAvailableTimer)
  }
}
subscribeAndInit(updateVehicleSpawnAvailableTimer, nextSpawnOnVehicleInTimeBySquad)

function requestRespawn() {
  let squadId = squadIndexForSpawn.get()
  let spawnGroup = currentRespawnGroup.get()
  let memberId = squadMemberIdForSpawn.get()
  let curSpawnSquadId = spawnSquadId.get()
  let isParatroopers = paratroopersOn.get()
  let withoutVehicle = spawnWithoutVehicle.get()
  let respEid = respawnerEid.get()
  setSpawnedSquads((curSpawnedSquads.get() ?? {}).__merge({ [curSpawnSquadId] = true }))
  logHR($"Request respawn, respawnerEid {respEid}, squadId {squadId}, memberId {memberId} spawnGroup {spawnGroup}")
  sendNetEvent(respEid, CmdRequestRespawn({ squadId, memberId, spawnGroup, isParatroopers,
    withoutVehicle, fuelLoadPct = fuelLoadPct.get() }))
}

function cancelRequestRespawn() {
  let squadId = squadIndexForSpawn.get()
  let memberId = squadMemberIdForSpawn.get()
  let spawnGroup = queueRespawnGroupId.get()
  let isParatroopers = paratroopersOn.get()
  let withoutVehicle = spawnWithoutVehicle.get()
  let respEid = respawnerEid.get()
  logHR($"Request cancel respawn, respawnerEid {respEid}, squadId {squadId}, memberId {memberId}, paratroopers {isParatroopers}, without vehicle {withoutVehicle}")
  sendNetEvent(respEid, CmdCancelRequestRespawn({ squadId, memberId, spawnGroup, isParatroopers,
    withoutVehicle }))
  queuedRespawnGroupId.set(queueRespawnGroupId.get())
}



function setRespRequested(val) {
  respRequested.set(val)
  if (val)
    requestRespawn()
  else
    cancelRequestRespawn()
}

function cancelRespawn() {
  if (respRequested.get())
    setRespRequested(false)
  else if (queueRespawnGroupId.get() != queuedRespawnGroupId.get())
    respRequested.trigger() 
}

function onActive() {
  respawnLastActiveTime.set(app.get_sync_time())
  if (canRespawnWaitNumber.get() > 0)
    requestRespawn()
  cancelRespawn()
}


function updateSquadSpawnIndex(...) {
  squadIndexForSpawn.set(squadsList.get().findindex(@(s) s.squadId == spawnSquadId.get()) ?? 0)
}

spawnSquadId.subscribe(function(_) {
  updateSquadSpawnIndex()
  onActive()
})
squadsList.subscribe(updateSquadSpawnIndex)

curSoldierIdx.subscribe(function(i){
  squadMemberIdForSpawn.set(i)
  onActive()
})

function getBestSquadId(squads, curSquadId, defSquadId = null) {
  local bestSquadId = (squads.findindex(@(sq) sq.squadId == curSquadId) == null ? null : curSquadId)
    ?? defSquadId

  local maxReadiness = squads.findvalue(@(sq)
    sq.squadId == bestSquadId && sq.canSpawn)?.readinessPercent ?? 0
  foreach (squad in squads)
    if (squad.canSpawn && squad.readinessPercent > maxReadiness) {
      bestSquadId = squad.squadId
      maxReadiness = squad.readinessPercent
    }
  return bestSquadId
}

function updateSpawnSquadId() {
  let squads = squadsList.get()
  let spawnedSquads = curSpawnedSquads.get()
  let preferSquads = squads.filter(@(s) s.squadId not in spawnedSquads)
  let curSpawnSquadId = spawnSquadId.get() ?? armyData.get()?.curSquadId
  let bestSquadId = getBestSquadId(preferSquads, curSpawnSquadId)
    ?? getBestSquadId(squads, curSpawnSquadId, squads?[0].squadId)

  spawnSquadId.set(bestSquadId)
}


let soldiersList = Computed(function() {
  let allSoldiers = soldiersData.get()
  let squadId = spawnSquadId.get()
  let { squads = [], armyId = null } = armyData.get()
  let armyPremIcon = armiesPresentation?[armyId].premIcon
  let { premIcon = null } = getSquadPresentation(squadId, armyId)
  let squadIndx = squads.findindex(@(s) s.squadId == squadId)
  let { squad = [] } = squads?[squadIndx]
  let readinessPercents = soldierRevivePoints.get()?[squadIndx] ?? []

  let list = []
  foreach (soldier in squad) {
    let data = allSoldiers?[soldier.guid]
    if (data != null)
      list.append(data.__merge({
        canSpawn = (readinessPercents?[soldier.id] ?? 100) == 100
        premIcon = premIcon ?? ((soldier?.isPremium ?? false) ? armyPremIcon : null)
      }))
  }
  return list
})

let respawnBlockedReason = Computed(function() {
  let zones = spawnZonesState.get()
  let respawnId = currentRespawnGroup.get()
  let canUse = canUseRespawnbaseByType.get()
  let lpt = localPlayerTeam.get()
  foreach (zone in zones) {
    if (zone?.forTeam == lpt && zone?.selectedGroup == respawnId && canUse == zone.iconType){
      if (curSquadData.get()?.squadType == "saboteur" && !canSpawnSpySquad.get())
        return {reason = "respawn/spySquadLimitReached"}
      if (!zone.isActive && zone.enemyAtRespawn)
        return  {reason = "respawn/enemy_at_respawn"}
      if (canRespawnWaitNumber.get() > 0)
        return  {reason = "respawn/waiting_in_queue", waitNumber = canRespawnWaitNumber.get(), timeToActivate = zone.activateAtTime}
      if (!zone.isActive && zone.activateAtTime > 0.0)
        return {reason = "respawn/blocked_by_timer", timeToActivate = zone.activateAtTime}
      if (!zone.isActive && zone.isMobileSpawn && zone.playersCount > 0)
        return {reason = "respawn/blocked_by_timer", timeToActivate = zone.playersCount}
      if (!zone.isActive && zone.isOccupied)
        return {reason = "respawn/is_occupied"}
      if (!zone.isActive && zone.isFreeTankSpawn && !isFreeTankSpawnsAvailable.get())
        return {reason = "respawn/free_spawn_for_player_inavailable"}
      if (!zone.isActive && zone.additionalInfo != "")
        return {reason = zone.additionalInfo}
      if (!zone.isActive)
        return {reason = "respawn/respawn_disabled"}
    }
  }
  return {}
})

let respawnSelectedEid = Computed(@() spawnZonesState.get().findindex(@(zone)
  localPlayerTeam.get() == zone.forTeam &&
  canUseRespawnbaseByType.get() == zone.iconType &&
  (selectedRespawnGroupId.get()?[zone.iconType] ?? -1) == zone.selectedGroup) ?? ecs.INVALID_ENTITY_ID)

let canSpawnCurrentSoldier = Computed(@() soldiersList.get()?[curSoldierIdx.get()]?.canSpawn ?? true)
let canSpawnCurrentSquadAndSoldier = Computed(@() (curSquadData.get()?.canSpawn ?? false) && canSpawnCurrentSoldier.get())
let canSpawnCurrent = Computed(@() !respawnBlockedReason.get()?.reason && canSpawnCurrentSquadAndSoldier.get())

currentRespawnGroup.subscribe(function(v) {
  queueRespawnGroupId.set(canSpawnCurrentSquadAndSoldier.get() ? v : -1)
  onActive()
})

canSpawnCurrentSquadAndSoldier.subscribe(function(v) {
  if (!v) {
    queueRespawnGroupId.set(-1)
    cancelRespawn()
  }
  else if (!respRequested.get()) {
    queueRespawnGroupId.set(currentRespawnGroup.get())
    cancelRespawn()
  }
})

canSpawnCurrent.subscribe(function(v){
  if (!v)
    cancelRespawn()
})

let findReadySoldier = @(squadIndex) soldierRevivePoints.get()?[squadIndex]?.findindex(@(readinessPercent) readinessPercent == 100)

soldiersList.subscribe(function(_) {
  curSoldierIdx.set(squadIndexForSpawn.get() < 0 ? 0 : findReadySoldier(squadIndexForSpawn.get()) ?? 0)
})

let respEndTotalTime = Computed(function(){
  if (!canSpawnCurrent.get() || !needSpawnMenu.get())
    return -1
  if (respEndTime.get() > 0)
    return respEndTime.get()
  if (respawnLastActiveTime.get() > 0 )
    return max(canRespawnTime.get(), respawnLastActiveTime.get() + respawnInactiveTimeout.get())
  return -1
})

let timeToRespawn = mkCountdownTimerPerSec(respEndTotalTime)

needSpawnMenu.subscribe(function(need) { if (need) respawnLastActiveTime.set(app.get_sync_time()) })
local pendingResp = null

function setPendingResp(_ = null) {
  if (pendingResp)
    return
  
  pendingResp = function() {
    pendingResp = null
    logHR($"Check pending resp. respEndTime = {respEndTime.get()}, respEndTotalTime = {respEndTotalTime.get()}, timeToRespawn = {timeToRespawn.get()}")
    if (needSpawnMenu.get() && respEndTime.get() <= 0 && respEndTotalTime.get() > 0
        && timeToRespawn.get() == 0 && !paratroopersPointSelectorOn.get())
      requestRespawn()
  }
  defer(pendingResp)
}

subscribeList(setPendingResp, needSpawnMenu, respEndTime, respEndTotalTime, timeToRespawn)

function equalUpdate(watch, newVal) {
  if (!isEqual(watch.get(), newVal))
    watch.set(newVal)
}

function updateVehiclesLimits(watch, newVal){
  watch.set(newVal.map(function(value, key){
    if ((squadsRespawnTypes.get()?[key] ?? "") == "APC" && localPlayerHasActiveApc.get()){
      return value + 1
    }
    return value
  }))
}

function trackComponents(_evt, eid, comp) {
  if (!comp.is_local)
    return
  respawnerEid.set(eid)
  canRespawnTime.set(comp["respawner__canRespawnTime"])

  let waitNumber = comp["respawner__canRespawnWaitNumber"]
  if (canRespawnWaitNumber.get() > 0 && waitNumber == 0)
    defer(@() canRespawnWaitNumber.set(waitNumber))
  else
    canRespawnWaitNumber.set(waitNumber)

  respEndTime.set(comp["respawner__respEndTime"])
  respawnsInBot.set(comp["respawner__respToBot"])
  respawnInactiveTimeout.set(comp["respawner__respawnWhenInactiveTimeout"])
  isFirstSpawn.set(comp["respawner__isFirstSpawn"])
  isSpectatorEnabled.set(comp["respawner__spectatorEnabled"])
  updateVehiclesLimits(curLimitVehiclesOnPointBySquad, comp.respawner__vehiclesLimitBySquad.getAll())
  equalUpdate(maxSpawnVehiclesOnPointBySquad, comp.respawner__maxVehiclesLimitBySquad.getAll())
  equalUpdate(nextSpawnOnVehicleInTimeBySquad, comp.respawner__nextSpawnOnVehicleTimeBySquad.getAll())
  logHR("Received from server respawner__respRequested = {0}, respawner__respEndTime = {1}, respawner__canRespawnTime = {2}, respawner__canRespawnWaitNumber = {3}"
    .subst(comp["respawner__respRequested"], comp["respawner__respEndTime"], comp["respawner__canRespawnTime"], comp["respawner__canRespawnWaitNumber"]))
  respRequested.set(comp["respawner__respRequested"])
}

ecs.register_es("reset_respawn_groups", {
  [[EventLevelLoaded, EventZoneCaptured, EventZoneIsAboutToBeCaptured]] = @() selectedRespawnGroupId.set({})
}, {}, {tags="gameClient"})

ecs.register_es("respawns_state_ui_es", {
    [["onInit","onChange",ecs.EventScriptReloaded]] = trackComponents,
  },
  {
    comps_track = [
      ["respawner__respToBot", ecs.TYPE_BOOL],
      ["respawner__respEndTime", ecs.TYPE_FLOAT, -1.0],
      ["respawner__canRespawnTime", ecs.TYPE_FLOAT, -1.0],
      ["respawner__canRespawnWaitNumber", ecs.TYPE_INT, -1],
      ["respawner__respawnWhenInactiveTimeout", ecs.TYPE_FLOAT, -1.0],
      ["respawner__respawnWhenInactiveShowTimer", ecs.TYPE_FLOAT, -1.0],
      ["respawner__respRequested", ecs.TYPE_BOOL, false],
      ["respawner__isFirstSpawn", ecs.TYPE_BOOL, false],
      ["respawner__vehiclesLimitBySquad", ecs.TYPE_INT_LIST],
      ["respawner__maxVehiclesLimitBySquad", ecs.TYPE_INT_LIST],
      ["respawner__nextSpawnOnVehicleTimeBySquad", ecs.TYPE_INT_LIST],
      ["respawner__spectatorEnabled", ecs.TYPE_BOOL, false],
      ["is_local", ecs.TYPE_BOOL],
    ]
  }
)

ecs.register_es("squads_state_show_respawn_ui_es",
  {[EventOnSpawnError] = @ (evt, _eid, _comp) logHR($"Spawn Error: {evt.data.reason}")},
  {comps_rq = ["player"]})

let requestRespawnToEntity = @(eid)
  sendNetEvent(localPlayerEid.get(), RequestNextRespawnEntity({memberEid=eid}))

let state = {
  respEndTime
  canRespawnTime
  canRespawnWaitNumber
  respawnsInBot
  canChangeRespawnParams
  canUseRespawnbaseByType
  squadIndexForSpawn
  vehicleInfo
  squadsCanSpawn
  selectedRespawnGroupId
  isSpectatorEnabled
  maxSpawnVehiclesOnPointBySquad
  nextSpawnOnVehicleInTimeBySquad
  doRequestRespawn = @() setRespRequested(true)
  doCancelRequestRespawn = @() setRespRequested(false)
  respRequested
  spawnSquadId
  spawnCount
  isFirstSpawn
  needSpawnMenu
  timeToCanRespawn
  canSpawnOnVehicleBySquad
  timeToRespawn
  showSquadSpawn
  squadsList
  curSquadData
  curVehicle
  canSpawnCurrent
  canSpawnCurrentSoldier
  soldiersList
  curSoldierIdx
  spawnScore
  respawnBlockedReason
  respawnSelectedEid
  
  updateSpawnSquadId
  requestRespawnToEntity
  paratroopersPointSelectorOn
  paratroopersOn
  isParatroopersSquad
  paratroopersPointSelectorRequested
  spawnWithoutVehicleAvailable
  kamikazePenaltyActive
  fuelLoadPct
  spawnWithVehicleRequested
  spawnWithoutVehicleForced
  currentRespawnGroup
  freeTankInfo
  freeTankSeatsCount
  freeTankSpawnInfoShow
}

let debugSpawn = mkWatched(persist,"debugSpawn")
let beforeDebugSpawn = mkWatched(persist, "beforeDebugSpawn")

let setOrCall = @(v, value) v instanceof Function ? v(value) : v.set(value)

function setDebugMode(isRespawnInBot) {
  let isChanged = debugSpawn.get()?.respawnsInBot != isRespawnInBot
  if (!isChanged) {
    foreach (key, value in beforeDebugSpawn.get())
      setOrCall(state[key], value)
    beforeDebugSpawn.set(null)
    debugSpawn.set(null)
    return
  }
  let newData = {
    respawnsInBot = isRespawnInBot
    respEndTime = 300 + app.get_sync_time()
    canRespawnTime = 35 + app.get_sync_time()
    canRespawnWaitNumber = -1
  }
  debugSpawn.set(newData)
  if (!beforeDebugSpawn.get())
    beforeDebugSpawn.set(newData.map(@(_value, key) state[key].get()))
  foreach (key, value in newData)
    setOrCall(state[key], value)
}

console_register_command(@() setDebugMode(false), "respawn.debugSquad")
console_register_command(@() setDebugMode(true), "respawn.debugMember")

return state
