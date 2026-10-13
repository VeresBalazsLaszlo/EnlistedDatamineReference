import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
from "%ui/hud/state/paratroopers_supply_menu_state.nut" import showSupplyMenu, squadSupplyMenuItems, selectedSupplyMenuItemIdx, radius, elemSize
from "%ui/ui_library.nut" import *

let menu = mkPieMenu({
  actions = squadSupplyMenuItems,
  curIdx = selectedSupplyMenuItemIdx,
  showPieMenu = showSupplyMenu
  radius = radius,
  elemSize = elemSize,
  stickNo = 0
})

return {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = menu
  key = "paratroopersSupplyMenuTabs"
}
