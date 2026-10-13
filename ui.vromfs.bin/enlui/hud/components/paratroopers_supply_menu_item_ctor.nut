from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *

let mkText = @(slot) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(slot?.text ?? "")
  color = DEFAULT_TEXT_COLOR
  indent = hdpx(5)
  transform = true
}.__update(fontSub)

return @(slot) function(...) {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    children = mkText(slot)
  }
}
