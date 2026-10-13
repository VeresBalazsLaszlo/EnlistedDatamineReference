import "%enlSqGlob/userInfo.nut" as userInfo
from "dagor.random" import frnd
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/queueState.nut" import isInQueue
from "%ui/meta/clientApi.nut" import update_profile, update_partial, get_all_configs, lastTransactId
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let matchingNotifications = require("%ui/notifications/matchingNotifications.nut")
let logPR = with_prefix("[profileRefresh] ")

const MAX_CONFIGS_UPDATE_DELAY = 120 
  

enum UpdateMode {
  NONE
  DIFF
  FULL
}

let updateMode = nestWatched("updateMode", UpdateMode.NONE)
let needUpdate = keepref(Computed(@() !isInBattleState.get() && !isInQueue.get()))

wlog(updateMode, "[profileRefresh] updateMode")
wlog(isInBattleState, "[profileRefresh] isInBattleState")
wlog(isInQueue, "[profileRefresh] isInQueue")

function checkUpdateProfile() {
  logPR($"Check update profile, updateMode = {updateMode.get()}")
  gui_scene.clearTimer(callee())
  if (isInBattleState.get()) {
    logPR("Skipping profile update in battle")
    return
  }

  if (isInQueue.get()) {
    logPR("Skipping profile update while staying at queue")
    return
  }

  if (updateMode.get() == UpdateMode.FULL) {
    logPR("Update full profile and configs")
    
    get_all_configs()
    update_profile()
    updateMode.set(UpdateMode.NONE)
    return
  }

  if (updateMode.get() == UpdateMode.DIFF) {
    logPR($"Partial update profile, last = {lastTransactId.get()}")
    update_partial(lastTransactId.get())
    updateMode.set(UpdateMode.NONE)
    return
  }

  logPR("No update needed")
}

needUpdate.subscribe(function(v) {
  if (v)
    checkUpdateProfile()
})

function updateConfigsDelayed() {
  let delay = frnd() * MAX_CONFIGS_UPDATE_DELAY
  logPR($"Delayed configs update within {delay} sec")
  gui_scene.resetTimeout(delay, checkUpdateProfile)
}

userInfo.subscribe(function(u) {
  if (u == null)
    updateMode.set(UpdateMode.NONE)
})

function onUpdateEvent(isFull = true) {
  logPR($"On update event, isFull = {isFull}")
  if (isFull) {
    updateMode.set(UpdateMode.FULL)
    updateConfigsDelayed()
    return
  }

  if (updateMode.get() != UpdateMode.FULL) {
    updateMode.set(UpdateMode.DIFF)
    checkUpdateProfile()
  }
}

matchingNotifications.subscribe("profile", function(ev) {
  logPR($"Notification subscription triggered, func={ev?.func}")
  onUpdateEvent(ev?.func == "updateConfig")
})

console_register_command(@(isFull) onUpdateEvent(isFull), "meta.updateProfileConfigs")
