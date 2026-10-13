from "%ui/battlepass/eliteBattlePass.nut" import hasEliteBattlePass
from "%ui/unlocks/taskRewardsState.nut" import seasonIndex
from "%ui/userstats/unlocksState.nut" import unlocksSorted, unlockProgress, emptyProgress, activeUnlocks
from "%ui/userstats/userstat.nut" import receiveUnlockRewards, receiveUnlockRewardsAll, userstatUnlocks, userstatStats, rerollUnlock
from "%ui/ui_library.nut" import *

const BP_DAILY_POINTS = "battle_pass_daily_points"


let isRerollInProgress = Watched(false)

let dailyTasks = Computed(@() unlocksSorted.get()
  .filter(@(u) u.table == "daily")
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


let getTaskNameBySeason = @(name, seasonIdx) "{0}_s{1}".subst(name, seasonIdx)

let bpDailyTask = Computed(function() {
  let taskName = getTaskNameBySeason(BP_DAILY_POINTS, seasonIndex.get())
  return activeUnlocks.get().findvalue(@(unlock) unlock?.name == taskName)
})

let bpDailyTaskProgress = Computed(function() {
  let taskName = getTaskNameBySeason(BP_DAILY_POINTS, seasonIndex.get())
  return unlockProgress.get()?[taskName] ?? emptyProgress
})

let canTakeDailyTaskReward = Computed(@()
  hasEliteBattlePass.get() || bpDailyTaskProgress.get()?.stage in bpDailyTask.get()?.stages)

function receiveTaskRewards(task) {
  let uName = task.name
  let stage = userstatUnlocks.get()?.unlocks[uName].stage ?? 0
  receiveUnlockRewards(uName, stage)
}

let receiveTaskRewardsAll = @(arrTaskRewards)
  receiveUnlockRewardsAll(arrTaskRewards.filter(@(task) task.hasReward))

let achievementsList = Computed(function() {
  let progresses = unlockProgress.get()
  return activeUnlocks.get()
    .filter(@(u) (u?.meta.achievement ?? false) && (u?.activity.active ?? true))
    .reduce(@(res, val) res.append(val.__merge(progresses?[val.name] ?? emptyProgress)), [])
    .sort(function(a, b) {
      return b.hasReward <=> a.hasReward
        || a.isFinished <=> b.isFinished
        || (a?.meta.taskListPlace ?? -1) <=> (b?.meta.taskListPlace ?? -1)
        || b.name <=> a.name
    })
})

let hasAchievementsReward = Computed(@()
  achievementsList.get().findindex(@(u) u.hasReward) != null)

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

let rewardDailyTask = Computed(@() canTakeDailyTaskReward.get()
  ? dailyTasks.get().findvalue(@(task) task.hasReward)
  : null)


return {
  dailyTasks
  dailyTasksByDifficulty
  achievementsList
  hasAchievementsReward
  receiveTaskRewards
  receiveTaskRewardsAll
  rewardDailyTask
  canTakeDailyTaskReward

  getLeftRerolls
  getTotalRerolls
  isRerollInProgress
  doRerollUnlock
}
