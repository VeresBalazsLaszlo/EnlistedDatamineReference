import "%ui/control/gui_buttons.nut" as JB
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
from "%ui/components/textButton.style.nut" import TextNormal, TextHover, textMargin
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub, fontBody
from "%ui/style/designConst.nut" import midPadding, largePadding, unitSize, defTxtColor, titleTxtColor, attentionTxtColor
from "%ui/style/colors.nut" import HighlightFailure
from "%ui/style/buttonsStyle.nut" import primaryFlatButtonStyle
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/currency/currencies.nut" import currenciesById, currenciesBalance
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/purchaseMsgBox.nut" import buyCurrencyText, currencyImage, mkItemCostInfo
from "%ui/components/itemsInfo.nut" import itemNameFromGametemplate, itemNameFromItem, trimUpgradeSuffix
from "%ui/meta/profile.nut" import curCampItems
from "%ui/shop/armyShopState.nut" import getShopItems, buyShopItemList, barterShopItemList,
  buyWithUpgradeShopItemList, curArmyItemsPrefiltered, itemToShopItem
from "%ui/shop/shopPkg.nut" import getCantBuyData
from "%ui/preset/presetEquipUtils.nut" import shopItemByTemplateData
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/state.nut" import curArmy, armoryByArmy, curArmyData
from "%ui/soldiers/model/config/itemsModifyConfig.nut" import itemUpgrades, getModifyConfig
from "%ui/researches/researchesSummary.nut" import upgradeLocksByArmy, upgradeCostMultByArmy
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, curGrowthProgress,
  curGrowthTiers
from "%ui/soldiers/components/itemComp.nut" import mkItem
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/ui_library.nut" import *
from "math" import ceil

let { openShopByCurrencyId } = require("%ui/currency/purchaseMsgBox.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontBody)
let headerStyle = { color = attentionTxtColor }.__update(fontBody)

let itemSize = [unitSize * 8, hdpxi(90)]
const SILVER_ID = "enlisted_silver"

function mkCostInfo(priceData) {
  let { totalPrice, totalFullPrice, currency } = priceData
  if (currency == null)
    return null

  return {
    flow = FLOW_VERTICAL
    margin = [midPadding, 0]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("preset/equip/buyMsg")
        color = titleTxtColor
      }.__update(fontSub)
      mkItemCostInfo(totalPrice, totalFullPrice, currency)
    ]
  }
}

let mkNotEnoughMoney = @(needMoreCurrency, currency) needMoreCurrency > 0 ? {
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("shop/notEnoughCurrency", { priceDiff = needMoreCurrency })
      }.__update(headerStyle, { color = HighlightFailure })
      currencyImage(currency)
    ]
  } : null

function mkItemNameList(items) {
  let names = []
  foreach (tpl in items.keys()) {
    let shopItem = shopItemByTemplateData(tpl)
    let itemname = shopItem != null ? itemNameFromItem(shopItem) : itemNameFromGametemplate(tpl)

    let strings = [itemname]
    if (items[tpl] > 1)
      strings.append(loc("common/amountShort", { count = items[tpl] }))
    names.append(" ".join(strings))
  }
  return ",\n".join(names)
}

let mkUpgradeResultCmp = @(upgradeResult, upgradeItemsCount)
    (upgradeResult.len() == 0) ? null : function() {
  let children = [{
    rendObj = ROBJ_TEXT
    text = loc("preset/equip/upgradeItems")
  }.__update(headerStyle)]

  let armyId = curArmy.get()
  foreach (basetpl, itemtpl in upgradeResult) {
    let count = upgradeItemsCount?[basetpl] ?? 0
    let resultItem = mkShopItem(itemtpl, allItemTemplates.get()[armyId][itemtpl], armyId)
      .__update({ count })
    children.append({
      size = [unitSize * 8, hdpxi(90)]
      children = mkItem({
        item = resultItem
        canDrag = false
        isInteractive = true
        isAvailable = true
        itemSize
      })
    })
  }
  return {
    watch = [curArmy, allItemTemplates]
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}

let applyPresetText = @(locId) {
  margin = [midPadding, 0]
  rendObj = ROBJ_TEXT
  text = loc(locId)
}.__update(defTxtStyle)

function mkBuyItemsCmp(canBuyItems, priceData, applyTextCmp) {
  let { upgradeResult } = priceData
  if (canBuyItems.len() == 0)
    return null

  return function() {
    let { totalPrice, currency } = priceData
    return {
      watch = [currenciesBalance, currenciesById]
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("preset/equip/notFoundMsg")
        }.__update(headerStyle)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = mkItemNameList(canBuyItems)
        }.__update(defTxtStyle)
        upgradeResult.len() > 0 ? null : applyTextCmp
        mkCostInfo(priceData)
        mkNotEnoughMoney(totalPrice - (currenciesBalance.get()?[currency] ?? 0),
          currenciesById.get()?[currency])
      ]
    }
  }
}

let unavailableCmp = @(unavailableItems) unavailableItems.len() == 0
  ? null
  : {
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("preset/equip/buyUnavailable")
        }.__update(headerStyle)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = mkItemNameList(unavailableItems)
        }.__update(defTxtStyle)
        applyPresetText("preset/equip/notFoundItems")
      ]
    }

function mkNotFound(canBuyItems, unavailableItems, priceData, needApplyText) {
  let { upgradeResult, upgradeItemsCount } = priceData

  let applyTextCmp = unavailableItems.len() > 0 ? null
    : needApplyText ? applyPresetText("preset/equip/notFoundItems")
    : applyPresetText("preset/equip/purchaseItems")

  return {
    flow = FLOW_VERTICAL
    gap = largePadding
    children = [
      mkBuyItemsCmp(canBuyItems, priceData, applyTextCmp)
      mkUpgradeResultCmp(upgradeResult, upgradeItemsCount)
      unavailableCmp(unavailableItems)
    ]
  }
}

let mkBuyOrdersBtn = @(barterCost, action) {
  text = @(_textField, params, handler, group, sf)
    textButtonTextCtor({
      children = {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        margin = textMargin
        children = mkTextRow(loc("preset/equip/buy"),
          @(text) {
            rendObj = ROBJ_TEXT
            text
            color = sf & S_HOVER ? TextHover : TextNormal
          }.__update(fontBody),
          {
            ["{cost}"] = barterCost.reduce(@(res, count, currencyTpl) 
              res.append(mkItemCurrency({
                currencyTpl
                count
                textStyle = {
                  color = sf & S_HOVER ? TextHover : TextNormal
                }.__update(fontBody)
              })), [])
          })
      }
    }, params, handler, group, sf)
  action
  customStyle = primaryFlatButtonStyle
}

let mkBuyButton = @(currency, action) {
  text = @(_textField, params, handler, group, sf)
    textButtonTextCtor({
      children = {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        margin = textMargin
        children = mkTextRow(loc("preset/equip/buy"),
          @(text) {
            rendObj = ROBJ_TEXT
            color = sf & S_HOVER ? TextHover : TextNormal
            text
          }.__update(fontBody),
          {
            ["{cost}"] = mkCurrency({ 
                txtStyle = {
                  color = sf & S_HOVER ? TextHover : TextNormal
                }.__update(fontBody, currency)
              })
          })
      }
    }, params, handler, group, sf)
  action
  customStyle = primaryFlatButtonStyle
}

let mkBuyCurrencyBtn = @(currency, action) {
  text = @(_textComp, _params, handler, group, sf)
    textButtonTextCtor(buyCurrencyText(currency, sf), fontHeading2, handler, group, sf)
  action
}

function filterByPurchaseReqs(shopItemsTbl, unavailableItems,
    curArmyDataV, curGrowthStateV, curGrowthConfigV,
    curGrowthProgressV, curGrowthTiersV, allItemTemplatesV) {

  let toRemove = []
  foreach (guid, itemData in shopItemsTbl) {
    let { shopItem, itemTpl, count } = itemData
    if (null != getCantBuyData(curArmyDataV,
        shopItem?.requirements,
        curGrowthStateV,
        curGrowthConfigV,
        curGrowthProgressV,
        curGrowthTiersV,
        allItemTemplatesV)) {

      unavailableItems[itemTpl] <- count
      toRemove.append(guid)
    }
  }

  foreach (guid in toRemove)
    shopItemsTbl.$rawdelete(guid)
}

function processNotFound(armyId, allItemTemplatesV, itemsCountVal,
    itemToShopItemV, curArmyItemsPrefilteredV,
    notFoundItemsList, unavailableItems, shopItemsTbl, upgradedItems) {

  let armyTemplates = allItemTemplatesV?[armyId] ?? {}
  let getShopItemsList = @(tpl) getShopItems(tpl, armyId, itemToShopItemV,
    allItemTemplatesV, curArmyItemsPrefilteredV)

  foreach (itemTpl, count in notFoundItemsList) {
    let { upgradeIdx = 0 } = armyTemplates?[itemTpl]
    local shopItem = getShopItemsList(itemTpl)?[0]
    local buyCount = count
    if (upgradeIdx > 0 && shopItem == null) {
      let basetpl = trimUpgradeSuffix(itemTpl)
      shopItem = getShopItemsList(basetpl)?[0]

      if (shopItem == null) {
        unavailableItems[itemTpl] <- count
        continue
      }

      let upgradeCount = min(count, itemsCountVal?[basetpl] ?? 0)
      if (upgradeCount > 0)
        buyCount = count - upgradeCount
      upgradedItems[basetpl] <- count
    }

    if (buyCount == 0)
      continue

    
    
    let { limit = -1 } = shopItem
    if (shopItem == null || limit > 0) {
      unavailableItems[itemTpl] <- count
      continue
    }

    shopItemsTbl[shopItem.guid] <- {
      itemTpl 
      shopItem
      count = buyCount + (shopItemsTbl?[shopItem.guid].count ?? 0)
    }
  }
}

function calcPurchaseCost(barterCost, shopItemsTbl) {
  foreach (buyData in shopItemsTbl) {
    let { count, shopItem } = buyData
    let { curItemCost = {} } = shopItem
    if (curItemCost.len() == 0)
      return

    foreach (itemType, cost in curItemCost)
      barterCost[itemType] <- (barterCost?[itemType] ?? 0) + cost * count
  }
}


function calcUpgradeCost(barterCost, upgradeResult, upgradeItemsCount,
    armyTemplates, upgradeCostMultVal, itemUpgradesVal, lockedUpgradesVal) {
  let lockedUpgrades = lockedUpgradesVal ?? []
  foreach (basetpl, count in upgradeItemsCount) {
    let upgradeMult = upgradeCostMultVal?[basetpl] ?? 1.0
    local itemtpl = basetpl
    local template = armyTemplates?[itemtpl]
    while (template != null) {
      let {
        itemtype, upgradeitem = null, growthTier = 0, upgradeIdx = 0
      } = template

      if (upgradeitem == null || lockedUpgrades.contains(upgradeitem))
        break

      let modifyConfig = getModifyConfig(itemUpgradesVal, growthTier, itemtype)
      if (modifyConfig == null)
        break

      foreach (orderTpl, price in modifyConfig) {
        local orderReq = price?.counts[upgradeIdx] ?? price?.count ?? 0
        if (!price?.isFixedPrice)
          orderReq = ceil(orderReq * upgradeMult).tointeger()
        barterCost[orderTpl] <- (barterCost?[orderTpl] ?? 0) + count * orderReq
      }
      itemtpl = upgradeitem
      template = armyTemplates?[itemtpl]
      upgradeResult[basetpl] <- itemtpl
    }
  }
}

function getPayInfo(shopItemsTbl) {
  let payDataBuy = {}
  local currency = null
  local totalPrice = 0
  local totalFullPrice = 0
  foreach (buyData in shopItemsTbl) {
    let { count, shopItem } = buyData
    let { guid } = shopItem
    let { price = 0, fullPrice = 0, currencyId = null } = shopItem?.curShopItemPrice
    currency = currency ?? currencyId

    if (price > 0 && currencyId != null) {
      totalPrice += price * count
      totalFullPrice += fullPrice * count
      payDataBuy[guid] <- { [currencyId] = price }
    } else {
      totalPrice = 0
      break
    }
  }

  return {
    payDataBuy
    totalPrice
    totalFullPrice
    currency
  }
}

function calcPriceView(armyTemplates, curCampItemsVal,
    upgradeCostMultVal, itemUpgradesVal, upgradeLocksVal,
    shopItemsTbl, upgradeItemsCount, showApplyBtn, onSuccessCb) {

  function requestCb(isSuccess) {
    if (isSuccess)
      onSuccessCb()
  }

  let applyBtn = {
    text = loc("squads/presets/apply")
    action = onSuccessCb
    customStyle = primaryFlatButtonStyle
  }
  let buttons = showApplyBtn ? [applyBtn] : []

  let itemData = shopItemsTbl.reduce(function(res, buyData) {
    let { count, shopItem } = buyData
    let { guid } = shopItem
    res[guid] <- count
    return res
  }, {})
  let shopItemsList = shopItemsTbl.values().map(@(v) v.shopItem)

  let barterCost = {}
  calcPurchaseCost(barterCost, shopItemsTbl)
  let upgradeCost = {}
  let upgradeResult = {}
  calcUpgradeCost(upgradeCost, upgradeResult, upgradeItemsCount,
    armyTemplates, upgradeCostMultVal, itemUpgradesVal, upgradeLocksVal)

  if (barterCost.len() == 0 && upgradeCost.len() > 0)
    barterCost[SILVER_ID] <- 0

  foreach (barterItem, count in barterCost) {
    let totalItems = {}
    let addCost = upgradeCost?[barterItem] ?? 0
    totalItems[barterItem] <- count + addCost
    let payItems = getPayItemsData(totalItems, curCampItemsVal)
    if (payItems == null)
      break
    let action = @() addCost > 0
      ? buyWithUpgradeShopItemList(shopItemsList, itemData, payItems, upgradeItemsCount, requestCb)
      : barterShopItemList(shopItemsList, itemData, payItems, requestCb)
    buttons.append(mkBuyOrdersBtn(totalItems, action))
  }

  let { totalPrice, totalFullPrice, currency, payDataBuy } = getPayInfo(shopItemsTbl)
  let currencyData = currenciesById.get()?[currency]

  if (totalPrice > 0) {
    if (totalPrice > (currenciesBalance.get()?[currency] ?? 0))
      buttons.append(mkBuyCurrencyBtn(currencyData, @() openShopByCurrencyId?[currency]()))
    else {
      let action = @() buyShopItemList(shopItemsList, itemData, payDataBuy, requestCb)
      buttons.append(mkBuyButton({
        currency = currencyData
        price = totalPrice
        fullPrice = totalFullPrice
      }, action))
    }
  }

  buttons.append({ text = loc("Cancel"), isCancel = true,
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } })

  return {
    buttons
    totalPrice
    totalFullPrice
    currency
    upgradeItemsCount
    upgradeResult
  }
}

function showNotFoundMsg(notFoundPresetItemsVal, showApplyBtn, onSuccessCb) {
  let armyId = curArmy.get()
  let templates = allItemTemplates.get()

  let armoryItemsCount = {}
  foreach (item in armoryByArmy.get()?[armyId] ?? {}) {
    let { basetpl } = item
    armoryItemsCount[basetpl] <- 1 + (armoryItemsCount?[basetpl] ?? 0)
  }

  let shopItemsTbl = {}
  let upgradeItemsCount = {}
  let unavailableItems = {}
  processNotFound(armyId, templates, armoryItemsCount,
    itemToShopItem.get(),
    curArmyItemsPrefiltered.get(),
    notFoundPresetItemsVal, unavailableItems, shopItemsTbl, upgradeItemsCount)

  filterByPurchaseReqs(shopItemsTbl, unavailableItems,
    curArmyData.get(),
    curGrowthState.get(),
    curGrowthConfig.get(),
    curGrowthProgress.get(),
    curGrowthTiers.get(),
    templates)

  let priceView = calcPriceView(templates?[armyId] ?? {},
    curCampItems.get(),
    upgradeCostMultByArmy.get()?[armyId],
    itemUpgrades.get(),
    upgradeLocksByArmy.get()?[armyId],
    shopItemsTbl, upgradeItemsCount, showApplyBtn, onSuccessCb)

  let canBuyList = notFoundPresetItemsVal.filter(@(_count, tpl) tpl not in unavailableItems)
  showMessageWithContent({
    content = mkNotFound(canBuyList, unavailableItems, priceView, showApplyBtn)
    buttons = priceView.buttons
  })
}

return {
  showNotFoundMsg
}
