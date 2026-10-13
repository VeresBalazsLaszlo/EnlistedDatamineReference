from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/hud/state/warnings.nut" import warningsList
from "%ui/style/designConst.nut" import strokeStyle
from "%ui/ui_library.nut" import *

let warnText = kwarg(@(locId, color = Color(255,120,120,255)) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color
  text = loc(locId)
  animations = [
    { prop=AnimProp.opacity, from=0.8, to=1.0, duration=0.6, play=true, loop=true, easing=CosineFull}
  ]
}.__update(fontHeading2, strokeStyle))

return function() {
  let curWarning = warningsList.get()?[0]
  return {
    watch = warningsList
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    size = FLEX_H
    children = curWarning ? warnText(curWarning, KWARG_NON_STRICT) : null
  }
}