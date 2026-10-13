from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/soldiers/model/config/itemsModifyConfig.nut" import itemUpgrades, getModifyConfig
from "%sqstd/math.nut" import ceil
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import curArmiesList, itemsByArmies, soldiersByArmies
from "%ui/soldiers/model/state.nut" import itemCountByArmy, curArmy, chosenSquadsByArmy, armyItemCountByTpl
from "%ui/researches/researchesSummary.nut" import upgradeCostMultByArmy
from "%ui/helpers/metalink.nut" import getLinkedSquadGuid, getItemIndex
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/upgrades"
const USED_ID = "used/upgrades"

let seen = Computed(@() settings.get()?[SEEN_ID])
let isUpgradeUsed = Computed(@() settings.get()?[USED_ID])

let ignoreSlots = { secondary = true }

function markUpgradesUsed(isUsed = true) {
  settings.mutate(@(set) set[USED_ID] <- isUsed)
}

function markSeenUpgrades(armyId, iGuidsList) {
  if (armyId == null)
    return

  let seenUpdates = seen.get()?[armyId] ?? {}
  let filtered = iGuidsList.filter(@(name) name not in seenUpdates)
  if (filtered.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let updatesSaved = clone (saved?[armyId] ?? {})
    filtered.each(@(name) updatesSaved[name] <- true)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

function updateSeen(armyId, availableUpgrades) {
  let seenUpdates = seen.get()?[armyId] ?? {}
  if (seenUpdates.len() == 0)
    return

  let filtered = seenUpdates.filter(@(name) name not in availableUpgrades).keys()
  if (filtered.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let updatesSaved = (saved?[armyId] ?? {})
      .filter(@(_, name) filtered.findindex(@(v) v == name) == null)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

function getEquipInfoByItem(item, curSoldiers) {
  let links = item?.links ?? {}
  if (links.len() <= 1)
    return null

  foreach (link, linkType in links)
    if (link in curSoldiers && (linkType not in ignoreSlots)) {
      let soldier = curSoldiers[link]
      return {
        soldier = link
        index = getItemIndex(soldier) ?? 0
        squad = getLinkedSquadGuid(soldier)
      }
    }

  return null
}

let availableUpgradesByArmy = Computed(function() {
  let itemsCount = itemCountByArmy.get()
  let allTemplates = allItemTemplates.get()
  let upgradeCostMult = upgradeCostMultByArmy.get()

  let res = {}
  foreach (armyId in curArmiesList.get()) {
    res[armyId] <- {}
    let armyItemsCount = itemsCount?[armyId] ?? {}
    let armyUpgradeCostMult = upgradeCostMult?[armyId]
    let armyTemplates = allTemplates?[armyId]
    foreach (tpl, _ in armyItemsCount) {
      let itemTemplate = armyTemplates?[tpl]
      if ((itemTemplate?.upgradeitem ?? "") == "")
        continue

      let { growthTier = 0, itemtype = "", upgradeIdx = 0 } = itemTemplate
      let modifyConfig = getModifyConfig(itemUpgrades.get(), growthTier, itemtype)
      if (modifyConfig == null)
        continue

      let upgradeMult = armyUpgradeCostMult?[tpl] ?? 1.0
      foreach (priceTpl, price in modifyConfig) {
        let ordersAvail = armyItemCountByTpl.get()?[priceTpl] ?? 0
        local orderReq = price?.counts[upgradeIdx] ?? price?.count ?? 0
        if (!price?.isFixedPrice)
          orderReq = ceil(orderReq * upgradeMult).tointeger()
        if (orderReq > 0 && orderReq <= ordersAvail) {
          res[armyId][tpl] <- true
          break
        }
      }
    }
  }
  return res
})

let availableUpgradesEquipsByArmy = Computed(function() {
  let armiesItems = itemsByArmies.get()
  let armiesSoldiers = soldiersByArmies.get()
  let armiesSquads = chosenSquadsByArmy.get()
  let upgradesByArmy = availableUpgradesByArmy.get()

  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let armyRes = {}
    let squadsIndexes = {}
    foreach (idx, squad in armiesSquads?[armyId] ?? [])
      squadsIndexes[squad.guid] <- idx

    let armyUpgrades = upgradesByArmy?[armyId] ?? {}
    let armyItems = armiesItems?[armyId] ?? {}
    let armySoldiers = armiesSoldiers?[armyId] ?? {}
    foreach (item in armyItems) {
      let tpl = item.basetpl
      if (tpl not in armyUpgrades)
        continue

      let equipData = getEquipInfoByItem(item, armySoldiers)
      if (equipData == null)
        continue

      if (tpl not in armyRes)
        armyRes[tpl] <- []

      armyRes[tpl].append(equipData.__update({
        priority = (squadsIndexes?[equipData.squad] ?? 1000) * 1000 + equipData.index
      }))
    }

    res[armyId] <- armyRes.map(function(tplData) {
      local bestPriority
      local bestIdx
      foreach (idx, itemData in tplData)
        if (bestPriority == null || itemData.priority < bestPriority) {
          bestPriority = itemData.priority
          bestIdx = idx
        }
      return tplData[bestIdx]
    })
  }
  return res
})

let unseenAvailableUpgradesByArmy = Computed(function() {
  if (!onlineSettingUpdated.get())
    return {}

  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let seenData = seen.get()?[armyId] ?? {}
    res[armyId] <- (availableUpgradesEquipsByArmy.get()?[armyId] ?? {})
      .filter(@(_, tpl) tpl not in seenData)
  }
  return res
})

let curUnseenAvailableUpgrades = Computed(@()
  unseenAvailableUpgradesByArmy.get()?[curArmy.get()] ?? {})

availableUpgradesEquipsByArmy.subscribe(function(v) {
  foreach (armyId, data in v)
    updateSeen(armyId, data)
})

console_register_command(function() {
  settings.mutate(function(s) {
    s?.$rawdelete(SEEN_ID)
    s?.$rawdelete(USED_ID)
  })
}, "meta.resetSeenUpdates")

return {
  isUpgradeUsed
  markUpgradesUsed
  markSeenUpgrades
  curUnseenAvailableUpgrades
}
