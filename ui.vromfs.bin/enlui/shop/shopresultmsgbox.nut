import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2, fontHeading1
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/meta/servProfile.nut" import purchasesExt
from "%ui/style/designConst.nut" import activeTxtColor, gap, midPadding, accentTitleTxtColor
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/shop/shopPkg.nut" import mkShopItemView
from "%ui/style/colors.nut" import borderColor
from "%ui/state/login_state.nut" import isLoggedIn
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/purchasesExt"
const SEEN_PERIOD_IN_SEC = 86400

let debugPurchases = Watched(null)
let seen = Computed(@() settings.get()?[SEEN_ID])

let unseenPurchasesExt = keepref(Computed(function() {
  if (!onlineSettingUpdated.get() || !isLoggedIn.get())
    return {}

  let time = serverTime.get()
  if (time <= 0)
    return {}

  let purchaseList = []
  let sItems = shopItems.get()
  let seenPurchasesExt = seen.get()
  foreach (guid, purchaseInfo in debugPurchases.get() ?? purchasesExt.get()) {
    if (time - purchaseInfo.lastTimestamp > SEEN_PERIOD_IN_SEC)
      continue

    let amount = purchaseInfo.amount - (seenPurchasesExt?[guid] ?? 0)
    if (amount <= 0)
      continue

    let shopItem = sItems.findvalue(@(item) item?.purchaseGuid == guid)
    if (shopItem == null || (shopItem?.isHidden ?? false))
      continue

    let { nameLocId = "" } = shopItem
    if (nameLocId == "")
      continue

    purchaseList.append({ guid, amount, shopItem, nameText = loc(nameLocId) })
  }
  return purchaseList
}))

function markSeen(purchases) {
  settings.mutate(function(set) {
    let saved = (set?[SEEN_ID] ?? {})
      .__merge(purchases.map(@(v) v.amount))
    set[SEEN_ID] <- saved
  })
}

function resetSeen() {
  settings.mutate(@(v) v.$rawdelete(SEEN_ID))
}

function mkShopItemSingleResult(purchase) {
  let { amount, shopItem } = purchase
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    midPadding
    children = [
      {
        rendObj = ROBJ_SOLID
        size = const [fsh(50), fsh(25)]
        padding = hdpx(1)
        color = borderColor(0, false)
        clipChildren = true
        children = mkShopItemView({ shopItem })
      }
      amount <= 1 ? null
        : {
            rendObj = ROBJ_TEXT
            text = loc("common/amountShort", { count = amount })
            padding = midPadding
            color = activeTxtColor
          }.__update(fontHeading1)
    ]
  }
}

let mkShopItemMultiResult = @(purchases)
  purchases.map(function(purchase) {
    let { amount, nameText } = purchase
    return {
      flow = FLOW_HORIZONTAL
      gap
      children = [
        {
          rendObj = ROBJ_TEXT
          text = nameText
          color = accentTitleTxtColor
        }.__update(fontBody)
        amount <= 0 ? null
          : {
              rendObj = ROBJ_TEXT
              text = loc("common/amountShort", { count = amount })
              color = activeTxtColor
            }.__update(fontBody)
      ]
    }
  })

let mkPurchasesView = @(purchases) {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = purchases.len() == 1
    ? mkShopItemSingleResult(purchases[0])
    : mkShopItemMultiResult(purchases)
}

function checkReqPurchasesMsgbox(purchases) {
  if (purchases.len() == 0)
    return

  let allPurchases = purchasesExt.get()
  showMessageWithContent({
    uid = "unseen_ext_purchases_result"
    content = {
      flow = FLOW_VERTICAL
      size = const [fsh(110), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("youHaveReceived")
          color = activeTxtColor
        }.__update(fontHeading2)
        mkPurchasesView(purchases)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("thanksForPurchases")
          color = activeTxtColor
        }.__update(fontBody)
      ]
    }
    buttons = [{
      text = loc("Ok")
      isCurrent = true
      isCancel = true
      action = @() markSeen(allPurchases)
    }]
  })
}

subscribeAndInit(checkReqPurchasesMsgbox, unseenPurchasesExt)

console_register_command(resetSeen, "meta.resetSeenPurchasesExt")

console_register_command(function() {
  if (debugPurchases.get()) {
    debugPurchases.set(null)
    return
  }

  let lastTimestamp = serverTime.get() - 1000
  const testGuids = {
    ["0145A719-313C-454D-B5B9-F332640A3A3C"] = 1,
    ["9930D465-C8E8-4BD7-93F2-990268321FEE"] = 1,
    ["A5EBD4F1-9DAC-4FDF-B9EE-B4B206B7F1E6"] = 1,
    ["6092C2CA-B113-456D-AA76-09591D87F6E1"] = 1,
    ["C164AF10-C9E3-41F9-AA4E-AC1ECC7F1478"] = 2,
    ["5FA9AD9D-B478-47BF-8DF0-07E6117DBCDA"] = 5,
  }
  let purchases = testGuids.map(@(amount) { amount, lastTimestamp })
  debugPurchases.set(purchases)
}, "ui.testShopResultWindow")
