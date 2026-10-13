import "%ui/userstats/serverTime.nut" as time
from "string" import strip
from "%ui/unlocks/unlocks_utils.nut" import getStageByIndex
from "%ui/userstats/unlocksState.nut" import activeUnlocks, unlockProgress, emptyProgress, allUnlocks
from "%ui/userstats/userstat.nut" import receiveUnlockRewards, buyUnlock, userstatUnlocks, setUserstatExecutor, userstatStats
from "dagor.workcycle" import resetTimeout
from "%dngscripts/globalState.nut" import hardPersistWatched
from "%ui/ui_library.nut" import *

let rewardsInProgress = Watched({})
let purchaseInProgress = Watched({})
let mkUnlockId = @(flag) Computed(@() activeUnlocks.get().findindex(@(unlock) unlock?.meta[flag] ?? false))
let basicUnlockId = mkUnlockId("monthly_challenges_common") 
let premiumUnlockId = mkUnlockId("monthly_challenges_premium")
let premiumStage0UnlockId = mkUnlockId("monthly_challenges_stage_0_premium")

let basicUnlock = Computed(@() activeUnlocks.get()?[basicUnlockId.get()])
let premiumUnlock = Computed(@() activeUnlocks.get()?[premiumUnlockId.get()])
let premiumStage0Unlock = Computed(@() (activeUnlocks.get()?[premiumStage0UnlockId.get()] ?? {})
  .__merge(unlockProgress.get()?[premiumStage0UnlockId.get()] ?? emptyProgress))
let basicProgress = Computed(@() unlockProgress.get()?[basicUnlockId.get()] ?? emptyProgress)
let premiumProgress = Computed(@() unlockProgress.get()?[premiumUnlockId.get()] ?? emptyProgress)
let nextBasicStage = Computed(@() getStageByIndex(basicUnlock.get(), basicProgress.get().lastRewardedStage))
let nextPremiumStage = Computed(@() getStageByIndex(premiumUnlock.get(), premiumProgress.get().lastRewardedStage))

let servProgress = Computed(@() userstatUnlocks.get()?.unlocks ?? {})

let seasonData = Computed(@() userstatStats.get()?.stats[basicUnlock.get()?.table])
let seasonIndex = Computed(@() seasonData.get()?["$index"] ?? 0)
let seasonEndTime = Computed(@() seasonData.get()?["$endsAt"].tointeger() ?? 0)


let isSeasonEnds = Watched(false)
let seasonEndsUpdateTime = hardPersistWatched("seasonEndsUpdateTime", 0)

function seasonEndsUpdate() {
  isSeasonEnds.set(seasonEndTime.get() > 0 && time.get() >= seasonEndTime.get())
  if (seasonEndsUpdateTime.get() > time.get())
    resetTimeout(seasonEndsUpdateTime.get() - time.get(), seasonEndsUpdate)
}

seasonEndTime.subscribe(function(v) {
  isSeasonEnds.set(v > 0 && time.get() >= v)
  if (v > time.get())
    seasonEndsUpdateTime.set(v)
})

function startSeasonEndsUpdateTimer() {
  if (seasonEndsUpdateTime.get() > time.get())
    resetTimeout(seasonEndsUpdateTime.get() - time.get(), seasonEndsUpdate)
}

seasonEndsUpdateTime.subscribe(@(_) startSeasonEndsUpdateTimer())


let hasBattlePass = Computed(@() basicUnlockId.get() != null)

let mkPrice = @(price = 0, currency = "") { currency, price }

let unlockPrices = Computed(function() {
  let res = {}
  foreach (unlockName, data in servProgress.get()) {
    let price = data?.price ?? 0
    if (price > 0)
      res[unlockName] <- mkPrice(price, data?.currencyCode ?? "")
  }
  foreach (unlockName, unlock in allUnlocks.get()) {
    if (unlockName in res)
      continue
    let idx = servProgress.get()?[unlockName].stage ?? 0
    let data = unlock?.stages[idx]
    let price = data?.price ?? 0
    if (price > 0)
      res[unlockName] <- mkPrice(price, data?.currencyCode ?? "")
  }
  return res
})

let mkRequirements = memoize(@(reqStr) reqStr.split("&").map(@(v) strip(v)).filter(@(v) v!=""))

function doReceiveRewards(unlockName) {
  if (unlockName == null || unlockName in rewardsInProgress.get())
    return
  let progressData = servProgress.get()?[unlockName]
  let stage = progressData?.stage ?? 0
  let lastReward = progressData?.lastRewardedStage ?? 0
  let requirement = allUnlocks.get()?[unlockName].requirement ?? ""
  let requirements = mkRequirements(requirement)
  foreach (req in requirements){
    let {isCompleted} = unlockProgress.get()?[req] ?? emptyProgress
    if (!isCompleted){
      log($"Can't receiveRewards results for '{unlockName}' due to incomplete requirements. Not completed unlock: '{req}'")
      return
    }
  }

  if (lastReward < stage) {
    rewardsInProgress.mutate(@(v) v[unlockName] <- stage)
    receiveUnlockRewards(unlockName, stage, {executeAfter="EN.receiveRewards", unlockName})
  }
}

setUserstatExecutor("EN.receiveRewards", function(_result, context) {
  let { unlockName = null } = context
  if (unlockName == null)
    return "Error: No 'unlockName' in context"

  log($"receiveRewards {unlockName}", rewardsInProgress.get())
  rewardsInProgress.mutate(@(v) v.$rawdelete(unlockName))
  return $"del rewardsInProgress['{unlockName}']"
})

let getUnlockPrice = @(unlockName) unlockPrices.get()?[unlockName] ?? mkPrice()

function doBuyUnlock(unlockName, cb = null) {
  if (!unlockName || unlockName in purchaseInProgress.get()) {
    log($"buyUnlock ignore {unlockName} because already in progress")
    return
  }
  let curUnlock = allUnlocks.get()?[unlockName]
  let stageDesc = servProgress.get()?[unlockName] ?? {}
  let stage = (stageDesc?.stage ?? 0) + 1
  let totalStages = curUnlock?.stages.len() ?? 0
  let price = getUnlockPrice(unlockName)
  log($"buyUnlock {unlockName} at {stage}/{totalStages} for {price.price}{price.currency} stage:", stageDesc)
  if ((stage <= totalStages || curUnlock?.periodic == true) && price.price > 0) {
    purchaseInProgress.mutate(@(v) v[unlockName] <- stage)
    buyUnlock(unlockName, stage, price.currency, price.price, function(res) {
      log($"buyUnlock {unlockName} at {purchaseInProgress.get()?[unlockName]} results:", res)
      purchaseInProgress.mutate(@(v) v.$rawdelete(unlockName))
      cb?(res)
    })
  }
}

console_register_command(@() doBuyUnlock(basicUnlockId.get(), console_print), "unlocks.buyBasic")
console_register_command(@()
  console_print($"{basicUnlockId.get()}:", basicProgress.get(), $"{premiumUnlockId.get()}:", premiumProgress.get()),
  "unlocks.rewardsProgress")

return {
  seasonEndTime
  seasonIndex
  basicUnlockId
  basicUnlock
  premiumUnlockId
  premiumUnlock
  premiumStage0Unlock
  basicProgress
  premiumProgress
  nextBasicStage
  nextPremiumStage
  unlockPrices
  purchaseInProgress
  hasBattlePass
  doReceiveRewards
  doBuyUnlock
  isSeasonEnds
}
