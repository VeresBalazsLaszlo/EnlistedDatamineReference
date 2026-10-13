from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/hero_weapons.nut" import curWeaponFiringMode, curWeaponHasScope, curWeaponAmmo
from "%ui/hud/huds/crosshair_state_es.nut" import isAiming
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  inputId = "Human.Shoot"
  text = loc("tips/prevent_reloading")
})

let isPreventReloadingVisible = Computed(@() isAiming.get()
  && !inVehicle.get()
  && curWeaponHasScope.get()
  && curWeaponFiringMode.get() == "bolt_action"
  && curWeaponAmmo.get() > 0)

return @() {
  watch = isPreventReloadingVisible
  children = isPreventReloadingVisible.get() ? tip : null
}
