import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/currency/premiumWnd.nut" as premiumWnd
import "%ui/components/mkGlareAnim.nut" as mkGlare
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import panelBgColor, midPadding, hoverSlotBgColor
from "%ui/style/cursors.nut" import setTooltip
from "%ui/currency/premiumComp.nut" import premiumActiveInfo, premiumImage, premiumBg
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/shop/armyShopState.nut" import premiumProducts
from "%ui/components/mkNotifier.nut" import mkNotifierBlink
from "%ui/currency/premium.nut" import hasPremium
from "%ui/ui_library.nut" import *

let IMAGE_WIDTH = hdpxi(62) - midPadding * 2
const btnWidth = hdpxi(62)


let hasDiscount = Computed(@() premiumProducts.get().findindex(@(i)
  (i?.discountInPercent ?? 0) > 0) != null)

let glareAnim = mkGlare({
  nestWidth = btnWidth
  glareWidth = btnWidth / 3
  glareDuration = 0.7
  glareOpacity = 0.5
  glareDelay = 5
})

let premiumWidget = watchElemState(@(sf) {
  watch = [hasDiscount, hasPremium]
  size = const [btnWidth, btnWidth]
  vplace = ALIGN_TOP
  behavior = Behaviors.Button
  onClick = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", null, "menubar_premium")
  }
  onHover = @(on) setTooltip(on
    ? tooltipCtor(premiumActiveInfo())
    : null)
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
    active = "ui/enlist/button_action"
  }
  animations = hasPremium.get() ? null
    : [{prop = AnimProp.color, from = panelBgColor, to = 0xFF302438, duration = 3,
        loop = true, play = true, easing = CosineFull }]
  children = {
    rendObj = ROBJ_SOLID
    color = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
    size = const [btnWidth, btnWidth]
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_IMAGE
        opacity = sf & S_HOVER ? 1 : 0.6
        size = const [btnWidth, btnWidth]
        image = premiumBg(btnWidth)
      }
      premiumImage(IMAGE_WIDTH)
      !hasDiscount.get() ? null
        : mkNotifierBlink(loc("shop/discountNotify"), {
            size = SIZE_TO_CONTENT,
            vplace = ALIGN_BOTTOM
          }, {}, fontSub)
      hasPremium.get() ? null : glareAnim
    ]
  }
})

return premiumWidget
