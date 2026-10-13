import "%ui/components/faComp.nut" as faComp
from "%ui/hud/state/vehicle_maintenance_state.nut" import isExtinguishing, isRepairing, maintenanceTime, maintenanceTotalTime
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/ui_library.nut" import *

let maintenanceTimer = mkCountdownTimer(maintenanceTime)
let maintenanceProgress = Computed(@() maintenanceTotalTime.get() > 0 ? (1 - (maintenanceTimer.get() / maintenanceTotalTime.get())) : 0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]
let maintenanceIndicatorSize = [hdpx(80), hdpx(80)]
let maintenanceIndicator = @(icon) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    faComp(icon, {
      color = Color(255, 255, 255)
      fontSize = hdpx(40)
    })
    {
      behavior = Behaviors.RtPropUpdate
      size = maintenanceIndicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * maintenanceProgress.get()
      }
    }
  ]
}

return function () {
  let action = isExtinguishing.get() ? "fire-extinguisher" : "wrench"

  return {
    watch = [maintenanceTime, maintenanceTimer]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = (maintenanceTime.get() > 0 && (isRepairing.get() || isExtinguishing.get())) ? maintenanceIndicator(action) : null
  }
}