from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import isVehicleAlive, isPlaneOnCarrier
from "%ui/ui_library.nut" import *

function throttle() {
  let watch = [isPlaneOnCarrier, isVehicleAlive]
  if (!isPlaneOnCarrier.get() || !isVehicleAlive.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/planeTakeOffIncreaseThrottle")
      inputId = "Plane.Throttle"
    })
  }
}

function rudder() {
  let watch = [isPlaneOnCarrier, isVehicleAlive]
  if (!isPlaneOnCarrier.get() || !isVehicleAlive.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/planeTakeOffUseRudder")
      inputId = "Plane.Rudder"
    })
  }
}

return freeze([
  rudder
  throttle
])