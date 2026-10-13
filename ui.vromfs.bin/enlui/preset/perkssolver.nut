from "%ui/meta/perks/perksPoints.nut" import pPointsList
from "%ui/meta/perks/perkTreePkg.nut" import MAX_LEVEL, POINTS_TIER2_REQUIRED
from "%ui/ui_library.nut" import *
























function computePossibleSets(costMaps, bit, perkCost, statLimit) {
  let newMaps = {}

  foreach (cost, list in costMaps) {
    let newCost = cost + perkCost
    if (newCost <= statLimit)
      newMaps[newCost] <- list.map(@(bitSet) bitSet | bit) 
  }

  foreach (cost, list in newMaps)
    costMaps[cost] <- (costMaps?[cost] ?? []).extend(list)
}

function calcTier1(bitSet, statData) {
  let { perks, tier1Count } = statData

  local total = 0
  for (local i = 0; i < tier1Count; i++)
    total += (bitSet & (1 << i)) ? perks[i].cost : 0

  return total
}

function cachedSum(tier1Sums, bitset, statData, stat) {
  local sum = tier1Sums[stat]?[bitset]
  if (sum == null) {
    sum = calcTier1(bitset, statData[stat])
    tier1Sums[stat][bitset] <- sum
  }
  return sum
}

function computeGoodSets(statData, costs, requiredPoints, totalPoints) {
  let sortFn = @(a, b) b <=> a
  let sorted = @(stats) stats.keys().sort(sortFn)

  local costMax = 0
  let tier1Sums = {}
  foreach (stat in pPointsList)
    tier1Sums[stat] <- {}

  let keysVIT = sorted(costs.vitality)
  let keysSPD = sorted(costs.speed)

  local result = {}
  foreach (cost1 in sorted(costs.weapon))
    foreach (cost2 in keysVIT)
      foreach (cost3 in keysSPD) {
        let cost = cost1 + cost2 + cost3
        if (cost <= costMax)
          continue

        foreach (set1 in costs.weapon[cost1]) {
          let tier1WPN = cachedSum(tier1Sums, set1, statData, "weapon")

          foreach (set2 in costs.vitality[cost2]) {
            let tier1VIT = cachedSum(tier1Sums, set2, statData, "vitality")

            foreach (set3 in costs.speed[cost3]) {
              let tier1SPD = cachedSum(tier1Sums, set3, statData, "speed")
              if (tier1WPN + tier1VIT + tier1SPD >= requiredPoints) {

                result = { weapon = set1, vitality = set2, speed = set3 }
                if (cost == totalPoints)
                  return result

                costMax = cost
              }

            }
          }
        }
      }

  return result
}

function bitSetToPerks(bitSet, perks) {
  let result = {}
  foreach (i, perkData in perks)
    if (bitSet & (1 << i))
      result[perkData.perkId] <- 1 + (result?[perkData.perkId] ?? 0)
  return result
}

function splitByStat(level, selectedPerks, availablePoints) {
  let allStats = {}
  foreach (stat in pPointsList)
    allStats[stat] <- {
      perks = []
      tier1Count = 0
      points = availablePoints[stat]
    }

  for (local i = selectedPerks.len() - 1; i >= 0; i--) {
    

    let { newAmount, perk } = selectedPerks[i]

    let { cost = {}, tier = 0, perkId } = perk
    let stat = cost.findindex(@(_) true)

    if (stat == null || cost[stat] == 0  
        || (tier == 3 && level < MAX_LEVEL))
      continue

    let data = allStats[stat]
    if (tier == 1)
      data.tier1Count += newAmount

    for (local j = 0; j < newAmount; j++)
      data.perks.append( { perkId, cost = cost[stat] } )
  }

  return allStats
}

function computeSubsets(level, selectedPerks, availablePoints, requiredPoints) {
  let statData = splitByStat(level, selectedPerks, availablePoints)

  let costs = {}
  foreach (stat in pPointsList) {
    let { perks = [], points } = statData[stat]
    let costMap = { [0] = [0] }
    

    foreach (i, perkData in perks)
      computePossibleSets(costMap, 1 << i, perkData.cost, points)
    costs[stat] <- costMap
  }

  let totalPoints = availablePoints.reduce(@(res, val) res + val, 0)

  let goodSet = computeGoodSets(statData, costs, requiredPoints, totalPoints)
  return goodSet.reduce(@(res, bitset, stat)
    res.__update(bitSetToPerks(bitset, statData?[stat].perks ?? [])), {})
}

function computeGreedy(level, selectedPerks, availablePoints, requiredPoints) {
  let points = clone availablePoints
  local tier1Required = requiredPoints
  let result = {}
  foreach (perkData in selectedPerks) {
    let { perk, newAmount } = perkData
    let { perkId, tier = null, cost = {} } = perk

    if (tier == 3 && level < MAX_LEVEL) {
      result[perkId] <- 0
      continue
    }

    let amount = cost.reduce(@(res, val, stat)
        (val == 0) ? res : min(res, points[stat]/val),
      newAmount)

    foreach (stat, val in cost) {
      let spent = val * amount
      points[stat] -= spent
      if (tier == 1)
        tier1Required -= spent
    }
    result[perkId] <- amount
  }

  return tier1Required > 0 ? null : result
}

function computePerks(level, selectedPerks, availablePoints, tier1Points) {
  if (selectedPerks.len() == 0)
    return {} 

  let requiredPoints = min(POINTS_TIER2_REQUIRED,
      availablePoints.reduce(@(res, val) res + val, 0)) - tier1Points

  let fastResult = computeGreedy(level, selectedPerks, availablePoints, requiredPoints)
  if (fastResult != null)
    return fastResult

  let tier1Cost = availablePoints.map(@(_) 0)
  foreach (perkData in selectedPerks) {
    let { perk, newAmount } = perkData
    let { tier = null, cost = {} } = perk
    if (tier == 1)
      foreach (stat, val in cost)
        tier1Cost[stat] += val * newAmount
  }

  let tier1CostTotal = tier1Cost.reduce(@(res, v, stat) min(v, availablePoints[stat]) + res, 0)
  let acceptedPoints = min(requiredPoints, tier1CostTotal)
  let result = computeSubsets(level, selectedPerks, availablePoints, acceptedPoints)

  foreach (perkData in selectedPerks) {
    let { perkId, tier = 0 } = perkData.perk
    if (perkId not in result
        || (acceptedPoints < requiredPoints && tier > 1))
      result[perkId] <- 0
  }

  return result
}

return { computePerks }
