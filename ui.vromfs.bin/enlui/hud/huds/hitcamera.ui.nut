from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/state/hitcamera.nut" import isVisible, totalMembersBeforeShot, deadMembers
from "xray_ui_order" import set_xray_before_ui
from "%ui/ui_library.nut" import *
from "dm.behaviors" import HitCamera

return function() {
  let watch = isVisible
  if (!isVisible.get())
    return { watch }

  set_xray_before_ui(false)

  return {
    watch
    size = const [hdpx(432), hdpx(198)]
    children = {
      rendObj = ROBJ_WORLD_BLUR
      fillColor = Color(0, 0, 0, 80)
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        {
          rendObj = ROBJ_TEXT
          color = Color(190, 190, 190, 180)
          text = (totalMembersBeforeShot.get() == 0) ? loc("hitcameraKillledMembers/empty")
            : (deadMembers.get() == 0) ? loc("hitcameraKillledMembers/notKilled")
            : loc("hitcameraKillledMembers/killed", { deadMembers = deadMembers.get() })
        }.__update(fontBody)
        {
          size = FLEX
          behavior = HitCamera
        }
      ]
    }
  }
}
