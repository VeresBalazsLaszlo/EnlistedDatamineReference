import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
from "%ui/hud/state/squad_soldiers_menu_state.nut" import showSquadSoldiersMenu, squadSoldiersMenuItems, radius, elemSize
from "%ui/hud/components/squad_behavior.nut" import changeBehaviour, changeFormation
from "%ui/ui_library.nut" import *

let squadSoldiersMenu = mkPieMenu({
  actions = squadSoldiersMenuItems,
  showPieMenu = showSquadSoldiersMenu
  radius = radius,
  elemSize = elemSize
})

let squadBehaviorPanel = @() {
  watch = radius
  size = [radius.get() * 2, 0]
  pos = [radius.get() * 2 + hdpx(10), hdpx(90)]
  children = {
    stopMouse = true
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    padding = hdpx(5)
    children = [
      changeFormation
      changeBehaviour
    ]
  }
}

return freeze({
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    squadSoldiersMenu
    squadBehaviorPanel
  ]
  key = "squadSoldiersMenuTabs"
})
