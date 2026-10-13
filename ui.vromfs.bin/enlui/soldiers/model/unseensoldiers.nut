from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/meta/profile.nut" import soldiersByArmies
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/ui_library.nut" import *

const SEEN_ID = "seenData/soldiers"

let seenData = Computed(@() settings.get()?[SEEN_ID])

let unseen = Computed(@() onlineSettingUpdated.get()
  ? soldiersByArmies.get().map(function(list, armyId) {
      let seenSoldiers = seenData.get()?[armyId] ?? {}
      return list.reduce(function(res, soldier) {
        let guid = soldier.guid
        if (!(guid in seenSoldiers))
          res[guid] <- true
        return res
      }, {})
    })
  : {})

let unseenCurrent = Computed(@() unseen.get()?[curArmy.get()] ?? {})

function changeStatus(armyId, soldierGuids, needDelete = false) {
  let update = {}
  let data = seenData.get()?[armyId]
  foreach (guid in typeof soldierGuids == "array" ? soldierGuids : [soldierGuids]) {
    if ((guid not in data && !needDelete) || (guid in data && needDelete))
      update[guid] <- true
  }
  if (update.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone set?[SEEN_ID] ?? {}
    let armySaved = clone saved?[armyId] ?? {}
    if (needDelete)
      update.each(@(_, key) armySaved.$rawdelete(key))
    else
      armySaved.__update(update)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

let markSoldiersSeen = @(armyId, soldierGuids) changeStatus(armyId, soldierGuids)

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      s.$rawdelete(SEEN_ID)
  })
}, "meta.resetSeenSoldiers")

return {
  unseenSoldiers = unseenCurrent
  markSoldierSeen = markSoldiersSeen
}
