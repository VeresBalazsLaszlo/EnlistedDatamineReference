from "%ui/eventPass/eliteEventPass.nut" import hasEliteEventPass
from "%ui/userstats/unlocksState.nut" import unlocksSorted, unlockProgress, emptyProgress, activeUnlocks
from "%ui/userstats/userstat.nut" import receiveUnlockRewards, userstatUnlocks, userstatStats, rerollUnlock
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *

let isRerollInProgress = Watched(false)

let dailyTasks = Computed(@() unlocksSorted.get()
  .filter(@(u) u?.meta.daily_unlocks_for_battlepass == bpEventSettings.get()?.bpDailyUnlocks)
  .map(@(u) u.__merge(unlockProgress.get()?[u.name] ?? emptyProgress))
  .sort(function(a, b) {
    return a.isFinished <=> b.isFinished
      || b.hasReward <=> a.hasReward
      || (a?.meta?.taskListPlace ?? -1) <=> (b?.meta?.taskListPlace ?? -1)
      || (a?.stages?[0]?.progress ?? 0) <=> (b?.stages?[0]?.progress ?? 0)
      || b.name <=> a.name
  }))

let dailyTasksByDifficulty = Computed(function() {
  let res = {
    easyTasks = []
    hardTasks = []
  }
  foreach (task in dailyTasks.get())
    if (task?.meta.core_unlock ?? false)
      res.easyTasks.append(task)
    else
      res.hardTasks.append(task)

  return res
})

let bpDailyTask = Computed(function() {
  let { bpDailyPoints = null } = bpEventSettings.get()
  return activeUnlocks.get()
    .findvalue(@(unlock) unlock?.name == bpDailyPoints)
})

let bpDailyTaskProgress = Computed(function() {
  let { bpDailyPoints = null } = bpEventSettings.get()
  return unlockProgress.get()?[bpDailyPoints] ?? emptyProgress
})

let canTakeDailyTaskReward = Computed(@()
  hasEliteEventPass.get() || bpDailyTaskProgress.get()?.stage in bpDailyTask.get()?.stages)

function receiveTaskRewards(task) {
  let uName = task.name
  let stage = userstatUnlocks.get()?.unlocks[uName].stage ?? 0
  receiveUnlockRewards(uName, stage)
}

let getLeftRerolls = @(unlockDesc, stats)
  stats?[unlockDesc?.table].freeRerollLeft ?? 0

let getTotalRerolls = @(unlockDesc, stats)
  stats?[unlockDesc?.table].freeRerollLimit

function doRerollUnlock(unlockDesc) {
  if (getLeftRerolls(unlockDesc, userstatStats.get()?.stats) <= 0 || isRerollInProgress.get())
    return

  isRerollInProgress.set(true)
  rerollUnlock(unlockDesc.name, function(_) {
    isRerollInProgress.set(false)
  })
}

return {
  dailyTasks
  dailyTasksByDifficulty
  bpDailyTask
  bpDailyTaskProgress
  receiveTaskRewards
  canTakeDailyTaskReward

  getLeftRerolls
  getTotalRerolls
  doRerollUnlock
}
