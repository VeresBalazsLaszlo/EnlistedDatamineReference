from "%ui/userstats/userstat.nut" import userstatUnlocks
from "%ui/userstats/unlocksState.nut" import allUnlocks, unlockProgress
from "%ui/options/onlineSettings.nut" import settings
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/ui_library.nut" import *

const RANK_UNLOCK = "player_military_rank_unlock"
const SEEN_ID = "seen/rank_stage_idx"


let rankBaseUnlock = Computed(@() allUnlocks.get()?[RANK_UNLOCK])

let rankUnlock = Computed(function() {
  let allProgress = unlockProgress.get()
  let rankUn = rankBaseUnlock.get()
  if (rankUn == null || allProgress == null)
    return null

  let rankState = []
  rankUn.stages.each(function(stage, idx) {
    if (stage.progress < rankUn.meta.godRating)
      rankState.append({
        progress = stage.progress / 100
        ratingOnNextSeason = rankUn.meta.ratingOnNextSeason[idx] / 100
        index = idx + 1
      })
  })

  local rewardIndex = -1
  let ranksQuantity = rankState.len()
  let seasonIdx = seasonIndex.get()
  allUnlocks.get().each(function(unlock) {
    let { rank_unlock = 0 } = unlock?.meta
    let { active = true, start_index = 0, end_index = seasonIdx } = unlock?.activity
    if (active
          && start_index <= seasonIdx
          && end_index >= seasonIdx
          && rank_unlock != 0
          && rank_unlock <= ranksQuantity) {
      let progress = allProgress?[unlock.name]
      rankState[rank_unlock - 1].__update({ unlock })
      if (progress?.hasReward ?? false)
        rewardIndex = rewardIndex < 0
          ? rank_unlock - 1
          : min(rank_unlock - 1, rewardIndex)
    }
  })
  if (rewardIndex >= 0)
    rankState[rewardIndex].hasReward <- true

  return rankState
})

let playerRank = Computed(function() {
  let ratingInfo = userstatUnlocks.get()?.unlocks[RANK_UNLOCK]
  let { stage = 0, progress = 0, nextStage = 0 } = ratingInfo
  if (stage == 0)
    return null

  return {
    rank = stage
    rating = progress
    nextRank = nextStage
  }
})


let defaultSeenRank = {
  seen = 0
  opened = 0
}

function markOpenedRank(rank) {
  settings.mutate(function(set) {
    set[SEEN_ID] <- (set?[SEEN_ID] ?? defaultSeenRank).__merge({ opened = rank })
  })
}


console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      s.$rawdelete(SEEN_ID)
  })
}, "meta.resetSeenRank")


let rankStatusText = Computed(function() {
  let rankUn = rankUnlock.get() ?? []
  let playerRating = (playerRank.get()?.rating ?? 0) / 100
  let completed = rankUn.reduce(@(res, u) playerRating >= u.progress ? res + 1 : res, 0)
  return $"{completed}/{rankUn.len()}"
})


let hasRankReward = Computed(@()
  (rankUnlock.get() ?? []).findvalue(@(u) u?.hasReward ?? false) != null)


return {
  playerRank
  rankUnlock
  markOpenedRank
  rankStatusText
  hasRankReward
}
