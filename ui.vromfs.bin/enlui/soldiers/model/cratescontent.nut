from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/components/itemsInfo.nut" import templateLevel
from "%ui/profile/decoratorState.nut" import availPortraits, availNickFrames
from "%ui/vehicles/vehDecorState.nut" import vehCamouflageCfg
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/meta/servProfile.nut" import soldiers, squads, vehCamouflages
from "%ui/meta/profile.nut" import curCampItems
from "%ui/ui_library.nut" import *
from "math" import round

enum DropKind {
  CRATE = "CRATE"
  DECORATOR = "DECORATOR"
  VEHDECORATOR = "VEHDECORATOR"
  ITEM = "ITEM"
  VEHICLE = "VEHICLE"
  SOLDIER = "SOLDIER"
  HERO = "HERO"
  SQUAD = "SQUAD"
  OUTFIT = "OUTFIT"
  BOOSTER = "BOOSTER"
  CAMOUFLAGE = "CAMOUFLAGE"
  CURRENCY = "CURRENCY"
}

let allCrates = mkComputedConfigGet("allCrates", {})

let ownedVehicles = Computed(function() {
  let res = {}
  foreach (item in curCampItems.get())
    if (item?.itemtype == "vehicle")
      res[trimUpgradeSuffix(item.basetpl)] <- true

  return res
})

let ownedHeroes = Computed(function() {
  let res = {}
  foreach (soldier in soldiers.get()) {
    if (soldier?.isHero ?? false)
      res[soldier.heroTpl] <- true
  }
  return res
})

let ownedSquads = Computed(function() {
  let res = {}
  foreach (squad in squads.get()) {
    res[squad.squadId] <- true
  }
  return res
})

let ownedCamos = Computed(function() {
  let res = {}
  foreach (camoData in vehCamouflages.get())
    camoData?.available.each(@(id) res[id] <- true)
  return res
})

function canObtain(item) {
  let { kind, id, heroTpl = "" } = item
  let camoCfg = vehCamouflageCfg.get()

  if (kind == DropKind.DECORATOR
      && (id in availPortraits.get() || id in availNickFrames.get()))
    return false

  if (kind == DropKind.VEHICLE && trimUpgradeSuffix(id) in ownedVehicles.get())
    return false

  if (kind == DropKind.HERO && heroTpl in ownedHeroes.get())
    return false

  if (kind == DropKind.SQUAD && id in ownedSquads.get())
    return false

  if (kind == DropKind.CAMOUFLAGE && (id in ownedCamos.get()
    || null == ownedVehicles.get()?.findvalue(
        @(_, basetpl) id in camoCfg?[basetpl]))) 
    return false

  return true
}

function unpack(dropId) {
  let crateInfo = allCrates.get()?[dropId]
  if (crateInfo == null)
    return null

  let subCrates = [dropId]
  let enclosedItems = {}
  local itemCount = 0

  while (subCrates.len() > 0 && itemCount <= 1)
    foreach (dropList in allCrates.get()?[subCrates.pop()].items ?? [])
      foreach (dropItem in dropList) {
        let { kind, id, heroTpl = "" } = dropItem

        if (kind == DropKind.CRATE) {
          subCrates.append(id)
          continue
        }

        if (!canObtain(dropItem))
          continue

        enclosedItems[(kind == DropKind.HERO ? heroTpl : id)] <- clone dropItem
        if (++itemCount > 1)
          break
      }

  if (enclosedItems.len() == 0)
    return unpack(crateInfo?.defaultItem)

  if (itemCount == 1 && crateInfo?.defaultItem == null)
    return enclosedItems.findvalue(@(_) true)

  return {
    id = dropId
    kind = DropKind.CRATE
  }
}

let equalityFn = {
  [DropKind.ITEM] = @(item1, item2) (item1?.itemData[1] ?? 1) == (item2?.itemData[1] ?? 1),
  [DropKind.HERO] = @(item1, item2) (item1?.heroTpl ?? "") == (item2?.heroTpl ?? ""),
  [DropKind.CURRENCY] = @(item1, item2) (item1?.itemData[1] ?? 1) == (item2?.itemData[1] ?? 1),
}

function addNonUniqueItem(itemsWithRates, item, rate, isUnpacked) {
  let isEqualFn = equalityFn?[item.kind] ?? @(_a, _b) true
  let existing = itemsWithRates.findvalue(@(data)
    data.item.id == item.id && isEqualFn(data.item, item))

  if (existing != null)
    existing.rate += rate
  else
    itemsWithRates.append({
      rate
      item
      isUnpacked
    })
}

function getContentWithWeights(dropId, onlyCrates = true) {
  let result = []
  let { items = null, mainItem = "" } = allCrates.get()?[dropId]
  if (items == null || mainItem != "")
    return result

  if (onlyCrates) {
    let hasCrates = items.findindex(@(dropItem)
      dropItem.findvalue(@(v) v.kind == DropKind.CRATE) != null) != null
    if (!hasCrates)
      return result 
  }

  foreach (dropItem in items) {
    local totalWeights = 0
    let crateItems = []

    foreach (randomItem in dropItem) {
      let { id, kind, itemData = [] } = randomItem

      local showItem = randomItem
      if (kind == DropKind.CRATE) {
        showItem = unpack(id)
        if (showItem == null)
          continue 
        if ("itemData" not in showItem)
          showItem.itemData <- itemData
      } else if (!canObtain(showItem))
        continue

      let [ rate = 1 ] = itemData
      totalWeights += rate
      addNonUniqueItem(crateItems, showItem, rate, showItem.kind != kind)
    }

    if (crateItems.len() == 0)
      continue

    foreach (item in crateItems)
      item.rate = round(item.rate.tofloat() / totalWeights * 10000) / 100

    let resultItems = crateItems.sort(@(a, b) a.rate <=> b.rate)
    result.append(resultItems)
  }

  return result
}

let getPossibleItemsList = @(dropId) getContentWithWeights(dropId, false)
let getPossibleCratesList = getContentWithWeights


function getLoadedCrateContent(crateId, allCratesVal, count = 1) {
  let crateInfo = allCratesVal?[crateId]
  if (crateInfo == null || (typeof crateInfo?.items != "array"))
    return null

  let { isLootbox = false } = crateInfo
  let result = {
    isLootbox
    amount = count
    maxAmount = count
  }
  let crateItemsCount = {}
  foreach (possibleItems in crateInfo?.items ?? []) {
    foreach (dropItem in possibleItems) {
      let { kind, id, hasMaxStats = false, tierMax = -1, tierMin = -1, itemData = [] } = dropItem

      if (kind == DropKind.SOLDIER || kind == DropKind.HERO) {
        let { soldierClasses = [] } = result
        soldierClasses.append(id)
        result.soldierClasses <- soldierClasses
        result.soldierHasMaxStats <- hasMaxStats
        result.soldierTierMax <- tierMax
        result.soldierTierMin <- tierMin
      }

      if (kind == DropKind.ITEM || kind == DropKind.VEHICLE
          || kind == DropKind.OUTFIT || kind == DropKind.BOOSTER
          || kind == DropKind.CURRENCY) {
        let curAmount = crateItemsCount?[id] ?? 0
        crateItemsCount[id] <- curAmount + (itemData?[1] ?? 1)
      }
    }
  }
  result.items <- crateItemsCount

  if (crateInfo?.mainItem != null) {
    let mainCrateId = crateInfo.mainItem
    let mainItemsData = {}
    mainItemsData[mainCrateId] <- allCratesVal?[mainCrateId]
    result.mainItemsData <- mainItemsData
  }
  if (crateInfo?.defaultItem != null)
    result.defaultItem <- crateInfo?.defaultItem

  return result
}

function getShopItemsContent(itemsPairs) {
  let items = {}
  let result = {
    isLootbox = false
    amount = 1
    maxAmount = 1
    items
  }
  foreach (itemsCfg in itemsPairs) {
    let { itemTpl = null, count = 1 } = itemsCfg
    if (itemTpl != null)
      items[itemTpl] <- (items?[itemTpl] ?? 0) + count
  }
  return result
}

function getShopListForItem(tpl, armyId, itemsToShopItems, allItemTemplatesVal) {
  let res = itemsToShopItems?[armyId][tpl] ?? []
  if (res.len() > 0)
    return res

  for (local i=1; i<4; i++){
    let upgraded = templateLevel(tpl, i)
    if (upgraded not in allItemTemplatesVal?[armyId])
      return []
    let upShopItems = itemsToShopItems?[armyId][upgraded]
    if (upShopItems != null){
      return upShopItems
    }
  }

  return []
}


function collectCrates(startCrateId, allCratesContent) {
  let crates = [startCrateId]
  local idx = 0
  while (idx < crates.len()) {
    let crateId = crates[idx]
    foreach (items in allCratesContent?[crateId].items ?? [])
      foreach (item in items)
        if (item.kind == DropKind.CRATE && !crates.contains(item.id))
          crates.append(item.id)
    ++idx
  }
  return crates
}

function unpackCrate(crateId, allCratesContent, obtained = []) {
  let includeItems = {}
  foreach (drop in obtained) {
    let { basetpl = null, sClass = null, currencyId = null } = drop
    let key = sClass ?? basetpl ?? currencyId
    if (key)
      includeItems[key] <- true
  }

  let crates = collectCrates(crateId, allCratesContent)
  let content = []
  foreach (crate in crates)
    foreach (items in allCratesContent?[crate].items ?? [])
      foreach (item in items)
        if (item.kind != DropKind.CRATE && (item.id in includeItems || canObtain(item)))
          content.append({ count = item?.itemData[1] ?? 1 }.__update(item))
  return content
}


return {
  getShopListForItem
  getLoadedCrateContent
  getShopItemsContent
  crateContentWatch = allCrates
  getPossibleCratesList
  getPossibleItemsList
  unpackCrate
  DropKind
}
