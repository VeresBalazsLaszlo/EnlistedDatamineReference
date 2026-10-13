import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "%ui/ui_library.nut" import *

const defValue = {
  vehicleEngineBroken = false
  vehicleTracksBroken = false
  vehicleWheelsBroken = false
  vehicleTransmissionBroken = false
  vehicleTurretHorDriveBroken = false
  vehicleTurretVerDriveBroken = false
  vehiclePartDamaged = false
  vehicleBeingRepaired = false
}

function partDamagedIndicate(parts, dmState, partDestroyedCount = 0) {
  local isDamaged = false
  foreach (idx in (parts ?? [])) {
    if (dmState?[idx] == 0) {
      partDestroyedCount--
      if (partDestroyedCount <= 0) {
        isDamaged = true
        break
      }
    }
  }
  return isDamaged
}

let turretHorDriveDmPartQuery = ecs.SqQuery("turretHorDriveDmPartQuery", {
  comps_ro = [["turret_drive_dm_part__horDriveDm", ecs.TYPE_INT, null]]
})
let getTurretHorDriveDmPart = @(eid) turretHorDriveDmPartQuery.perform(eid, @(_, comp) comp["turret_drive_dm_part__horDriveDm"])

let turretVerDriveDmPartQuery = ecs.SqQuery("turretVerDriveDmPartQuery", {
  comps_ro = [["turret_drive_dm_part__verDriveDm", ecs.TYPE_INT, null]]
})
let getTurretVerDriveDmPart = @(eid) turretVerDriveDmPartQuery.perform(eid, @(_, comp) comp["turret_drive_dm_part__verDriveDm"])

let watchedVehicleDamage = mkEcsComputed({
  comps = [
    ["dm_phys_parts__enginePartIds", ecs.TYPE_INT_LIST, null],
    ["dm_phys_parts__transmissionPartIds", ecs.TYPE_INT_LIST, null],
    ["dm_phys_parts__tracksPartIds", ecs.TYPE_INT_LIST, null],
    ["dm_phys_parts__wheelsPartIds", ecs.TYPE_INT_LIST, null],
    ["dm_state", ecs.TYPE_UINT16_LIST],
    ["repairable__repairRequired", ecs.TYPE_BOOL, false],
    ["repairable__inProgress", ecs.TYPE_BOOL, false],
    ["turret_control__gunEids", ecs.TYPE_EID_LIST, null],
    ["vehicle__destroyedWheelsCountWarn", ecs.TYPE_INT, 0],
  ]
  comps_rq = ["vehicleWithWatched"]
})


let state = Computed(function() {
  let comp = watchedVehicleDamage.get()
  if (comp == null)
    return defValue

  let turretEids = comp.turret_control__gunEids ?? []
  let turretHorDriveParts = turretEids.map(getTurretHorDriveDmPart).filter(@(v) v != null)
  let turretVerDriveParts = turretEids.map(getTurretVerDriveDmPart).filter(@(v) v != null)
  return {
    vehicleEngineBroken = partDamagedIndicate(comp.dm_phys_parts__enginePartIds, comp.dm_state)
    vehicleTransmissionBroken = partDamagedIndicate(comp.dm_phys_parts__transmissionPartIds, comp.dm_state)
    vehicleTracksBroken = partDamagedIndicate(comp.dm_phys_parts__tracksPartIds, comp.dm_state)
    vehicleWheelsBroken = partDamagedIndicate(comp.dm_phys_parts__wheelsPartIds, comp.dm_state,
      comp.vehicle__destroyedWheelsCountWarn)
    vehicleTurretHorDriveBroken = partDamagedIndicate(turretHorDriveParts, comp.dm_state)
    vehicleTurretVerDriveBroken = partDamagedIndicate(turretVerDriveParts, comp.dm_state)
    vehiclePartDamaged = comp.repairable__repairRequired
    vehicleBeingRepaired = comp.repairable__inProgress
  }
})

let exportState = watchedTable2TableOfWatched(state)

return exportState
