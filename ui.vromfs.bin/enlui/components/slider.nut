import "%ui/style/colors.nut" as colors
import "math" as math
from "%ui/style/sounds.nut" import buttonSound
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/ui_library.nut" import *

const sliderHeight = fsh(1)

let calcFrameColor = @(sf, isEnabled) !isEnabled ? colors.BtnBdDisabled
  : sf & S_KB_FOCUS ? colors.TextActive
  : sf & S_HOVER ? colors.TextHover
  : colors.comboboxBorderColor

const opaque = Color(0,0,0,255)
let calcKnobColor =  @(sf, isEnabled) !isEnabled ? colors.BtnActionBgDisabled
  : sf & S_KB_FOCUS ? (colors.TextActive | opaque)
  : sf & S_HOVER ? (colors.TextHover | opaque)
  : (colors.TextDefault | opaque)

let filledBgColor = @(sf, isEnabled) !isEnabled ? colors.BtnFilledBgDisabled
  : sf & S_HOVER ? colors.TextHighlight
  : colors.TextDefault

let scales = {}
scales.linear <- {
  to = @(value, minv, maxv) (value.tofloat() - minv) / (maxv - minv)
  from = @(factor, minv, maxv) factor.tofloat() * (maxv - minv) + minv
}
scales.logarithmic <- {
  to = @(value, minv, maxv) value == 0 ? 0 : math.log(value.tofloat() / minv) / math.log(maxv / minv)
  from = @(factor, minv, maxv) minv * math.pow(maxv / minv, factor)
}
scales.logarithmicWithZero <- {
  to = @(value, minv, maxv) scales.logarithmic.to(value.tofloat(), minv, maxv)
  from = @(factor, minv, maxv) factor == 0 ? 0 : scales.logarithmic.from(factor, minv, maxv)
}

let sliderLeftLoc = loc("slider/reduce", "Reduce value")
let sliderRightLoc = loc("slider/increase", "Increase value")

function slider(orient, var, options = {}) {
  let {
    gainObject = null, group = ElemGroup(), scaling = scales.linear,
    step = null, ignoreWheel = true, xmbNode = null, setValue = @(v) var.set(v),
    isEnabled = Watched(true)
  } = options

  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let rangeval = maxval - minval
  let unit = options?.unit && options?.scaling != scales.linear ? options?.unit
    : step ? step / rangeval
    : 0.01
  let pageScroll = options?.pageScroll ?? step ?? 0.05
  let knobStateFlags = Watched(0)
  let sliderStateFlags = Watched(0)
  let isEnabledWatched = isObservable(isEnabled) ? isEnabled : Watched(isEnabled)

  let knob = @() {
    watch = [knobStateFlags, isEnabledWatched]
    onElemState = @(sf) knobStateFlags.set(sf)
    size  = const [fsh(1), fsh(2)]
    color = calcKnobColor(knobStateFlags.get(), isEnabledWatched.get())
    rendObj = ROBJ_SOLID
    group
  }

  function onChange(factor){
    let value = scaling.from(factor, minval, maxval)
    let oldValue = var.get()
    setValue(value)
    if (oldValue != var.get())
      sound_play("ui/slider")
  }

  let hotkeysElem = {
    key = "hotkeys"
    hotkeys = [
      ["Left | J:D.Left", sliderLeftLoc, function() {
        let delta = maxval > minval ? -pageScroll : pageScroll
        onChange(clamp(scaling.to(var.get() + delta, minval, maxval), 0, 1))
      }],
      ["Right | J:D.Right", sliderRightLoc, function() {
        let delta = maxval > minval ? pageScroll : -pageScroll
        onChange(clamp(scaling.to(var.get() + delta, minval, maxval), 0, 1))
      }],
    ]
  }

  return function() {
    let factor = clamp(scaling.to(var.get(), minval, maxval), 0, 1)
    return {
      size = FLEX
      behavior = Behaviors.Slider
      sound = buttonSound
      watch = [var, sliderStateFlags, isEnabledWatched]
      orientation = orient
      min = 0
      max = 1
      unit
      pageScroll
      ignoreWheel
      fValue = factor
      knob
      onChange = isEnabledWatched.get() ? onChange : null
      onElemState = @(sf) sliderStateFlags.set(sf)
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      xmbNode
      children = [
        {
          group = group
          rendObj = ROBJ_SOLID
          color = filledBgColor(sliderStateFlags.get(), isEnabledWatched.get())
          size = [flex(factor), sliderHeight]
          children = [
            gainObject
            {
              rendObj = ROBJ_FRAME
              color = calcFrameColor(sliderStateFlags.get(), isEnabledWatched.get())
              borderWidth = const [hdpx(1),0,hdpx(1),hdpx(1)]
              size = FLEX
            }
          ]
        }
        knob
        {
          group = group
          rendObj = ROBJ_SOLID
          color = colors.ControlBgOpaque
          size = [flex(1.0 - factor), sliderHeight]
          halign = ALIGN_RIGHT
          children = {
            rendObj = ROBJ_FRAME
            color = calcFrameColor(sliderStateFlags.get(), isEnabledWatched.get())
            borderWidth = const [1,1,1,0]
            size = FLEX
          }
        }
        isEnabledWatched.get() && (sliderStateFlags.get() & S_HOVER) ? hotkeysElem  : null
      ]
    }
  }
}


return {
  Horiz = @(var, options = {}) slider(O_HORIZONTAL, var, options)
  scales
}
