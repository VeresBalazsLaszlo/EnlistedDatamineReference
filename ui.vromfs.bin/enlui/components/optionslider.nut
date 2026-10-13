from "%ui/ui_library.nut" import *

let slider = require("%ui/components/slider.nut")

let optionSlider = @(opt, group, xmbNode) {
  size = FLEX
  children = slider.Horiz(opt.var, { min = 0, max = 1, unit = 0.1,
    scaling = slider.scales.linear, pageScroll = 0.1,
    setValue = null, group, xmbNode
  }.__update(opt))
}

let export = class {
  _call = @(_self, opt, group, xmbNode) optionSlider(opt, group, xmbNode)
  scales = slider.scales
}()

return export
