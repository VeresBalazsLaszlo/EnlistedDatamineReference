from "%ui/hud/state/enlisted_hero_state.nut" import isRadioMode
from "%ui/hud/state/mortar.nut" import isMortarMode
from "%ui/hud/state/health_state.nut" import isAlive, isDowned
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_free_seat_state.nut" import hasFreeSeat
from "%ui/ui_library.nut" import *

let canUseVehicle = Computed(@() isAlive.get() && !isDowned.get() && !isMortarMode.get() &&
  !isRadioMode.get() && !inVehicle.get())

function vehicleFreeSeatTip() {
  let watch = [canUseVehicle, hasFreeSeat]
  if (!canUseVehicle.get() || hasFreeSeat.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/vehcile_locked_by_seat_taken")
    })
  }
}

return vehicleFreeSeatTip