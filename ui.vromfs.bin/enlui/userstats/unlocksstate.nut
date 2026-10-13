from "string" import strip
from "%ui/userstats/userstat.nut" import userstatUnlocks, userstatDescList, userstatStats
from "math" import min
from "%ui/ui_library.nut" import *

let isDebugPersonal = Watched(false)
const DAILY_TASK_KEY = "daily"

let emptyProgress = {
  stage = 0
  lastRewardedStage = 0
  current = 0
  required = 1
  isCompleted = false
  hasReward = false
  isFinished = false 
}

let unlockTablesBase = keepref(Computed(function() {
  let stats = userstatStats.get()
  let res = {}
  foreach (name, _value in stats?.stats ?? {})
    res[name] <- true
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- false
  return res
}))

let unlockTables = Watched(unlockTablesBase.get())
unlockTablesBase.subscribe(function(v) {
  if (!isEqual(v, unlockTables.get()))
    unlockTables.set(v)
})

let personalUnlocksData = Computed(@() userstatUnlocks.get()?.personalUnlocks ?? {})

let unlockLogs = Computed(@() (userstatUnlocks.get()?.logs ?? []))

let allUnlocks = Computed(@() (userstatDescList.get()?.unlocks ?? {})
  .map(function(u, _name) {
    let upd = {}
    if ((u?.personal ?? "") != "")
      upd.personalData <- personalUnlocksData.get()?[u.name] ?? {}
    if ("stages" in u)
      upd.stages <- u.stages.map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
    return u.__merge(upd)
  }))

let activeUnlocks = Computed(@() allUnlocks.get().filter(function(ud) {
  if (!(unlockTables.get()?[ud?.table] ?? false) && ud?.type != "INDEPENDENT")
    return false
  if ("personalData" in ud)
    return isDebugPersonal.get() || ud.personalData.len() > 0
  return true
}))

let unlocksSorted = Computed( function() {
  let list = activeUnlocks.get()
  let res = []
  foreach (unlock in list)
    if (!unlock?.meta?.hideOnClient)
      res.append(unlock)
  return res
})

function calcUnlockProgress(progressData, unlockDesc) {
  let res = clone emptyProgress
  let stage = progressData?.stage ?? 0
  res.stage = stage
  res.lastRewardedStage = progressData?.lastRewardedStage ?? 0
  res.hasReward = stage > res.lastRewardedStage

  if (progressData?.progress != null && unlockDesc != null) {
    res.current = progressData.progress
    res.required = progressData.nextStage
    return res
  }

  let stageToShow = min(stage, (unlockDesc?.stages.len() ?? 1) - 1)
  res.required = max((unlockDesc?.stages[stageToShow].progress ?? 1).tointeger(), 1)
  if (stage > 0) {
    let isLastStageCompleted = (unlockDesc?.periodic != true) && (stage >= stageToShow)
    res.isCompleted = isLastStageCompleted || res.hasReward
    res.isFinished = isLastStageCompleted && !res.hasReward
    res.current = res.required
  }
  return res
}

let unlockProgress = Computed(function() {
  let progressList = userstatUnlocks.get()?.unlocks ?? {}
  let unlockDataList = allUnlocks.get()
  let allKeys = progressList.__merge(unlockDataList) 
  return allKeys.map(@(_, name) calcUnlockProgress(progressList?[name], unlockDataList?[name]))
})

let getUnlockProgress = @(unlockDesc, unlockProgressVal) unlockProgressVal?[unlockDesc?.name] ?? (clone emptyProgress)

let mkRequirements = memoize(@(reqStr) reqStr.split("&").map(@(v) strip(v)).filter(@(v) v!=""))
let isUnlockAvailable = @(unlockProgressV, unlock)
  mkRequirements(unlock?.requirement ?? "")
    .findvalue(@(r) !(unlockProgressV?[r].isCompleted ?? false)) == null

console_register_command(function() {
    isDebugPersonal.set(!isDebugPersonal.get())
    console_print($"Debug Personal tasks: {isDebugPersonal.get()}")
  },
  "unlocks.debugPersonalUnlocks")

return {
  allUnlocks
  unlockLogs
  activeUnlocks
  unlocksSorted
  unlockProgress
  emptyProgress = freeze(emptyProgress)
  getUnlockProgress
  isUnlockAvailable
  DAILY_TASK_KEY
}