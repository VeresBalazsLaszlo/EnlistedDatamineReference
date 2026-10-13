from "%ui/style/designConst.nut" import accentColor, titleTxtColor, defTxtColor, smallPadding, darkTxtColor, hoverPanelBgColor, darkPanelBgColor
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/ui_library.nut" import *

let knobSize = [hdpxi(14), hdpxi(14)]

let calcEmptyFrameColor = @(sf, isEnabled) !isEnabled ? hoverPanelBgColor
  : sf & S_HOVER ? darkPanelBgColor
  : hoverPanelBgColor

let calcKnobFrameColor = @(sf, isEnabled) !isEnabled ? hoverPanelBgColor
  : sf & S_ACTIVE ? darkTxtColor
  : sf & S_HOVER ? hoverPanelBgColor
  : accentColor



let defLabelStyle = {
  color = defTxtColor
}.__update(fontSub)


let hoverLabelStyle = {
  color = titleTxtColor
}.__update(fontSub)


function mkSlider(var, label, options = {}) {
  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let setValue = options?.setValue ?? @(v) var.set(v)
  let rangeval = maxval - minval
  let step = options?.step ?? 0
  let unit = (options?.unit ?? step) ? step / rangeval : 0.01
  let isEnabled = options?.isEnabled ?? true
  let group = ElemGroup()

  let knob = watchElemState(@(sf) {
    size = knobSize
    group
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [[ VECTOR_ELLIPSE, 0, 50, 50, 50 ]]
    fillColor = !isEnabled ? darkTxtColor : accentColor
    color = calcKnobFrameColor(sf, isEnabled)
  })

  let sliderText = @(text, sf) {
    rendObj = ROBJ_TEXT
    group
    text
  }.__update(isEnabled && (sf & S_HOVER) ? hoverLabelStyle : defLabelStyle)


  function onChange(factor){
    let value = factor.tofloat() * (maxval - minval) + minval
    if (!isEnabled)
      return
    setValue(value)
  }

  return watchElemState(function(sf) {
    let factor = clamp((var.get().tofloat() - minval) / (maxval - minval), 0, 1)
    let valueToShow = options?.valueToShow ?? var.get()
    return {
      watch = var
      size = FLEX_H
      behavior = Behaviors.Slider
      min = 0
      max = 1
      unit
      ignoreWheel = true
      group
      fValue = factor
      onChange
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          size = FLEX_H
          children = [
            sliderText(label, sf)
            sliderText(valueToShow, sf).__update({ hplace = ALIGN_RIGHT })
          ]
        }
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          children = [
            {
              flow = FLOW_HORIZONTAL
              size = const [FLEX, hdpx(6)]
              children = [
                {
                  group
                  rendObj = ROBJ_BOX
                  size = [flex(factor), FLEX]
                  fillColor = isEnabled ? hoverPanelBgColor : accentColor
                  borderWidth = sf & S_HOVER ? hdpx(1) : hdpx(0)
                  borderRadius = factor < 100.0 ? [hdpx(2), 0, 0, hdpx(2)] : hdpx(2)
                  borderColor = accentColor
                }
                {
                  group
                  rendObj = ROBJ_BOX
                  fillColor = calcEmptyFrameColor(sf, isEnabled)
                  borderRadius = factor > 0.0 ? [0, hdpx(2), hdpx(2), 0] : hdpx(2)
                  size = [flex(1.0 - factor), FLEX]
                }
              ]
            }
            {
              pos = [pw(factor * 100), 0]
              children = knob
            }
          ]
        }
      ]
    }
  })
}


return mkSlider