from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/colors.nut" import TextHighlight, BtnTextHover
from "%ui/ui_library.nut" import *

let buildCounter = @(counterWatch, overrride = {}) @() {
  watch = counterWatch
  vplace = ALIGN_TOP
  pos = const [0, -hdpx(10)]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  color = TextHighlight
  fontFx = FFT_GLOW
  fontFxColor = BtnTextHover
  text = counterWatch.get()
}.__update(fontSub, overrride)

return buildCounter