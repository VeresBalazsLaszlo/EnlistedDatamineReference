import "%ui/unlocks/isNewbie.nut" as isNewbie
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/unlocks/taskListState.nut" import achievementsList
from "%ui/unlocks/weeklyUnlocksState.nut" import weeklyTasks
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/ui_library.nut" import *
from "types" import Bool, Integer, Array

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

const SEEN_ID = "seen/unlocks"
const WEEKLYTASKS_SEEN_ID = "seen/weeklytasks"

let sessionsCount = mkOnlineSaveData("sessionsCount", @() 0)
let sessionsCountStored = sessionsCount.watch


function moveWeeklyUnlocks() {
  if (WEEKLYTASKS_SEEN_ID not in settings.get())
    return

  let seenData = settings.get()[WEEKLYTASKS_SEEN_ID]
  let res = {}
  foreach (name, val in seenData) {
    let newVal = val instanceof Bool ? SeenMarks.SEEN
      : val instanceof Integer ? val
      : null
    if (newVal != null)
      res[name] <- newVal
  }
  settings.mutate(function(set) {
    set[SEEN_ID] <- res
    set.$rawdelete(WEEKLYTASKS_SEEN_ID)
  })
}


settings.subscribe(function(v) {
  if (WEEKLYTASKS_SEEN_ID in v)
    gui_scene.resetTimeout(0.1, moveWeeklyUnlocks)
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenUnlocks = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let opened = {}
  let seen = {}
  foreach(key, seenData in settings.get()?[SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      seen[key] <- true
  }

  let unopenedAchievements = {}
  foreach (unlock in achievementsList.get().filter(@(u) u.hasReward))
    if (unlock.name not in opened)
      unopenedAchievements[unlock.name] <- true

  let unseenWeeklyTasks = {}
  let unopenedWeeklyTasks = {}
  foreach (unlock in weeklyTasks.get()) {
    let { name, isFinished = false, activity = null } = unlock
    let { active = false } = activity
    if (!active || isFinished)
      continue

    if (name not in seen)
      unseenWeeklyTasks[name] <- true
    if (name not in opened)
      unopenedWeeklyTasks[name] <- true
  }

  return {
    opened
    seen
    unopenedAchievements
    unseenWeeklyTasks
    unopenedWeeklyTasks
  }
})

let hasUnopenedAchievements = Computed(@()
  (seenUnlocks.get()?.unopenedAchievements.len() ?? 0) > 0)

let hasWeeklyTasks = Computed(@() weeklyTasks.get().len() > 0)

let hasUnopenedWeeklyTasks = Computed(@()
  (seenUnlocks.get()?.unopenedWeeklyTasks.len() ?? 0) > 0)

let hasUnseenWeeklyTasks = Computed(@()
  weeklyTasks.get().findindex(@(u) u?.hasReward ?? false) != null
    || (seenUnlocks.get()?.unseenWeeklyTasks.len() ?? 0) > 0)

function changeStatus(status, names) {
  let unlocksNames = names instanceof Array ? names : [names]
  let update = {}
  foreach (name in unlocksNames)
    if (getSeenStatus(settings.get()?[SEEN_ID][name]) != status)
      update[name] <- status

  if (update.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone set?[SEEN_ID] ?? {}
    saved.__update(update)
    set[SEEN_ID] <- saved
  })
}


let markUnlockSeen = @(names) changeStatus(SeenMarks.SEEN, names)

let markUnlocksOpened = @(names) changeStatus(SeenMarks.OPENED, names)

let hasNecessaryData = keepref(Computed(@() onlineSettingUpdated.get()
  && "not_a_new_player_unlock" in unlockProgress.get()
  && weeklyTasks.get() != null))


hasNecessaryData.subscribe(function(hasData) {
  if (!hasData || !isNewbie.get())
    return
  let sessions = sessionsCountStored.get()
  if (sessions == 0) {
    let unlocksToMarkUnseen = (weeklyTasks.get().reduce(@(res, v) res.append(v.name), []))
    markUnlockSeen(unlocksToMarkUnseen)
    sessionsCount.setValue(1)
  }
  else
    sessionsCount.setValue(sessions + 1)
})

let hasNewbieUnlocksData = Computed(@() hasNecessaryData.get() && isNewbie.get())

console_register_command(@() settings.mutate(@(v) v.$rawdelete(SEEN_ID)), "meta.resetSeenUnlocks")

return {
  seenUnlocks
  markUnlockSeen
  markUnlocksOpened
  hasUnopenedAchievements
  hasWeeklyTasks
  hasUnopenedWeeklyTasks
  hasUnseenWeeklyTasks
  hasNewbieUnlocksData
}
