from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/hero_weapons.nut" import curWeaponIsGrenade, isThrowMode
from "%ui/hud/state/health_state.nut" import isDowned
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/enlisted_hero_state.nut" import isThrowDistanceIncreased
from "%ui/ui_library.nut" import *

let tipNormalThrow = tipCmp({
  text = loc("tips/throw_grenade", "Throw grenade")
  inputId = "Human.Shoot"
})

let tipLongThrow = tipCmp({
  text = loc("tips/throw_grenade_long", "Throw grenade (Throw range increased)")
  inputId = "Human.Shoot"
})

let tipFastLongThrow = tipCmp({
  text = loc("tips/throw_grenade_increased_range", "Throw range increased")
})

let showTip = Computed(@() !inVehicle.get() && !isDowned.get())
function throw_grenade() {
  return {
    watch = [showTip, isThrowDistanceIncreased, curWeaponIsGrenade, isThrowMode]
    children = !showTip.get()
      ? null
      : curWeaponIsGrenade.get()
        ? isThrowDistanceIncreased.get()
          ? tipLongThrow
          : tipNormalThrow
        : isThrowMode.get()
          ? isThrowDistanceIncreased.get()
            ? tipFastLongThrow
            : null
          : null
  }
}

return throw_grenade
