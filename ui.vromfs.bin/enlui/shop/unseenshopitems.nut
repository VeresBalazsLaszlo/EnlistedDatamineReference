from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *
from "types" import Table, Bool, Integer

const OLD_SEEN_ID = "seen/currencies"
const SEEN_ID = "seen/shopItems"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let seenData = Computed(@() settings.get()?[SEEN_ID] ?? {})

function applyCompatibility() {
  if (OLD_SEEN_ID not in settings.get())
    return

  let seenOld = settings.get()[OLD_SEEN_ID]
  let res = {}
  foreach (armyId, armySeenData in seenOld) {
    if (!(armySeenData instanceof Table))
      continue

    res[armyId] <- {}
    foreach (itemId, armySaved in armySeenData) {
      let newArmySaved = armySaved instanceof Bool ? SeenMarks.SEEN
        : armySaved instanceof Integer ? armySaved
        : null
      if (newArmySaved != null)
        res[armyId][itemId] <- newArmySaved
    }
  }
  settings.mutate(function(set) {
    set[SEEN_ID] <- res
    set.$rawdelete(OLD_SEEN_ID)
  })
}


settings.subscribe(function(v) {
  if (OLD_SEEN_ID in v)
    gui_scene.resetTimeout(0.1, applyCompatibility)
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenShopItems = Computed(function() {
  let opened = {}
  let seen = {}
  foreach(armyId, armySeen in seenData.get())
    foreach(key, status in armySeen) {
      if (status != SeenMarks.NOT_SEEN) {
        if (armyId not in opened)
          opened[armyId] <- {}
        opened[armyId][key] <- true
      }
      if (status == SeenMarks.SEEN) {
        if (armyId not in seen)
          seen[armyId] <- {}
        seen[armyId][key] <- true
      }
    }
  return { opened, seen }
})

function changeStatus(status, armyId, itemGuids) {
  let update = {}
  foreach (guid in typeof itemGuids == "array" ? itemGuids : [itemGuids])
    if (getSeenStatus(seenData.get()?[armyId][guid]) != status)
      update[guid] <- status
  if (update.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone set?[SEEN_ID] ?? {}
    let armySaved = clone saved?[armyId] ?? {}
    armySaved.__update(update)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

let markShopItemSeen = @(armyId, itemGuids) changeStatus(SeenMarks.SEEN, armyId, itemGuids)

let markShopItemOpened = @(armyId, itemGuids) changeStatus(SeenMarks.OPENED, armyId, itemGuids)

function excludeShopItemSeen(armyId, excludeList) {
  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    saved[armyId] <- armySaved.filter(@(_, name) excludeList.findindex(@(v) v == name) == null)
    set[SEEN_ID] <- saved
  })
}

console_register_command(@() settings.mutate(@(s) s?.$rawdelete(SEEN_ID)), "meta.resetSeenShopItems")

return {
  seenShopItems
  markShopItemSeen
  markShopItemOpened
  excludeShopItemSeen
  getSeenStatus
  SeenMarks
}
