from "%ui/style/designConst.nut" import accentColor, titleTxtColor, defBdColor, commonBorderRadius
from "%ui/style/cursors.nut" import setTooltip
from "%ui/helpers/time.nut" import secondsToString
from "%ui/ui_library.nut" import *

function mkTimeLine(var, options={}) {
  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let group = ElemGroup()


  let setValue = options?.setValue ?? @(v) var.set(v)
  function onChange(factor){
    let value = factor.tofloat() * (maxval - minval) + minval
    if (!(options?.canChangeVal ?? true))
      return
    setValue(value)
  }

  return function() {
    let factor = clamp((var.get().tofloat() - minval) / (maxval - minval), 0, 1)
    return {
      watch = var
      size = const [FLEX, hdpx(16)]
      behavior = Behaviors.Slider
      min = 0
      max = 1
      unit = 0.001
      group
      fValue = factor
      onChange
      onSliderMouseMove = @(val) setTooltip(val == null ? null : secondsToString(val.tofloat() * (maxval - minval) + minval))
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          size = FLEX
          children = [
            {
              group
              rendObj = ROBJ_BOX
              size = [flex(factor), FLEX]
              fillColor = titleTxtColor
              borderRadius = factor < 1.0
                ? [commonBorderRadius, 0, 0, commonBorderRadius]
                : commonBorderRadius
              borderColor = accentColor
            }
            {
              group
              rendObj = ROBJ_BOX
              fillColor = defBdColor
              borderRadius = factor > 0.0
                ? [0, commonBorderRadius, commonBorderRadius, 0]
                : commonBorderRadius
              size = [flex(1.0 - factor), FLEX]
            }
          ]
        }
      ]
    }
  }
}


return mkTimeLine