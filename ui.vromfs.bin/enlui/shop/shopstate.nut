import "%ui/soldiers/model/squadsParams.nut" as squadsParams
from "%ui/shop/shopPkg.nut" import getCantBuyData
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/state.nut" import curArmyData, curChosenSquads
from "%ui/meta/profile.nut" import curCampSoldiers
from "%ui/shop/armyShopState.nut" import curUnseenAvailShopGuids, notOpenedShopItems, curArmyItemsPrefiltered
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, curGrowthProgress, curGrowthTiers
from "%ui/researches/researchesSummary.nut" import classSlotLocksByArmy
from "%ui/helpers/metalink.nut" import getObjectsByLinkSorted, getLinkedArmyName, getItemIndex
from "%ui/ui_library.nut" import *
from "%ui/state/login_state.nut" import isSteamRunning

let curGroupIdx = Watched(0)
let curFeaturedIdx = Watched(0)
let chapterIdx = Watched(-1)
let curSelectionShop = Watched(null)

function canBarterItem(item, armyItemCount) {
  foreach (payItemTpl, cost in item.curItemCost)
    if ((armyItemCount?[payItemTpl] ?? 0) < cost)
      return false
  return true
}

let isTemporaryVisible = @(itemId, shopItem, itemCount, itemsByTime)
  ((shopItem?.isVisibleIfCanBarter ?? false) && canBarterItem(shopItem, itemCount))
    || itemId in itemsByTime

function mkShopState() {
  let mainOrders = {
    enlisted_silver = true
    weapon_order_gold = true
    soldier_order_gold = true
    vehicle_with_skin_order_gold = true
  }

  function hasPriceContainsSpecOrders(shopItem) {
    foreach (orderId, price in shopItem?.itemCost ?? {})
      if (orderId not in mainOrders && price > 0)
        return true
    return false
  }

  function premFilterFunc(shopItem) {
    if (hasPriceContainsSpecOrders(shopItem))
      return true

    return shopItem?.offerGroup == "premium_group"
  }

  let itemsGroupsChapters = {
    wpack_silver_pistol_group = 0
    wpack_silver_rifle_group = 1
    wpack_silver_submachine_gun_group = 2
    wpack_silver_special_group = 3
    item_group = 4
  }


  let sortItemsFunc = @(a, b) (a?.viewOrder ?? 1000) <=> (b?.viewOrder ?? 1000)

  let sortFeaturedFunc = @(a, b) (a?.featuredWeight ?? 0) <=> (b?.featuredWeight ?? 0)

  function getChapterItems(armyItems, chapterScheme) {
    let chapters = chapterScheme.map(@(weight) { container = null, goods = [], weight })
    foreach (sItem in armyItems) {
      let { offerContainer = "", offerGroup = "" } = sItem
      if (offerContainer in chapters)
        chapters[offerContainer].container = sItem
      if (offerGroup in chapters)
        chapters[offerGroup].goods.append(sItem)
    }
    chapters.each(@(chapter) chapter.goods.sort(sortItemsFunc))
    return chapters.values().sort(@(a, b) a.weight <=> b.weight)
  }

  let armyGroups = [
    {
      id = "premium"
      reqFeatured = true
      autoseenDelay = true
      filterFunc = premFilterFunc
    }
    {
      id = "weapon"
      locId = "soldierWeaponry"
      mkChapters = @(armyShopItems) getChapterItems(armyShopItems, itemsGroupsChapters)
    }
    {
      id = "soldier"
      locId = "menu/soldier"
      filterFunc = @(shopItem)
        shopItem?.offerGroup == "soldier_silver_group"
    }
    {
      id = "silver"
      filterFunc = @(shopItem) shopItem?.offerGroup == "enlisted_silver"
    }
    {
      id = "gold"
      filterFunc = @(shopItem) shopItem?.offerGroup == "enlisted_gold"
      hideDiscountTabs = true
      hideDiscountItems = isSteamRunning.get()
    }
  ]


  let curItemsByGroup = Computed(function() {
    let prefilteredItems = curArmyItemsPrefiltered.get()
    let res = {}
    foreach (group in armyGroups) {
      let { filterFunc = null, mkChapters = null } = group
      if (mkChapters != null) {
        let groupRes = []
        foreach (chapter in mkChapters(prefilteredItems))
          foreach (sItem in chapter.goods)
            groupRes.append(sItem)
        res[group.id] <- groupRes
      }
      else if (filterFunc != null)
        res[group.id] <- prefilteredItems
          .reduce(function(r, val) {
            if (filterFunc(val))
              r.append(val)
            return r
          }, [])
          .sort(sortItemsFunc)
    }
    return res
  })


  let curShopItemsByGroup = Computed(function() {
    let items = curItemsByGroup.get()
    let armyItems = curArmyItemsPrefiltered.get()
    return armyGroups.map(function(group) {
      let { id, locId = null, autoseenDelay = false, mkChapters = null, hideDiscountTabs = null,
        hideDiscountItems = null } = group
      return {
        id
        locId
        autoseenDelay
        goods = (items?[group.id] ?? []).filter(@(item) (item?.featuredWeight ?? 0) == 0)
        chapters = mkChapters?(armyItems)
        hideDiscountTabs
        hideDiscountItems
      }
    })
  })


  let maxDiscountByGroup = Computed(@() curItemsByGroup.get()
    .map(@(group) group.reduce(@(r, v) max(r, v?.hideDiscount ? 0 : v?.discountInPercent ?? 0), 0)))

  let specialOfferByGroup = Computed(@() curItemsByGroup.get()
    .map(@(group) group
      .findvalue(@(v) (v?.discountInPercent ?? 0) > 0 && v?.showSpecialOfferText) != null))

  let curFeaturedByGroup = Computed(@() curItemsByGroup.get()
    .map(@(group) group
      .filter(@(item) (item?.featuredWeight ?? 0) > 0)
      .sort(sortFeaturedFunc)
    ))


  let curShopDataByGroup = Computed(function() {
    let curUnseen = curUnseenAvailShopGuids.get()
    let curUnopened = {}
    foreach (guid in notOpenedShopItems.get())
      curUnopened[guid] <- true

    let maxDiscounts = maxDiscountByGroup.get()
    let specialOffer = specialOfferByGroup.get()
    let res = {}
    foreach (id, group in curItemsByGroup.get())
      res[id] <- {
        hasUnseen = group.findvalue(@(v) v.guid in curUnseen) != null
        unopened = group.filter(@(v) v.guid in curUnopened).map(@(v) v.guid)
        discount = maxDiscounts?[id] ?? 0
        showSpecialOffer = specialOffer?[id] ?? false
      }

    return res
  })

  function switchGroup() {
    let grCount = curShopItemsByGroup.get().len()
    curGroupIdx.set((curGroupIdx.get() + 1) % grCount)
    chapterIdx.set(-1)
  }

  function autoSwitchNavigation() {
    let groups = curShopItemsByGroup.get()
    let { group = null, chapter = null } = curSelectionShop.get()
    local groupIndex, chapterIndex

    curSelectionShop.set(null)

    if (chapter)
      foreach (k,v in groups) {
        chapterIndex = v.chapters?.findindex(@(g) g.container?.offerContainer == chapter)
        if (chapterIndex != null) {
          groupIndex = k
          break
        }
      }

    if (group) {
      groupIndex = groups.findindex(@(g) g.id == group)
    }

    if (groupIndex != null)
      curGroupIdx.set(groupIndex)
    if (chapterIndex != null)
      chapterIdx.set(chapterIndex)
    
  }

  return {
    curShopItemsByGroup
    curShopDataByGroup
    curFeaturedByGroup
    switchGroup
    autoSwitchNavigation
  }
}


let getCantBuyDataOnClick = @(shopItem)
  getCantBuyData(curArmyData.get(),
    shopItem?.requirements,
    curGrowthState.get(),
    curGrowthConfig.get(),
    curGrowthProgress.get(),
    curGrowthTiers.get(),
    allItemTemplates.get())


function getGoodManageObject(manageData) {
  if (manageData == null)
    return null
  let { soldier = null, weapon = null } = manageData

  if (soldier != null) {
    let allSquadsParams = squadsParams.get()
    let { sClass } = soldier
    foreach (squad in curChosenSquads.get()) {
      let armyId = getLinkedArmyName(squad)
      let suitableClasses = allSquadsParams?[armyId][squad.squadId].maxClasses ?? {}
      if ((suitableClasses?[sClass] ?? 0) > 0)
        return { squadId = squad.squadId }
    }
  }

  else if (weapon != null) {
    let { itemtype } = weapon
    foreach (squad in curChosenSquads.get()) {
      let armyId = getLinkedArmyName(squad)
      foreach(squadSoldier in getObjectsByLinkSorted(curCampSoldiers.get(), squad.guid, "squad")) {
        let { sClass, equipScheme } = squadSoldier
        foreach(slotName, slotData in equipScheme)
          if ((slotData?.itemTypes ?? []).contains(itemtype)) {
            let locked = (classSlotLocksByArmy.get()?[armyId][sClass] ?? []).contains(slotName)
            if (!locked)
              return {
                squadId = squad.squadId
                soldierIdx = getItemIndex(squadSoldier)
                manageSlotType = slotName
              }
          }
      }
    }
  }

  return null
}


return {
  mkShopState
  curGroupIdx
  curFeaturedIdx
  chapterIdx
  setAutoGroup = @(group) curSelectionShop.set({group})
  setAutoChapter = @(chapter) curSelectionShop.set({chapter})

  isTemporaryVisible
  getCantBuyDataOnClick
  getGoodManageObject
}
