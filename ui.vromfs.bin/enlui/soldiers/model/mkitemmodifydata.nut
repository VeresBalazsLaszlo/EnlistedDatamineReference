import "%ui/soldiers/model/config/upgradesConfig.nut" as upgrades
from "%ui/soldiers/model/config/itemsModifyConfig.nut" import itemUpgrades, itemDisposes, getModifyConfig, disposableTypes
from "%sqstd/math.nut" import ceil
from "%ui/helpers/metalink.nut" import getLinkedArmyName, isObjLinkedToAnyOfObjects
from "%ui/researches/researchesSummary.nut" import upgradeLocksByArmy, upgradeCostMultByArmy, disposeCountMultByArmy
from "%ui/soldiers/model/state.nut" import armyItemCountByTpl
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/meta/profile.nut" import curCampSoldiers, curCampItems
from "%ui/ui_library.nut" import *

let canUpgrade = @(item)
   (item?.guid ?? "") != "" && (item?.upgradeitem ?? "") != ""

function mkItemUpgradeData(item) {
  let { basetpl = "", growthTier = 0, upgradeIdx = 0, upgradesId = null, upgradeitem = "" } = item

  if (!canUpgrade(item))
    return Computed(@() {
      isUpgradable = false
      upgradeMax = max(upgradeIdx, (upgrades.get()?[upgradesId].len() ?? 0) - 1)
    })

  let itemBaseTpl = trimUpgradeSuffix(basetpl)
  let armyId = getLinkedArmyName(item)
  return Computed(function() {
    let upgradeMult = upgradeCostMultByArmy.get()?[armyId][itemBaseTpl] ?? 1.0
    let priceOptions = []

    let res = {
      isUpgradable = false
      isResearchRequired = false
      armyId
      hasEnoughOrders = false
      upgradeMult
      upgradeMax = max(upgradeIdx, (upgrades.get()?[upgradesId].len() ?? 0) - 1)
      itemBaseTpl
      upgradeitem
      guids = []
      priceOptions
    }

    let { itemtype = null } = findItemTemplate(allItemTemplates.get(), armyId, itemBaseTpl)
    let modifyConfig = getModifyConfig(itemUpgrades.get(), growthTier, itemtype)
    if (modifyConfig == null)
      return res

    let lockedUpgrades = upgradeLocksByArmy.get()?[armyId] ?? []
    if (lockedUpgrades.contains(upgradeitem))
      return res.__update({ isUpgradable = true, isResearchRequired = true })

    local canBuy = false
    local maxBuyCount = 0

    foreach (orderTpl, price in modifyConfig) {
      local orderReq = price?.counts[upgradeIdx] ?? price?.count ?? 0
      if (!price?.isFixedPrice)
        orderReq = ceil(orderReq * upgradeMult).tointeger()
      let ordersInStock = armyItemCountByTpl.get()?[orderTpl] ?? 0
      let hasEnoughOrders = orderReq > 0 && ordersInStock >= orderReq
      canBuy = canBuy || hasEnoughOrders
      let canBuyCount = orderReq > 0 ? ordersInStock / orderReq : 0

      priceOptions.append({ orderTpl, orderReq, ordersInStock, hasEnoughOrders, canBuyCount })
      if (maxBuyCount < canBuyCount)
        maxBuyCount = canBuyCount
    }

    let allGuids = item?.guids ?? [item?.guid]

    if (priceOptions.len() > 0)
      res.__update({
        hasEnoughOrders = canBuy
        isUpgradable = true
        guids = allGuids.slice(0, maxBuyCount)
      })

    return res
  })
}

let canDispose = @(item) (item?.guid ?? "") != ""
  && !(item?.isFixed ?? false)
  && (item?.sign ?? 0) == 0
  && ((item?.upgradesId ?? "") != "" || (disposableTypes.get()?[item?.itemtype] ?? false))

function mkItemDisposeData(item) {
  if (!canDispose(item))
    return WatchedRo({ isDisposable = false })

  let { basetpl = "", growthTier = 0, upgradeIdx = 0 } = item
  let itemBaseTpl = trimUpgradeSuffix(basetpl)
  let armyId = getLinkedArmyName(item)
  return Computed(function() {
    let res = {
      isDisposable = false
      isDestructible = false
      isRecyclable = false
      armyId
      orderCount = 0
      orderTpl = ""
      disposeMult = null
      itemBaseTpl
      guids = null
    }

    let { itemtype = null } = findItemTemplate(allItemTemplates.get(), armyId, itemBaseTpl)
    local disposes = getModifyConfig(itemDisposes.get(), growthTier, itemtype)
    if (disposes == null)
      return res

    disposes = disposes.values()[0] 

    let { isDestructible = false, count = 0, counts = [], batchSize = 1, isFixedPrice = false
    } = disposes
    if (!isDestructible && itemBaseTpl == basetpl)
      return res

    local disposeMult = 1.0
    if (!isFixedPrice)
      disposeMult += (disposeCountMultByArmy.get()?[armyId][itemBaseTpl] ?? 0.0)
    let orderCount = (counts?[upgradeIdx] ?? count) * disposeMult
    let orderTpl = disposes.itemTpl
    let guids = isObjLinkedToAnyOfObjects(item, curCampItems.get() ?? {}) ? null
      : isObjLinkedToAnyOfObjects(item, curCampSoldiers.get() ?? {}) ? null
      : item?.guids ?? [item?.guid]
    return res.__update({
      isDisposable = true
      isRecyclable = orderCount <= 0
      guids
      isDestructible, itemBaseTpl, disposeMult, orderTpl, orderCount, batchSize
    })
  })
}

return {
  mkItemUpgradeData
  mkItemDisposeData
}