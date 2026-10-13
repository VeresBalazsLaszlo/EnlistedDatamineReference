from "%ui/squad/squadState.nut" import isSquadNotEmpty, isInSquad
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%dngscripts/globalState.nut" import nestWatched
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

const NEWBIE_UNLOCK_ID = "not_a_new_player_unlock"
const SAVE_ID = "user/notNewbiePlayer"

let isDebugNewbie = nestWatched("isDebugNewbie", null)

let isNewbieUnlock = Computed(@() unlockProgress.get()?[NEWBIE_UNLOCK_ID].isCompleted)

let isNewbieBase = Computed(function() {
  if (isInSquad.get() && isSquadNotEmpty.get())
    return false
  return !(settings.get()?[SAVE_ID] ?? isNewbieUnlock.get() ?? false)
})

function saveNewbie() {
  if (SAVE_ID not in settings.get() && isNewbieUnlock.get())
    settings.mutate(@(set) set[SAVE_ID] <- true)
}

subscribeList(saveNewbie, isNewbieUnlock, onlineSettingUpdated)

let isNewbie = Computed(@() !!(isDebugNewbie.get() ?? isNewbieBase.get()))

console_register_command(function(val) {
  isDebugNewbie.set(val)
  console_print($"debugNewbie = {isDebugNewbie.get()}, isNewbie = {isNewbieBase.get()}")
}, "ui.debugNewbieSet")

return isNewbie