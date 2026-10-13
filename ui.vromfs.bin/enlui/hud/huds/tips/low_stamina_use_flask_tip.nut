import "%ui/hud/state/free_fall_state.nut" as isFreeFall
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/flask.nut" import hasHeroFlask, flaskAffectApplied
from "%ui/hud/state/stamina_es.nut" import staminaUseFlask
from "%ui/hud/state/parachute_state.nut" import isParachuteOpened
from "%ui/hud/state/hero_water_state.nut" import isUnderWater, isSwimming
from "%ui/hud/state/burning_state_es.nut" import isBurning
from "%ui/hud/state/vehicle_state.nut" import inVehicle, isPassenger
from "%ui/ui_library.nut" import *

let canUseFlask = Computed(@() hasHeroFlask.get()
  && !isFreeFall.get()
  && !isParachuteOpened.get()
  && !isUnderWater.get()
  && !isSwimming.get()
  && !isBurning.get()
  && (!inVehicle.get() || isPassenger.get()))

let tip = tipCmp({
  text = loc("tips/use_flask"),
  inputId = "Inventory.UseFlask"
})

return @() {
  watch = [staminaUseFlask, flaskAffectApplied, canUseFlask]
  children = canUseFlask.get() && !flaskAffectApplied.get() && staminaUseFlask.get() ? tip : null
}
