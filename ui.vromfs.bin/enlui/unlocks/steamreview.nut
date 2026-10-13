import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

const STEAM_REVIEW_UNLOCK_ID = "steam_review_unlock"
const STEAM_MANY_BATTLES_UNLOCK_ID = "steam_many_battles_unlock"
const SAVE_ID = "user/steamReview"

let isDebugSteamReviewAvailable = Watched(null)
let isDebugSecondSteamReviewAvailable = Watched(null)

let isSteamReviewAvailableUnlock = Computed(@()
  unlockProgress.get()?[STEAM_REVIEW_UNLOCK_ID].isCompleted ?? false)

let isSteamSecondaryReviewAvailableUnlock = Computed(@()
  unlockProgress.get()?[STEAM_MANY_BATTLES_UNLOCK_ID].isCompleted ?? false)

let isSteamReviewAvailable = Computed(function() {
  return settings.get()?[SAVE_ID] ?? isSteamReviewAvailableUnlock.get() ?? false
})

function saveSteamReview() {
  if (SAVE_ID not in settings.get() && isSteamReviewAvailableUnlock.get())
    settings.mutate(@(set) set[SAVE_ID] <- serverTime.get())
}

subscribeList(saveSteamReview, isSteamReviewAvailableUnlock, onlineSettingUpdated)

let isAvailable = Computed(@() isDebugSteamReviewAvailable.get() ?? isSteamReviewAvailable.get())
let isSecondAvailable = Computed(@() isDebugSecondSteamReviewAvailable.get() ?? isSteamSecondaryReviewAvailableUnlock.get())

function printUnlockState() {
  console_print($"debug value = { isDebugSteamReviewAvailable.get() }, unlock value = {
    isSteamReviewAvailable.get() }, computed value: { isAvailable.get() }")
}

console_register_command(function(val) {
  isDebugSteamReviewAvailable.set(val)
  printUnlockState()
}, "debug.steam_review_unlock_set_debug_state")

console_register_command(printUnlockState, "debug.steam_review_unlock_state")

function printSecondUnlockState() {
  console_print($"debug value = { isDebugSecondSteamReviewAvailable.get() }, unlock value = {
    isSteamSecondaryReviewAvailableUnlock.get() }, computed value: { isSecondAvailable.get() }")
}

console_register_command(function(val) {
  isDebugSecondSteamReviewAvailable.set(val)
  printSecondUnlockState()
}, "debug.steam_review_secondary_set_unlock_state")

console_register_command(printSecondUnlockState, "debug.steam_review_secondary_unlock_state")

return {
  isGameRateUnlock = isAvailable
  isSteamSecondaryReviewAvailableUnlock = isSecondAvailable
}
