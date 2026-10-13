from "%ui/userstats/unlocksState.nut" import activeUnlocks, unlockProgress, emptyProgress
from "%ui/userstats/userstat.nut" import seasonRewards, updateSeasonRewards, userstatDescList
from "%ui/leaderboard/lbState.nut" import hasLbHistory
from "%ui/ui_library.nut" import *

const REWARD_UNLOCK = "unlock"
const REWARD_LB = "leaderboard"

let lbRewardsTypes = ["tillPlaces", "tillPercent"]

userstatDescList.subscribe(function(v) {
  if (v.len() > 0)
    updateSeasonRewards()
})

function getSubArray(tbl, id) {
  if (id not in tbl)
    tbl[id] <- []
  return tbl[id]
}

let eventRewardsUnlocks = Computed(function() {
  let res = {}
  foreach (unlock in activeUnlocks.get()) {
    let { events_lb_rewards = null } = unlock?.meta
    if (events_lb_rewards == null)
      continue
    getSubArray(res, events_lb_rewards).append(
      unlock.__merge({ rType = REWARD_UNLOCK }, unlockProgress.get()?[unlock.name] ?? emptyProgress))
  }
  return res
})

let mkLbUnlocksStages = {}

lbRewardsTypes.each(function(rType) {
  mkLbUnlocksStages[rType] <- function(rewardCfg) {
    let rewards = rewardCfg?[rType] ?? {}
    if (rewards.len() == 0)
      return null
    let stages = []
    rewards.each(@(r, place) stages.append({ progress = place.tointeger(), rewards = r.itemdefids }))
    
    return stages.sort(@(a, b) b.progress < 0 <=> a.progress < 0 || b.progress <=> a.progress)
  }
})

let lbRewards = Computed(function() {
  let res = {}
  let showPrevSeasonRewards = hasLbHistory.get()
  let rewardsBase = showPrevSeasonRewards
    ? seasonRewards.get()?.previous
    : seasonRewards.get()?.current
  foreach (rewardsBlock in rewardsBase ?? []) {
    let { index = 1, modes = [], category = "", rewards = [] } = rewardsBlock
    let lbUnlockBase = {
      season = index
      category
      rType = REWARD_LB
      stages = []
    }
    foreach (modeId in modes) {
      let resModeUnlocks = getSubArray(res, modeId)
      foreach (rewardCfg in rewards)
        foreach (name, mkStages in mkLbUnlocksStages) {
          let stages = mkStages(rewardCfg)
          if (stages != null)
            resModeUnlocks.append(lbUnlockBase.__merge({ name, stages }))
        }
    }
  }
  return res
})

function mergeTblArrays(t1, t2) {
  let res = {}
  foreach (key, list in t1)
    res[key] <- clone list
  foreach (key, list in t2)
    if (key in res)
      res[key].extend(list)
    else
      res[key] <- clone list
  return res
}

let allEventRewards = Computed(@() mergeTblArrays(eventRewardsUnlocks.get(), lbRewards.get()))

return freeze({
  REWARD_UNLOCK
  REWARD_LB
  eventRewardsUnlocks
  lbRewards
  lbRewardsTypes

  allEventRewards
})