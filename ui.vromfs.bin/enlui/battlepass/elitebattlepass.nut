from "%ui/unlocks/taskRewardsState.nut" import seasonIndex, premiumUnlock, isSeasonEnds
from "%ui/shop/armyShopState.nut" import purchaseInProgress
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/userstats/userstat.nut" import userstatStats
from "%ui/ui_library.nut" import *

const PREMPASS_STAT = "prempass_active_stat_s{0}"

let elitePassItem = Computed(@() shopItems.get()
  .findvalue(@(i) i?.prempass_active_stat_season == seasonIndex.get()))

let isDebugBP = mkWatched(persist, "isDebugBP", false)
let hasEliteBattlePassBase = Computed(@()
  (userstatStats.get()?.stats.battle_pass.main_game[PREMPASS_STAT.subst(seasonIndex.get())] ?? 0) > 0)

let eliteBpUnlockId = Computed(@() premiumUnlock.get()?.requirement)
let premRewardsAllowed = Computed(@() eliteBpUnlockId.get() == null
  || (unlockProgress.get()?[eliteBpUnlockId.get()].isFinished ?? false))

let hasEliteBattlePass = Computed(function() {
  let res = hasEliteBattlePassBase.get() || premRewardsAllowed.get()
  return isDebugBP.get() ? !res : res
})

let isPurchaseBpInProgress = Computed(@() elitePassItem.get() != null
  && purchaseInProgress.get() == elitePassItem.get())

let canBuyBattlePass = Computed(@() !hasEliteBattlePass.get()
  && elitePassItem.get() != null && !isSeasonEnds.get())

console_register_command(@() isDebugBP.set(!isDebugBP.get()), "meta.debugBattlePass")

return {
  canBuyBattlePass
  hasEliteBattlePass
  premRewardsAllowed
  isPurchaseBpInProgress
  elitePassItem
}