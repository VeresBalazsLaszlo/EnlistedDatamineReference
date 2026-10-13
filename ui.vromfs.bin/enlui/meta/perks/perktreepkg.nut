import "%ui/components/colorize.nut" as colorize
from "%ui/style/designConst.nut" import titleTxtColor, attentionTxtColor, smallPadding
from "%ui/components/soldiersUiComps.nut" import levelBlock
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/ui_library.nut" import *

let { pPointsBaseParams } = require("%ui/meta/perks/perksPoints.nut")

enum PerkState {
  LOCKED    
  UNLOCKED_PART  
  UNLOCKED_FULL  
  AVAILABLE 
  UNDEFINED 
}

const POINTS_TIER2_REQUIRED = 6
const MAX_LEVEL = 5



let stateForPerk = @(isLocked, points, unlocked)
  points == unlocked ? PerkState.UNLOCKED_FULL
    : unlocked > 0 ? PerkState.UNLOCKED_PART
    : isLocked ? PerkState.LOCKED
    : PerkState.AVAILABLE

let statForPerk = @(perkData) perkData?.cost.findindex(@(_) true) ?? ""

function priceForPerk(perkData) {
  let stat = statForPerk(perkData)
  return perkData?.cost[stat] ?? 0
}

function hasEnoughPoints(pointInfo, perkData) {
  foreach (statId, costVal in perkData.cost)
    if (costVal + (pointInfo.used?[statId] ?? 0) > pointInfo.total[statId])
      return false

  return true
}

let statIconForPerk = @(perkData)
  pPointsBaseParams?[statForPerk(perkData)] ?? {
    icon = "remove"
    color = Color(80,80,80)
  }

let iconForPerk = @(perkData) perkData.perkId.startswith("starter_")
  ? statIconForPerk(perkData)
  : {
      icon = $"ui/skin#perks/{perkData.perkId}_icon.svg"
      color = pPointsBaseParams?[statForPerk(perkData)].color ?? Color(80,80,80)
    }

let mkHeaderText = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = titleTxtColor
}.__update(fontSub)

let requiredLevelHeader = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    mkHeaderText(loc("perks/soldier"))
    levelBlock(MAX_LEVEL, MAX_LEVEL)
  ]
}

let thirdTierHint = loc("perks/obtain/tier3/hint", { level = colorize(titleTxtColor,
  loc("perks/level", { level = MAX_LEVEL }))
})

function tiersAvailable(level, used, showAll = false) {
  let usedPoints = used.reduce(@(sum, val) sum + val, 0)
  let pointsToSpend = POINTS_TIER2_REQUIRED - usedPoints
  let hasSecondTier = showAll || usedPoints >= POINTS_TIER2_REQUIRED
  let pointsLoc =  loc("perks/points", { count = pointsToSpend })
  let secondTierCondition = mkHeaderText(loc("perks/obtain/tier2",
    { points = colorize(attentionTxtColor, pointsLoc) }))
  let secondTierHint = loc("perks/obtain/tier2/hint",
    { points = colorize(titleTxtColor, pointsLoc) })
  return {
    [1] = { available = true },
    [2] = {
      available = hasSecondTier
      header = secondTierCondition
      hint = secondTierHint
    },
    [3] = {
      available = hasSecondTier && (showAll || level >= MAX_LEVEL)
      header = hasSecondTier ? requiredLevelHeader : secondTierCondition
      hint = hasSecondTier ? thirdTierHint : secondTierHint
    }
  }
}

function treeIdForSoldier(perkTreeCfg, perkTreesSpecial, soldier) {
  let className = perkTreesSpecial?[soldier?.sClass ?? ""] ?? soldier?.sKind
  return className in perkTreeCfg ? className : "common"
}

let treeForSoldier = @(perkTreeCfg, perkTreesSpecial, soldier)
  perkTreeCfg?[treeIdForSoldier(perkTreeCfg, perkTreesSpecial, soldier)]

function getPerkPointsInfo(perkListVal, soldierPerks, exclude = {}) {
  let res = {
    used = {}
    total = { speed = 0, vitality = 0, weapon = 0 }
  }

  let { points = null, perks = {} } = soldierPerks
  if (points == null)
    return res

  res.total = clone points
  foreach (perkId, count in perks) {
    if (perkId in exclude)
      continue

    let perkCfg = perkListVal?[perkId]
    if (perkCfg == null)
      continue

    
    foreach (statId, costVal in perkCfg?.cost ?? {})
      res.used[statId] <- (res.used?[statId] ?? 0) + costVal * min(count, perkCfg?.available ?? 1)
  }

  return res
}

function canDiscardPerk(perkListVal, soldierPerks, perkData) {
  if (soldierPerks.len() == 0)
    return false

  if (perkData.tier > 1)
    return true

  let exclude = {}
  foreach (perkId, _ in soldierPerks.perks) {
    if ((perkListVal?[perkId].tier ?? 1) > 1)
      exclude[perkId] <- true
  }
  if (exclude.len() == 0)
    return true

  let info = getPerkPointsInfo(perkListVal, soldierPerks, exclude)
  let usedPoints = info.used.reduce(@(sum, val) sum + val, 0)
  return (usedPoints - priceForPerk(perkData) >= POINTS_TIER2_REQUIRED)
}

return {
  PerkState
  priceForPerk
  statForPerk
  iconForPerk
  statIconForPerk
  stateForPerk
  hasEnoughPoints
  tiersAvailable
  treeForSoldier
  getPerkPointsInfo
  canDiscardPerk
  MAX_LEVEL
  POINTS_TIER2_REQUIRED
}
