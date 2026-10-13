import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
from "%ui/hud/state/vehicle_repair_menu_state.nut" import showRepairMenu, repairMenuItems, repairMenuItemIdx, radius, elemSize
from "%ui/ui_library.nut" import *

let menu = mkPieMenu({
  actions = repairMenuItems
  curIdx = repairMenuItemIdx
  showPieMenu = showRepairMenu
  radius = radius,
  elemSize = elemSize,
  stickNo = 0
})

return {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = menu
  key = "vehicleRepairMenuTabs"
}
