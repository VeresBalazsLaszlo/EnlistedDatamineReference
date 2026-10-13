from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/style.nut" import FAIL_TEXT_COLOR, MY_SQUAD_TEXT_COLOR
from "%ui/hud/state/vehicle_damage_state.nut" import vehicleEngineBroken, vehicleTransmissionBroken, vehicleTracksBroken, vehicleWheelsBroken, vehicleTurretHorDriveBroken, vehicleTurretVerDriveBroken, vehiclePartDamaged, vehicleBeingRepaired
from "%ui/hud/state/vehicle_state.nut" import inVehicle, isVehicleAlive, isHighSpeedWarningEnabled, isFlapsCritical, isOverloadCritical
from "%ui/hud/state/health_state.nut" import isAlive
from "%sqstd/string.nut" import implode
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/state/vehicle_maintenance_state.nut" import isRepairing
from "%ui/ui_library.nut" import *

let vehicleCantMoveWarnings = [
  {state = vehicleEngineBroken, text = @() loc("hud/engine_broken", "engine broken")}
  {state = vehicleTransmissionBroken, text = @() loc("hud/transmission_broken", "transmission broken")}
  {state = vehicleTracksBroken, text = @() loc("hud/tracks_broken", "tracks broken")}
  {state = vehicleWheelsBroken, text = @() loc("hud/wheels_broken", "wheels broken")}
]

let vehicleTurretDriveWarnings = [
  {state = vehicleTurretHorDriveBroken, text = @() loc("hud/turret_hor_drive_broken", "horizontal drive broken")}
  {state = vehicleTurretVerDriveBroken, text = @() loc("hud/turret_ver_drive_broken", "vertical drive broken")}
]

let showVehicleWarnings = Computed(@() inVehicle.get() && isVehicleAlive.get() && isAlive.get())

let watch = [ showVehicleWarnings, vehiclePartDamaged, isHighSpeedWarningEnabled, isFlapsCritical,
    isOverloadCritical, vehicleBeingRepaired, isRepairing, isTutorial ]
  .extend(vehicleCantMoveWarnings.map(@(w) w.state), vehicleTurretDriveWarnings.map(@(w) w.state))

function mkTip(warnings, msgKey, msgDefVal) {
  let reasons = warnings.filter(@(w) w.state.get()).map(@(w) w.text())
  let text = reasons.len() > 0 ? loc(msgKey, msgDefVal, {reason = implode(reasons, ", ")}) : null
  return tipCmp({ text })
}

return function () {
  let children = []

  if (showVehicleWarnings.get()) {
    children.append(mkTip(vehicleCantMoveWarnings, "hud/vehicle_cant_move", "Vehicle can't move: {reason}")) 
    children.append(mkTip(vehicleTurretDriveWarnings, "hud/vehicle_turret_cant_move", "Vehicle turret can't move: {reason}")) 
    children.append(tipCmp({
      text = (isTutorial.get() ? vehicleTracksBroken.get() : vehiclePartDamaged.get())
        ? loc("hud/vehicle_part_damaged_warning", "A part of the vehicle is damaged, go out to fix it")
        : null
    }))
    children.append(tipCmp({
      text = vehicleBeingRepaired.get() && !isRepairing.get()
        ? loc("hud/vehicle_being_repaired_warning")
        : null
      style = { color = MY_SQUAD_TEXT_COLOR }
    }))
    children.append(tipCmp({
      text = isHighSpeedWarningEnabled.get() ? loc("hud/vehicle_high_speed_warning") : null
      style = { color = FAIL_TEXT_COLOR }
    }))
    if (isFlapsCritical.get())
      children.append(tipCmp({
        text = loc("hud/plane_flaps_critical_warning")
        style = { color = FAIL_TEXT_COLOR }
      }))
    if (isOverloadCritical.get())
      children.append(tipCmp({
        text = loc("hud/plane_overload_critical_warning")
        style = { color = FAIL_TEXT_COLOR }
      }))
  }

  return {
    watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(5)

    children
  }
}
