from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import titleTxtColor
from "%ui/eventPass/eventTaskRewardsState.nut" import seasonEndTime
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTime
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = titleTxtColor }.__update(fontSub)
const tokenIconSize = hdpxi(22)

let dynamicSeasonBg = @(size, opacity) function() {
  let watch = [ bpEventSettings ]
  let { bpImageBgPath = null, seasonBgColor = null } = bpEventSettings.get()
  if (bpImageBgPath == null)
    return { watch }

  return {
    watch
    rendObj = ROBJ_IMAGE
    size
    opacity
    image = Picture(bpImageBgPath)
    color = seasonBgColor
  }
}

let eventPassIcon = @(size) function() {
  let { getBpImagePath } = bpEventSettings.get()
  return {
    watch = bpEventSettings
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture(getBpImagePath([size, size]))
  }
}

let timeTracker = @() {
  watch = seasonEndTime
  hplace = ALIGN_RIGHT
  children = mkSeasonTime(seasonEndTime.get(), {
      rendObj = ROBJ_TEXT
      text = loc("timeExpired")
    }.__update(defTxtStyle))
}

function tokenIconCmp() {
  let { getTokenIcon, starColor = titleTxtColor } = bpEventSettings.get()
  let size = [tokenIconSize, tokenIconSize]
  return {
    watch = bpEventSettings
    rendObj = ROBJ_IMAGE
    size
    color = starColor
    image = Picture(getTokenIcon(size))
  }
}

return {
  timeTracker
  eventPassIcon
  dynamicSeasonBg
  tokenIconCmp
}
