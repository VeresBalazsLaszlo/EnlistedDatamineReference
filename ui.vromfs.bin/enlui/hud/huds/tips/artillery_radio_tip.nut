from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/hero_weapons.nut" import curWeaponWeapType
from "%ui/hud/state/enlisted_hero_state.nut" import isRadioMode
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  text = loc("tips/use_radio", "Use radio")
  inputId = "Human.Shoot"
})

let showTip = Computed(@() !inVehicle.get() && !isRadioMode.get() && curWeaponWeapType.get() == "radio")

function use_radio() {
  let watch = showTip
  if (!showTip.get())
    return { watch }

  return {
    watch
    children = tip
  }
}

return use_radio
