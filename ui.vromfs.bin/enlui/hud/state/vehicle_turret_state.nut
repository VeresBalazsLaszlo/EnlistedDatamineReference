import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/vehicle_state.nut" import inTank, isPassenger
from "%ui/hud/state/hero_in_vehicle_state.nut" import isHoldingGunPassenger
from "dasevents" import EventOnSeatOwnersChanged
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let { vehicleTurrets, vehicleTurretsSetValue } = mkFrameIncrementObservable([], "vehicleTurrets")

let watchedVehicleAmmo = mkEcsComputed({
  comps = [["ui_turrets_state__ammo", ecs.TYPE_OBJECT]]
  comps_rq = ["vehicleWithWatched"]
})



let turretsAmmo = Computed(function() {
  let ammo = watchedVehicleAmmo.get()
  let res = {}
  if (ammo == null)
    return res
  foreach (turret in vehicleTurrets.get()) {
    res[turret.gunEid] <- ammo?[turret.gunEid.tostring()] ?? {}
    foreach (eid in (turret?.subGroupGunEids ?? []))
      res[eid] <- ammo?[eid.tostring()] ?? {}
    if (turret.groupName != "")
      res[turret.groupName] <- ammo?[turret.groupName] ?? {}
  }
  return res
})

let { mainTurretEid, mainTurretEidSetValue } = mkFrameIncrementObservable(ecs.INVALID_ENTITY_ID, "mainTurretEid")
let { currentMainTurretEid, currentMainTurretEidSetValue } = mkFrameIncrementObservable(ecs.INVALID_ENTITY_ID, "currentMainTurretEid")
let { firstInputTurretEid, firstInputTurretEidSetValue } = mkFrameIncrementObservable(ecs.INVALID_ENTITY_ID, "firstInputTurretEid")

const MACHINE_GUN_TRIGGER = 2

function resetState() {
  vehicleTurretsSetValue([])
}

let turretQuery = ecs.SqQuery("turretQuery", {
  comps_ro=[
    ["gun__propsId", ecs.TYPE_INT, -1],
    ["gun__reloadable", ecs.TYPE_BOOL, false],
    ["turret__groupName", ecs.TYPE_STRING, ""],
    ["turretInput", ecs.TYPE_TAG, null],
    ["turret_input__isLocalControlLocked", ecs.TYPE_BOOL, false],
    ["currentBulletId", ecs.TYPE_INT, 0],
    ["nextBulletId", ecs.TYPE_INT, -1],
    ["turret__triggerGroup", ecs.TYPE_INT, -1],
    ["gun__ammoSetsInfo", ecs.TYPE_SHARED_ARRAY, null],
    ["gun__shellsAmmo", ecs.TYPE_ARRAY, []],
    ["turret__disableAim", ecs.TYPE_TAG, null],
    ["firstTurretInput", ecs.TYPE_TAG, null],
    ["item__name", ecs.TYPE_STRING, null],
    ["gun__icon", ecs.TYPE_STRING, null]
  ]
})

function get_trigger_mappings(hotkeys) {
  let mappings = {}
  foreach (mapping in hotkeys) {
    let name = mapping?.name
    let hotkey = mapping?.hotkey
    if (name != null && hotkey != null)
      mappings[name] <- hotkey
  }
  return mappings
}

let getAmmoSets = @(_, comp)
  (comp["gun__ammoSetsInfo"]?.getAll() ?? []).map(@(set, setInd) { name=set?[0]?.name ?? "", type=set?[0]?.type ?? "", maxAmmo = comp["gun__shellsAmmo"]?[setInd] ?? 0 })

function initTurretsState(comp, ignore_control_turret_eid = ecs.INVALID_ENTITY_ID) {
  let turretsByGroup = {}

  let triggerMappingComp = comp["turret_control__triggerMapping"]?.getAll() ?? []
  let triggerMappings = get_trigger_mappings(triggerMappingComp)
  let turretInfo = comp["turret_control__turretInfo"]
  local firstTurretInputEid = ecs.INVALID_ENTITY_ID
  foreach (gunIndex, gunEid in comp["turret_control__gunEids"]) {
    let trigger = turretInfo?[gunIndex]?.trigger
    let gEid = gunEid
    turretQuery.perform(gunEid, function(v,gunComp) {
      let gunPropsId = gunComp["gun__propsId"]

      let turret = {
        gunEid = gEid
        gunPropsId
        name = gunComp["item__name"]
        currentAmmoSetId = gunComp["currentBulletId"]
        nextAmmoSetId = gunComp["nextBulletId"]
        isReloadable = gunComp["gun__reloadable"]
        icon = gunComp["gun__icon"]
        isControlled = gunComp["turretInput"] != null && gEid != ignore_control_turret_eid
        isLocalControlLocked = gunComp["turret_input__isLocalControlLocked"]
        isBomb = trigger == "bombs"
        isRocket = trigger == "rockets"
        hotkey = triggerMappings?[trigger]
        triggerGroup = gunComp["turret__triggerGroup"]
        groupName = gunComp["turret__groupName"]
        isWithSeveralShells = gunComp["nextBulletId"] != -1
        ammoSet = getAmmoSets(v, gunComp)
        showCrosshair = gunComp.turret__disableAim == null
      }
      if (gunComp["firstTurretInput"] != null)
        firstTurretInputEid = gEid
      let groupName = turret.groupName
      if (turretsByGroup?[groupName] == null)
        turretsByGroup[groupName] <- []
      turretsByGroup[groupName].append(turret)
    })
  }
  firstInputTurretEidSetValue(firstTurretInputEid)

  let turrets = []
  foreach (group, turretsInGroup in turretsByGroup)
    if (group != "") {
      let mainTurretInGroup = turretsInGroup[0]
      if (mainTurretInGroup.isBomb || mainTurretInGroup.isRocket) {
        let byName = {}
        let nameOrder = []
        foreach (turret in turretsInGroup) {
          if (!(turret.name in byName)) {
            byName[turret.name] <- []
            nameOrder.append(turret.name)
          }
          byName[turret.name].append(turret)
        }
        if (nameOrder.len() > 1) {
          foreach (turretName in nameOrder) {
            let subTurrets = byName[turretName]
            let subMain = subTurrets[0]
            subMain.subGroupGunEids <- subTurrets.map(@(t) t.gunEid)
            turrets.append(subMain)
          }
        } else {
          mainTurretInGroup.namesInGroup <-
            turretsInGroup.reduce(function(res, turret) { res[turret.gunEid] <- turret.name; return res }, {})
          turrets.append(mainTurretInGroup)
        }
      } else
        turrets.append(mainTurretInGroup)
    } else
      turrets.extend(turretsInGroup)

  let mainTurretEidValue = (turretsByGroup?[""][0] ?? turrets?[0])?.gunEid ?? ecs.INVALID_ENTITY_ID
  mainTurretEidSetValue(mainTurretEidValue)
  currentMainTurretEidSetValue(
    turretsByGroup?[""].findvalue(@(turret) turret.isControlled && turret.triggerGroup != MACHINE_GUN_TRIGGER)?.gunEid ?? mainTurretEidValue)

  vehicleTurretsSetValue(turrets)
}

ecs.register_es("vehicle_turret_state_ui_es",
  {
    [["onInit", "onChange", EventOnSeatOwnersChanged]] = @(_, comp) initTurretsState(comp),
    onDestroy = @(...) resetState(),
  },
  {
    comps_ro = [
      ["turret_control__triggerMapping", ecs.TYPE_SHARED_ARRAY, null],
      ["turret_control__turretInfo", ecs.TYPE_SHARED_ARRAY],
    ]
    comps_track = [
      ["turret_control__isInputLocked", ecs.TYPE_BOOL],
      ["turret_control__gunEids", ecs.TYPE_EID_LIST],
      ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
    ]
    comps_rq = ["vehicleWithWatched"]
  }
)

let turretsVehicleQuery = ecs.SqQuery("turretsVehicleQuery", {
  comps_ro = [
    ["turret_control__triggerMapping", ecs.TYPE_SHARED_ARRAY, null],
    ["turret_control__turretInfo", ecs.TYPE_SHARED_ARRAY],
    ["turret_control__gunEids", ecs.TYPE_EID_LIST],
    ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
  ],
  comps_rq = ["vehicleWithWatched"]
})

ecs.register_es("track_controlled_turret_ui_es",
  { [["onInit", "onChange"]] = function(_eid, comp) {
      turretsVehicleQuery(comp["turret__owner"], @(_, vehicleComp) initTurretsState(vehicleComp))
    },
    onDestroy = function(deleted_eid, comp) {
      turretsVehicleQuery(comp.turret__owner, @(_, vehicleComp) initTurretsState(vehicleComp, deleted_eid))
    }
  },
  {
    comps_track = [
      ["currentBulletId", ecs.TYPE_INT, 0],
      ["nextBulletId", ecs.TYPE_INT, 0],
    ]
    comps_ro = [["turret__owner", ecs.TYPE_EID]]
    comps_rq = ["turretInput"]
  }
)

let turretsReloadState = mkEcsComputedEidMap({
  comps = [
    ["ui_turret_reload_progress__startTime", ecs.TYPE_FLOAT],
    ["ui_turret_reload_progress__finishTime", ecs.TYPE_FLOAT],
    ["ui_turret_reload_progress__progressStopped", ecs.TYPE_FLOAT, -1],
    ["turret__perksReloadMult", ecs.TYPE_FLOAT, 1.],
    ["turret__ammoStowageReloadMult", ecs.TYPE_FLOAT, 1.]
  ]
  comps_rq = ["isTurret", "turretInput"]
  tags = "ui"
})

let turretsReload = Computed(@() turretsReloadState.get().map(@(comp) {
  perksReloadTimeMult = comp.turret__perksReloadMult
  ammoStowageReloadTimeMult = comp.turret__ammoStowageReloadMult
  progressStopped = comp["ui_turret_reload_progress__progressStopped"]
  endTime = comp["ui_turret_reload_progress__finishTime"]
  totalTime = comp["ui_turret_reload_progress__finishTime"] - comp["ui_turret_reload_progress__startTime"]
}))

let turretsReplenishmentState = mkEcsComputedEidMap({
  comps = [
    ["ui_turret_replenishment_progress__startTime", ecs.TYPE_FLOAT],
    ["ui_turret_replenishment_progress__finishTime", ecs.TYPE_FLOAT]
  ]
  comps_rq = ["isTurret", "turretInput"]
  tags = "ui"
})

let turretsReplenishment = Computed(@() turretsReplenishmentState.get().map(@(comp) {
  endTime = comp.ui_turret_replenishment_progress__finishTime
  totalTime = comp.ui_turret_replenishment_progress__finishTime - comp.ui_turret_replenishment_progress__startTime
}))

let showVehicleWeapons = Computed(function() {
  let haveTurrets = (vehicleTurrets.get()?.len() ?? 0) > 0
  return (inTank.get() ? haveTurrets && !isPassenger.get() : haveTurrets) && !isHoldingGunPassenger.get()
})

let mainTurretAmmo = Computed(@() turretsAmmo.get()?[mainTurretEid.get()])
let currentMainTurretAmmo = Computed(@() turretsAmmo.get()?[currentMainTurretEid.get()])

return {
  vehicleTurrets
  showVehicleWeapons
  mainTurretEid
  currentMainTurretEid
  firstInputTurretEid
  currentMainTurretAmmo
  turretsReload
  turretsReplenishment
  turretsAmmo
  mainTurretAmmo
}
