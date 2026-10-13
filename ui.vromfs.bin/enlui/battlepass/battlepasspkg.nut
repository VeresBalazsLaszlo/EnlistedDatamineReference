from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import titleTxtColor
from "%ui/battlepass/bpState.nut" import seasonEndTime, seasonIndex
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTime
from "%ui/battlepass/battlepass_presentation.nut" import getBpPresentation
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = titleTxtColor }.__update(fontSub)

const customImagePath = "!ui/uiskin/battlepass/bp_seasons/{0}.svg:{1}:{1}:K"
const imagePath = "!ui/uiskin/battlepass/bp_seasons/bp_season_{0}.svg:{1}:{1}:K"
const bpBgPath = "!ui/uiskin/battlepass/bp_seasons/bp_bg_white.avif"

function staticSeasonBPIcon(seasonBPIndex, size) {
  let { icon } = getBpPresentation(seasonIndex.get())
  let fallbackImage = $"!ui/uiskin/battlepass/bp_logo.svg:{size}:{size}:K"
  let bpImagePath = icon ? customImagePath.subst(icon, size)
    : (seasonBPIndex ?? 0) > 0 ? imagePath.subst(seasonBPIndex, size)
    : fallbackImage
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture(bpImagePath)
    fallbackImage = Picture(fallbackImage)
  }
}


let dynamicSeasonBpBg = @(size, opacity) function() {
  let { bgColor } = getBpPresentation(seasonIndex.get())
  return {
    watch = seasonIndex
    rendObj = ROBJ_IMAGE
    size
    opacity
    image = Picture(bpBgPath)
    color = bgColor
  }
}

let dynamicSeasonBPIcon = @(size) @()
  staticSeasonBPIcon(seasonIndex.get(), size).__update({ watch = seasonIndex })

let timeTracker = @() {
  watch = seasonEndTime
  hplace = ALIGN_RIGHT
  children = mkSeasonTime(seasonEndTime.get(), {
      rendObj = ROBJ_TEXT
      text = loc("timeExpired")
    }.__update(defTxtStyle))
}


return {
  timeTracker
  dynamicSeasonBPIcon
  staticSeasonBPIcon
  dynamicSeasonBpBg
}
