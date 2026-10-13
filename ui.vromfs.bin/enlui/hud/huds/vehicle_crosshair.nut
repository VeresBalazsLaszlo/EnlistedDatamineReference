import "%ui/hud/state/vehicle_turret_overheat_state.nut" as overheat
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid
from "%ui/hud/state/vehicle_turret_state.nut" import currentMainTurretAmmo, currentMainTurretEid, turretsReload, vehicleTurrets
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/ui_library.nut" import *
from "vehicle.behaviors" import VehicleCrosshair

let circleProgressImage = Picture("ui/skin#scanner_range.avif")
const aim_color = Color(200, 200, 200, 150)
const aim_bgcolor = Color(0, 0, 0, 25)
const overheatFg = Color(160, 0, 0, 180)
const overheatBg = Color(0, 0, 0, 0)

let hasAmmo = Computed(@() (currentMainTurretAmmo.get()?.curAmmo ?? 0) + (currentMainTurretAmmo.get()?.totalAmmo ?? 0) > 0)
let mainTurretReload = Computed(@() turretsReload.get()?[currentMainTurretEid.get()] ?? {})
let reloadEndTime = Computed(@() mainTurretReload.get()?.endTime ?? -1)

let reloadTimer = mkCountdownTimer(reloadEndTime)
let vehicleReloadProgress = Computed(@()
  !hasAmmo.get() ? 0
    : (mainTurretReload.get()?.progressStopped ?? -1) >= 0 ? mainTurretReload.get().progressStopped
    : (mainTurretReload.get()?.totalTime ?? -1) > 0 ? max(0, (1 - (reloadTimer.get() / mainTurretReload.get().totalTime)))
    : 1.0
)

function bgAim(){
  return {
    color = aim_bgcolor
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = fsh(4.0)
    commands = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
  }
}

function aim(){
  return {
    color = aim_color
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = fsh(4.0)
    watch = vehicleReloadProgress
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_SECTOR, 50, 50, 50, 50, -90.0, -90.0 + (vehicleReloadProgress.get() ?? 1.0) * 360.0],
    ]
  }
}

function overheatBlock() {
  return {
    watch = overheat
    opacity = min(1.0, overheat.get()*2.0)
    fValue = overheat.get()
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = circleProgressImage
    size = fsh(4)
    fgColor = overheatFg
    bgColor = overheatBg
  }
}

let crosshair = @() {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  behavior = VehicleCrosshair
  transform = true

  watch = controlledVehicleEid
  eid = controlledVehicleEid.get()

  children = [bgAim aim overheatBlock]
}

let isCrosshairEnabled = Computed(@() vehicleTurrets.get().findvalue(@(turret) turret.showCrosshair && !turret.isLocalControlLocked) != null)

function root() {
  return {
    watch = isCrosshairEnabled
    size = FLEX
    children = isCrosshairEnabled.get() ? crosshair : null
  }
}


return root
