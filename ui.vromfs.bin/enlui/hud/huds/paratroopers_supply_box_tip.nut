from "%ui/hud/state/paratroopers_supply_box_state.nut" import showParatroopersSupplyBoxTip
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

function paratroopers_supply_box_tip() {
  let watch = showParatroopersSupplyBoxTip
  if (!showParatroopersSupplyBoxTip.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/use_paratroopers_supply_box")
      inputId = "Human.SupplyMenu"
    })
  }
}

return paratroopers_supply_box_tip
