from "%ui/meta/servProfile.nut" import decorators, medals, wallposters
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/profile/decoratorState.nut" import decoratorsCfgByType
from "%ui/ui_library.nut" import *
from "types" import Bool, Integer

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

const DECORATORS_SEEN_ID = "seen/decorators1"
const MEDALS_SEEN_ID = "seen/medals1"
const WALLPOSTERS_SEEN_ID = "seen/wallposters1"

let compatibility = {
  ["seen/decorators"] = DECORATORS_SEEN_ID,
  ["seen/medals"] = MEDALS_SEEN_ID,
  ["seen/wallposters"] = WALLPOSTERS_SEEN_ID
}

function applyCompatibility() {
  let settingsData = settings.get()
  foreach (oldKey, newKey in compatibility) {
    if (oldKey not in settingsData)
      continue

    let seenData = settingsData[oldKey]
    let res = {}
    foreach (key, val in seenData) {
      let newVal = val instanceof Bool ? SeenMarks.SEEN
        : val instanceof Integer ? val
        : null
      if (newVal != null)
        res[key] <- newVal
    }
    settings.mutate(function(set) {
      set[newKey] <- res
      set.$rawdelete(oldKey)
    })
  }
}


settings.subscribe(function(v) {
  foreach (oldKey, _newKey in compatibility)
    if (oldKey in v) {
      gui_scene.resetTimeout(0.1, applyCompatibility)
      break
    }
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenDecorators = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.get()?[DECORATORS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }
  let allDecor = decorators.get().filter(function(d) {
    let { expireTime = 0, cTime = 0 } = d
    return expireTime == 0 || expireTime - cTime <= 0
  })
  let unopened = allDecor.filter(@(d) d.guid not in res.opened)
  let unseen = allDecor.filter(@(d) d.guid not in res.seen)
  return res.__update({ unopened, unseen })
})

let cfgPortraits = Computed(@() decoratorsCfgByType.get()?.portrait ?? {})
let cfgNickFrames = Computed(@() decoratorsCfgByType.get()?.nickFrame ?? {})
let hasUnseenPortraits = Computed(function() {
  let cfgP = cfgPortraits.get()
  return (seenDecorators.get()?.unseen ?? {}).findindex(@(d) d.guid in cfgP) != null
})

let hasUnseenNickFrames = Computed(function() {
  let cfgN = cfgNickFrames.get()
  return (seenDecorators.get()?.unseen ?? {}).findindex(@(d) d.guid in cfgN)!=null
})

let _unopened = Computed(function() {
  let cfgP = cfgPortraits.get()
  let cfgN = cfgNickFrames.get()
  let unopenedPortraits = []
  let unopenedNickFrames = []
  foreach (guid, data in (seenDecorators.get()?.unopened ?? {})){
    if (guid in cfgP)
      unopenedPortraits.append(data)
    if (guid in cfgN)
      unopenedNickFrames.append(data)
  }
  return {unopenedPortraits, unopenedNickFrames}
})

let unopenedPortraits = Computed(@() _unopened.get()["unopenedPortraits"])
let unopenedNickFrames = Computed(@() _unopened.get()["unopenedNickFrames"])

let hasUnopenedDecorators = Computed(@()
  (seenDecorators.get()?.unopened.len() ?? 0) > 0)

let hasUnseenDecorators = Computed(@()
  (seenDecorators.get()?.unseen.len() ?? 0) > 0)


let seenMedals = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.get()?[MEDALS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }
  let allMedalIds = {}
  foreach (m in medals.get())
    allMedalIds[m.id] <- true

  let unopened = allMedalIds.filter(@(_v, id) id not in res.opened)
  let unseen = allMedalIds.filter(@(_v, id) id not in res.seen)
  return res.__update({ unopened, unseen })
})

let hasUnseenMedals = Computed(@()
  (seenMedals.get()?.unseen.len() ?? 0) > 0)

let hasUnopenedMedals = Computed(@()
  (seenMedals.get()?.unopened.len() ?? 0) > 0)


let seenWallposters = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.get()?[WALLPOSTERS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }

  let allWallposterTpls = {}
  foreach (w in wallposters.get())
    allWallposterTpls[w.tpl] <- true

  let unopened = allWallposterTpls.filter(@(_v, tpl) tpl not in res.opened)
  let unseen = allWallposterTpls.filter(@(_v, tpl) tpl not in res.seen)
  return res.__update({ unopened, unseen })
})

let hasUnseenWallposters = Computed(@()
  (seenWallposters.get()?.unseen.len() ?? 0) > 0)

let hasUnopenedWallposters = Computed(@()
  (seenWallposters.get()?.unopened.len() ?? 0) > 0)


function markSeenDecorator(guid) {
  if (guid not in (seenDecorators.get()?.seen ?? {}))
    settings.mutate(function(set) {
      set[DECORATORS_SEEN_ID] <- (set?[DECORATORS_SEEN_ID] ?? {})
        .__merge({ [guid] = SeenMarks.SEEN })
    })
}

function markDecoratorsOpened(guids) {
  if (guids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[DECORATORS_SEEN_ID] ?? {})
      foreach(guid in guids)
        saved[guid] <- SeenMarks.OPENED
      set[DECORATORS_SEEN_ID] <- saved
    })
}

function markSeenMedal(id) {
  if (id not in (seenMedals.get()?.seen ?? {}))
    settings.mutate(function(set) {
      set[MEDALS_SEEN_ID] <- (set?[MEDALS_SEEN_ID] ?? {})
        .__merge({ [id] = SeenMarks.SEEN })
    })
}

function markMedalsOpened(ids) {
  if (ids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[MEDALS_SEEN_ID] ?? {})
      foreach(id in ids)
        saved[id] <- SeenMarks.OPENED
      set[MEDALS_SEEN_ID] <- saved
    })
}

function markSeenWallposter(id) {
  if (id not in (seenWallposters.get()?.seen ?? {}))
    settings.mutate(function(set) {
      set[WALLPOSTERS_SEEN_ID] <- (set?[WALLPOSTERS_SEEN_ID] ?? {})
        .__merge({ [id] = SeenMarks.SEEN })
    })
}

function markWallpostersOpened(ids) {
  if (ids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[WALLPOSTERS_SEEN_ID] ?? {})
      foreach(id in ids)
        saved[id] <- SeenMarks.OPENED
      set[WALLPOSTERS_SEEN_ID] <- saved
    })
}

console_register_command(@() settings.mutate(@(v) v.$rawdelete(DECORATORS_SEEN_ID)), "meta.resetSeenDecorators")
console_register_command(@() settings.mutate(@(v) v.$rawdelete(MEDALS_SEEN_ID)), "meta.resetSeenMedals")
console_register_command(@() settings.mutate(@(v) v.$rawdelete(WALLPOSTERS_SEEN_ID)), "meta.resetSeenWallposters")

return {
  seenDecorators
  unopenedPortraits
  unopenedNickFrames
  hasUnopenedDecorators
  hasUnseenDecorators
  hasUnseenPortraits
  hasUnseenNickFrames
  markSeenDecorator
  markDecoratorsOpened

  seenMedals
  hasUnopenedMedals
  hasUnseenMedals
  markSeenMedal
  markMedalsOpened

  seenWallposters
  markSeenWallposter
  markWallpostersOpened
  hasUnseenWallposters
  hasUnopenedWallposters
}
