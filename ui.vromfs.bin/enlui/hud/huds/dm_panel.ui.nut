from "%ui/hud/state/dm_panel.nut" import isVisible
from "%ui/ui_library.nut" import *
from "dm.behaviors" import DMPanel

let dmBarSize = [hdpx(200), hdpx(200)]
const dmBarPadding = hdpx(10)

return @() {
  watch = [isVisible]
  size = !isVisible.get() ? null : dmBarSize
  children = !isVisible.get() ? null : {
    rendObj = ROBJ_WORLD_BLUR
    fillColor = Color(0,0,0,80)
    size = FLEX
    padding = dmBarPadding
    children = {
      size = FLEX
      rendObj = ROBJ_XRAYDOLL
      behavior = DMPanel
    }
  }
}