import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/gameModes/gameModeState.nut" import eventGameModes
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/events"

const DAY = 24 * 3600
const SEEN_TIMEOUT = 14 * DAY

let seen = Computed(@() (settings.get()?[SEEN_ID] ?? {}))

let curEventsQueueId = Computed(function(prev) {
  let curr = eventGameModes.get().map(@(v) v.id)
  return isEqual(prev, curr) ? prev : curr
})

let unseenEvents = Computed(function() {
  let res = []
  if (!onlineSettingUpdated.get())
    return res

  return curEventsQueueId.get().filter(@(id) id not in seen.get())
})

function markSeenEvent(queueId) {
  if (!onlineSettingUpdated.get() || queueId == null)
    return

  if (queueId in seen.get())
    return

  settings.mutate(function(set) {
    set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({ [queueId] = serverTime.get() })
  })
}

function checkSavedEvents(events) {
  if (!onlineSettingUpdated.get())
    return

  settings.mutate(function(set) {
    let curTime = serverTime.get()
    let res = set?[SEEN_ID] ?? {}
    foreach (queueId, savedTime in seen.get()) {
      let diffTime = curTime - savedTime
      if (diffTime >= SEEN_TIMEOUT && !events.contains(queueId)) {
        if (queueId in res)
          res[queueId] <- curTime
      }
    }
    set[SEEN_ID] <- res
  })
}

function markAllSeenEvents () {
  if (!onlineSettingUpdated.get())
    return

  settings.mutate(function(set) {
    let res = set?[SEEN_ID] ?? {}
    foreach (queueId in curEventsQueueId.get()) {
      if (queueId not in seen.get())
        res[queueId] <- serverTime.get()
    }
    set[SEEN_ID] <- res
  })
}

checkSavedEvents(curEventsQueueId.get())
curEventsQueueId.subscribe(@(evt) defer(@() checkSavedEvents(evt)))

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      s.$rawdelete(SEEN_ID)
  })
}, "events.resetSeenEvents")

return {
  unseenEvents
  markSeenEvent
  markAllSeenEvents
}