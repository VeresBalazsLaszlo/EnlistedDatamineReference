import "%ui/hud/state/userstatStateInBattle.nut" as statsInGame
from "%ui/userstats/unlocksState.nut" import unlocksSorted, emptyProgress, DAILY_TASK_KEY
from "%ui/unlocks/weeklyUnlocksState.nut" import isWeeklyUnlock
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/ui_library.nut" import *

let isEvent = Computed(@() statsInGame.get()?.modes.contains("endgame_events") ?? false)

function appendAllSteps(res, unlockName, step, byRequirement) {
  if (unlockName not in byRequirement)
    return step - 1
  local totalSteps = step
  foreach(unlock in byRequirement[unlockName]) {
    let curTotal = appendAllSteps(res, unlock.name, step + 1, byRequirement)
    res.append(unlock.__merge({ step, totalSteps = curTotal }))
    totalSteps = max(totalSteps, curTotal)
  }
  return totalSteps
}

let battleUnlocks = Computed(function() {
  let seasonIdx = seasonIndex.get()
  let filterFunc = isEvent.get()
    ? @(u) isWeeklyUnlock(u, seasonIdx) || (u?.meta.event_group != null) 
    : @(u) (u?.meta.isVisibleInBattle ?? true)
        && (u.table == DAILY_TASK_KEY || isWeeklyUnlock(u, seasonIdx) || (u?.meta.event_unlock ?? false))
  let unlocks = unlocksSorted.get().filter(filterFunc)
  if (!isEvent.get())
    return unlocks

  let byRequirement = {}
  foreach(u in unlocks) {
    let requirement = u?.requirement ?? ""
    if (requirement not in byRequirement)
      byRequirement[requirement] <- []
    byRequirement[requirement].append(u)
  }

  let res = []
  appendAllSteps(res, "", 1, byRequirement)
  return res
})

function getTasksWithProgress(unlocks, unlocksProgress, stats) {
  let modes = {}
  foreach(mode in stats?.modes ?? [])
    modes[mode] <- true
  return unlocks
    .map(function(unlock) {
      let progress = unlocksProgress?[unlock.name] ?? emptyProgress
      let { stat = null, mode = null } = unlock?.meta
      if (!(modes?[mode] ?? false))
        return unlock.__merge(progress)

      local { current = 0, required = 1 } = progress
      let statToCheck = typeof stat == "array" ? stat : [stat]
      let inGameStat = statToCheck?.reduce(@(res, s) (stats?[s] ?? 0) + res, 0) ?? 0
      current = min(current + inGameStat, required)
      return unlock.__merge(progress, { current, isCompleted = current >= required })
    })
    .filter(@(u) !(u?.isFinished ?? false))
    .sort(@(a, b) b.hasReward <=> a.hasReward
        || (a?.meta?.taskListPlace ?? -1) <=> (b?.meta?.taskListPlace ?? -1)
        || (a?.stages?[0]?.progress ?? 0) <=> (b?.stages?[0]?.progress ?? 0)
        || b.name <=> a.name)
}

return {
  getTasksWithProgress
  battleUnlocks
  statsInGame
}