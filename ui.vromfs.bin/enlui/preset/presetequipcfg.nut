import "%ui/soldiers/model/equivalentItemsList.nut" as equivalentItemsList
from "%ui/soldiers/model/state.nut" import curArmy, armoryByArmy, getSoldierItemSlots
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/soldiers/model/selectItemState.nut" import getPossibleUnequipList, getAlternativeEquipList, getPossibleEquipList, getBREquipList, getBetterItem, getWorseItem, MAX_ITEM_BR
from "%ui/meta/profile.nut" import curCampItems
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/soldiers/model/soldierSlotsCount.nut" import soldierSlotsCount
from "%ui/soldiers/model/config/equipIncreaseConfig.nut" import equipSlotIncreaseCfg
from "%ui/ui_library.nut" import *

















const SLOT_COUNT = 6
const SLOT_COUNT_MAX = 10

function minimumEquipList(_preset, soldier, campItemsByLinkVal, notFoundItemsWatch, _) {
  let { guid = null } = soldier
  let slotsItems = getSoldierItemSlots(guid, campItemsByLinkVal)
  let unequipList = getPossibleUnequipList(guid, slotsItems)
  let changeEquipList = getAlternativeEquipList(soldier, slotsItems,
      getWorseItem, unequipList, MAX_ITEM_BR)
    .extend(unequipList)

  notFoundItemsWatch.set({})
  return changeEquipList
}

function getSlotsIncreaseFromEquipList(equipList) {
  if (equipList.len == 0)
    return null

  let result = {}
  equipList.each(function(slotData) {
    foreach (slotType, tplsList in equipSlotIncreaseCfg.get())
      if (slotData.itemTpl in tplsList)
        result[slotType] <- tplsList[slotData.itemTpl]
  })
  return result
}

function bestEquipList(preset, soldier, campItemsByLinkVal, notFoundItemsWatch, _) {
  local { maxBR = null } = preset
  maxBR = maxBR ?? MAX_ITEM_BR
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
  let changeEquipList = getAlternativeEquipList(soldier, slotsItems, getBetterItem, [], maxBR)

  let affectedSlotsList = changeEquipList.filter(@(v) v.slotType == "backpack")
    .map(@(v) v.__update({ itemTpl = curCampItems.get()?[v.guid].basetpl }))

  let newSlotsIncrease = affectedSlotsList.len() == 0 ? null 
    : getSlotsIncreaseFromEquipList(affectedSlotsList)
  let { guid = null, equipScheme = {} } = soldier
  let soldierSlotsCountVal = soldierSlotsCount(guid, equipScheme, newSlotsIncrease)

  let toAddEquipList = getPossibleEquipList(soldier, slotsItems, maxBR, soldierSlotsCountVal)
    .extend(changeEquipList)

  foreach (slotData in toAddEquipList) {
    if (slotData.slotId >= (soldierSlotsCountVal?[slotData.slotType] ?? 1))
      slotData.guid = ""
  }

  foreach(slotData in slotsItems) {
    if (slotData.slotId >= (soldierSlotsCountVal?[slotData.slotType] ?? 1))
      toAddEquipList.append({
        slotType = slotData.slotType
        slotId = slotData.slotId
        guid = ""
      })
  }

  notFoundItemsWatch.set({})
  return toAddEquipList
}

function buyEquipList(preset, soldier, campItemsByLinkVal, notFoundItemsWatch, _) {
  local { maxBR = null } = preset
  maxBR = maxBR ?? MAX_ITEM_BR
  let { guid = null, equipScheme = {} } = soldier
  let slotsItems = getSoldierItemSlots(guid, campItemsByLinkVal)
  let changeEquipList = getBREquipList(soldier, slotsItems, getBetterItem, notFoundItemsWatch, maxBR)

  let affectedSlotsList = changeEquipList.filter(@(v) v.slotType == "backpack")

  let newSlotsIncrease = affectedSlotsList.len() == 0 ? null 
    : getSlotsIncreaseFromEquipList(affectedSlotsList)
  let soldierSlotsCountVal = soldierSlotsCount(guid, equipScheme, newSlotsIncrease)

  foreach (slotData in changeEquipList) {
    if (slotData.slotId >= (soldierSlotsCountVal?[slotData.slotType] ?? 1))
      slotData.guid = ""
  }

  foreach (slotData in slotsItems) {
    if (slotData.slotId >= (soldierSlotsCountVal?[slotData.slotType] ?? 1))
      changeEquipList.append({
        slotType = slotData.slotType
        slotId = slotData.slotId
        guid = ""
      })
  }

  return changeEquipList
}

function isItemInScheme(slotId, tpl, soldier, schemes) {
  let armyId = getLinkedArmyName(soldier)
  let { itemTypes = [], items = [] } = schemes?[armyId][soldier?.equipSchemeId][slotId]

  let { itemtype = "" } = findItemTemplate(allItemTemplates.get(), armyId, tpl)
  return (itemTypes.contains(itemtype) || items.contains(tpl))
}

function itemListByTpl(presetItems) {
  let sameItemsList = equivalentItemsList.get()
  let allTemplates = allItemTemplates.get()

  let searched = {}
  foreach (item in presetItems) {
    let { itemTpl } = item
    let templates = []

    let armyId = getLinkedArmyName(item)
    let template = allTemplates?[armyId][itemTpl]
    let { itemtype = "" } = template
    let sameItems = sameItemsList?[itemtype]

    if (sameItems?.contains(itemTpl) ?? false)
      templates.extend(sameItems)

    searched[itemTpl] <- templates
  }

  let inventory = armoryByArmy.get()?[curArmy.get()] ?? []

  let result = searched.map(@(_) [])
  foreach (item in inventory) {
    let basetpl = trimUpgradeSuffix(item.basetpl)
    if (basetpl in result) {
      result[basetpl].append(item)
      continue
    }

    let equivalentItem = searched.findindex(@(list) list.contains(basetpl))
    if (equivalentItem == null)
      continue
    result[equivalentItem].append(item)
  }

  foreach (itemList in result)
    itemList.sort(@(a, b) (b?.upgradeIdx ?? 0) <=> (a?.upgradeIdx ?? 0))

  return result
}

function selectedEquipList(presetCfg, soldier,
    campItemsByLinkVal, notFoundItemsWatch, schemesVal) {
  let { data = null } = presetCfg
  let { items = null } = data
  if (items == null )
    return []

  let noReplace = {}
  let changeEquipList = []
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
  foreach (equippedItem in slotsItems) {
    let { slotType, slotId } = equippedItem
    let presetItem = items.findvalue(@(i)
      i.slotType == slotType && i.slotId == slotId)
    if (presetItem == null) {
      changeEquipList.append({
        item = null
        slotType
        slotId
      })
      continue
    }

    let { itemTpl } = presetItem
    let { isFixed = false, basetpl = null, upgradeitem = null } = equippedItem?.item
    if (isFixed
      || (trimUpgradeSuffix(basetpl) == itemTpl && (upgradeitem == null))
      || !isItemInScheme(slotType, itemTpl, soldier, schemesVal)) {
        noReplace[slotType] <- (noReplace?[slotType] ?? []).append(slotId)
    }
  }

  let notFoundTbl = {}
  let availableItems = itemListByTpl(items)

  foreach (presetItem in items) {
    let { slotType, slotId, itemTpl } = presetItem
    if (noReplace?[slotType].contains(slotId))
      continue

    let itemData = clone presetItem
    if (availableItems[itemTpl].len() == 0) {
      itemData.shopItem <- itemTpl
      notFoundTbl[itemTpl] <- (notFoundTbl?[itemTpl] ?? 0) + 1
    } else {
      let item = availableItems[itemTpl].remove(0)
      itemData.item <- item
    }
    changeEquipList.append(itemData)
  }

  notFoundItemsWatch.set(notFoundTbl)
  return changeEquipList
}

return {
  minimumEquipList
  bestEquipList
  selectedEquipList
  buyEquipList
  SLOT_COUNT
  SLOT_COUNT_MAX
}
