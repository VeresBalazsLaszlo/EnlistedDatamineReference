import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
from "%ui/hud/state/building_tool_menu_state.nut" import showBuildingToolMenu, curBuildingToolMenuItems, radius, elemSize
from "%ui/ui_library.nut" import *

let buildingToolMenu = mkPieMenu({
  actions = curBuildingToolMenuItems,
  showPieMenu = showBuildingToolMenu
  radius = radius,
  elemSize = elemSize,
})

return {
  size = FLEX
  children = buildingToolMenu
  key = "buildMenuMenuTabs"
}
