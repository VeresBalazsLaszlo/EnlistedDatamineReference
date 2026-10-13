import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/mkCountdownTimer.nut" as mkCountdownTimer
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/defcomps.nut" import txt
from "%ui/currency/currencies.nut" import currenciesList, currenciesById
from "%ui/soldiers/model/state.nut" import curCampItemsCount
from "%ui/currency/currenciesComp.nut" import mkCurrency, mkCurrencyCount
from "%ui/shop/currencyComp.nut" import mkItemCurrency, mkDiscountWidget
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, isContentSoldier
from "%ui/style/designConst.nut" import brightAccentColor, midPadding, bonusColor, defTxtColor, activeTxtColor, titleTxtColor
from "%ui/ui_library.nut" import *

let { oldPriceLine } = require("%ui/currency/currenciesComp.nut")


const sidePadding = fsh(2)
const discountBannerHeight = hdpx(48)


function hasItemsToBarter(curItemCost, campItems) {
  if (curItemCost.len() == 0)
    return false

  foreach (itemTpl, reqCount in curItemCost)
    if ((campItems?[itemTpl] ?? 0) < reqCount)
      return false

  return true
}

let mkPriceText = @(price, currencyId) loc($"priceText/{currencyId}", { price })

let mkPurchaseText = @(isSoldier) isSoldier ? loc("mainmenu/enlistFor") : loc("mainmenu/buyFor")

function mkItemPurchaseInfo(shopItem, campItems, currencies, isNarrow) {
  let { curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0, shop_price_full = 0, discountInPercent = 0,
    isPriceHidden = false, hideDiscount = false
  } = shopItem

  let hasBarter = hasItemsToBarter(curItemCost, campItems)
  let hasDiscount = curShopItemPrice.fullPrice > curShopItemPrice.price
  let isSoldier = isContentSoldier(shopItemContentCtor(shopItem)?.get().content)
  if (hasBarter && !hasDiscount)
    return {
      rendObj = ROBJ_TEXT
      text = isSoldier ? loc("mainmenu/enlist") : loc("mainmenu/receive")
      color = activeTxtColor
      padding = const [0, sidePadding, 0, 0]
    }.__update(fontBody)

  let { price, fullPrice, currencyId = null } = curShopItemPrice
  
  let currency = currencies.findvalue(@(c) c.id == currencyId)
  if (currency != null && (price > 0 || discountInPercent > 0))
    return {
      flow = FLOW_HORIZONTAL
      padding = const [0, sidePadding, 0, 0]
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        isNarrow || isPriceHidden ? null
          : {
              rendObj = ROBJ_TEXT
              text = mkPurchaseText(isSoldier)
              color = activeTxtColor
            }.__update(fontSub)
        isPriceHidden ? null : mkCurrency({
          currency
          price
          fullPrice
        })
        mkDiscountWidget(discountInPercent)
      ]
    }

  
  if (shop_price_curr != "" && shop_price > 0) {
    let hasStoreDiscount = shop_price_full > shop_price
    let children = []
    if (!isPriceHidden) {
      if (!isNarrow || !hasStoreDiscount)
        children.append(txt({
          text = mkPurchaseText(isSoldier)
          color = activeTxtColor
        }.__update(fontSub)))

      children.append(mkCurrencyCount(
        mkPriceText(shop_price, shop_price_curr),
        { color = hasStoreDiscount ? bonusColor : activeTxtColor }
      ))

      if (hasStoreDiscount)
        children.append({children = [
          mkCurrencyCount(mkPriceText(shop_price_full, shop_price_curr), { color = defTxtColor })
          oldPriceLine.__merge({ color = defTxtColor })
        ]})
    }
    if (!hideDiscount)
      children.append(mkDiscountWidget(discountInPercent))

    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = midPadding
      padding = const [0, sidePadding, 0, 0]
      children
    }
  }

  return null
}

function mkItemBarterInfo(shopItem) {
  let { guid, curItemCost } = shopItem
  if (curItemCost.len() == 0)
    return null

  return function() {
    let children = []
    foreach (itemTpl, reqCount in curItemCost) {
      let inStock = curCampItemsCount.get()?[itemTpl] ?? 0
      children.append(mkItemCurrency({
        currencyTpl = itemTpl
        count = $"{inStock}/{reqCount}"
        keySuffix = guid
        textStyle = (inStock >= reqCount 
          ? { color = bonusColor }
          : {}).__update(fontBody)
      }))
    }
    return {
      watch = curCampItemsCount
      flow = FLOW_HORIZONTAL
      gap = midPadding
      padding = const [0,0,0,sidePadding]
      children
    }
  }
}

function mkItemPriceInfo(shopItem) {
  let { guid, curItemCost } = shopItem
  if (curItemCost.len() == 0)
    return null

  let children = []
  foreach (itemTpl, reqCount in curItemCost) {
    children.append(mkItemCurrency({
      currencyTpl = itemTpl
      count = reqCount
      keySuffix = guid
      textStyle = fontBody
    }))
  }
  return {
    flow = FLOW_HORIZONTAL
    gap = midPadding
    padding = const [0,0,0,sidePadding]
    children
  }
}

let baseIconSize = [hdpxi(25), hdpxi(25)]

let mkPrice = @(shopItem, bgParams = {}, needPriceText = true,
  showGoldPrice = true, styleOverride = {}, discountStyle = null,
  iconSize = baseIconSize, dimStyle = {}
) (shopItem?.isPriceHidden ?? false) ? null : function() {
    let children = []
    foreach (itemTpl, value in shopItem.curItemCost)
      children.append(mkItemCurrency({
        currencyTpl = itemTpl
        count = value
        keySuffix = shopItem.guid
        textStyle = styleOverride
        iconSize
      }))
    if (showGoldPrice) {
      let { curShopItemPrice } = shopItem
      let { price, fullPrice, currencyId = null } = curShopItemPrice
      let currency = currenciesById.get()?[currencyId]
      if (currency != null && price > 0) {
        if (children.len() > 0)
          children.append(txt({ text = loc("mainmenu/or")}.__update(fontBody)))
        children.append(mkCurrency({
          currency
          price
          fullPrice
          discountStyle
          dimStyle
          txtStyle = styleOverride
          iconSize = iconSize[0]
        }))
      }
    }

    let otherTxtStyle = fontBody.__merge(styleOverride)
    if (children.len() == 0) {
      let { shop_price_curr = "", shop_price = 0 } = shopItem
      if (shop_price_curr != "" && shop_price > 0)
        children.append(txt({
          text = loc($"priceText/{shop_price_curr}", { price = shop_price })
        }.__update(otherTxtStyle)))
    }

    if (needPriceText && children.len() > 0)
      children.insert(0, txt({ text = loc("price")}.__update(otherTxtStyle)))

    return {
      watch = currenciesById
      flow = FLOW_HORIZONTAL
      gap = midPadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children
    }.__update(bgParams)
  }

function mkSinglePrice(priceData, count, guid) {
  let { currTpl = "", value = 0, price = 0, fullPrice = 0} = priceData
  if (currTpl == "EnlistedGold"){
    let currency = currenciesById.get()?[currTpl]
    return mkCurrency({ currency, price = price * count, fullPrice = fullPrice * count})
  }

  return mkItemCurrency({
    currencyTpl = currTpl,
    count = value * count,
    keySuffix = guid
  })
}

function mkDiscountInfo(discountData) {
  if (discountData == null)
    return null

  let { locId, endTime = 0 } = discountData
  return mkHeaderFlag({
    size = const [FLEX, discountBannerHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    padding = const [0, fsh(1)]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc(locId))
        color = Color(0,0,0)
      }.__update(fontSub)
      { size = FLEX }
      endTime == 0 ? null : mkCountdownTimer({ timestamp = endTime, color = titleTxtColor })
    ]
  }, primeFlagStyle.__merge({
    size = FLEX_H
    offset = 0
    flagColor = brightAccentColor
  }))
}

function mkShopItemPrice(shopItem, personalOffer = null, isNarrow = false, showInStock = true) {
  local {
    curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0, discountInPercent = 0,
    discountIntervalTs = [], isPriceHidden = false, showSpecialOfferText = false
  } = shopItem
  let { price } = curShopItemPrice
  let [ beginTime = 0, endTime = 0 ] = discountIntervalTs
  let isDiscountActive = beginTime > 0
    && beginTime <= serverTime.get()
    && (serverTime.get() <= endTime || endTime == 0)
  let discountData = personalOffer != null ? {
        endTime = personalOffer.endTime
        locId = "specialOfferShort"
      }
    : discountInPercent > 0 || (discountInPercent == 0 && isDiscountActive) ? {
        endTime
        locId = showSpecialOfferText ? "specialOfferShort" : "shop/discountNotify"
      }
    : null

  if (discountData == null
    && curItemCost.len() == 0
    && price == 0
    && discountInPercent == 0
    && (shop_price_curr == "" || shop_price == 0 || isPriceHidden))
      return null

  return @() {
    watch = [curCampItemsCount, currenciesList]
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      mkDiscountInfo(discountData)
      {
        size = [FLEX, discountBannerHeight]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          showInStock ? mkItemBarterInfo(shopItem) : mkItemPriceInfo(shopItem)
          { size = FLEX }
          mkItemPurchaseInfo(shopItem, curCampItemsCount.get(), currenciesList.get(), isNarrow)
        ]
      }
    ]
  }
}

return {
  mkShopItemPrice
  mkPrice = kwarg(mkPrice)
  mkSinglePrice
}
