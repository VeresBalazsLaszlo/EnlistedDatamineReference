import "%ui/components/colorize.nut" as colorize
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/currency/premium.nut" import premiumActiveTime, hasPremium
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, hasPremiumColor
from "%ui/ui_library.nut" import *

const premiumBtnSize = hdpxi(62)

let premiumImagePath = @(size) "ui/skin#currency/enlisted_prem.svg:{0}:{0}"
  .subst(size.tointeger())

let premiumGreyImagePath = @(size) "ui/skin#currency/enlisted_prem_grey.svg:{0}:{0}"
  .subst(size.tointeger())

let premiumImage = @(size, override = {}) @() {
  watch = hasPremium
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(premiumImagePath(size))
  color = hasPremium.get() ? Color(255,255,255) : Color(120,120,120)
}.__update(override)

let premiumGreyImage = @(size, color) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(premiumGreyImagePath(size))
  keepAspect = KEEP_ASPECT_FIT
  color
}

function premiumActiveInfo(customStyle = {}, premColor = hasPremiumColor) {
  let timeLeft = Computed(@()
    premiumActiveTime.get() > 0 ? secondsToHoursLoc(premiumActiveTime.get()) : null)
  return @() timeLeft.get()
    ? {
        watch = timeLeft
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = activeTxtColor
        text = utf8ToUpper("{0} {1}".subst(loc("premium/activated"),
          loc("premium/activatedLeft", { timeInfo = colorize(premColor, timeLeft.get()) })))
      }.__update(fontSub, customStyle)
    : {
        watch = timeLeft
        rendObj = ROBJ_TEXT
        color =  defTxtColor
        text = utf8ToUpper(loc("premium/notActivated"))
      }.__update(fontSub, customStyle)
}


let premiumBg = @(size) Picture("!ui/uiskin/premium/prem_bg.svg:{0}:{0}:K".subst(size))

return {
  premiumImage
  premiumGreyImage
  premiumActiveInfo
  premiumBtnSize
  premiumBg
}
