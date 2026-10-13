from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, transpDarkPanelBgColor, darkTxtColor
from "%ui/state/eventState.nut" import mkEventPenaltyTime
from "%ui/helpers/time.nut" import secondsToTimeSimpleString
from "%ui/ui_library.nut" import *

function mkPenaltyText() {
  let eventPenaltyTime = mkEventPenaltyTime()
  return function() {
    let watch = eventPenaltyTime
    if (eventPenaltyTime.get() <= 0)
      return { watch }
    return {
      watch
      rendObj = ROBJ_SOLID
      color = transpDarkPanelBgColor
      padding = smallPadding
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_RIGHT
      children = {
        rendObj = ROBJ_TEXT
        text = loc("gameMode/penaltyTimer",
          { time = secondsToTimeSimpleString(eventPenaltyTime.get()) })
        color = darkTxtColor
      }.__update(fontSub)
    }
  }
}

return mkPenaltyText
