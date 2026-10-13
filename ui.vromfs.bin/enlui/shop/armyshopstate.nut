import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/shop/checkPurchases.nut" as checkPurchases
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
import "%ui/mainMenu/qrWindow.nut" as qrWindow
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/options/mkOnlinePersistentFlag.nut" import mkOnlinePersistentFlag
from "%ui/shop/unseenShopItems.nut" import seenShopItems, excludeShopItemSeen, getSeenStatus,
  SeenMarks
from "%ui/components/openUrl.nut" import openUrl
from "%ui/mainMenu/sectionsState.nut" import curSection, setCurSection, Section
from "%ui/shop/goodsAndPurchases_pc.nut" import marketIds
from "%ui/soldiers/model/state.nut" import curArmyData, curArmy, curCampItemsCount, armySquadsById,
  armyItemCountByTpl
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/reserve.nut" import hasCurArmyReserve
from "%ui/meta/clientApi.nut" import buy_shop_items, buy_shop_offer, barter_shop_items,
  check_purchases, buy_shop_items_list, barter_shop_items_multiple, buy_with_upgrade_items_multiple
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/currency/premium.nut" import hasPremium
from "%dngscripts/platform.nut" import is_pc, is_sony, is_gdk
from "%ui/consoleStore/consoleStore.nut" import openConsumable
from "%ui/soldiers/model/newItemsToShow.nut" import needNewItemsWindow, unseenReward
from "%ui/shop/dropRouletteState.nut" import dropRoulette
from "%ui/soldiers/model/cratesContent.nut" import getLoadedCrateContent, crateContentWatch,
  getShopListForItem, unpackCrate, getShopItemsContent
from "%ui/shop/currencyPresentation.nut" import currencyPresentation
from "%ui/shop/shopItems.nut" import shopItemsBase, shopItems, shopDiscountGen, shopItemsIntervals
from "%ui/profile/profileCountry.nut" import isPlayerRecommendedEmailRegistration
from "%ui/state/clientState.nut" import gameLanguage
from "%ui/featureFlags.nut" import PSNAllowShowQRCodeStore
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthProgress, GrowthStatus
from "%ui/soldiers/model/unseenWeaponry.nut" import updateArmoryIndex
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *
from "%ui/soldiers/model/boosters.nut" import recalcActiveBosters


const HAS_PC_STORE = is_pc && !is_gdk
let shopOrdersUsed = mkOnlinePersistentFlag("hasShopOrdersUsed")
let hasShopOrdersUsed = shopOrdersUsed.flag
let shopOrdersUsedActivate = shopOrdersUsed.activate


let itemToShopItem = mkComputedConfigGet("itemToShopItem", {})

let needGoodManage = Watched(false)
let goodManageData = Watched(null)

let marketIdPurchasable = keepref(Computed(function() {
  let res = {}
  foreach (item in shopItemsBase.get()) {
    let { purchaseGuid = "", itemCost = {}, storeId = "", devStoreId = "" } = item
    
    if (purchaseGuid != "" && itemCost.len() == 0 && storeId == "" && devStoreId == "") {
      res[purchaseGuid] <- true
      foreach (guid in (item?.aliasGuids ?? []))
        res[guid] <- true
    }
  }
  return res.keys()
}))

marketIds.set(marketIdPurchasable.get())
marketIdPurchasable.subscribe(@(v) marketIds.set(v))

let shopGroupItemsChain = mkWatched(persist, "shopGroupItemsChain", [])
curArmy.subscribe(@(_) shopGroupItemsChain.set([]))

let purchaseInProgress = Watched(null)
let shopItemToShow = Watched(null)
let shopItemsToHighlight = Watched(null)

curSection.subscribe(function(s) {
  if (s != Section.SHOP){
    shopGroupItemsChain.set([])
    shopItemsToHighlight.set(null)
    shopItemToShow.set(null)
  }
})

function subscribeIntervalUpdater(cb) {
  serverTime.subscribe(function(t) {
    if (t <= 0)
      return
    serverTime.unsubscribe(callee())
    cb()
  })
  if (serverTime.get() > 0)
    cb()
  shopItemsIntervals.subscribe(cb)
}




let purchaseIsPossible = Computed(@() purchaseInProgress.get() == null
  && !needNewItemsWindow.get())

let incrementDiscountGeneration = @() shopDiscountGen.modify(@(gen) gen + 1)

function updateDiscountIntervalsTimer(...) {
  let currentTs = serverTime.get()
  let { discountIntervalItems = [] } = shopItemsIntervals.get()
  let nextTime = discountIntervalItems.reduce(function(firstTs, item){
    let [from, to = 0] = item.discountIntervalTs
    return (currentTs < from && (from < firstTs || firstTs == 0)) ? from
      : (currentTs < to && (to < firstTs || firstTs == 0)) ? to
      : firstTs
  }, 0) - currentTs
  if (nextTime > 0)
    gui_scene.resetTimeout(nextTime, incrementDiscountGeneration)
}

subscribeIntervalUpdater(updateDiscountIntervalsTimer)

let curSwitchTime = Watched(0)

function updateShowIntervalsTimer(...) {
  let currentTs = serverTime.get()
  let { showIntervalItems = [] } = shopItemsIntervals.get()
  let nextTime = showIntervalItems.reduce(function(firstTs, item) {
    let [from, to = 0] = item.showIntervalTs
    return (currentTs < from && (from < firstTs || firstTs == 0)) ? from
      : (currentTs < to && (to < firstTs || firstTs == 0)) ? to
      : firstTs
  }, 0) - currentTs
  if (nextTime > 0)
    gui_scene.resetTimeout(nextTime, updateShowIntervalsTimer)
  curSwitchTime.set(currentTs)
}

subscribeIntervalUpdater(updateShowIntervalsTimer)

let shownByTimestamp = Computed(function() {
  let res = {}
  let ts = curSwitchTime.get()
  foreach (id, item in shopItems.get()) {
    let { showIntervalTs = null } = item
    if ((showIntervalTs?.len() ?? 0) == 0)
      continue

    let [from, to = 0] = showIntervalTs
    if (from <= ts && (ts < to || to == 0))
      res[id] <- true
  }
  return res
})

function canBarterItem(item, armyItemCount) {
  let { curItemCost = {} } = item
  if (curItemCost.len() == 0)
    return false

  foreach (payItemTpl, cost in curItemCost)
    if ((armyItemCount?[payItemTpl] ?? 0) < cost)
      return false

  return true
}

let isTemporaryVisible = @(itemId, shopItem, itemCount, itemsByTime)
  ((shopItem?.isVisibleIfCanBarter ?? false) && canBarterItem(shopItem, itemCount))
    || itemId in itemsByTime

function isAvailableBySquads(shopItem, squadsByArmyV) {
  let { squads = [] } = shopItem
  if (squads.len() == 0)
    return true

  foreach (squadData in squads) {
    let { id, armyId = null } = squadData
    let squad = squadsByArmyV?[armyId][id]
    if (squad == null || (squad?.expireTime ?? 0) > 0)
      return true
  }
  return false
}

let isAvailableByLimit = @(sItem, purchases)
  (sItem?.limit ?? 0) <= 0 || sItem.limit > (purchases?[sItem?.id].amount ?? 0)

function isShopItemAvailable(shopItem, squads, purchases) {
  let { isHiddenOnChinese = false } = shopItem
  return !(isChineseVersion && isHiddenOnChinese)
    && isAvailableBySquads(shopItem, squads)
    && isAvailableByLimit(shopItem, purchases)
}

let curArmyItemsPrefiltered = Computed(function() {
  let armyId = curArmyData.get()?.guid
  let itemCount = armyItemCountByTpl.get()
  let itemsByTime = shownByTimestamp.get()
  let squadsById = armySquadsById.get()
  let purchases = purchasesCount.get()
  return shopItems.get().filter(function(item, id) {
    let { armies = [], isHidden = false } = item
    return (armies.contains(armyId) || armies.len() == 0)
      && (!isHidden || isTemporaryVisible(id, item, itemCount, itemsByTime))
      && isShopItemAvailable(item, squadsById, purchases)
  })
})

let curArmyShopInfo = Computed(function() {
  let itemCount = armyItemCountByTpl.get()
  let itemsByTime = shownByTimestamp.get()
  local goods = curArmyItemsPrefiltered.get()
  let hasTemporary = goods.findindex(@(i, id)
    isTemporaryVisible(id, i, itemCount, itemsByTime)) != null
  goods = goods.values()
  return { goods, hasTemporary }
})

let curArmyShopItems = Computed(@() curArmyShopInfo.get().goods)

function trimTree(node, curFolder){
  let res = []
  for (local i=0; i<node.childItems.len(); i++){
    local subNode = node.childItems[i]
    if ((subNode?.offerContainer ?? "") == "")
      res.append(subNode)
    else {
      subNode = trimTree(subNode, curFolder)
      if (subNode)
        res.append(subNode)
    }
  }
  if (res.len() == 0)
    return null

  if (res.len() == 1 && node?.id != curFolder?.id)
    return res[0]

  node.childItems = res
  return node
}

function getGroup(groups, id) {
  if (id not in groups)
    groups[id] <- { childItems = [] }
  return groups[id]
}

function getCurShopTree(allItems){
  let groups = {}
  let rootItems = []

  foreach (item in allItems) {
    let { offerGroup = "", offerContainer = ""} = item
    let isContainer = offerContainer != ""
    let isInGroup = offerGroup != ""
    local itemToAppend = item

    if (isContainer)
      itemToAppend = getGroup(groups, offerContainer).__update(item)

    if (isInGroup)
      getGroup(groups, offerGroup).childItems.append(itemToAppend)

    else
      rootItems.append(itemToAppend)
  }
  return rootItems
}

let flatFolder = @(node) node.reduce(@(res, child) res.append(child), [])

let curFullTree = Computed(@() getCurShopTree(curArmyShopItems.get()))

let curArmyShopFolder = Computed(function(){
  let chain = shopGroupItemsChain.get()
  let fullTree = clone curFullTree.get()
  local tree = trimTree({childItems = fullTree}, chain?[chain.len()-1])
  let chainLen = (chain?.len() ?? 0)
  if (chainLen == 0)
    return { path = [], items = flatFolder(tree?.childItems ?? []) }

  local curChild = null
  local curFolder = null
  local depth = 0
  do {
    curFolder = chain[depth].offerContainer
    curChild = tree.childItems.findvalue(@(v) v?.offerContainer == curFolder)
    if (curChild){
      depth++
      tree = curChild
    }
  } while (curChild && depth < chainLen)
  return { path = chain.slice(0, depth), items = flatFolder(tree.childItems) }
})


let viewCurrencies = Watched(null)
let realCurrencies = Computed(function() {
  let itemsCount = curCampItemsCount.get()
  let res = {}
  foreach (currencyTpl, _ in currencyPresentation)
    res[currencyTpl] <- itemsCount?[currencyTpl] ?? 0
  return res
})

realCurrencies.subscribe(function(currencies) {
  if (viewCurrencies.get() != null)
    return
  viewCurrencies.set(clone currencies)
})

isLoggedIn.subscribe(function(isLogged) {
  if (!isLogged)
    viewCurrencies.set(null)
})

let curShopCurrencies = Computed(function() {
  let res = {}
  foreach (shopItem in curArmyShopItems.get()) {
    let { itemCost = null } = shopItem
    if (itemCost != null)
      res.__update(itemCost)
  }
  return res.keys()
})

let viewArmyCurrency = Computed(function() {
  let res = {}
  let viewCurrenciesVal = viewCurrencies.get()
  foreach (currencyTpl in curShopCurrencies.get())
    res[currencyTpl] <- viewCurrenciesVal?[currencyTpl] ?? 0

  let armyId = curArmy.get()
  let allItemTemplatesVal = allItemTemplates.get()
  return res.filter(@(count, tpl) count > 0
    || !(allItemTemplatesVal?[armyId][tpl].isZeroHidden ?? true))
})


function getBuyRequirementError(shopItem) {
  let requirements = shopItem?.requirements
  if ((requirements?.hasArmyReserve ?? false) && !hasCurArmyReserve.get())
    return {
      text = loc("shop/freePlaceForReserve")
      solvableByPremium = !hasPremium.get()
    }
  return null
}

let curAvailableShopItems = Computed(@()
  curArmyShopItems.get().filter(@(item) (item?.offerContainer ?? "") == ""))

function getUnseenGuids(tree, seen, avail) {
  let res = {}
  foreach (branch in tree) {
    let { guid, childItems = [] } = branch
    if (childItems.len() == 0) {
      if (guid not in seen && guid in avail)
        res[guid] <- true
      continue
    }

    let treeRes = getUnseenGuids(childItems, seen, avail)
    if (treeRes.len() == 0)
      continue

    res.__update(treeRes)
    res[guid] <- true
  }
  return res
}

let getGrStatus = @(growths, growthId) growths?[growthId].status ?? GrowthStatus.UNAVAILABLE

function getCantBuyDataBool(req, growths, grTiers) {
  let { growthId = "", growthTierId = "" } = req
  if (growthId != "" && getGrStatus(growths, growthId) != GrowthStatus.REWARDED)
    return true
  if (growthTierId != "" && getGrStatus(grTiers, growthTierId) < GrowthStatus.COMPLETED)
    return true
  return false
}

let availShopItems = Computed(function() {
  let res = {}
  let growthState = curGrowthState.get()
  let growthProgress = curGrowthProgress.get()
  foreach (item in curAvailableShopItems.get()) {
    let { featuredWeight = 0 } = item
    if (featuredWeight == 0) {
      let isLocked = getCantBuyDataBool(item.requirements, growthState, growthProgress)
      if (!isLocked)
        res[item.guid] <- true
    }
  }
  return res
})

let curUnseenAvailShopGuids = Computed(function() {
  let avail = availShopItems.get()
  let seen = seenShopItems.get().seen?[curArmy.get()] ?? {}
  let tree = curFullTree.get().filter(@(item) (item?.offerContainer ?? "") != ""
    || (item?.offerGroup ?? "") != "")
  return getUnseenGuids(tree, seen, avail)
})

curAvailableShopItems.subscribe(function(items) {
  let armyId = curArmy.get()
  let seen = seenShopItems.get().seen?[armyId] ?? {}
  if (seen.len() == 0)
    return

  let excludeList = []
  foreach (guid, _ in seen) {
    if (items.findindex(@(i) i.guid == guid) == null)
      excludeList.append(guid)
  }

  if (excludeList.len() == 0)
    return

  defer(@() excludeShopItemSeen(armyId, excludeList))
})

let premiumProducts = Computed(function() {
  let res = []
  foreach (i in shopItems.get())
    if ((i?.squads.len() ?? 0) == 0 
        && (i?.armies.len() ?? 0) == 0
        && (i?.crates.len() ?? 0) == 0
        && (i?.premiumDays ?? 0) > 0
        && (i?.curShopItemPrice.price ?? 0) > 0
        && (i?.curShopItemPrice.currencyId ?? "") != "")
      res.append(i)
  res.sort(@(a, b) (a?.premiumDays ?? 0) <=> (b?.premiumDays ?? 0))
  return res
})

function getCrateData(shopItem) {
  let crate = shopItem?.crates[0]
  return {
    crate
    possibleDrop = crate == null ? [] : unpackCrate(crate, crateContentWatch.get())
  }
}

function tryOpenRoulette(crateData) {
  let { crate, possibleDrop } = crateData
  if (crate == null)
    return

  recalcActiveBosters()
  let items = unseenReward.get()
  if (items.len() > 0 && possibleDrop.len() > 1) {
    dropRoulette.set({ crate, items, possibleDrop })
  }
}

function barterShopItem(shopItem, payData, cb = null, cnt = 1) {
  if (purchaseInProgress.get() != null)
    return

  purchaseInProgress.set(shopItem)
  shopItemToShow.set(shopItem)
  let crateData = getCrateData(shopItem)

  barter_shop_items(curArmy.get(), shopItem.guid, payData, cnt, function(res) {
    purchaseInProgress.set(null)
    shopOrdersUsedActivate()
    updateArmoryIndex(res)
    cb?(res?.error == null)
    tryOpenRoulette(crateData)
  })
}

function barterShopItemList(shopItemsList, itemData, payData, cb) {
  if (purchaseInProgress.get() != null)
    return

  purchaseInProgress.set(shopItemsList.top())

  barter_shop_items_multiple(curArmy.get(), itemData, payData, function(res) {
    purchaseInProgress.set(null)
    shopOrdersUsedActivate()
    updateArmoryIndex(res)
    cb?(res?.error == null)
  })
}

function buyWithUpgradeShopItemList(shopItemsList, itemData, payData, upgradeItemsCount, cb) {
  if (purchaseInProgress.get() != null)
    return

  if (shopItemsList.len() > 0)
    purchaseInProgress.set(shopItemsList.top())

  buy_with_upgrade_items_multiple(curArmy.get(), itemData, payData, upgradeItemsCount,
    function(res) {
      purchaseInProgress.set(null)
      cb?(res?.error == null)
    })
}

function buyShopItem(shopItem, currencyId, price, cb = null, count = 1) {
  if (purchaseInProgress.get() != null)
    return

  purchaseInProgress.set(shopItem)
  shopItemToShow.set(shopItem)
  let crateData = getCrateData(shopItem)

  buy_shop_items(curArmy.get(), shopItem.guid, currencyId, price, count, function(res) {
    purchaseInProgress.set(null)
    updateArmoryIndex(res)
    cb?(res?.error == null)
    tryOpenRoulette(crateData)
  })
}

function buyShopOffer(shopItem, currencyId, price, cb = null, pOfferGuid = null) {
  if (purchaseInProgress.get() != null)
    return

  purchaseInProgress.set(shopItem)
  shopItemToShow.set(shopItem)
  let crateData = getCrateData(shopItem)

  buy_shop_offer(curArmy.get(), shopItem.guid, currencyId, price, pOfferGuid, function(res) {
    purchaseInProgress.set(null)
    updateArmoryIndex(res)
    cb?(res?.error == null)
    tryOpenRoulette(crateData)
  })
}

function buyShopItemList(shopItemsList, itemData, payData, cb) {
  if (purchaseInProgress.get() != null)
    return

  purchaseInProgress.set(shopItemsList.top())

  buy_shop_items_list(curArmy.get(), itemData, payData, function(res) {
    purchaseInProgress.set(null)
    cb?(res?.error == null)
  })
}

function openPurchaseUrl(url) {
  openUrl(url)
  checkPurchases()
}

function buyCurrency(currency) {
  if (HAS_PC_STORE) {
    openPurchaseUrl(currency?.purchaseUrl ?? "")
    return
  }

  if ((!is_sony || PSNAllowShowQRCodeStore.get()) && isPlayerRecommendedEmailRegistration() && gameLanguage == "Russian") {
    qrWindow({
        header = currency?.locId ? loc(currency.locId) : ""
        url = currency?.qrConsoleUrl ?? "",
        needShowRealUrl = false,
        desc = currency?.qrDesc ? loc(currency.qrDesc) : ""
      },
      function() {
        openConsumable()
        checkPurchases()
      }
    )
    return
  }

  openConsumable()
  checkPurchases()
}

userInfo.subscribe(function(u) {
  if (u != null)
    check_purchases()
})
if (userInfo.get() != null)
  check_purchases()

function blinkCurrencies() {
  foreach (currencyTpl, count in viewArmyCurrency.get())
    if (count > 0)
      anim_start($"blink_{currencyTpl}")
}

function setupBlinkCurrencies() {
  if (curSection.get() != Section.SHOP || hasShopOrdersUsed.get())
    gui_scene.clearTimer(blinkCurrencies)
  else
    gui_scene.setInterval(2.5, blinkCurrencies)
}

subscribeList(setupBlinkCurrencies, curSection, hasShopOrdersUsed)
setupBlinkCurrencies()

function shopItemContentCtor(shopItem) {
  let { items = null, crates = null } = shopItem

  if ((items?.len() ?? 0) > 0) {
    let armyId = curArmy.get()
    let content = getShopItemsContent(items)
    if (content) {
      let [ itemCfg ] = items
      return WatchedRo({ id = itemCfg.itemTpl, armyId, content })
    }
  }

  if ((crates?.len() ?? 0) > 0) {
    let [ crateId ] = crates
    let armyId = curArmy.get()
    return Computed(function() {
      let content = getLoadedCrateContent(crateId, crateContentWatch.get())
      if (content)
        return { id = crateId, armyId, content }
      return null
    })
  }

  return null
}

function shopItemContentArrayCtor(shopItemW) {
  return Computed(function() {
    let armyId = curArmy.get()
    let res = []
    let { crates = [] } = shopItemW.get()
    foreach (crateId in crates) {
      let content = getLoadedCrateContent(crateId, crateContentWatch.get())
      if (content)
        res.append({ id = crateId, armyId, content })
    }
    return res
  })
}

function getShopItemPath(shopItem, allShopItems){
  let path = []
  local curOfferGroup = shopItem?.offerGroup ?? ""
  while(curOfferGroup != ""){
    shopItem = allShopItems.findvalue(@(v) v?.offerContainer == curOfferGroup)
    path.insert(0, shopItem)
    curOfferGroup = shopItem?.offerGroup ?? ""
  }
  return path
}

let getShopItems = @(tpl, armyId, itemToShopItemV, allItemTemplatesV, curArmyItemsPrefilteredV)
  getShopListForItem(tpl, armyId, itemToShopItemV, allItemTemplatesV)
    .map(@(shopItemId) curArmyItemsPrefilteredV?[shopItemId])

let getShopItemsCmp = @(tpl) Computed(function() {
  let items = getShopItems(tpl, curArmy.get(), itemToShopItem.get(), allItemTemplates.get(),
    curArmyItemsPrefiltered.get())
  if (items.len() > 0)
    return items

  let trimmedTpl = trimUpgradeSuffix(tpl)
  if (tpl == trimmedTpl)
    return []

  return getShopItems(trimmedTpl, curArmy.get(), itemToShopItem.get(), allItemTemplates.get(),
    curArmyItemsPrefiltered.get())
})

let getShopItemsList = @(tpl) getShopItems(tpl,
  curArmy.get(), itemToShopItem.get(), allItemTemplates.get(), curArmyItemsPrefiltered.get())

function openAndHighlightItems(targetShopItems, allShopItems){
  local longestPathIdx = -1
  local targetPath = []
  targetShopItems.each(function(v, i){
    let path = getShopItemPath(v, allShopItems)
    if (path.len() > targetPath.len()){
      targetPath = path
      longestPathIdx = i
    }
  })
  if (longestPathIdx != -1) {
    targetShopItems = clone targetShopItems
    targetShopItems.insert(0, targetShopItems.remove(longestPathIdx))
  }
  shopItemsToHighlight.set(targetShopItems)
  shopGroupItemsChain.set(targetPath)
  setCurSection(Section.SHOP)
}

let setCurArmyShopPath = @(path) shopGroupItemsChain.set(path)

let findSquadShopItem = @(armyId, squadId)
  curArmyShopItems.get().findvalue(function(sItem) {
    let { squads = [] } = sItem
    return squads.len() == 1 && squads[0].armyId == armyId && squads[0].id == squadId
  })

let notOpenedShopItems = Computed(function() {
  let opened = seenShopItems.get()?.opened[curArmy.get()] ?? {}
  let notOpenedGuids = curAvailableShopItems.get()
    .filter(@(item) getSeenStatus(opened?[item.guid]) == SeenMarks.NOT_SEEN)
    .map(@(item) item.guid)
  return notOpenedGuids
})

let isItemsShopOpened = mkWatched(persist, "isItemsShopOpened", false)

function isContentSoldier(content) {
  let { soldierClasses = [], soldierTierMin = -1 } = content
  return (soldierClasses.len() ?? 0) > 0 && soldierTierMin > 0
}

return {
  HAS_PC_STORE
  shownByTimestamp
  curArmyShopItems
  curArmyItemsPrefiltered
  itemToShopItem
  realCurrencies
  viewCurrencies
  viewArmyCurrency
  purchaseInProgress
  purchaseIsPossible
  buyShopItem
  buyShopOffer
  barterShopItem
  openPurchaseUrl
  buyCurrency
  buyShopItemList
  barterShopItemList
  buyWithUpgradeShopItemList
  getBuyRequirementError
  isAvailableByLimit
  curUnseenAvailShopGuids
  premiumProducts
  shopItemContentCtor
  shopItemContentArrayCtor
  isContentSoldier
  getShopItems
  getShopItemsCmp
  getShopItemsList
  openAndHighlightItems
  curArmyShopFolder
  setCurArmyShopPath
  findSquadShopItem
  notOpenedShopItems
  isItemsShopOpened
  needGoodManage
  goodManageData
  curAvailableShopItems
  isShopItemAvailable
}
