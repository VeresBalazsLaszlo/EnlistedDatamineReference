from "string" import strip
from "%ui/unlocks/unlocks_utils.nut" import getStageByIndex
from "%ui/userstats/unlocksState.nut" import activeUnlocks, unlockProgress, emptyProgress, allUnlocks
from "%ui/userstats/userstat.nut" import receiveUnlockRewards, buyUnlock, userstatUnlocks, setUserstatExecutor, userstatStats
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/ui_library.nut" import *

let rewardsInProgress = Watched({})
let purchaseInProgress = Watched({})

let mkUnlockId = @(flag) Computed(function() {
  let unlockName = bpEventSettings.get()?[flag]
  return activeUnlocks.get().findindex(@(unlock) unlock?.meta[unlockName] ?? false)
})

let basicUnlockId = mkUnlockId("bpBasicUnlock")
let premiumUnlockId = mkUnlockId("bpPremiumUnlock")
let premiumStage0UnlockId = mkUnlockId("bpPremiumStage0")
let dailyUnlockId = mkUnlockId("bpDailyReward")

let basicUnlock = Computed(@() activeUnlocks.get()?[basicUnlockId.get()])
let premiumUnlock = Computed(@() activeUnlocks.get()?[premiumUnlockId.get()])
let premiumStage0Unlock = Computed(@() (activeUnlocks.get()?[premiumStage0UnlockId.get()] ?? {})
  .__merge(unlockProgress.get()?[premiumStage0UnlockId.get()] ?? emptyProgress))
let basicProgress = Computed(@() unlockProgress.get()?[basicUnlockId.get()] ?? emptyProgress)
let premiumProgress = Computed(@() unlockProgress.get()?[premiumUnlockId.get()] ?? emptyProgress)
let nextBasicStage = Computed(@() getStageByIndex(basicUnlock.get(), basicProgress.get().lastRewardedStage))
let nextPremiumStage = Computed(@() getStageByIndex(premiumUnlock.get(), premiumProgress.get().lastRewardedStage))

let purchaseStageUnlock = Computed(@()
  activeUnlocks.get()?[bpEventSettings.get()?.purchaseStageUnlock])

let purchaseStageProgress = Computed(function() {
  let unlock = purchaseStageUnlock.get()
  return unlock == null ? null
    : unlock.__merge(unlockProgress.get()?[unlock?.name] ?? emptyProgress)
})

let servProgress = Computed(@() userstatUnlocks.get()?.unlocks ?? {})

let seasonData = Computed(@() userstatStats.get()?.stats[basicUnlock.get()?.table])
let seasonIndex = Computed(@() seasonData.get()?["$index"] ?? 0)
let seasonEndTime = Computed(@() seasonData.get()?["$endsAt"].tointeger() ?? 0)

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

let dailyEventUnlock = Computed(function() {
  let unlock = activeUnlocks.get()?[dailyUnlockId.get()]
  if (unlock == null)
    return null

  return unlock.__merge(unlockProgress.get()?[dailyUnlockId.get()] ?? emptyProgress)
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
    receiveUnlockRewards(unlockName, stage, { executeAfter="EN.receiveEventRewards", unlockName })
  }
}

setUserstatExecutor("EN.receiveEventRewards", function(_result, context) {
  let { unlockName = null } = context
  if (unlockName == null)
    return "Error: No 'unlockName' in userstat context"

  log($"receiveEventRewards {unlockName}", rewardsInProgress.get())
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

function testEventSettings() {
  function check(cond, msg) {
    if (!cond)
      log(msg)
  }

  function findUnlock(key) {
    let name = bpEventSettings.get()?[key]
    check(name != null,
      $"Add '{key}' to bpEventSettings.")
    check(name in allUnlocks.get(),
      $"{key}: Unlock '{name}' not received by client")
    check(name in activeUnlocks.get(),
      $"{key}: Unlock '{name}' must be active")
    check(null != activeUnlocks.get().findindex(@(unlock) unlock?.meta[name] ?? false),
      $"{key}: Unlock should have '{name}' field defined in meta")
  }

  check(bpEventSettings.get() != null,
    "Define battlepassWidget in matching.")
  let unlocks = ["bpBasicUnlock", "bpPremiumUnlock"]
  unlocks.each(findUnlock)

  let { premPassItem = "" } = bpEventSettings.get()
  check(premPassItem in shopItems.get(),
    $"Add pass item '{premPassItem}' to shop config.")
  log("Check completed.")
}

console_register_command(testEventSettings, "meta.checkEventConfig")

console_register_command(@() doBuyUnlock(basicUnlockId.get(), console_print), "unlocks.buyEventBasic")
console_register_command(@()
  console_print($"{basicUnlockId.get()}:", basicProgress.get(), $"{premiumUnlockId.get()}:", premiumProgress.get()),
  "unlocks.rewardsEventProgress")

return {
  seasonEndTime
  seasonIndex
  basicUnlockId
  basicUnlock
  premiumUnlockId
  premiumUnlock
  premiumStage0Unlock
  dailyEventUnlock
  purchaseStageProgress

  basicProgress
  premiumProgress
  nextBasicStage
  nextPremiumStage
  unlockPrices
  rewardsInProgress
  purchaseInProgress
  hasBattlePass
  doReceiveRewards
  doBuyUnlock
}