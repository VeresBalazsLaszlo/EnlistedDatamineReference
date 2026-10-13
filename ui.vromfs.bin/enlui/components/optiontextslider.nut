from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *

let slider = require("%ui/components/slider.nut")

let slider_value_width = calc_str_box("200%", fontBody)[0]

return function(opt, _group, xmbNode, morphText = @(val) val) {
  let valWatch = opt.var
  return {
    size = FLEX
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = fsh(1)

    children = [
      slider.Horiz(valWatch, opt.__merge({xmbNode}))
      @() {
        watch = valWatch
        size = [slider_value_width, SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        color = DEFAULT_TEXT_COLOR
        text = morphText(valWatch.get())
      }.__update(fontBody)
    ]
  }
}