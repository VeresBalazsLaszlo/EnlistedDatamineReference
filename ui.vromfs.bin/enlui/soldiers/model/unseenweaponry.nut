from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/meta/profile.nut" import curArmiesList, itemsByArmies, campItemsByLink, curCampSoldiers
from "%ui/soldiers/model/state.nut" import chosenSquadsByArmy, armoryByArmy, soldiersBySquad, canChangeEquipmentInSlot, curArmy
from "%ui/soldiers/model/all_items_templates.nut" import equipSchemesByArmy, allItemTemplates, findItemTemplate
from "%ui/researches/researchesSummary.nut" import classSlotLocksByArmy
from "%sqstd/timers.nut" import debounce
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

const WEAPONRY_SEEN_ID = "seen/weaponry" 
onlineSettingUpdated.subscribe(function(value) {
  if (value && WEAPONRY_SEEN_ID in settings.get())
    settings.mutate(@(v) v.$rawdelete(WEAPONRY_SEEN_ID))
})

const SEEN_ID = "seen/soldierSlots"
let SLOTS = ["primary", "side", "secondary", "melee",
  "backpack", "grenade", "mine", "flask_usable", "binoculars_usable",
  "antitank", "flamethrower", "mortar"]
let SLOTS_MAP = SLOTS.totable()

let soldierSeenSlots = Computed(@() settings.get()?[SEEN_ID]) 
let betterWeaponrySoldier = Watched({})


let itemTypesForSlots = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let allItemtypes = {}
    let allItems = {}
    foreach (_, scheme in equipSchemesByArmy.get()?[armyId] ?? {}) {
      foreach (slotId in SLOTS) {
        if (slotId not in scheme)
          continue
        let { itemTypes = [], items = [] } = scheme[slotId]
        allItemtypes.__update(itemTypes.totable())
        allItems.__update(items.totable())
      }
    }
    res[armyId] <- {
      itemTypes = allItemtypes
      items = allItems
    }
  }
  return res
})

function bestTier(currentTier, slotConfig, byTpl, byItemType) {
  let { itemTypes = [], items = [] } = slotConfig

  foreach (itemType in itemTypes) {
    let tiers = byItemType?[itemType].len() ?? -1
    local maxTier = -1
    for (local i = tiers - 1; i >= 0; i--)
      if ((byItemType?[itemType][i].len() ?? 0) > 0) {
        maxTier = i
        break
      }
    if (maxTier > currentTier)
      return maxTier
  }

  foreach (basetpl in items) {
    if (basetpl not in byTpl)
      continue
    let maxTier = byTpl[basetpl].reduce(@(res, value) max(res, value), -1)
    if (maxTier > currentTier)
      return maxTier
  }

  return currentTier
}

function addArmoryItemToIndex(item, armyId, byTpl, byItemType) {
  let { guid, basetpl } = item
  let { itemtype = "", tier = 0 } = findItemTemplate(allItemTemplates.get(), armyId, basetpl)
  
  let itemsToIndex = itemTypesForSlots.get()?[armyId]
  let tpl = trimUpgradeSuffix(basetpl)
  if (itemtype not in itemsToIndex?.itemTypes && tpl not in itemsToIndex?.items)
    return

  local tplItems = byTpl?[tpl]
  if (tplItems == null)
    byTpl[tpl] <- { [guid] = tier }
  else
    tplItems[guid] <- tier

  let length = tier + 1
  local itemTypeList = byItemType?[itemtype] 
  if (itemTypeList == null) {
    itemTypeList = array(length)
    byItemType[itemtype] <- itemTypeList
  }
  else if (itemTypeList.len() < length)
    itemTypeList.resize(length)

  let guidsList = itemTypeList[tier]
  if (guidsList == null)
    itemTypeList[tier] = { [guid] = true }
  else
    guidsList[guid] <- true
}

function removeArmoryItemFromIndex(item, armyId, byTpl, byItemType) {
  let { guid, basetpl } = item
  let { itemtype, tier = 0 } = findItemTemplate(allItemTemplates.get(), armyId, basetpl)

  let tpl = trimUpgradeSuffix(basetpl)
  byTpl?[tpl].$rawdelete(guid)
  byItemType?[itemtype][tier].$rawdelete(guid)
}

function removeGuids(guidsToRemove, armyCache) {
  let { byTpl = {}, byItemType = {} } = armyCache
  local removedSuccess = false

  foreach (baseTpl, guidsTbl in byTpl) {
    let newTbl = guidsTbl.filter(@(_, guid) guid not in guidsToRemove)
    if (newTbl.len() != guidsTbl.len()) {
      byTpl[baseTpl] = newTbl
      removedSuccess = true
    }
  }

  foreach (tiers in byItemType)
    foreach (idx, guidsTbl in tiers) {
      if (guidsTbl == null)
        continue
      let newTbl = guidsTbl.filter(@(_, guid) guid not in guidsToRemove)
      if (newTbl.len() != guidsTbl.len()) {
        tiers[idx] = newTbl
        removedSuccess = true
      }
    }
  return removedSuccess
}

let inventoryTiersCache = Watched({})

function createIndex() {
  inventoryTiersCache.mutate(function(value) {
    foreach (armyId in curArmiesList.get()) {
      let byItemType = {} 
      let byTpl = {} 

      foreach (item in (armoryByArmy.get()?[armyId] ?? []))
        addArmoryItemToIndex(item, armyId, byTpl, byItemType)

      value[armyId] <- { byTpl, byItemType }
    }
  })
}

let slotsLinkTiers = Computed(function() {
  let res = {}
  let itemsList = itemsByArmies.get()
  foreach (armyId in curArmiesList.get()) {
    foreach (item in itemsList?[armyId] ?? {}) {
      let { growthTier = 0 } = item
      foreach (linkTo, linkSlot in item.links)
        if (linkSlot in SLOTS_MAP) {
          local slotsTiers = res?[linkTo]
          if (slotsTiers == null) {
            slotsTiers = { [linkSlot] = growthTier }
            res[linkTo] <- slotsTiers
          } else {
            let currentTier = slotsTiers?[linkSlot]
            if (currentTier == null || growthTier > currentTier)
              slotsTiers[linkSlot] <- growthTier
          }
        }
    }
  }
  return res
})

function getSoldierFixedWeapon(soldierGuid) {
  let weapon = {}
  foreach (slotType, itemsList in campItemsByLink.get()?[soldierGuid] ?? {}) {
    if (itemsList?[0].isFixed)
      weapon[slotType] <- true
  }
  return weapon
}

function recalcUnseen(_ = null) {
  let markedSoldiers = {}

  foreach (armyId in curArmiesList.get()) {
    let classLocks = classSlotLocksByArmy.get()?[armyId]
    let equipSchemes = equipSchemesByArmy.get()?[armyId]
    let { byTpl = {}, byItemType = {} } = inventoryTiersCache.get()?[armyId]

    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? []) {
      foreach (soldier in soldiersBySquad.get()?[squad.guid] ?? []) {
        let scheme = equipSchemes?[soldier?.equipSchemeId]
        let fixedWeapon = getSoldierFixedWeapon(soldier.guid)

        let betterSlots = {}
        foreach (slotId in SLOTS) {
          if (slotId not in scheme)
            continue

          if ((fixedWeapon.len() > 0 && (slotId in fixedWeapon))
              || (classLocks?[soldier?.sClass] ?? []).contains(slotId)
              || !canChangeEquipmentInSlot(soldier?.sClass, slotId))
            continue

          let equippedTier = slotsLinkTiers.get()?[soldier.guid][slotId] ?? -1 
          let tier = bestTier(equippedTier, scheme?[slotId], byTpl, byItemType)

          if (tier > equippedTier)
            betterSlots[slotId] <- equippedTier
        }
        if (betterSlots.len() > 0)
          markedSoldiers[soldier.guid] <- betterSlots
      }
    }
  }
  betterWeaponrySoldier.set(markedSoldiers)
}

let recalcUnseenDebounced = debounce(recalcUnseen, 0.01)
subscribeList(recalcUnseenDebounced, soldierSeenSlots, chosenSquadsByArmy,
  soldiersBySquad, classSlotLocksByArmy, inventoryTiersCache)


itemTypesForSlots.subscribe(function(value) {
  if (value.len() > 0)
    createIndex() 
})


createIndex()
recalcUnseen()

function clearSeenSlot(item) {
  let armyId = getLinkedArmyName(item)
  let { basetpl } = item
  let { itemtype = "", tier = 0 } = findItemTemplate(allItemTemplates.get(), armyId, basetpl)
  let tpl = trimUpgradeSuffix(basetpl)

  settings.mutate(function(value) {
    if (SEEN_ID not in value)
      value[SEEN_ID] <- {}

    let equipSchemes = equipSchemesByArmy.get()?[armyId]
    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? [])
      foreach (soldier in soldiersBySquad.get()?[squad.guid] ?? []) {

        let scheme = equipSchemes?[soldier?.equipSchemeId]
        if (scheme == null || soldier.guid not in value[SEEN_ID])
          continue

        let fixedWeapon = getSoldierFixedWeapon(soldier.guid)
        let hasFixedWeapon = fixedWeapon.len() > 0
        let soldierData = value[SEEN_ID]?[soldier.guid] ?? {}

        foreach (slotType, slotData in scheme) {
          if (slotType not in soldierData || (hasFixedWeapon && (slotType in fixedWeapon)))
            continue

          let { itemTypes = [], items = [] } = slotData
          if (itemTypes.contains(itemtype) || items.contains(tpl)) {
            if (soldierData[slotType] <= tier)
              soldierData.$rawdelete(slotType)
            break
          }
        }
        value[SEEN_ID][soldier.guid] <- soldierData
      }
  })
}

function markSeenSlot(armyId, ownerGuid, slotType) {
  let soldier = curCampSoldiers.get()?[ownerGuid]
  if (soldier == null)
    return

  let scheme = equipSchemesByArmy.get()?[armyId][soldier?.equipSchemeId]

  let { byTpl = {}, byItemType = {} } = inventoryTiersCache.get()?[armyId]
  let tierFromInventory = bestTier(-1, scheme?[slotType], byTpl, byItemType)
  if (tierFromInventory == (settings.get()?[SEEN_ID][ownerGuid][slotType] ?? -1))
    return

  settings.mutate(function(value) {
    let seenTbl = clone value?[SEEN_ID] ?? {}
    let soldierData = clone seenTbl?[ownerGuid] ?? {}
    seenTbl[ownerGuid] <- soldierData
    soldierData[slotType] <- tierFromInventory
    value[SEEN_ID] <- seenTbl
  })
}

function markInventorySlotsSeen(armyId) {
  settings.mutate(function(value) {
    let newSeenTbl = clone value?[SEEN_ID] ?? {}
    let equipSchemes = equipSchemesByArmy.get()?[armyId]

    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? [])
      foreach (soldier in soldiersBySquad.get()?[squad.guid] ?? []) {

        let scheme = equipSchemes?[soldier?.equipSchemeId]
        if (scheme == null)
          continue

        let fixedWeapon = getSoldierFixedWeapon(soldier.guid)
        let hasFixedWeapon = fixedWeapon.len() > 0
        let soldierData = clone newSeenTbl?[soldier.guid] ?? {}

        foreach (slotType, _ in scheme) {
          if (hasFixedWeapon && (slotType in fixedWeapon))
            continue

          let equippedTier = slotsLinkTiers.get()?[soldier.guid][slotType] ?? -1
          soldierData[slotType] <- equippedTier
        }
        newSeenTbl[soldier.guid] <- soldierData
      }
    value[SEEN_ID] <- newSeenTbl
  })
}

function resetInventorySlotsSeen() {
  settings.mutate(function(value) {
    value.$rawdelete(SEEN_ID)
  })
}

console_register_command(@() markInventorySlotsSeen(curArmy.get()), "meta.markSeenSlots")
console_register_command(resetInventorySlotsSeen, "meta.resetSeenSlots")
console_register_command(createIndex, "meta.indexInventory")
console_register_command(recalcUnseen, "meta.recalcUnseen")
console_register_command(@() debugTableData(soldierSeenSlots.get()), "meta.printSavedSeenSlots")

function itemOperation(item, fn) {
  let armyId = getLinkedArmyName(item)
  let { byTpl = {}, byItemType = {} } = inventoryTiersCache.get()?[armyId]
  fn(item, armyId, byTpl, byItemType)
}

function updateArmoryIndex(result) {
  foreach (_, item in result?.items ?? {}) {
    if (item.links.len() == 1) { 
      itemOperation(item, addArmoryItemToIndex)
      clearSeenSlot(item)
    } else
      itemOperation(item, removeArmoryItemFromIndex)
  }

  let guidsToRemove = (result?.removed.items ?? []).totable()
  if (guidsToRemove.len() == 0)
    return

  foreach (tiersCache in inventoryTiersCache.get())
    if (removeGuids(guidsToRemove, tiersCache))
      break
}

let soldiersUpgradeAlerts = Computed(function() {
  let res = {}
  foreach (soldierGuid, slotData in betterWeaponrySoldier.get()) {
    foreach (slotType, _ in slotData) {
      if (slotType not in soldierSeenSlots.get()?[soldierGuid]) {
        res[soldierGuid] <- true
        break
      }
    }
  }
  return res
})

let armyUpgradeAlerts = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    local hasNotifier = false
    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? []) {
      let soldiers = (soldiersBySquad.get()?[squad.guid] ?? [])
      if (soldiers.findvalue(@(soldier) soldier.guid in soldiersUpgradeAlerts.get()) != null) {
        hasNotifier = true
        break
      }
      if (hasNotifier)
        break
    }
    res[armyId] <- hasNotifier
  }
  return res
})

return {
  betterWeaponrySoldier
  soldierSlotsTiersEquipped = slotsLinkTiers
  soldierSeenSlots
  soldiersUpgradeAlerts
  armyUpgradeAlerts

  markSeenSlot
  updateArmoryIndex
  markInventorySlotsSeen
}
