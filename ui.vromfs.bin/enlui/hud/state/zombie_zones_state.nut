import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "gameevents" import EventLevelLoaded
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/ui_library.nut" import *

let { zombieArenas, zombieArenasModify, zombieArenasSetKeyVal,
  zombieArenasDeleteKey } = mkFrameIncrementObservable({}, "zombieArenas")
let { zombieRadios, zombieRadiosModify, zombieRadiosSetKeyVal,
  zombieRadiosDeleteKey } = mkFrameIncrementObservable({}, "zombieRadios")
let { zombieBosses, zombieBossesModify, zombieBossesSetKeyVal,
  zombieBossesDeleteKey } = mkFrameIncrementObservable({}, "zombieBosses")




let zombieObjectiveMode = mkEcsComputed({
  comps = [["zombie_mode__sessionFinished", ecs.TYPE_BOOL, false]]
  comps_rq = ["zombie_travel_mode"]
})
let isZombieObjectiveMode = Computed(@() zombieObjectiveMode.get() != null)

let zombieTeamUiMode = mkEcsComputed({
  comps = [["team__id", ecs.TYPE_INT, -1]]
  comps_rq = ["zombie_team_ui"]
})
let showZombieTeamUi = Computed(@() zombieTeamUiMode.get() != null)

let selfresCount = mkEcsComputed({
  comps = [["total_kits__selfRessurrect", ecs.TYPE_INT]]
  comps_rq = ["watchedByPlr"]
  defVal = 0
})


function onArenaInitialized(_evt, eid, comp) {
  let zone = {
    eid
    kills  = comp["zombie_arena__kills"]
    killsRequire = comp["zombie_arena__killsRequire"]
    curWave = comp["objective_spawner__curWaveId"]
    nextWaveTime = comp["zombie_arena__zombieNextWaveAtTime"]
    active   = comp["active"]
    bossRelHp = comp["zombie_arena__bossRelHp"]
    nameLocId = comp["zombie_arena__bossName"]
  }
  zombieArenasSetKeyVal(eid, zone)
}

function onArenaChanged(_evt, eid, comp) {
  let changedZoneVals = {}
  zombieArenasModify(function(zones){
    let zone = zones?[eid]
    if (zone==null)
      return zones

    if (zone?["kills"] != comp["zombie_arena__kills"])
      changedZoneVals["kills"] <- comp["zombie_arena__kills"]
    if (zone?["killsRequire"] != comp["zombie_arena__killsRequire"])
      changedZoneVals["killsRequire"] <- comp["zombie_arena__killsRequire"]
    if (zone?["nextWaveTime"] != comp["zombie_arena__zombieNextWaveAtTime"])
      changedZoneVals["nextWaveTime"] <- (comp["zombie_arena__zombieNextWaveAtTime"])
    if (zone?["active"] != comp["active"])
      changedZoneVals["active"] <- comp["active"]
    if (zone?["curWave"] != comp["objective_spawner__curWaveId"])
      changedZoneVals["curWave"] <- comp["objective_spawner__curWaveId"]
    if (zone?["bossRelHp"] != comp["zombie_arena__bossRelHp"])
      changedZoneVals["bossRelHp"] <- comp["zombie_arena__bossRelHp"]
    if (zone?["nameLocId"] != comp["zombie_arena__bossName"])
      changedZoneVals["nameLocId"] <- comp["zombie_arena__bossName"]

    let newZone = zone.__merge(changedZoneVals)
    zones[eid] <- newZone
    return zones
  })
}

ecs.register_es("zombie_arena_ui_state_es",
  {
    onChange = onArenaChanged,
    [[EventLevelLoaded, "onInit"]] = onArenaInitialized,
    onDestroy = @(_, eid, __) zombieArenasDeleteKey(eid),
  },
  {
    comps_track = [
      ["active", ecs.TYPE_BOOL],
      ["zombie_arena__killsRequire", ecs.TYPE_INT],
      ["zombie_arena__kills", ecs.TYPE_INT],
      ["objective_spawner__curWaveId", ecs.TYPE_INT],
      ["zombie_arena__zombieNextWaveAtTime", ecs.TYPE_FLOAT],
      ["zombie_arena__bossRelHp", ecs.TYPE_FLOAT],
      ["zombie_arena__bossName", ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["zombie_arena"],
  },
  { tags="gameClient" }
)

function onRadioInitialized(_evt, eid, comp) {
  let zone = {
    eid
    curWaveId = comp["objective_spawner__curWaveId"]
    nextActivationAfterTime = comp["objective_spawner__nextActivationAfterTime"]
    activationPeriod = comp["objective_spawner__activationPeriod"]
    active = comp["active"]
    wavesCount = comp["objective_spawner__wavesCount"]
    objectiveActive = comp["objective_spawner__active"]
  }
  zombieRadiosSetKeyVal(eid, zone)
}

function onRadioChanged(_evt, eid, comp) {
  let changedZoneVals = {}
  zombieRadiosModify(function(zones){
    let zone = zones?[eid]
    if (zone==null)
      return zones

    if (zone?["nextActivationAfterTime"] != comp["objective_spawner__nextActivationAfterTime"])
      changedZoneVals["nextActivationAfterTime"] <- comp["objective_spawner__nextActivationAfterTime"]
    if (zone?["activationPeriod"] != comp["objective_spawner__activationPeriod"])
      changedZoneVals["activationPeriod"] <- comp["objective_spawner__activationPeriod"]
    if (zone?["curWaveId"] != comp["objective_spawner__curWaveId"])
      changedZoneVals["curWaveId"] <- comp["objective_spawner__curWaveId"]
    if (zone?["wavesCount"] != comp["objective_spawner__wavesCount"])
      changedZoneVals["wavesCount"] <- comp["objective_spawner__wavesCount"]
    if (zone?["active"] != comp["active"])
      changedZoneVals["active"] <- comp["active"]
    if (zone?["objectiveActive"] != comp["objective_spawner__active"])
      changedZoneVals["objectiveActive"] <- comp["objective_spawner__active"]

    let newZone = zone.__merge(changedZoneVals)
    zones[eid] <- newZone
    return zones
  })
}

ecs.register_es("zombie_radio_ui_state_es",
  {
    onChange = onRadioChanged,
    [[EventLevelLoaded, "onInit"]] = onRadioInitialized,
    onDestroy = @(_, eid, __) zombieRadiosDeleteKey(eid),
  },
  {
    comps_track = [
      ["active", ecs.TYPE_BOOL],
      ["objective_spawner__active", ecs.TYPE_BOOL],
      ["objective_spawner__curWaveId", ecs.TYPE_INT],
      ["objective_spawner__nextActivationAfterTime", ecs.TYPE_FLOAT],
      ["objective_spawner__activationPeriod", ecs.TYPE_FLOAT],
      ["objective_spawner__wavesCount", ecs.TYPE_INT],
    ],
    comps_rq = ["zombie_radio"],
  },
  { tags="gameClient" }
)


function onBossInitialized(_evt, eid, comp) {
  let zone = {
    eid
    active = comp["active"]
    hp = comp["zombie_zone__hp"]
    maxHp = comp["hitpoints__maxHp"]
    nameLocId = comp["killLogName"]
    agressive = comp["zombie_zone__agressive"]
  }
  zombieBossesSetKeyVal(eid, zone)
}

function onBossChanged(_evt, eid, comp) {
  let changedZoneVals = {}
  zombieBossesModify(function(zones){
    let zone = zones?[eid]
    if (zone == null)
      return zones

    if (zone?["active"] != comp["active"])
      changedZoneVals["active"] <- comp["active"]
    if (zone?["hp"] != comp["zombie_zone__hp"])
      changedZoneVals["hp"] <- comp["zombie_zone__hp"]
    if (zone?["maxHp"] != comp["hitpoints__maxHp"])
      changedZoneVals["maxHp"] <- comp["zombie_Boss__humansNear"]
    if (zone?["agressive"] != comp["zombie_zone__agressive"])
      changedZoneVals["agressive"] <- comp["zombie_zone__agressive"]

    let newZone = zone.__merge(changedZoneVals)
    zones[eid] <- newZone
    return zones
  })
}

ecs.register_es("zombie_boss_ui_state_es",
  {
    onChange = onBossChanged,
    [[EventLevelLoaded, "onInit"]] = onBossInitialized,
    onDestroy = @(_, eid, __) zombieBossesDeleteKey(eid),
  },
  {
    comps_track = [
      ["active", ecs.TYPE_BOOL],
      ["zombie_zone__agressive", ecs.TYPE_BOOL, true],
      ["zombie_zone__hp", ecs.TYPE_INT],
      ["hitpoints__maxHp", ecs.TYPE_FLOAT],
      ["killLogName", ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["zone_zombie"],
  },
  { tags="gameClient" }
)

let zombieModeTokens = mkEcsComputed({
  comps = [["player__tokens", ecs.TYPE_INT], ["player__objectiveTokens", ecs.TYPE_INT]]
  comps_rq = ["localPlayer"]
})
let numTokens = Computed(@() zombieModeTokens.get()?.player__tokens ?? 0)
let objectiveTokens = Computed(@() zombieModeTokens.get()?.player__objectiveTokens ?? 0)



let evacuation = mkEcsComputed({
  comps = [["zombie_evacuation__atTime", ecs.TYPE_FLOAT]]
  comps_rq = ["zombie_evacuation"]
  comps_filter = [["active", ecs.TYPE_BOOL]]
  filter = "active"
})
let evacuationEnabled = Computed(@() evacuation.get() != null)
let evacuationTimeLeft = mkCountdownTimerPerSec(evacuation)

let zombieCraters = mkEcsComputed({
  comps = [["entity_spawner__activeCratersCount", ecs.TYPE_INT], ["entity_spawner__aliveCratersCount", ecs.TYPE_INT]]
})
let aliveCratersCount = Computed(@() zombieCraters.get()?.entity_spawner__aliveCratersCount ?? 0)
let activeCratersCount = Computed(@() zombieCraters.get()?.entity_spawner__activeCratersCount ?? 0)

let zombiePatrols = mkEcsComputed({
  comps = [["zombie_patrol__spawnTimerDebugUIInfo", ecs.TYPE_INT],
           ["zombie_patrol__spawnCountDebugUIInfo", ecs.TYPE_INT],
           ["zombie_patrol__selectedWaveDebugUIInfo", ecs.TYPE_INT],
           ["patrols_spawner__selectedState", ecs.TYPE_INT, -1],
           ["patrols_spawner__percentProgressUI", ecs.TYPE_INT, -1]]
})
let patrolsDebugTime = Computed(@() zombiePatrols.get()?.zombie_patrol__spawnTimerDebugUIInfo ?? 0)
let patrolsCount = Computed(@() zombiePatrols.get()?.zombie_patrol__spawnCountDebugUIInfo ?? 0)
let patrolsInProgress = Computed(@() patrolsCount.get() > 0)
let patrolsWave = Computed(@() zombiePatrols.get()?.zombie_patrol__selectedWaveDebugUIInfo ?? 0)
let patrolsOverrideState = Computed(@() zombiePatrols.get()?.patrols_spawner__selectedState ?? -1)
let patrolsProgress = Computed(@() zombiePatrols.get()?.patrols_spawner__percentProgressUI ?? -1)


let sessionEndTime = mkEcsComputed({
  comps = [["zombie_mode_sessionEndTime", ecs.TYPE_FLOAT]]
  defVal = 0
})


let getZombieArenaWatch = memoize(@(eid) Computed(@() zombieArenas.get()?[eid]))
let getZombieRadioWatch = memoize(@(eid) Computed(@() zombieRadios.get()?[eid]))
let getZombieBossWatch = memoize(@(eid) Computed(@() zombieBosses.get()?[eid]))

return {
  isZombieObjectiveMode
  patrolsDebugTime
  patrolsInProgress
  patrolsCount
  patrolsWave
  patrolsOverrideState
  patrolsProgress
  zombieBosses
  getZombieBossWatch
  zombieArenas
  getZombieArenaWatch
  aliveCratersCount
  activeCratersCount
  zombieRadios
  getZombieRadioWatch
  numTokens
  objectiveTokens
  evacuationEnabled
  evacuationTimeLeft
  sessionEndTime
  selfresCount
  showZombieTeamUi
}
