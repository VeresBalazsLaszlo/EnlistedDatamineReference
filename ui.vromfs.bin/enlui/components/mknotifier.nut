from "%ui/style/designConst.nut" import smallPadding, titleTxtColor, midPadding
from "%ui/ui_library.nut" import *

let mkNotifier = @(txt, customStyle = {}, bgStyle = {}, txtStyle = {}) {
  halign = ALIGN_CENTER
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = Color(0,100,0)
      animations = [
        { prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true, loop = true, easing = Blink }
      ]
    }.__update(bgStyle)
    {
        rendObj = ROBJ_TEXTAREA
        margin = [smallPadding, midPadding]
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        color = titleTxtColor
        text = txt
    }.__update(txtStyle)
  ]
}.__update(customStyle)

let blinkOnOverride = { key = "blink_on" }

return {
  mkNotifierBlink = @(txt, customStyle = {}, bgStyle = {}, txtStyle = {})
    mkNotifier(txt, customStyle, bgStyle.__merge(blinkOnOverride), txtStyle)
}