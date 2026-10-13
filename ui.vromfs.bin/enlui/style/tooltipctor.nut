from "%ui/style/designConst.nut" import darkPanelBgColor, midPadding, disabledTxtColor, commonBorderRadius
from "%ui/ui_library.nut" import *

return @(content, size = SIZE_TO_CONTENT) {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = mul_color(darkPanelBgColor, 0.95)
  borderColor = disabledTxtColor
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  size
  padding = midPadding
  children = content
}
