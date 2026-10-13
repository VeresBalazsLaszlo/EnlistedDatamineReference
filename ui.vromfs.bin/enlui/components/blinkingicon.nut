import "%ui/components/faComp.nut" as faComp
from "%ui/style/designConst.nut" import unseenColor, brightAccentColor
from "%ui/ui_library.nut" import *

let defcomps = require("%ui/components/defcomps.nut")


let fxOverride = {
  fontFxColor = 0xAA000000
  fontFxFactor = hdpx(16)
  fontFx = FFT_SHADOW
  fontFxOffsX = hdpx(1)
  fontFxOffsY = hdpx(1)
}


let warningIcon = @(iconId, text = null, color = unseenColor) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  margin = const [hdpx(2), hdpx(3), 0, 0]
  gap = hdpx(1)
  children = [
    faComp(iconId, {
      fontSize = hdpx(13)
      color
    }.__update(fxOverride))
    text != null ? defcomps.note({ text, color }) : null
  ]
}

let blinkingIcon = @(iconId, text = null, color = unseenColor)
  warningIcon(iconId, text, color).__update({
    transform = true
    animations = [{
      prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1,
      play = true, loop = true, easing = Blink
    }]
  })


let manageBlinkingObject = {
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth = hdpx(2)
  borderColor = brightAccentColor
  fillColor = 0x33333333
  animations = [{
    prop = AnimProp.opacity, from = 1, to = 0, duration = 1,
    play = true, loop = true, easing = Blink
  }]
}


return {
  warningIcon
  blinkingIcon
  manageBlinkingObject
}
