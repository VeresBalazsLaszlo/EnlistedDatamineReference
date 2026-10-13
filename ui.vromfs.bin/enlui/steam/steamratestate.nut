import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/userstats/serverTime.nut" as serverTime
import "steam" as steam
import "%sqstd/rand.nut" as Rand
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/options/bigQuery.nut" import bqSendEvent
from "%ui/state/clientState.nut" import isChineseLanguage
from "%ui/state/steamState.nut" import isPureSteamAccount
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%ui/unlocks/steamReview.nut" import isGameRateUnlock, isSteamSecondaryReviewAvailableUnlock
from "%sqstd/time.nut" import daysToSeconds
from "datetime" import time
from "%ui/ui_library.nut" import *
from "types" import Bool

const SEEN_STEAM_REVIEW = "hasSeenSteamReviewWindow"
const STEAM_REVIEW_STATE = "steamReviewState"

let rand = Rand(time())
let steamAppID = steam.get_app_id()
let steamURL = steamAppID != 0 ? $"http://store.steampowered.com/app/{ steamAppID }/" : null

let suggestionRateSteam = {
  reShowInSeconds = daysToSeconds(30)
  reShowChancePercent = 7
  minPlaceOnWin = 5
}

function setSteamReviewSeenState(state) {
  if (!onlineSettingUpdated.get())
    return

  settings.mutate(@(s) s[STEAM_REVIEW_STATE] <- state)
}

onlineSettingUpdated.subscribe(function(v) {
  if (!v) return

  
  let state = settings.get()?[SEEN_STEAM_REVIEW]
  if (state != null) {
    onlineSettingUpdated.unsubscribe(callee())
    if (state instanceof Bool) {
      setSteamReviewSeenState({
        shownTimes = 1
        lastTimeSeen = serverTime.get()
        isUserOpenSteam = state
      })
    }
    else {
      setSteamReviewSeenState({
        shownTimes = 1
        lastTimeSeen = state
        isUserOpenSteam = false
      })
    }
    settings.mutate(@(s) s.$rawdelete(SEEN_STEAM_REVIEW))
  }

  let srState = settings.get()?[STEAM_REVIEW_STATE]
  if (srState != null) {
    if (srState?.lastTimeSeen instanceof Bool) {
      settings.mutate(@(s) s[STEAM_REVIEW_STATE] = {
        shownTimes = srState.shownTimes
        lastTimeSeen = serverTime.get()
        isUserOpenSteam = srState.lastTimeSeen
      })
    }
  }
})

let getSteamReviewSeenState = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  return settings.get()?[STEAM_REVIEW_STATE] ?? {
    shownTimes = 0
    lastTimeSeen = null
    isUserOpenSteam = false
  }
})

function onSteamReviewShown(doNotSendAnalytics = false) {
  let state = clone getSteamReviewSeenState.get()
  if (state == null) {
    return
  }

  state.shownTimes++
  state.lastTimeSeen = serverTime.get()
  setSteamReviewSeenState(state)

  if (!doNotSendAnalytics)
    bqSendEvent("steam_rate_popup")
}

function onSteamLinkClick() {
  let state = clone getSteamReviewSeenState.get()
  if (state == null)
    return

  state.isUserOpenSteam = true
  setSteamReviewSeenState(state)
  sendBigQueryUIEvent("steam_rate_confirm")
}

let getSteamRateWindowAvailability = Computed(function() {
  if (!isPureSteamAccount.get() || isChineseLanguage)
    return { isAvailable = false }

  let state = getSteamReviewSeenState.get()
  if (state == null)
    return { isAvailable = false }

  let { shownTimes, lastTimeSeen, isUserOpenSteam } = state
  if (isUserOpenSteam || lastTimeSeen instanceof Bool)
    return { isAvailable = false }

  if (shownTimes > 1)
    return { isAvailable = false }

  if (shownTimes == 0)
    return { isAvailable = isGameRateUnlock.get() && isNewbie.get() }

  if (shownTimes == 1) {
    let currentTime = serverTime.get()
    let cooldownTime = lastTimeSeen + suggestionRateSteam.reShowInSeconds
    if (currentTime < cooldownTime)
      return { isAvailable = false }

    let chancePassed = (rand.rint(0, 100) <= suggestionRateSteam.reShowChancePercent)
    if (!chancePassed) {
      return { isAvailable = false, tryNextTime = true }
    }
  }

  return { isAvailable = isSteamSecondaryReviewAvailableUnlock.get() }
})


console_register_command(function() {
  console_print($"{STEAM_REVIEW_STATE}: ", getSteamReviewSeenState.get())
}, "debug.steam_window_seen_state")

console_register_command(function(shownTimes, isUserOpenSteam, daysDelta) {
  let currentTime = serverTime.get()
  setSteamReviewSeenState({
    shownTimes
    isUserOpenSteam
    lastTimeSeen = currentTime + daysToSeconds(daysDelta)
  })
  console_print($"{STEAM_REVIEW_STATE}: ", getSteamReviewSeenState.get())
}, "debug.steam_window_set_seen_state")

console_register_command(function() {
  console_print("getSteamRateWindowAvailability: ", getSteamRateWindowAvailability.get())
}, "debug.is_steam_rate_available")

return {
  getSteamReviewSeenState
  getSteamRateWindowAvailability
  steamURL
  suggestionRateSteam
  onSteamReviewShown
  onSteamLinkClick
  setSteamReviewSeenState
}
