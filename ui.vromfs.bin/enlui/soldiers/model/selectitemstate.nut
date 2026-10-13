import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/soldiers/model/equivalentItemsList.nut" as equivalentItemsList
from "%ui/soldiers/model/state.nut" import getEquippedItemGuid, armoryByArmy, getScheme, getItemOwnerSoldier, getSoldierItemSlots, getDemandingSlots, curArmy
from "%ui/meta/profile.nut" import campItemsByLink, soldiersByArmies, curCampSoldiers, curCampItems
from "%ui/soldiers/model/itemActions.nut" import equipItem, massEquipItems
from "%ui/researches/researchesSummary.nut" import classSlotLocksByArmy, upgradeLocksByArmy
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate, itemTypesInSlots
from "%ui/soldiers/model/config/equipIncreaseConfig.nut" import equipSlotIncreaseCfg
from "%ui/soldiers/model/items_list_lib.nut" import prepareItems, addShopItems, itemsSort
from "%ui/components/soldierClasses.nut" import soldierClasses
from "%ui/soldiers/model/soldierSlotsCount.nut" import soldierSlotsCount
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/components/itemsInfo.nut" import getObjectName, trimUpgradeSuffix
from "%ui/mainMenu/sectionsState.nut" import curSection
from "%ui/state/roomState.nut" import RoomState, isInRoom, roomState, roomIsLobby
from "%ui/soldiers/model/squadInfoState.nut" import isObjGuidBelongToRentedSquad
from "%ui/soldiers/components/squadsComps.nut" import showRentedSquadLimitsBox
from "%ui/soldiers/model/cratesContent.nut" import getShopListForItem
from "%ui/shop/armyShopState.nut" import curArmyItemsPrefiltered, itemToShopItem
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/soldiers/model/unseenWeaponry.nut" import markSeenSlot
from "%ui/growth/growthState.nut" import curGrowthConfig, curGrowthState, curGrowthProgress, GrowthStatus
from "%ui/ui_library.nut" import *

let { equipSlotTbl } = require("%ui/soldiers/model/config/equipGroups.nut")

const MAX_ITEM_BR = 5

let selectParamsList = mkWatched(persist, "selectParamsList", [])
let selectParams = Computed(@() selectParamsList.get().len() ? selectParamsList.get().top() : null)
let selectParamsArmyId = Computed(@() selectParams.get()?.armyId)

let curEquippedItem = Computed(function() {
  let { ownerGuid = null, slotType = null, slotId = null } = selectParams.get()
  if (ownerGuid == null || slotType == null)
    return null
  let guid = getEquippedItemGuid(campItemsByLink.get(), ownerGuid, slotType, slotId)
  return curCampItems.get()?[guid]
})

let curInventoryItem = Watched(null)
curCampItems.subscribe(@(_) curInventoryItem.set(null))

let viewItem = Computed(@() curInventoryItem.get() ?? curEquippedItem.get()) 
let isWeaponFixed = Computed(@() curEquippedItem.get()?.isFixed ?? false)

function excludeItems(item, curArmyShopItemsPrefV, curArmyV, allItemTemplatesV, itemToShopItemV){
  if (item.guid != "")
    return true
  let tpl = item.basetpl
  let shopItemIds = getShopListForItem(tpl, curArmyV, itemToShopItemV, allItemTemplatesV)
  return (shopItemIds.len() >= 1 && shopItemIds[0] in curArmyShopItemsPrefV)
}

function calcItems(params, objInfoByGuidV, armoryByArmyV, curArmyShopItemsPrefV,
  itemToShopItemV, allItemTemplatesV) {
  let { armyId = null, filterFunc = @(_tplId, _tpl) true } = params
  if (!armyId)
    return []

  let itemTemplatesVal = allItemTemplates.get()
  local itemsList = prepareItems((armoryByArmyV?[armyId] ?? [])
    .filter(@(item)
      item && filterFunc(item.basetpl, findItemTemplate(itemTemplatesVal, armyId, item.basetpl))),
      objInfoByGuidV)
  addShopItems(itemsList, armyId, @(tplId, tpl)
    filterFunc(tplId, tpl) && (tpl?.upgradeIdx ?? 0) == 0)
  itemsList = itemsList.filter(@(item)
    excludeItems(item, curArmyShopItemsPrefV, armyId, allItemTemplatesV, itemToShopItemV))
  return itemsList.sort(itemsSort)
}

function calcOther(params, armoryByArmyV, itemTypesInSlotsV) {
  let { slotType = null, armyId = null, filterFunc = @(_tplId, _tpl) true } = params
  if (!armyId)
    return []

  let allTypes = itemTypesInSlotsV?[slotType]
  let itemTemplatesVal = allItemTemplates.get()
  local otherList = (armoryByArmyV?[armyId] ?? [])
    .filter(@(item) item
      && !filterFunc(item.basetpl, findItemTemplate(itemTemplatesVal, armyId, item.basetpl))
      && allTypes?[item?.itemtype])

  otherList = prepareItems(otherList, curCampItems.get())
  addShopItems(otherList, armyId, @(tplId, tpl)
    (allTypes?[tpl.itemtype] ?? false) && !filterFunc(tplId, tpl) && (tpl?.upgradeIdx ?? 0) == 0)
  otherList.sort(itemsSort)
  return otherList
}

let slotItems = Computed(@() isWeaponFixed.get() ? []
  : calcItems(selectParams.get(), curCampItems.get(), armoryByArmy.get(),
      curArmyItemsPrefiltered.get(), itemToShopItem.get(), allItemTemplates.get()))

let inventoryItems = Computed(function() {
  let res = {}
  foreach (item in slotItems.get())
    if (!(item?.isShopItem ?? false))
      res[item.basetpl] <- item
  return res
})

let otherSlotItems = Computed(@() isWeaponFixed.get() ? []
  : calcOther(selectParams.get(), armoryByArmy.get(), itemTypesInSlots.get()))

function mkDefaultFilterFunc(showItemTypes = [], showItems = []) {
  let isFilterTypes = (showItemTypes?.len() ?? 0) != 0
  return (showItems?.len() ?? 0) != 0
    ? (isFilterTypes
      ? @(tmpl, item) showItems.contains(trimUpgradeSuffix(tmpl))
          || showItemTypes.contains(item?.itemtype)
      : @(tmpl, _) showItems.contains(trimUpgradeSuffix(tmpl)))
    : (isFilterTypes
      ? @(_, item) showItemTypes.contains(item?.itemtype)
      : @(_0, _1) true)
}

let paramsForPrevItems = Computed(function() {
  let { soldierGuid = null, ownerGuid = null, armyId = null } = selectParams.get()
  if (soldierGuid != null)
    return null

  let ownerItem = curCampItems.get()?[ownerGuid]
  if (ownerItem == null)
    return null

  return {
    armyId = armyId
    ownerGuid = ownerGuid
    soldierGuid = soldierGuid
    filterFunc = mkDefaultFilterFunc([ownerItem?.itemtype])
    ownerName = getObjectName(ownerItem)
  }
})

let prevItems = Computed(@()
  calcItems(paramsForPrevItems.get(), curCampItems.get(), armoryByArmy.get(),
    curArmyItemsPrefiltered.get(), itemToShopItem.get(), allItemTemplates.get())
    .filter(@(item) "guid" in item))


function markLastViewedSlot() {
  let params = selectParams.get()
  if (params == null)
    return

  let { armyId, soldierGuid, slotType } = params
  markSeenSlot(armyId, soldierGuid, slotType)
}

function openSelectItem(armyId, ownerGuid, slotType, slotId = -1) {
  if (ownerGuid == null)
    return
  let ownerItem = curCampItems.get()?[ownerGuid] ?? curCampSoldiers.get()?[ownerGuid]
  if (!ownerItem) {
    
    return
  }
  let scheme = getScheme(ownerItem, slotType)
  if (!scheme) {
    
    
    
    return
  }

  let soldierGuid = ownerGuid in curCampSoldiers.get()
    ? ownerGuid
    : getItemOwnerSoldier(ownerGuid)?.guid

  markLastViewedSlot()

  let params = {
    armyId
    ownerGuid
    soldierGuid
    slotType
    slotId
    scheme
    filterFunc = mkDefaultFilterFunc(scheme?.itemTypes, scheme?.items)
    ownerName = getObjectName(ownerItem)
  }
  selectParamsList.mutate(function(l) {
    let idx = l.findindex(@(p) p?.soldierGuid == soldierGuid)
    if (idx != null)
      l.resize(idx)
    l.append(params)
  })
  curInventoryItem.set(null) 
}

function selectInsideListSlot(dir, doWrap) {
  let params = selectParams.get()
  if (params == null)
    return false

  local { armyId, ownerGuid, slotType, slotId } = params
  let curScheme = curSoldierInfo.get()?.equipScheme ?? {}
  let size = soldierSlotsCount(ownerGuid, curScheme)?[slotType] ?? 0

  if (size <= 1)
    return false
  slotId = slotId + dir
  if (doWrap)
    slotId = (slotId + size) % size
  else if (slotId < 0 || slotId >= size)
    return false

  openSelectItem(armyId, ownerGuid, slotType, slotId)
  return true
}

function selectSlot(dir) {
  let params = selectParams.get()
  if (params == null || selectInsideListSlot(dir, false))
    return

  local { slotType } = params
  let { equipScheme = {}, sClass = "unknown" } = curSoldierInfo.get()
  let { armyId, ownerGuid } = params
  let lockedSlotList = classSlotLocksByArmy.get()?[armyId][sClass] ?? []

  let availableSlotTypes = equipSlotTbl
    .keys()
    .filter(@(sType) sType in equipScheme
      && !equipScheme[sType]?.isDisabled
      && !equipScheme[sType]?.isLocked
      && !lockedSlotList.contains(sType))
    .sort(@(a, b)
      (equipScheme[a]?.uiOrder ?? 0) <=> (equipScheme[b]?.uiOrder ?? 0)) 

  local slotIdx = availableSlotTypes.indexof(slotType)
  if (slotIdx == null)
    return

  slotIdx += dir
  if (slotIdx < 0 || slotIdx >= availableSlotTypes.len())
    return

  slotType = availableSlotTypes[slotIdx]
  let subslotsCount = soldierSlotsCount(curSoldierInfo.get()?.guid, equipScheme)?[slotType] ?? 0
  let slotId = subslotsCount < 1 ? -1
    : dir < 0 ? subslotsCount - 1
    : 0

  openSelectItem(armyId, ownerGuid, slotType, slotId)
}

function itemClear() {
  if (selectParamsList.get().len() > 0)
    selectParamsList.mutate(@(l) l.remove(l.len() - 1))
  if (selectParams.get() == null)
    curInventoryItem.set(null) 
}

curSection.subscribe(@(_) itemClear())

enum ItemCheckResult {
  NEED_RESEARCH = 0
  WRONG_CLASS = 1
  IN_SHOP = 2
}

function checkSelectItem(item) {
  let { basetpl = null, itemtype = null, isShopItem = false } = item
  let soldier = curSoldierInfo.get()
  if (basetpl == null || soldier == null)
    return null

  let trimmed = trimUpgradeSuffix(basetpl)
  let armyId = getLinkedArmyName(soldier)
  let { sClass = "unknown", equipScheme = {} } = soldier
  let sClassLoc = loc(soldierClasses?[sClass].locId ?? "unknown")

  let { slotType = null,scheme = {} } = selectParams.get()
  let slotsLocked = classSlotLocksByArmy.get()?[armyId][sClass] ?? []
  if (slotsLocked.contains(slotType))
    return {
      result = ItemCheckResult.NEED_RESEARCH
      soldierClass = sClassLoc
      soldier
      slotType
    }

  let itemTypes = equipScheme?[slotType].itemTypes ?? []
  let itemList = scheme?.items ?? []
  if ((itemTypes.len() != 0 || itemList.len() != 0)
    && !itemTypes.contains(itemtype)
    && !itemList.contains(trimmed))
    return {
      result = ItemCheckResult.WRONG_CLASS
      soldierClass = sClassLoc
    }

  if (isShopItem){
    return {
      result = ItemCheckResult.IN_SHOP
    }
  }

  return null
}

function selectItem(item, cb = null) {
  
  if (item?.basetpl == curEquippedItem.get()?.basetpl
      || (item?.isFixed ?? false))
    return

  let { slotType = null, slotId = null, ownerGuid = null } = selectParams.get()

  if (ownerGuid != null && isObjGuidBelongToRentedSquad(ownerGuid)) {
    showRentedSquadLimitsBox()
    return
  }

  equipItem(item?.guid, slotType, slotId, ownerGuid, cb)
}

let defaultSortOrder = {
  explosion_pack = 6
  impact_grenade = 5
  incendiary_grenade = 4
  grenade = 3
  molotov = 2
  antipersonnel_mine = 2
  antitank_mine = 1
  smoke_grenade = 1
  medkits = 1
  axe = 1
  shovel = 1
  sword = 3
}

let classSortOrder = {
  tanker = { repair_kit = 2 }
  sniper = { smoke_grenade = 5 }
  engineer = { shovel = 2 }
  assault = { assault_rifle = 4, assault_semi = 3, submgun = 2, shotgun = 1 }
}

let unwantedTypes = { boltaction_noscope = true, melee = true }

function getBetterItem(items, count, sortFunc) {

  let betterTypeAndTier = @(a, b) ((b?.itemtype ?? "") not in unwantedTypes)
      <=> ((a?.itemtype ?? "") not in unwantedTypes)
    || (b?.growthTier ?? 0) <=> (a?.growthTier ?? 0)
    || sortFunc(a, b)
    || (b?.upgradeIdx ?? 0) <=> (a?.upgradeIdx ?? 0)
    || (a?.guid ?? "") <=> (b?.guid ?? "")

  return items.sort(betterTypeAndTier).slice(0, count) 
}

let getWorseItem = @(items, count, _sortFunc = null) items
  .sort(@(a, b) ((b?.itemtype ?? "") in unwantedTypes) 
      <=> ((a?.itemtype ?? "") in unwantedTypes)
    || (a?.growthTier ?? 0) <=> (b?.growthTier ?? 0)
    || (a?.upgradeIdx ?? 0) <=> (b?.upgradeIdx ?? 0)
    || (a?.sign ?? 0) <=> (b?.sign ?? 0))
  .slice(0, count)

let getBR = @(item) item?.growthTier ?? 1

function getItemForSlot(soldier, inventory, slotType, count, chooseFunc, armyId, maxBR) {
  let sortOrder = defaultSortOrder.__merge(classSortOrder?[soldier.sClass] ?? {})
  let sortFunc = @(a, b) (sortOrder?[b?.itemtype] ?? 0) <=> (sortOrder?[a?.itemtype] ?? 0)

  let { itemTypes = [], items = [] } = getScheme(soldier, slotType)
  if (itemTypes.len() == 0 && items.len() == 0)
    return null

  let filterCb = mkDefaultFilterFunc(itemTypes, items)

  let itemTemplatesVal = allItemTemplates.get()
  let itemsList = inventory
    .filter(@(item) !(item?.isFixed ?? false) && getBR(item) <= maxBR
      && filterCb(item.basetpl, findItemTemplate(itemTemplatesVal, armyId, item.basetpl)))
  return chooseFunc(itemsList, count, sortFunc)
}

let sameTypeTier = @(item1, item2) item1 != null && item2 != null
  && item1.itemtype == item2.itemtype
  && (item1?.growthTier ?? 0) == (item2?.growthTier ?? 0)
  && (item1?.sign ?? 0) == (item2?.sign ?? 0)

function getAlternativeEquipList(soldier, slotsItems, chooseFunc, excludeSlots, maxBR) {
  let armyId = getLinkedArmyName(soldier)
  let owner = curCampSoldiers.get()?[soldier.guid]
  let filteredItems = slotsItems
    .filter(@(i) !(excludeSlots.findindex(@(v) v.slotType == i.slotType) != null
      && excludeSlots.findindex(@(v) v.slotId == i.slotId) != null))

  let sortOrder = defaultSortOrder.__merge(classSortOrder?[soldier.sClass] ?? {})
  let sortFunc = @(a, b)
    (sortOrder?[b.itemtype] ?? 0) <=> (sortOrder?[a.itemtype] ?? 0)

  let equipList = []
  foreach (slotsItem in filteredItems) {
    let { slotType, slotId } = slotsItem
    let chosenItem = slotsItem?.item
    if (chosenItem?.isFixed ?? false)
      continue

    let itemsFromInventory = getItemForSlot(soldier, armoryByArmy.get()?[armyId] ?? [],
      slotType, 1, chooseFunc, armyId, maxBR)

    if (itemsFromInventory.len() == 0) {
      
      if (maxBR < getBR(chosenItem)) {
        let required = getDemandingSlots(slotType, owner, campItemsByLink.get())
        if (required.len() <= 0)
          equipList.append({ slotType, slotId, guid = "" })
      }
      continue
    }

    local candidateItem = itemsFromInventory.top() 
    if (maxBR >= getBR(chosenItem)) {
      
      candidateItem = chooseFunc([chosenItem, candidateItem], 1, sortFunc).top()
    }

    if (!sameTypeTier(chosenItem, candidateItem))
      equipList.append({ slotType, slotId, guid = candidateItem.guid })
  }
  return equipList
}

let curCanUnequipSoldiersList = Computed(function() {
  let res = {}
  let itemsByLink = campItemsByLink.get()
  let infoByGuid = curCampSoldiers.get()
  let soldiers = soldiersByArmies.get()?[curArmy.get()] ?? {}
  foreach (guid, _ in soldiers) {
    let slotsItems = getSoldierItemSlots(guid, itemsByLink)
    foreach (slotsItem in slotsItems) {
      let { slotType } = slotsItem
      let demands = getDemandingSlots(slotType, infoByGuid?[guid], itemsByLink)
      if (demands.len() == 0 || demands.filter(@(i) i != null).len() > 1) {
        res[guid] <- true
        break
      }
    }
  }
  return res
})

let AUTO_SLOTS = [
  "grenade", "inventory", "mine", "binoculars_usable", "flask_usable"
]

function cleanByValues(src, val) {
  foreach (key in src.keys())
    if (src[key] == val)
      src.$rawdelete(key)
}

function getEmptyNeededSlots(slotsItems, equipScheme) {
  let slotToGroup = {}
  foreach (slotType, slot in equipScheme) {
    let { atLeastOne = "" } = slot
    if (atLeastOne != "")
      slotToGroup[slotType] <- atLeastOne
  }
  foreach (item in slotsItems)
    if (item.slotType in slotToGroup)
      cleanByValues(slotToGroup, slotToGroup[item.slotType])
  return slotToGroup
}

function getPossibleEquipList(soldier, slotsItems, maxBR, soldierSlotsCountTbl) {
  let { equipScheme = {} } = soldier
  let emptySlotsTypes = getEmptyNeededSlots(slotsItems, equipScheme)

  local freeSlots = {}
  foreach (slotType, count in soldierSlotsCountTbl) {
    freeSlots[slotType] <- {}
    for (local i = 0; i < count; i++) {
      freeSlots[slotType][i] <- true
    }
  }

  foreach (equippedItem in slotsItems) {
    let { slotType, slotId } = equippedItem
    if (slotType in freeSlots)
      if (slotId == -1)
        freeSlots[slotType].clear()
      else if (slotId in freeSlots[slotType])
        freeSlots[slotType].$rawdelete(slotId)
  }

  let reqSlotsList = AUTO_SLOTS.filter(@(slotType)
    slotType in freeSlots && freeSlots[slotType].len() > 0)

  let equipList = []
  if (reqSlotsList.len() == 0 && emptySlotsTypes.len() == 0)
    return equipList

  let armyId = getLinkedArmyName(soldier)
  let inventory = armoryByArmy.get()?[armyId] ?? []

  foreach (slotType in reqSlotsList) {
    let slotList = freeSlots?[slotType] ?? {}
    if (slotList.len() == 0)
      continue

    let chosenItems = getItemForSlot(soldier, inventory, slotType, slotList.len(),
      getBetterItem, armyId, maxBR)

    let emptySlots = slotList.keys()
    foreach (i, newItem in chosenItems) {
      
      equipList.append({ slotType, slotId = emptySlots[i], guid = newItem.guid })
    }
  }

  
  foreach (slotType in emptySlotsTypes.keys()) {
    let newItemList = getItemForSlot(soldier, inventory, slotType, 1,
      getBetterItem, armyId, maxBR)

    if (newItemList.len() > 0 && slotType in emptySlotsTypes) {
      cleanByValues(emptySlotsTypes, emptySlotsTypes[slotType])
      foreach (newItem in newItemList)
        equipList.append({ slotType, slotId = -1, guid = newItem.guid })
    }
  }

  return equipList
}

function getArmoryItemCount(inventory, templatesBySlots, equivalentItemsListVal) {
  let templates = {}

  foreach (listByBR in templatesBySlots)
    foreach (templateList in listByBR)
      foreach (tpl in templateList)
        templates[tpl] <- true

  foreach (tpl in templates.keys()) {
    let sameItems = equivalentItemsListVal.findvalue(@(list) list.contains(tpl)) ?? []
    foreach (itemTpl in sameItems)
      templates[itemTpl] <- true
  }

  let countByTemplate = {}
  foreach (item in inventory) {
    let { basetpl = "" } = item
    if ((basetpl not in templates) && (trimUpgradeSuffix(basetpl) not in templates))
      continue

    countByTemplate[basetpl] <- 1 + (countByTemplate?[basetpl] ?? 0)
  }

  return countByTemplate
}

function addTemplate(growthTier, templateId, key, schemeTbl, result) {
  local isAdded = false
  foreach (slotType, _ in schemeTbl?[key] ?? {}) {
    let saved = result?[slotType] ?? {}
    let templates = saved?[growthTier] ?? []
    templates.append(templateId)
    saved[growthTier] <- templates
    result[slotType] <- saved
    isAdded = true
  }
  return isAdded
}

function highestUpgrade(templates, lockedUpgrades, templateId) {
  local { upgradeitem = "" } = templates?[templateId]
  while (upgradeitem != "" && !lockedUpgrades.contains(upgradeitem)) {
    templateId = upgradeitem
    upgradeitem = templates?[templateId].upgradeitem ?? ""
  }
  return templateId
}

let getGrStatus = @(growths, growthId) growths?[growthId].status ?? GrowthStatus.UNAVAILABLE
let getOrder = @(templates, sortOrder, tmpl) sortOrder?[templates?[tmpl].itemtype ?? ""] ?? 0

let slotPriority = {
  other = @(_, _) true
  backpack = function(templates, tmpl) {
    if (templates?[tmpl].slot != "backpack")
      return 0

    foreach (templatesTbl in equipSlotIncreaseCfg.get())
      if (tmpl in templatesTbl)
        return templatesTbl[tmpl]
    return 0
  }
}

function getBREquipList(soldier, slotsItems, _chooseFunc, notFoundItemsWatch, maxBR) {
  let armyId = getLinkedArmyName(soldier)

  let { equipScheme = {}, sClass } = soldier
  let byItems = {}
  let byItemTypes = {}
  foreach (slotType, slotScheme in equipScheme) {
    if (slotType == "secondary"
        || (classSlotLocksByArmy.get()?[armyId][sClass] ?? []).contains(slotType))
      continue

    let { itemTypes = [], items = [] } = slotScheme
    foreach (itemtype in itemTypes) {
      let slots = byItemTypes?[itemtype] ?? {}
      slots[slotType] <- true
      byItemTypes[itemtype] <- slots
    }
    foreach (basetpl in items) {
      let slots = byItems?[basetpl] ?? {}
      slots[slotType] <- true
      byItems[basetpl] <- slots
    }
  }

  let bySlots = {}
  let growths = curGrowthState.get()
  let grTiers = curGrowthProgress.get()
  let templates = allItemTemplates.get()?[armyId] ?? {}
  foreach (templateId, template in templates) {
    let { growthTier = 0, itemtype = "" } = template
    let shopItemId = itemToShopItem.get()?[armyId][templateId][0]
    let shopItem = curArmyItemsPrefiltered.get()?[shopItemId]
    if (growthTier > maxBR || shopItem == null)
      continue

    let { requirements = {} } = shopItem
    let { growthId = "", growthTierId = "" } = requirements
    if ((growthId != "" && getGrStatus(growths, growthId) != GrowthStatus.REWARDED)
        || (growthTierId != "" && getGrStatus(grTiers, growthTierId) < GrowthStatus.COMPLETED))
      continue

    let inItems = addTemplate(growthTier, templateId, templateId, byItems, bySlots) 
    if (!inItems)
      addTemplate(growthTier, templateId, itemtype, byItemTypes, bySlots)
  }

  let sKind = sClassesCfg.get()?[sClass].kind ?? sClass 
  let sortOrder = defaultSortOrder.__merge(classSortOrder?[sKind] ?? {})
  let growthConfig = curGrowthConfig.get()

  let newItems = {}
  let sameItemsList = {}
  let slotsSizes = {}
  let slotsIncreaseCfg = equipSlotIncreaseCfg.get()
  foreach (slotType, slotData in equipScheme) {
    let itemsForSlot = bySlots?[slotType] ?? {}
    let { listSize = 0 } = slotData
    let slotId = listSize - 1
    let { item = null } = slotsItems
      .findvalue(@(slot) slotType == slot.slotType && slotId == slot.slotId)
    if (item?.isFixed ?? false)
      continue

    for (local i = maxBR; i >= 0; i--) {
      if (i not in itemsForSlot)
        continue

      let slotPriorityFn = slotPriority?[slotType] ?? slotPriority.other

      let sortedItems = itemsForSlot[i].sort(@(a, b)
        (growthConfig?[b].col ?? 0) <=> (growthConfig?[a].col ?? 0)
          || slotPriorityFn(templates, b) <=> slotPriorityFn(templates, a)
          || getOrder(templates, sortOrder, b) <=> getOrder(templates, sortOrder, a))

      let lockedUpgrades = upgradeLocksByArmy.get()?[armyId] ?? []
      local itemTpl = highestUpgrade(templates, lockedUpgrades, sortedItems[0])

      let sameItems = equivalentItemsList.get()
        .findvalue(@(list) list.contains(itemTpl)) ?? []
      sameItemsList[slotType] <- sameItems

      let { basetpl = null } = item
      if (sameItems.contains(basetpl))
        itemTpl = basetpl

      newItems[slotType] <- itemTpl

      slotsSizes[slotType] <- listSize + (slotsSizes?[slotType] ?? 0)
      if (slotType == "backpack")
        foreach (expandedSlot, tplsList in slotsIncreaseCfg) {
          if (itemTpl in tplsList) {
            slotsSizes[expandedSlot] <- tplsList[itemTpl] + (slotsSizes?[expandedSlot] ?? 0)
            break
          }
        }
      break
    }
  }

  let armoryItemCount = getArmoryItemCount(armoryByArmy.get()?[armyId],
    bySlots, equivalentItemsList.get())

  let equipList = []
  let purchaseItems = {}
  let usedItems = {}
  foreach (slotType, tpl in newItems) {
    let maxSlotIdx = slotsSizes?[slotType] ?? 0
    local curSlotId = maxSlotIdx > 0 ? 0 : -1
    while (curSlotId < maxSlotIdx) {
      let sameItems = sameItemsList?[slotType] ?? []
      let itemTpl = sameItems.findvalue(@(tmpl) (armoryItemCount?[tmpl] ?? 0) > 0) ?? tpl

      let inventoryItem = (armoryItemCount?[itemTpl] ?? 0) <= 0
        ? null
        : armoryByArmy.get()?[armyId].findvalue(@(invItem)
            (invItem.guid not in usedItems)
              && (invItem.basetpl == itemTpl || sameItems.contains(invItem.basetpl)))

      let isFromShop = inventoryItem == null
      equipList.append({
        slotType
        slotId = curSlotId
        itemTpl
        item = inventoryItem
        shopItem = isFromShop ? itemTpl : null
      })

      if (isFromShop)
        purchaseItems[itemTpl] <- (purchaseItems?[itemTpl] ?? 0) + 1
      else {
        armoryItemCount[itemTpl]--
        usedItems[inventoryItem.guid] <- true
      }
      curSlotId++
    }
  }

  notFoundItemsWatch.set(purchaseItems)
  return equipList
}

let calcRatingByTypeTier = @(sortOrder, item)
  ((sortOrder?[item?.itemtype] ?? 0) << 4) + (item?.growthTier ?? 0)

function addReplacementItem(toReplace, sortOrder, ownerGuid, slotType, slotsItem) {
  if (toReplace == null || (slotsItem?.item.isFixed ?? false))
    return
  
  
  
  
  local slotTypeData = toReplace?[slotType]
  if (slotTypeData == null) {
    slotTypeData = {}
    toReplace[slotType] <- slotTypeData
  }

  let itemRating = calcRatingByTypeTier(sortOrder, slotsItem.item)
  if (itemRating == 0)
    return

  local itemRatingData = slotTypeData?[itemRating]
  if (itemRatingData == null) {
    itemRatingData = {}
    slotTypeData[itemRating] <- itemRatingData
  }
  itemRatingData[ownerGuid] <- slotsItem.item.guid
}

function getPossibleUnequipList(ownerGuid, slotsItems, toReplace = null, sortOrder = null) {
  let itemsByLink = campItemsByLink.get()
  let infoByGuid = curCampSoldiers.get()
  let equipList = []
  let unequipped = {}
  foreach (slotsItem in slotsItems) {
    if (slotsItem?.item.isFixed ?? false)
      continue

    let { slotType, slotId } = slotsItem
    let listByDemands = getDemandingSlots(slotType, infoByGuid?[ownerGuid], itemsByLink)
    if (listByDemands.len() > 0
      && listByDemands.filter(@(i) i != null && i not in unequipped).len() <= 1) {
        addReplacementItem(toReplace, sortOrder, ownerGuid, slotType, slotsItem)
        continue
      }

    equipList.append({
      slotType, slotId, guid = ""
    })
    unequipped[slotsItem.item.guid] <- true
  }
  return equipList
}

function getWorst(itemList, keysSorted, scheme, objInfoByGuidVal) {
  foreach(key in keysSorted) {
    if (key not in itemList)
      continue
    let itemListByKey = itemList[key]
    if (itemListByKey.len() == 0) {
      itemList.$rawdelete(key)
      continue
    }
    foreach (guid, _ in itemListByKey) {
      let item = objInfoByGuidVal[guid]
      if (scheme.itemTypes.contains(item?.itemtype)
        || (scheme?.items ?? [])
          .findvalue(@(itemTpl) item?.basetpl.startswith(itemTpl)) != null )
        return { replacementGuid = guid, newitemRating = key }
    }
  }
  return { replacementGuid = null, newitemRating = -1 }
}

let excludeTypes = {
  medbox = true
  building_tool = true
  launcher = true
  mortar = true
  flaregun = true
  flamethrower = true
  antitank_rifle = true
  rifle_at_grenade_launcher = true
  infantry_launcher = true
}

function calcExchange(equipLists, toReplace, armoryItems) {
  
  let itemTypesToSlotType = {}
  let slots = { primary = "mainWeapon", melee = "melee" }
  foreach (slotName, itemType in slots) {
    foreach (itemtype, _ in (itemTypesInSlots.get()?[itemType] ?? {})) {
      if (itemtype in excludeTypes)
        continue
      itemTypesToSlotType[itemtype] <- slotName
    }
  }

  let sortOrder = defaultSortOrder
  let armoryList = {}
  foreach (item in armoryItems) {
    let { sign = 0 } = item
    if (sign > 0)
      continue

    let slotType = itemTypesToSlotType?[item?.itemtype] ?? ""
    if (slotType == "")
      continue

    let itemRating = calcRatingByTypeTier(sortOrder, item)
    local slotTypeData = armoryList?[slotType]
    if (slotTypeData == null) {
      slotTypeData = {}
      armoryList[slotType] <- slotTypeData
    }
    local itemRatingData = slotTypeData?[itemRating]
    if (itemRatingData == null) {
      itemRatingData = {}
      slotTypeData[itemRating] <- itemRatingData
    }
    itemRatingData[item.guid] <- true
  }

  
  
  foreach (slotType, byitemRating in toReplace) {

    let armoryOrder = (armoryList?[slotType] ?? {}).keys().sort(@(a, b) a <=> b)
    let equipped = byitemRating.keys().sort(@(a, b) b <=> a)

    foreach(itemRating in equipped) {
      foreach (soldierGuid, itemGuid in byitemRating[itemRating]) {

        let soldier = curCampSoldiers.get()?[soldierGuid]
        let scheme = getScheme(soldier, slotType)

        let { replacementGuid, newitemRating } = getWorst(armoryList?[slotType] ?? {},
          armoryOrder, scheme, curCampItems.get())
        if (replacementGuid == null || itemRating <= newitemRating)
          continue
        equipLists[soldierGuid].append({
          slotType, slotId = -1, guid = replacementGuid
        })
        armoryList[slotType][newitemRating].$rawdelete(replacementGuid)
        if (itemRating not in armoryList[slotType])
          armoryList[slotType][itemRating] <- {}
        armoryList[slotType][itemRating][itemGuid] <- true
      }
    }
  }
  return equipLists
}

function massUnequipSoldierList(soldierList, equipLists, toReplace) {
  foreach (soldier in soldierList) {
    let soldierGuid = soldier.guid
    let sortOrder = defaultSortOrder.__merge(classSortOrder?[soldier.sClass] ?? {})
    let soldierItems = getSoldierItemSlots(soldierGuid, campItemsByLink.get())
    equipLists[soldierGuid] <- getPossibleUnequipList(soldierGuid, soldierItems, toReplace, sortOrder)
  }
}

function massUnequipArmyReserve(reserveSquadsVal, soldiersBySquadVal, armoryByArmyVal, cb) {
  let equipLists = {}
  let toReplace = {}
  foreach(squad in reserveSquadsVal) {
    massUnequipSoldierList(soldiersBySquadVal?[squad.guid] ?? [], equipLists, toReplace)
  }
  let squad = reserveSquadsVal.findvalue(@(_) true)
  let armyId = getLinkedArmyName(squad) ?? ""
  let equipListsBySoldier = calcExchange(equipLists, toReplace, armoryByArmyVal?[armyId] ?? [])
  if (equipListsBySoldier.len() > 0)
    massEquipItems(equipListsBySoldier, cb)
}


function massUnequipReserve(soldierList, armoryByArmyVal) {
  let equipLists = {}
  let toReplace = {}
  massUnequipSoldierList(soldierList, equipLists, toReplace)
  let soldier = soldierList.findvalue(@(_) true)
  let armyId = getLinkedArmyName(soldier) ?? ""
  let equipListsBySoldier = calcExchange(equipLists, toReplace, armoryByArmyVal?[armyId] ?? [])
  if (equipListsBySoldier.len() > 0)
    massEquipItems(equipListsBySoldier)
}

let closeNeeded = keepref(Computed(@() isInRoom.get()
  && !roomIsLobby.get()
  && roomState.get() != RoomState.GAME_STARTED))

closeNeeded.subscribe(@(v) v ? itemClear() : null)

return {
  viewItem
  curInventoryItem
  curEquippedItem
  selectParams
  selectParamsList
  selectParamsArmyId
  inventoryItems
  slotItems
  otherSlotItems 
  paramsForPrevItems
  prevItems 

  openSelectItem
  trySelectNext = @() selectInsideListSlot(1, true)
  selectNextSlot = @() selectSlot(1)
  selectPreviousSlot = @() selectSlot(-1)
  itemClear
  markLastViewedSlot
  checkSelectItem
  selectItem
  ItemCheckResult

  curCanUnequipSoldiersList
  getPossibleEquipList
  getPossibleUnequipList
  getAlternativeEquipList
  getBREquipList
  getBetterItem
  getWorseItem
  massUnequipArmyReserve
  massUnequipReserve

  MAX_ITEM_BR
  getBR
}
