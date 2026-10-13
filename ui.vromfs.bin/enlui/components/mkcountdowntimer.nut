import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/style/designConst.nut" import smallPadding, accentTitleTxtColor, defTxtColor
from "%ui/ui_library.nut" import *

const timerIcon = "ui/skin#battlepass/boost_time.svg"
const defTimerSize = hdpxi(13)
let mkClockIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = const [defTimerSize, defTimerSize]
  image = Picture($"{timerIcon}:{defTimerSize}:{defTimerSize}")
  color
}

function mkTimer(timestamp, prefixLocId = "", expiredLocId = "timeExpired",
  color = accentTitleTxtColor, prefixColor = defTxtColor, override = {}
) {
  let prefixTxt = loc(prefixLocId)
  let expiredTxt = loc(expiredLocId)
  let expireSec = Computed(@() max(timestamp - serverTime.get(), 0))

  return function() {
    let expireSecVal = expireSec.get()
    let hasExpired = expireSecVal <= 0

    return {
      watch = expireSec
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        hasExpired || prefixTxt == "" ? null
          : {
              rendObj = ROBJ_TEXT
              text = prefixTxt
              color = prefixColor
            }.__update(fontSub)
        hasExpired ? null : mkClockIcon(color)
        {
          rendObj = ROBJ_TEXT
          text = hasExpired ? expiredTxt : secondsToHoursLoc(expireSecVal)
          color
        }.__update(fontSub)
      ]
    }.__update(override)
  }
}

return kwarg(mkTimer)
