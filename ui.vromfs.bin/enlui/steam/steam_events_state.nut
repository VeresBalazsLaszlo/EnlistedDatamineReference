import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
import "steam" as steam
from "%ui/state/clientState.nut" import isChineseLanguage
from "settings" import get_setting_by_blk_path
from "%ui/state/appState.nut" import isInMainMenuState
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%ui/ui_library.nut" import *

let eventsConfig = require("%ui/steam/steam_events_config.nut")


const STEAM_EVENTS_SEEN = "steamEventsSeen"


let deprecatedKeys = {
  awards = "seenSteamAwardsWindowTimestamp",
  wargames = "seenSteamWargamesWindowTimestamp",
}

let steamEvents = get_setting_by_blk_path("steamEvents")

let availableEvents = keepref(Watched(null))
let steamEvent = Computed(function() {
  return isInMainMenuState.get() && availableEvents.get()?[0]
})

function markEventSeen(event, ts = null) {
  let data = settings.get()?[STEAM_EVENTS_SEEN] ?? {}
  if (ts == null)
    data.$rawdelete(event)
  else
    data[event] <- ts ?? serverTime.get()
  settings.mutate(@(s) s[STEAM_EVENTS_SEEN] <- data)
}

function getEventSeen(event) {
  return settings.get()?[STEAM_EVENTS_SEEN][event]
}

function updateAvailableEvents(ts) {
  let events = []
  foreach (id, config in steamEvents) {
    let { start = 0, end = 0 } = config
    if (ts >= start && ts < end && getEventSeen(id) == null) {
      let { checkCb = @() true } = eventsConfig?[id]
      if (checkCb())
        events.append(id)
    }
  }

  availableEvents.set(events)
}

function check() {
  if (isChineseLanguage)
    return

  
  let ts = serverTime.get()
  updateAvailableEvents(ts)
}

let isReady = Computed(function() {
  return steam.is_running() && serverTime.get() != 0 && userInfo.get() != null
    && onlineSettingUpdated.get()
})

isReady.subscribe(function(_) {
  isReady.unsubscribe(callee())
  check()
})

function onClose() {
  let events = availableEvents.get()
  if (events && events.len() > 0) {
    availableEvents.mutate(function(v) {
      v.remove(0)
    })
  }
}

onlineSettingUpdated.subscribe(function(v) {
  if (!v)
    return

  let settingsVal = settings.get()
  foreach (id, deprecatedID in deprecatedKeys) {
    let ts = settingsVal?[deprecatedID]
    if (ts != null) {
      markEventSeen(id, ts)
      settings.mutate(@(s) s.$rawdelete(deprecatedID))
    }
  }
})

let printEventsSeen = @() console_print("steamEvents: ", settings.get()?[STEAM_EVENTS_SEEN] ?? {})

console_register_command(function() {
  printEventsSeen()
}, "debug.steam_events_seen")

console_register_command(function(event) {
  let ts = serverTime.get()
  markEventSeen(event, ts)
  printEventsSeen()
}, "debug.steam_events_seen_set")

console_register_command(function(event) {
  markEventSeen(event)
  printEventsSeen()
}, "debug.steam_events_seen_remove")


return {
  steamEvent
  markEventSeen
  onClose
}
