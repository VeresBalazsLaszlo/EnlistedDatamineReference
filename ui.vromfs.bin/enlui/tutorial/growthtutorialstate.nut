from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, growthConfig, GrowthStatus
from "%ui/shop/armyShopState.nut" import viewCurrencies
from "%ui/ui_library.nut" import *

const SILVER_ID = "enlisted_silver"


let tutorialGrowth = Computed(function() {
  let res = {}
  foreach (armyCfg in growthConfig.get())
    foreach (cfg in armyCfg) {
      let { id, reward = null, isAutoRewarded = false } = cfg
      let { squadId = "" } = reward
      res[id] <- !isAutoRewarded && squadId != ""
    }
  return res
})

let isTutorialPassed = Computed(function() {
  let availForTutorial = tutorialGrowth.get()
  let states = curGrowthState.get()
  return states.findvalue(@(g) g.status == GrowthStatus.REWARDED
    && (availForTutorial?[g.guid] ?? false)) != null
})

let curGrowthGuidToPurchase = Computed(function() {
  if (isTutorialPassed.get())
    return null

  let configs = curGrowthConfig.get()
  let silverHave = viewCurrencies.get()?[SILVER_ID] ?? 0
  let states = curGrowthState.get()
  return states.findindex(function(g) {
    if (g.status != GrowthStatus.PURCHASABLE)
      return false
    let { rewardCost = 0, reward = null } = configs?[g.guid]
    let { squadId = "" } = reward
    return squadId != "" && rewardCost < silverHave
  })
})

let needTutorial = Computed(@() curGrowthGuidToPurchase.get() != null)

return {
  isTutorialPassed
  curGrowthGuidToPurchase
  needTutorial
}
