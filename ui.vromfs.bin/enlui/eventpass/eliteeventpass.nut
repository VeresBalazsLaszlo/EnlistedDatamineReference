from "%ui/eventPass/eventTaskRewardsState.nut" import premiumUnlock, premiumStage0Unlock
from "%ui/shop/armyShopState.nut" import purchaseInProgress
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/userstats/userstat.nut" import userstatStats
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *

let elitePassItem = Computed(function() {
  let { premPassItem = null } = bpEventSettings.get()
  return shopItems.get()?[premPassItem]
})

let isDebugEventPass = Watched(false)
let hasEliteEventPassBase = Computed(function() {
  let { premPassStat = "" } = bpEventSettings.get()
  return (userstatStats.get()?.stats.battle_pass.main_game[premPassStat] ?? 0) > 0
})

let eventTokenMultiplier = Computed(@()
  bpEventSettings.get()?.premPassTokenMult ?? 1)

let eliteBpUnlockId = Computed(@() premiumUnlock.get()?.requirement)
let premRewardsAllowed = Computed(@() eliteBpUnlockId.get() == null
  || (unlockProgress.get()?[eliteBpUnlockId.get()].isFinished ?? false))

let hasEliteEventPass = Computed(function() {
  let { isMarathonEvent = false } = bpEventSettings.get()
  let res = hasEliteEventPassBase.get() || premRewardsAllowed.get()
    || (isMarathonEvent && (premiumStage0Unlock.get()?.isFinished ?? false))
  return isDebugEventPass.get() ? !res : res
})

let isPurchaseBpInProgress = Computed(@() elitePassItem.get() != null
  && purchaseInProgress.get() == elitePassItem.get())

let canBuyEventPass = Computed(@() !hasEliteEventPass.get() && elitePassItem.get() != null)

console_register_command(@(value) isDebugEventPass.set(!!value), "meta.debugEventPass")

return {
  canBuyEventPass
  hasEliteEventPass
  premRewardsAllowed
  isPurchaseBpInProgress
  elitePassItem
  eventTokenMultiplier
}
