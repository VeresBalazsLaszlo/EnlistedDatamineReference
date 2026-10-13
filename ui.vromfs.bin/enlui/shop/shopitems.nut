import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/state/dmm_distr.nut" as isDmmDistr
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/shop/goodsAndPurchases_pc.nut" import goodsInfo
from "%ui/meta/profile.nut" import squadsByArmies
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%dngscripts/platform.nut" import is_pc, isPlatformRelevant
from "%ui/ui_library.nut" import *
from "auth" import get_country_code
from "settings" import get_setting_by_blk_path

let prohibitionCountriesList = get_setting_by_blk_path("countriesProhibitingLootbox")

let debugNoFilter = Watched(false)
let shopDiscountGen = Watched(0)

let shopItemsServer = mkComputedConfigGet("shop_items", {})
let shopSquadsCompensations = mkComputedConfigGet(["shop_compensations","squads"], {})
let shopDecorsCompensations = mkComputedConfigGet(["shop_compensations","decorators"], {})

let lootboxCrateIds = Computed(function() {
  let crateConfigs = crateContentWatch.get()
  let res = {}
  foreach (crateId, crateInfo in crateConfigs)
    if (crateInfo?.isLootbox)
      res[crateId] <- true
  return res
})

function mkCountrySpecificFilter() {
  let countryCode = get_country_code().tolower()
  let prohibitedMode = prohibitionCountriesList?[countryCode]
  if (prohibitedMode != "off")
    return @(_) true

  return function(shopItem) {
    if ((shopItem?.curShopItemPrice.price ?? 0) == 0)
      return true

    foreach (crateId in shopItem?.crates ?? [])
      if (crateId in lootboxCrateIds.get())
        return false

    return true
  }
}

let isShopItemSuitable = @(item) (item?.can_be_bought ?? true)
  || (item?.curShopItemPrice.price ?? 0) > 0
  || (item?.itemCost.len() ?? 0) > 0

let shopItemsBase = Computed(function() {
  let ownedSquads = squadsByArmies.get()
  let currentShopItems = shopItemsServer.get()
  let shopItems = {}
  foreach (key, shopItem in currentShopItems) {
    let { squads = [], shopItemPrice = null } = shopItem
    let { price = 0 } = shopItemPrice
    let additionalPrice = squads.reduce(function(sum, squadData) {
      let { armyId, id, priceLink = "" } = squadData
      if (priceLink == "")
        return sum

      let hasSquad = (ownedSquads?[armyId] ?? {}).findvalue(@(s) s.squadId == id) != null
      return hasSquad ? sum : sum + (currentShopItems?[priceLink].shopItemPrice.price ?? 0)
    }, 0)
    if (additionalPrice > 0) {
      let shopItemModified = clone shopItem
      shopItemModified.shopItemPrice <- clone shopItemPrice
      if ("basePrice" not in shopItem.shopItemPrice) {
        shopItemModified.shopItemPrice.basePrice <- price
      }
      shopItemModified.shopItemPrice.price <- shopItemModified.shopItemPrice.basePrice + additionalPrice
      shopItems[key] <- shopItemModified
    }
    else
      shopItems[key] <- shopItem
  }
  return shopItems
})

function calcPriceWithDiscount(priceData, priceIncrement, discountInPercent) {
  let price = (priceData?.price ?? 0) + priceIncrement
  let res = priceData.__merge({ price, fullPrice = price })
  if (discountInPercent <= 0)
    return res

  res.price = price - price * discountInPercent / 100
  return res
}

let shopTreeRoute = Computed(function() {
  let res = {}
  let items = shopItemsBase.get()
  foreach (item in items){
    let { offerContainer = "" } = item
    if (offerContainer == "")
      continue
    foreach (army in item.armies){
      if (army not in res)
        res[army] <- {}
      res[army][offerContainer] <- item.id
    }
  }
  return res
})

function isInInterval(ts, interval = []){
  if (interval.len() == 0)
    return true
  let [from, to = 0] = interval
  return ts >= from && (to == 0 || ts < to)
}

let priorityDiscounts = Watched({})

function updateItemCost(sItem, purchases, allItems, shopTreeRouteVal) {
  local { shopItemPrice, discountInPercent = 0, discountIntervalTs = [] } = sItem
  local curItem = sItem
  let itemArmy = sItem?.armies[0] ?? ""
  let sTime = serverTime.get()
  if (!isInInterval(sTime, discountIntervalTs))
    discountInPercent = 0
  while (curItem && (curItem?.offerGroup ?? "") != ""){
    curItem = allItems?[shopTreeRouteVal?[itemArmy][curItem.offerGroup]]
    if ((curItem?.discountInPercent ?? 0) > discountInPercent
      && isInInterval(sTime, curItem?.discountIntervalTs)){
      discountInPercent = curItem.discountInPercent
      discountIntervalTs = curItem?.discountIntervalTs ?? []
    }
  }
  sItem.discountInPercent <- discountInPercent
  sItem.discountIntervalTs <- discountIntervalTs

  let amount = purchases?[sItem?.id].amount ?? 0
  let priceIncrement = amount * (sItem?.shopItemPriceInc ?? 0)
  sItem.curShopItemPrice <- calcPriceWithDiscount(shopItemPrice, priceIncrement, discountInPercent)

  return sItem
}

function updateStoreItemCost(sItem, gItem) {
  let item = {}.__update(sItem, gItem)
  let discountInPercent = gItem?.discount_mul
    ? ((100 * (1.0 - gItem.discount_mul)) + 0.5).tointeger()
    : 0

  local discountIntervalTs = []
  let showCountdown = (gItem?.discount_countdown ?? "0") != "0" 
  if (showCountdown && gItem?.discount_till && serverTime.get() < gItem.discount_till)
    discountIntervalTs = [ serverTime.get(), gItem.discount_till ]

  let resItem = item.__update({ discountInPercent, discountIntervalTs,
    curShopItemPrice = { price = 0, fullPrice = 0 } })
  return resItem
}

let itemsOfferResultCache = {}

function isItemAllowed(item, items) {
  let { offerContainer = "" } = item

  if (offerContainer == "") {
    let { isDmm = false, isHiddenForDmm = false, platforms = [] } = item
    if (!isPlatformRelevant(platforms))
      return false

    if (is_pc && ((!isDmmDistr && isDmm) || (isDmmDistr && isHiddenForDmm)))
      return false
    return true
  }

  if (offerContainer in itemsOfferResultCache)
    return itemsOfferResultCache[offerContainer]

  
  let result = items.findvalue(function(i) {
    return i?.offerGroup == offerContainer
      && (!is_pc || ((isDmmDistr && i?.isDmm) || !i?.isHiddenForDmm))
      && isPlatformRelevant(i?.platforms ?? [])
  }) != null

  itemsOfferResultCache[offerContainer] <- result
  return result
}

let shopItems = Computed(function() {
  
  let needsUpdate = shopDiscountGen.get() 
  let discounts = priorityDiscounts.get()
  let items = shopItemsBase.get()
  let goods = goodsInfo.get()
  let isNoFilter = debugNoFilter.get()
  itemsOfferResultCache.$clear() 
  let shopTreeRouteVal = shopTreeRoute.get()
  let purchasesCountVal = purchasesCount.get()
  let isAllowedFunc = mkCountrySpecificFilter()

  let res = {}
  foreach (guid, item in items)
    if (isItemAllowed(item, items)) {
      local newItem = item.__merge({ guid, curItemCost = item?.itemCost ?? {} })
      let offerDiscount = guid not in discounts ? {}
        : {
            discountInPercent = discounts[guid]
            discountIntervalTs = []
          }
      newItem.__update(offerDiscount, goods?[item?.purchaseGuid] ?? {})
      newItem = updateItemCost(newItem, purchasesCountVal, items, shopTreeRouteVal)

      let { purchaseGuid = null } = newItem
      if (goods?[purchaseGuid] && (newItem?.curShopItemPrice.fullPrice ?? 0) == 0)
        
        newItem = updateStoreItemCost(newItem, goods[purchaseGuid])
      if (isAllowedFunc(newItem) && (isShopItemSuitable(newItem) || isNoFilter))
        res[guid] <- newItem
    }
  return res
})

let shopItemsIntervals = Computed(function() {
  let discountIntervalItems = []
  let menuFeaturedIntervalItems = []
  let showIntervalItems = []
  let res = { discountIntervalItems, menuFeaturedIntervalItems, showIntervalItems }
  foreach (item in shopItems.get()) {
    let { discountIntervalTs = [], menuFeaturedIntervalTs = [], showIntervalTs = [] } = item
    if (discountIntervalTs.len() > 0)
      discountIntervalItems.append(item)
    if (menuFeaturedIntervalTs.len() > 0)
      menuFeaturedIntervalItems.append(item)
    if (showIntervalTs.len() > 0)
      showIntervalItems.append(item)
  }
  return res
})

console_register_command(function() {
  let isNoFilter = !debugNoFilter.get()
  debugNoFilter.set(isNoFilter)
  console_print("{0} filtered shop items".subst(isNoFilter ? "Show" : "Hide"))
}, "shop.toggleFiltered")

return {
  shopItemsBase
  shopItems
  shopItemsIntervals
  shopDiscountGen
  priorityDiscounts
  shopSquadsCompensations
  shopDecorsCompensations
}
