from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/gamemodes"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let getSeenStatus = @(val) val == true || val == SeenMarks.SEEN ? SeenMarks.SEEN
  : val == SeenMarks.OPENED ? SeenMarks.OPENED
  : SeenMarks.NOT_SEEN

let seenGamemodes = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let seen = {}
  let opened = {}
  foreach(key, seenData in settings.get()?[SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      seen[key] <- true
  }
  return { seen, opened }
})

function markSeenGamemode(gamemodeId) {
  if (getSeenStatus(settings.get()?[SEEN_ID][gamemodeId]) != SeenMarks.SEEN)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      saved[gamemodeId] <- SeenMarks.SEEN
      set[SEEN_ID] <- saved
    })
}

function markOpenedGamemodes(gamemodeIds) {
  if (gamemodeIds.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      foreach (gamemodeId in gamemodeIds)
        saved[gamemodeId] <- SeenMarks.OPENED
      set[SEEN_ID] <- saved
    })
}

console_register_command(@() settings.mutate(@(s) s.$rawdelete(SEEN_ID)), "meta.resetSeenGamemodes")

return {
  seenGamemodes
  markSeenGamemode
  markOpenedGamemodes
}
