from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/vehicle_maintenance_state.nut" import vehicleRepairTime, isInsideRepair
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/helpers/time.nut" import secondsToTimeSimpleString
from "%ui/ui_library.nut" import *

let repairTimer = mkCountdownTimer(vehicleRepairTime)
return function () {
  let watch = [ inVehicle, vehicleRepairTime, repairTimer, isInsideRepair ]
  if (!inVehicle.get() || isInsideRepair.get() || vehicleRepairTime.get() <= 0)
    return { watch }

  return {
    watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tipCmp({
      text = loc("hud/vehicle_repair", "Vehicle repair in progress, {time} left",
        {time = secondsToTimeSimpleString(repairTimer.get())})
    })
  }
}