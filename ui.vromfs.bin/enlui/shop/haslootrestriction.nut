import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/style/fontsStyle.nut" import fontBody
from "auth" import get_country_code
from "%ui/meta/metaConfigUpdater.nut" import isLootBoxProhibited, setProhibitingLootbox, ProhibitionStatus
from "settings" import get_setting_by_blk_path
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/style/designConst.nut" import midPadding
from "%ui/ui_library.nut" import *

let isCountryProhibited = mkWatched(persist, "isCountryProhibited", false)
let skipCountryCheck = mkWatched(persist, "skipCountryCheck", false)

let prohibitionCountriesList = get_setting_by_blk_path("countriesProhibitingLootbox")
let getCountryName = @() loc("country/{0}".subst(get_country_code().tolower()))

userInfo.subscribe(function(data) {
  if (!data)
    return

  let countryCode = get_country_code().tolower()
  let prohibitedMode = prohibitionCountriesList?[countryCode]
  let isProhibited = prohibitedMode == "ask"
  if (!isProhibited)
    setProhibitingLootbox(ProhibitionStatus.Allowed)
  isCountryProhibited.set(isProhibited)
})

function checkLootRestriction(cb, comp, crateContent) {
  if (skipCountryCheck.get() ||
      !(isCountryProhibited.get() || isLootBoxProhibited.get())) {
    cb?()
    return
  }

  let { content = null } = crateContent?.get()
  let { soldierTierMin = -1, soldierHasMaxStats = true, amount = 0, maxAmount = 0,
    isLootbox = false } = content

  let isContentLootbox = amount < maxAmount
    || isLootbox
    || (soldierTierMin > 0 && !soldierHasMaxStats)
  if (!isContentLootbox) {
    cb?()
    return
  }

  function onDecline() {
    
    skipCountryCheck.set(true)
    setProhibitingLootbox(ProhibitionStatus.Allowed)
    cb?()
  }

  function onAccept() {
    
    showMessageWithContent({
      content = {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = hdpx(10)
        children = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("countryRestriction/confirmation", { country = getCountryName() })
        }.__update(fontBody)
      }
      buttons = [
        {
          text = loc("Yes"),
          action = function() {
            skipCountryCheck.set(true)
            setProhibitingLootbox(ProhibitionStatus.Prohibited)
            cb?()
          }
        }
        {
          text = loc("notFrom", { country = getCountryName() }),
          action = onDecline,
          isCancel = true
        }
      ]
    })
  }

  let { itemView, description } = comp

  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = midPadding
      children = [
        itemView
        description
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = const [sw(50), SIZE_TO_CONTENT]
          maxWidth = hdpx(1000)
          text = loc("countryRestriction", { country = getCountryName() })
        }.__update(fontBody)
      ]
    }
    buttons = [
      { text = loc("buyAnyway"), action = onAccept, isCurrent = true }
      { text = loc("notFrom", { country = getCountryName() }), action = onDecline}
      { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
  })
}

console_register_command(function() {
  skipCountryCheck.set(false)
  setProhibitingLootbox(ProhibitionStatus.Prohibited)
}, "debug.resetLootboxCheck")

return checkLootRestriction
