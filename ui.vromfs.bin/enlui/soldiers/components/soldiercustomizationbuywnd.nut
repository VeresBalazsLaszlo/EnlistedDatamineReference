import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/spinner.nut" as spinner
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/style/designConst.nut" import midPadding, maxContentWidth, commonBtnHeight, defTxtColor, titleTxtColor, blurBgColor, blurBgFillColor
  , horGap, emptyGap, bigPadding
from "%ui/components/textButton.style.nut" import textMargin
from "%ui/components/textButton.nut" import Regular, Primary, textColor, primaryStyle
from "%ui/currency/currenciesComp.nut" import currencyBtn
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/soldiers/model/config/outfitConfig.nut" import freeOutfitsForArmy
from "%ui/soldiers/soldierCustomizationState.nut" import curCustomizationItem, currentItemPart,
  getAvailableItem, closeCustomizationWnd, customizedSoldierInfo, oldSoldiersLook,
  customizedSoldierLook, freeItemsForSoldier, customizationToApply, itemsForSquad, buyItemsSquad,
  itemsToBuy, itemsDisplayData, toDisplayData, customizeScheme, campaignOutfit, schemeItemsPrice,
  curSoldierItemsPrice, ignoreForMultiPurchase, isSoldierLocked, isSlotLocked, soldiersDropCfg
from "%ui/soldiers/soldierCustomizationPkg.nut" import mkPrice, itemBlock
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/soldiers/model/state.nut" import curCampItemsCount, curSquadSoldiersInfo
from "%ui/shop/currencyComp.nut" import mkCurrencyUi
from "%ui/meta/profile.nut" import curCampItems
from "%ui/meta/clientApi.nut" import buy_outfit, use_outfit_orders, change_outfit_squad
from "%ui/ui_library.nut" import *

const PURCHASE_WND_UID = "PURCHASE_WND"
const APPEARANCE_ORDER_TPL = "appearance_change_order"
const ENLISTED_GOLD = "EnlistedGold"

let verticalGap = midPadding * 2
let purchaseWndWidth = min(sw(40), maxContentWidth) - hdpx(75) * 2
let waitingSpinner = spinner(hdpx(35))


let isPurchasing = Watched(false)
local afterPurchaseCb = null
let isCustomizationBuyOpened = Watched(false)
let isMultiplePurchasing = Watched(false)
let itemsInPurchaseWnd = Watched({})

function closePurchaseWnd() {
  isMultiplePurchasing.set(false)
  isCustomizationBuyOpened.set(false)
}
let purchaseCloseBtn = closeBtnBase({ onClick = closePurchaseWnd })

isPurchasing.subscribe(@(v) v ? null : closePurchaseWnd())
itemsInPurchaseWnd.subscribe(function(v) {
  if (v.len() == 0)
    closePurchaseWnd()
})

function setPurchaseWindowData(items, isMultiple = false, onBuyCb = @() null) {
  itemsInPurchaseWnd.set(items)
  isMultiplePurchasing.set(isMultiple)
  isCustomizationBuyOpened.set(true)
  afterPurchaseCb = onBuyCb
}

let isItemInScheme = @(scheme, slot, item) (scheme?[slot] ?? []).contains(item)

let multipleItemsCost = Computed(function() {
  let totalPrice = {}
  foreach (item in itemsInPurchaseWnd.get()) {
    let count = buyItemsSquad.get()?[item] ?? 0
    if (count < 1)
      continue

    let itemPrice = schemeItemsPrice.get()?[item] ?? {}

    foreach (costData in itemPrice) {
      let { currencyId = "", orderTpl = "", price = 0 } = costData
      let key = currencyId != "" ? currencyId : orderTpl
      let costForCurrency = totalPrice?[key] ?? { cost = 0, num = 0 }
      costForCurrency.cost += price * count
      costForCurrency.num ++
      totalPrice[key] <- costForCurrency
    }
  }

  let numItems = totalPrice.reduce(@(res, costForCurrency)
    res > costForCurrency.num ? res : costForCurrency.num, 0)

  return totalPrice.map(function(costForCurrency) {
    if (costForCurrency.num == numItems)
      return costForCurrency.cost
    throw null
  })
})

let totalItemsCost = Computed(function() {
  let itemsToCheckPrice = itemsInPurchaseWnd.get()
  let totalPrice = {}
  if (itemsToCheckPrice.len() <= 0)
    return totalPrice

  let { armyId = null, guid = null} = customizedSoldierInfo.get()
  if (armyId == null || guid == null)
    return totalPrice

  foreach (item in itemsToCheckPrice) {
    if (item in freeItemsForSoldier.get())
      continue
    let curItemPrice = curSoldierItemsPrice.get()?[item] ?? {}
    curItemPrice.each(function(v) {
      let { currencyId = "", orderTpl = "" } = v
      let key = currencyId != "" ? currencyId : orderTpl
      totalPrice[key] <- (totalPrice?[key] ?? 0) + v.price
    })
  }

  return totalPrice
})

let itemsCost = Computed(@()
  isMultiplePurchasing.get() ? multipleItemsCost.get() : totalItemsCost.get())

let itemsBuyList = Computed(@()
  isMultiplePurchasing.get()
    ? buyItemsSquad.get().filter(@(_, item) itemsInPurchaseWnd.get().findvalue(@(v) v == item))
    : itemsInPurchaseWnd.get().reduce(@(res, value) res.rawset(value, 1), {}))

function multipleApplyOutfit(needEverything = false) {
  let applyItems = needEverything ? customizedSoldierLook.get() : customizationToApply.get()
  let premList = freeOutfitsForArmy.get() ?? []
  let usedItems = {}
  let itemsByTpl = {}
  let requestData = {}
  let dropsCfg = soldiersDropCfg.get()
  foreach (soldier in curSquadSoldiersInfo.get()) {
    if (isSoldierLocked(soldier, dropsCfg))
      continue

    let soldierGuid = soldier.guid
    let multiPrem = {}
    let equippedItems = soldiersLook.get()?[soldierGuid].items ?? {}
    foreach (slotId, itemToEquip in applyItems) {
      if (ignoreForMultiPurchase(itemToEquip) || isSlotLocked(soldier, slotId, dropsCfg))
        continue

      let equipped = equippedItems?[slotId] ?? ""
      if (equipped == itemToEquip || !isItemInScheme(customizeScheme.get(), slotId, itemToEquip)) {
        multiPrem[slotId] <- ""
        continue
      }

      let possibleItems = itemsByTpl?[itemToEquip]
        ?? premList.filter(@(item) item.basetpl == itemToEquip)
      itemsByTpl[itemToEquip] <- possibleItems

      let { itemGuid, alreadyEquipped } =
        getAvailableItem(possibleItems, soldierGuid, slotId, "", usedItems)

      if (!alreadyEquipped && itemGuid != "") {
        usedItems[itemGuid] <- true
        multiPrem[slotId] <- itemGuid
      }
    }
    requestData[soldierGuid] <- {
      free = {}
      premium = multiPrem
    }
  }

  change_outfit_squad(requestData, campaignOutfit.get())
  closeCustomizationWnd()
}

function afterPurchase(_) {
  afterPurchaseCb?()
  isPurchasing.set(false)
}

function buyItemsWithCurrency() {
  let { armyId = null } = customizedSoldierInfo.get()
  if (armyId == null || isPurchasing.get())
    return

  let { EnlistedGold } = itemsCost.get()
  let items = itemsBuyList.get()
  return purchaseMsgBox({
    price = EnlistedGold
    currencyId = ENLISTED_GOLD
    alwaysShowCancel = true
    purchase = function() {
      isPurchasing.set(true)
      buy_outfit(armyId, items, EnlistedGold, afterPurchase)
    }
  })
}

function buyItemsWithTickets() {
  let { armyId = null } = customizedSoldierInfo.get()
  if (armyId == null || isPurchasing.get())
    return

  let costData = itemsCost.get()
  let orderTpl = costData.findindex(@(_, id) id != ENLISTED_GOLD)
  if (orderTpl == null)
    return

  let price = costData[orderTpl]
  let items = itemsBuyList.get()
  let orders = getPayItemsData({ [orderTpl] = price }, curCampItems.get())

  isPurchasing.set(true)
  use_outfit_orders(armyId, items, orders, afterPurchase)
}

function removeItem(itemToDelete) {
  let key = itemsInPurchaseWnd.get().findindex(@(item) item == itemToDelete)

  if (key != null) {
    itemsInPurchaseWnd.mutate(@(v) v.$rawdelete(key))
    if (itemsInPurchaseWnd.get().len() == 0) {
      curCustomizationItem.set(oldSoldiersLook.get()?[currentItemPart.get()])
      closePurchaseWnd()
    }
  }
}

function removeAndCloseWnd(itemToDelete) {
  removeItem(itemToDelete)
  curCustomizationItem.set(null)
  closePurchaseWnd()
}


let customizationCurrency = mkCurrencyUi(APPEARANCE_ORDER_TPL)

let purchaseHeader = {
  size = FLEX_H
  halign = ALIGN_RIGHT
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("appearance/header")
      color = titleTxtColor
      hplace = ALIGN_CENTER
    }.__update(fontBody)
    {
      flow = FLOW_HORIZONTAL
      children = [
        emptyGap
        currenciesWidgetUi
        horGap
        customizationCurrency
        emptyGap
        purchaseCloseBtn
      ]
    }
  ]
}

let purchaseItemWrapParams = {
  width = purchaseWndWidth
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  vGap = verticalGap
  hGap = verticalGap
}

function purchaseContent() {
  let itemsToShow = itemsBuyList.get().keys()
  let itemAction = itemsToShow.len() > 1 ? removeItem : removeAndCloseWnd

  let { guid } = curSoldierInfo.get()
  let prices = schemeItemsPrice.get()
  let itemsCount = itemsBuyList.get()
  return {
    watch = [curSoldierInfo, itemsDisplayData,
      itemsBuyList, isMultiplePurchasing, schemeItemsPrice]
    size = [purchaseWndWidth, SIZE_TO_CONTENT]
    padding = [verticalGap, 0]
    gap = verticalGap
    flow = FLOW_VERTICAL
    children = [
      isMultiplePurchasing.get() ? {
          rendObj = ROBJ_TEXT
          text = loc("appearance/buyAndApply")
          color = defTxtColor
          hplace = ALIGN_CENTER
        }.__update(fontBody) : null
      wrap(toDisplayData(itemsDisplayData.get(), itemsToShow)
          .map(@(itemData) itemBlock(guid, itemData, prices, itemsCount, itemAction)),
        purchaseItemWrapParams)
      ]
  }
}

let btnTextCtor = @(locId, tmpl, cost, isEnabled = true) @(_, params, handler, group, sf)
  textButtonTextCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = textMargin
    children = mkTextRow(loc(locId),
      @(text) {
        rendObj = ROBJ_TEXT
        text
        color = textColor(sf, primaryStyle, isEnabled)
      }.__update(fontBody),
      {
        ["{currency}"] = mkPrice(tmpl, cost, { 
            color = textColor(sf, primaryStyle, isEnabled)
          }.__update(fontBody))
      }
    )
  }, params, handler, group, sf)


let multiBuyBtn = Regular(loc("appearance/buyForSquad"),
  function() {
    let items = itemsToBuy.get().filter(@(_item, slot) !ignoreForMultiPurchase(slot))
    setPurchaseWindowData(items, true, multipleApplyOutfit)
  },
  {
    hotkeys = [["^J:Y"]]
  })

function purchaseBtnBlock() {
  let allPrices = itemsCost.get()
  let priceList = []
  foreach (key, val in allPrices) {
    if (key == ENLISTED_GOLD)
      priceList.append({
        tmpl = key
        cost = val
      })
    else
      priceList.insert(0, {
        tmpl = key
        cost = val
      })
  }

  let btnsBlock = []
  foreach(v in priceList) {
    if (v.cost > 0) {
      let isEnabledTicket = (curCampItemsCount.get()?[APPEARANCE_ORDER_TPL] ?? 0) >= v.cost
      btnsBlock.append(
        v.tmpl == ENLISTED_GOLD
          ? currencyBtn({
              btnText = loc("btn/buy")
              currencyId = ENLISTED_GOLD
              price = v.cost
              cb = buyItemsWithCurrency
            })
          : Primary(btnTextCtor("btn/buyCurrency", v.tmpl, v.cost, isEnabledTicket),
              buyItemsWithTickets, {
                isEnabled = isEnabledTicket
                hotkeys = [["^J:X"]]
              })
      )
    }
  }

  if (!isMultiplePurchasing.get()
      && itemsToBuy.get().findindex(@(_item, slot) !ignoreForMultiPurchase(slot)) != null)
    btnsBlock.append(multiBuyBtn)

  btnsBlock.append(
    Regular(loc("Cancel"), closePurchaseWnd, {
      hotkeys = [[$"^{JB.B} | Esc"]]
    }))

  return {
    watch = [itemsCost, curCampItemsCount, isMultiplePurchasing, isPurchasing, itemsToBuy]
    size = const [FLEX, hdpx(100)]
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    gap = bigPadding
    children = isPurchasing.get() ? waitingSpinner : btnsBlock
  }
}


let purchaseWndContent = {
  size = FLEX_H
  maxWidth = maxContentWidth
  padding = hdpx(75)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = verticalGap
  children = [
    purchaseHeader
    purchaseContent
    purchaseBtnBlock
  ]
}

let purchaseWnd = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = FLEX_H
  color = blurBgColor
  fillColor = blurBgFillColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = purchaseWndContent
}

isCustomizationBuyOpened.subscribe(function(val) {
  if (!val) {
    removeModalWindow(PURCHASE_WND_UID)
    return
  }

  addModalWindow({
    key = PURCHASE_WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = FLEX
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = purchaseWnd
    onClick = @() null
  })
})

let multiApplyBtn = @() {
  watch = itemsForSquad
  size = [FLEX, commonBtnHeight]
  children = Regular(loc("appearance/applySquad"),
    function() {
      if (buyItemsSquad.get().len() == 0) {
        multipleApplyOutfit(true)
        return
      }
      let items = clone customizedSoldierLook.get()
      setPurchaseWindowData(items, true, @() multipleApplyOutfit(true))
    },
    {
      size = [FLEX, commonBtnHeight]
      hotkeys = [["^J:LS"]]
      isEnabled = itemsForSquad.get().len() > 0
    })
}

function purchaseBtn() {
  let items = itemsToBuy.get()
  let count = items.len()
  return {
    watch = itemsToBuy
    flow = FLOW_VERTICAL
    gap = verticalGap
    children = [
      count == 0 ? null
        : {
            rendObj = ROBJ_TEXT
            text = loc("appearance/itemsInCart", { count })
          }.__update(fontHeading2)
      Regular(loc("appearance/purchase"),
        @() setPurchaseWindowData(clone items), {
          margin = 0
          isEnabled = count > 0
          hotkeys = [["^J:Y"]]
        })
    ]
  }
}

return {
  multiApplyBtn
  purchaseBtn
  customizationCurrency
}
