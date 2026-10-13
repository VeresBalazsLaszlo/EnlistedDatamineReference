import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/components/textButton.nut" import textColor, primaryStyle
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/ui_library.nut" import *

function activatePremiumText(sf) {
  let bonus = gameProfile.get()?.premiumBonuses.soldiersReserve ?? 0
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = const [hdpx(8), hdpx(20), hdpx(8), hdpx(50)]
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        color = textColor(sf, primaryStyle)
        text = loc("btn/reserveSize", {addSize = bonus})
      }.__update(fontHeading2)
      premiumImage(hdpx(30))
    ]
  }
}

let activatePremiumBtn = {
  text = function(textComp, params, handler, group, sf) {
    textComp = activatePremiumText(sf)
    params = fontHeading2
    return textButtonTextCtor(textComp, params, handler, group, sf)
  }
  action = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", "army_shop", "reserve_full_message")
  }
}

return activatePremiumBtn