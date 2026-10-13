import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/currency/premium.nut" import hasPremium
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, midPadding, defTxtColor, selectedPanelBgColor, brightAccentColor
from "%ui/ui_library.nut" import *

let premiumTextTitle = @(sf) {
  rendObj = ROBJ_TEXT
  text = loc("premium/widgetTitle")
  behavior = Behaviors.TextArea
  color = sf & S_HOVER ? brightAccentColor : defTxtColor
}.__update(fontSub)

let premiumTextSubtitle = {
  rendObj = ROBJ_TEXT
  text = loc("premium/widgetSubtitle")
  color = brightAccentColor
}.__update(fontSub)

const bw = hdpx(2)
let mkEdge = @(sf, isLeftSide) {
  rendObj = ROBJ_FRAME
  size = const [hdpxi(16), FLEX]
  color = sf & S_HOVER ? brightAccentColor : selectedPanelBgColor
  borderWidth = [bw, isLeftSide ? bw : 0, bw, isLeftSide ? 0 : bw]
}

let x2Size = [hdpxi(40), hdpxi(34)]
let x2Image = {
  rendObj = ROBJ_IMAGE
  size = x2Size
  margin = const [hdpx(4), 0]
  image = Picture($"!ui/gameImage/premium_banner_x2.svg:{x2Size[0]}:{x2Size[1]}")
}

function mkPromoWidget(openWnd) {
  return function(srcWindow, srcComponent = null, override = {}){
    return watchElemState(@(sf) {
      behavior = Behaviors.Button
      onClick = @() openWnd(srcWindow, srcComponent)
      children = {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          mkEdge(sf, false)
          x2Image
          {
            flow = FLOW_VERTICAL
            size = FLEX_V
            margin = [0, 0, 0, midPadding]
            children = [
              premiumTextTitle(sf)
              premiumTextSubtitle
            ]
          }
          mkEdge(sf, true)
        ]
      }
    }.__update(override))
  }
}

function openPremiumWnd(srcWindow, srcComponent) {
  premiumWnd()
  sendBigQueryUIEvent("open_premium_window", srcWindow, srcComponent)
}

let premiumWidget = mkPromoWidget(openPremiumWnd)

let promoWidget = @(srcWindow, srcComponent = null, override = {}) @() {
  watch = [hasPremium]
  children = hasPremium.get() ? null : premiumWidget(srcWindow, srcComponent, override)
}

return {
  promoWidget
}