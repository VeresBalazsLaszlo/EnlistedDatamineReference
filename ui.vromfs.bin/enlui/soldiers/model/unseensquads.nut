from "%ui/soldiers/model/state.nut" import armySquadsById
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/squads"

let seen = Computed(@() settings.get()?[SEEN_ID])

let squadsToCheck = Computed(function() {
  let result = {}
  foreach (armyId, squadsList in squadsCfgById.get()) {
    let squadsById = armySquadsById.get()[armyId]
    let squads = {}
    foreach (squadId, squad in squadsList) {
      if (!(squad?.isInitial ?? false) || (squad?.unlockCost ?? 0) > 0) 
        squads[squadId] <- squadsById?[squadId]
    }
    result[armyId] <- squads
  }
  return result
})

let unseenSquads = Computed(function() {
  let result = {}
  if (!onlineSettingUpdated.get())
    return result

  let seenIds = seen.get()
  foreach (armyId, squadsList in squadsToCheck.get()) {
    let armySeenIds = seenIds?[armyId]
    let squads = {}
    foreach (squadId, squadData in squadsList)
      squads[squadId] <- squadData != null && squadId not in armySeenIds

    result[armyId] <- squads
  }

  return result
})

function resetSeen() {
  settings.mutate(@(v) v.$rawdelete(SEEN_ID))
}

function markSeenSquads(armyId, squadIdsList) {
  let filtered = squadIdsList.filter(@(squadId) unseenSquads.get()?[armyId][squadId] ?? false)
  if (filtered.len() == 0)
    return
  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    filtered.each(@(squadId) armySaved[squadId] <- true)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

console_register_command(resetSeen, "meta.resetSeenSquads")

return {
  unseenSquads
  markSeenSquads
}
