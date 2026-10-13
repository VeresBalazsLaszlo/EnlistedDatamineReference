import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
from "%ui/meta/configs.nut" import mkComputedConfigView, mkComputedConfigGet
from "%ui/meta/servProfile.nut" import growthState, growthProgress
from "%ui/meta/clientApi.nut" import growth_select, growth_select_forced, growth_purchase,
  growth_reward_take_forced, growth_state_set, growth_tier_set, growth_use_army_exp,
  growth_buy_exp, growth_army_unlock, growth_reset
from "%ui/soldiers/model/state.nut" import armies, curArmy, curArmyData
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/researches/researchesState.nut" import researchesToSquads
from "%ui/ui_library.nut" import *

let getSquadIdList = @(researchId)
  researchesToSquads.get()?[researchId ?? ""] ?? []

enum GrowthStatus {
  UNAVAILABLE = 0
  ACTIVE = 1
  COMPLETED = 2
  PURCHASABLE = 3
  REWARDED = 4
}

let isGrowthVisible = Watched(false)
let curGrowthId = Watched(null)
let reqGrowthId = Watched(null)
let reqGrowthAddExp = Watched(0)
let growthTierToScroll = Watched(null)

let growthConfig = mkComputedConfigGet("growthConfig", {})

local isGrowthActionInProgress = false

let growthSquadsByArmy = mkComputedConfigView(@(cfg)
  (cfg?.growthConfig ?? {}).map(function(growths) {
    let res = {}
    foreach (growth in growths) {
      let { id, reward } = growth
      let { squadId = null } = reward
      if (squadId != null)
        res[squadId] <- id
    }
    return res
  }))

let canBuyGrowth = Computed(function() {
  let availShopItems = shopItems.get()
  let res = {}
  foreach (armyId, armyGrowth in growthConfig.get()) {
    let purchasable = {}
    res[armyId] <- purchasable
    foreach (growthCfg in armyGrowth) {
      if ((growthCfg?.expRequired ?? 0) > 0
          || (growthCfg?.shopItemsGuids ?? []).findvalue(@(v) v in availShopItems))
        purchasable[growthCfg.id] <- true
    }
  }
  return res
})

let curGrowthConfig = Computed(function() {
  let growthAvail = canBuyGrowth.get()?[curArmy.get()]
  let statuses = growthState.get()
  return (growthConfig.get()?[curArmy.get()] ?? {}).filter(@(g) g.id in growthAvail
      || (statuses?[g.id] ?? GrowthStatus.UNAVAILABLE) == GrowthStatus.REWARDED)
})

let curGrowthByItem = Computed(function() {
  let growthByItem = curGrowthConfig.get().reduce(function(res, val) {
    let { itemTemplate = null } = val.reward
    if (itemTemplate != null)
      res.rawset(itemTemplate, val.id)
    return res
  }, {})
  return growthByItem
})

let growthTiers = mkComputedConfigView(function(cfg) {
  return cfg?.growthTiers
    .map(@(tiers) tiers.map(@(t) { index = 0, from = 0, to = 0, required = 1 }.__merge(t))) ?? {}
})

let curGrowthTiers = Computed(@() growthTiers.get()?[curArmy.get()] ?? [])

let setCurGrowthTier = @(tier) growthTierToScroll.set(tier)

let mkGrowthData = @() Computed(function() {
  let growthRelations = curGrowthConfig.get().reduce(function(res, val, _, tbl) {
    let { id, col = 0, line = 0, requirements = [] } = val
    if (requirements.len() > 0) {
      let ancestor = tbl[requirements[0]]
      if (col == (ancestor?.col ?? 0) && line == (ancestor?.line ?? 0)) {
        let ancestorRelations = res?[ancestor.id] ?? [ancestor.id]
        let inheritorRelations = res?[id] ?? [id]
        ancestorRelations.extend(inheritorRelations)
        res[ancestor.id] <- ancestorRelations
        foreach(updateId in inheritorRelations)
          res[updateId] <- ancestorRelations
      }
    }
    return res
  }, {})

  let tiersByCol = {}
  foreach (tier in curGrowthTiers.get()) {
    let tierData = { tierIdx = tier.index, tierId = tier.id }
    for (local i = tier.from; i <= tier.to; i++)
      tiersByCol[i] <- tierData
  }

  let growthLinks = {}
  foreach (growthId, growth in curGrowthConfig.get())
    growthLinks[growthId] <- { isPrem = (growth?.expRequired ?? 0) == 0 }
      .__update(tiersByCol[growth?.col ?? 0])

  return { growthRelations, growthLinks }
})


let curGrowthSelected = Computed(function() {
  let grSelected = armies.get()?[curArmy.get()].growthSelected
  return (grSelected ?? "") == "" ? null : grSelected
})
let curGrowthFreeExp = Computed(@() armies.get()?[curArmy.get()].growthExp ?? 0)

let curSquads = Computed(function() {
  let armyId = curArmy.get()
  return squadsCfgById.get()?[armyId] ?? {}
})
let curTemplates = Computed(@() allItemTemplates.get()?[curArmy.get()] ?? {})

function getGrowthBySquadId(armyId, squadId) {
  let configByArmy = growthConfig.get()?[armyId] ?? {}
  return configByArmy.findvalue(@(g) g.reward?.squadId == squadId)
}

function getGrowthToFocus(armyId, researchData) {
  let squadIdList = getSquadIdList(researchData.research_id)
  let configByArmy = growthConfig.get()?[armyId] ?? {}
  return configByArmy.findvalue(@(g) squadIdList.contains(g.reward?.squadId))
}

function getSortedGrowthsByResearch(armyId, research) {
  let sortedGrowths = getSquadIdList(research.research_id)
    .map(@(squadId) getGrowthBySquadId(armyId, squadId))
    .filter(@(growth) growth != null)
    .sort(@(a, b) (a?.col ?? 0) <=> (b?.col ?? 0))
  return sortedGrowths
}

function getSortedGrowthsByVehicle(armyId, vehicleTpl) {
  let sortedGrowths = (allowedVehicles.get()?[armyId] ?? {})
    .reduce(@(res, vehicles, squadId) vehicleTpl in vehicles ? res.append(squadId) : res, []) 
    .map(@(squadId) getGrowthBySquadId(armyId, squadId))
    .filter(@(growth) growth != null)
    .sort(@(a, b) (a?.col ?? 0) <=> (b?.col ?? 0))
  return sortedGrowths
}

let curResearchableGrowth = Computed(@()
  curGrowthConfig.get().filter(@(g) (g?.expRequired ?? 0) > 0)
)

let curAvailableToSelect = Computed(function() {
  let curResearchable = curResearchableGrowth.get()
  return growthState.get()
    .findindex(@(g) g.status == GrowthStatus.ACTIVE && g.guid in curResearchable)
})

let reqGrowthSelection = Computed(@()
  (curArmyData.get()?.growthSelected ?? "") == ""
    && curAvailableToSelect.get() != null)


console_register_command(@(growthId) growth_select(curArmy.get(), growthId),
  "meta.growthSelect")
console_register_command(@() growth_select_forced(curArmy.get(), curGrowthId.get()),
  "meta.growthSelectCurrent")
console_register_command(@() growth_reward_take_forced(curArmy.get(), curGrowthId.get()),
  "meta.growthTakeCurrent")
console_register_command(@(exp) growth_state_set(curGrowthId.get(), exp, -1),
  "meta.setCurGrowthExp")
console_register_command(@(status) growth_state_set(curGrowthId.get(), -1, status),
  "meta.setCurGrowthStatus")
console_register_command(@(index, progress) growth_tier_set(curArmy.get(), index, progress, -1),
  "meta.setGrowthTierProgress")
console_register_command(@(index, status) growth_tier_set(curArmy.get(), index, -1, status),
  "meta.setGrowthTierStatus")
console_register_command(@() growth_army_unlock(curArmy.get()), "meta.growthArmyUnlock")
console_register_command(@() growth_reset(), "meta.growthReset")

function perform(action, cb = null) {
  if (isGrowthActionInProgress)
    return
  isGrowthActionInProgress = true

  action(function(res) {
    isGrowthActionInProgress = false
    cb?(res)
  })
}

let callGrowthExp = @(armyId, growthId, exp, cb)
  perform(@(fn)
    growth_use_army_exp(armyId, growthId, exp, fn), cb)

let callGrowthPurchase = @(armyId, growthId, payItems)
  perform(@(fn)
    growth_purchase(armyId, growthId, payItems, fn))

let callGrowthBuyExp = @(armyId, growthId, exp, cost, cb)
  perform(@(fn)
    growth_buy_exp(armyId, growthId, exp, cost, fn), cb)

return {
  isGrowthVisible
  GrowthStatus
  curGrowthId
  reqGrowthId
  reqGrowthAddExp
  growthConfig
  curGrowthConfig
  curGrowthByItem
  curGrowthTiers
  curGrowthState = growthState
  curGrowthProgress = growthProgress
  curGrowthSelected
  curGrowthFreeExp
  curSquads
  curTemplates
  mkGrowthData
  setCurGrowthTier
  growthTierToScroll
  growthSquadsByArmy
  getGrowthToFocus
  getSortedGrowthsByResearch
  getSortedGrowthsByVehicle
  reqGrowthSelection
  curAvailableToSelect

  callGrowthSelect = growth_select
  callGrowthExp
  callGrowthPurchase
  callGrowthBuyExp
}
