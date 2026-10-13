from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_maintenance_state.nut" import hasRepairKit, hasExtinguisher, canMaintainVehicle, isRepairRequired, isExtinguishRequired, isRepairFromInsideAvailable
from "%ui/ui_library.nut" import *

function action() {
  let watch = [hasRepairKit, hasExtinguisher, canMaintainVehicle, isRepairRequired,
    isExtinguishRequired, isRepairFromInsideAvailable, inVehicle]
  let extinguishAvailable = canMaintainVehicle.get() && hasExtinguisher.get()
    && isExtinguishRequired.get()
  let repairAvailable = canMaintainVehicle.get() && hasRepairKit.get()
    && (isRepairFromInsideAvailable.get() || (!inVehicle.get() && isRepairRequired.get()))
  if (!extinguishAvailable && !repairAvailable)
    return { watch }

  return {
    watch
    children = tipCmp({
      text = extinguishAvailable ? loc("hud/extinguish", "Hold to extinguish")
        : (isRepairFromInsideAvailable.get() && inVehicle.get()) ? loc("hud/repair_from_inside")
        : loc("hud/repair", "Hold to repair")
      inputId = (isRepairFromInsideAvailable.get() && inVehicle.get())
        ? "Vehicle.InsideRepair"
        : "Human.VehicleMaintenance"
    })
  }
}

return action