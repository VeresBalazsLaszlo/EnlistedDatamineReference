import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
from "%ui/hud/state/pie_menu_state.nut" import showPieMenu, pieMenuLayer, curPieMenuItems, radius, elemSize
from "%ui/hud/components/piemenu_navigation.nut" import pieMenuNavigation
from "%ui/hud/state/wallposters_use_state.nut" import canUseWallposter
from "%ui/ui_library.nut" import *

let pieMenu = mkPieMenu({
  actions = curPieMenuItems,
  showPieMenu = showPieMenu
  radius = radius,
  elemSize = elemSize,
  key = "pieMenu"
})

canUseWallposter.subscribe(@(val) !val ? pieMenuLayer.get() == 0 ? pieMenuLayer.set(1) : null : null)

return freeze({
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    pieMenu
    pieMenuNavigation
  ]
  key = "pieMenuTabs"
})
