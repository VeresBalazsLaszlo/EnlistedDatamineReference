from "%ui/style/designConst.nut" import midPadding, isWide
from "%ui/ui_library.nut" import *

return {
  verticalGap = hdpx(54)
  localPadding = hdpx(36)
  rowHeight = hdpx(50)
  localGap = midPadding * 2
  armieChooseBlockWidth = hdpx(144)
  eventBlockWidth = isWide ? hdpx(280) : hdpx(230)
  lockIconSize = hdpxi(16)
}