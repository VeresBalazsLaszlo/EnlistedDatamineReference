from "%ui/userstats/unlocksState.nut" import unlockProgress, emptyProgress, allUnlocks
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/ui_library.nut" import *

let curFinishedWeeklyTasksCount = Watched(0)
let bpStarsAnimGen = Watched(0)

let weeklyTasksSortFunc = @(a, b)
  (b?.activity.active ?? false) <=> (a?.activity.active ?? false)
    || (a?.isFinished ?? false) <=> (b?.isFinished ?? false)
    || (a?.meta.taskListPlace ?? -1) <=> (b?.meta.taskListPlace ?? -1)
    || a.name <=> b.name


function isWeeklyUnlock(unlock, seasonIdx) {
  let { weekly_unlock = false, battlepass_season = -1, rank_unlock = 0 } = unlock?.meta
  return rank_unlock <= 0 && weekly_unlock && battlepass_season == seasonIdx
}


let weeklyTasks = Computed(function() {
  let progress = unlockProgress.get()
  let seasonIdx = seasonIndex.get()
  let unlocks = allUnlocks.get()
    .filter(@(u) isWeeklyUnlock(u, seasonIdx))
    .map(@(u, key) u.__merge(progress?[key] ?? emptyProgress))
    .values()
    .sort(weeklyTasksSortFunc)

  return unlocks
})


let eventTasks = Computed(function() {
  let progress = unlockProgress.get()
  let unlocks = allUnlocks.get()
    .filter(@(u) u?.meta.event_unlock ?? false)
    .map(@(u, key) u.__merge(progress?[key] ?? emptyProgress))
    .values()

  return unlocks
})

let rewardWeeklyTask = Computed(@() weeklyTasks.get()
  .findvalue(@(task) task.hasReward && (task?.activity.active ?? false)))

let rewardEventTask = Computed(@() eventTasks.get()
  .findvalue(@(task) task.hasReward && (task?.activity.active ?? false)))

let getFinishedWeeklyTasksCount = @()
  weeklyTasks.get().filter(@(u) u?.isFinished ?? false).len()

function saveFinishedWeeklyTasks() {
  curFinishedWeeklyTasksCount.set(getFinishedWeeklyTasksCount())
}

let needWeeklyTasksAnim = @()
  getFinishedWeeklyTasksCount() > curFinishedWeeklyTasksCount.get()

function triggerBPStarsAnim() {
  if (needWeeklyTasksAnim())
    bpStarsAnimGen.modify(@(v) v + 1)
}

return {
  weeklyTasks
  rewardWeeklyTask
  rewardEventTask
  saveFinishedWeeklyTasks
  triggerBPStarsAnim
  bpStarsAnimGen
  isWeeklyUnlock
}
