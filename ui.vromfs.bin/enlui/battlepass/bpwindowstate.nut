import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/battlepass/bpState.nut" import basicProgress, premiumProgress, combinedUnlocks, nextStage, nextRewardStage, progressCounters, currentProgress
from "%ui/battlepass/eliteBattlePass.nut" import hasEliteBattlePass
from "%ui/battlepass/rewardsPkg.nut" import getOneReward
from "%ui/unlocks/taskRewardsState.nut" import isSeasonEnds
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/ui_library.nut" import *

let curItem = mkWatched(persist, "curItem", null)
let isOpened = mkWatched(persist, "isOpened", false)
let isVisible = Watched(false)

enum RewardState {
  COMPLETED = 0
  IN_PROGRESS = 1
  INACTIVE = 2
  ACQUIRED = 3
}

let unlockToShow = Computed(@() progressCounters.get().isCompleted
  ? combinedUnlocks.get()
  : combinedUnlocks.get().slice(0, progressCounters.get().total))

let getOneRewardByStageData = @(stageData, itemsMappingVal)
  getOneReward(stageData?.rewards ?? stageData?.currencyRewards ?? {}, itemsMappingVal)

let combinedRewards = Computed(function(){
  let { current, required, interval } = currentProgress.get()
  let mappedItems = itemsMapping.get()
  let currentStage = progressCounters.get().current
  let { isLoop, total } = progressCounters.get()
  let basicRewarded = basicProgress.get().lastRewardedStage
  let premiumRewarded = premiumProgress.get().lastRewardedStage

  let nextRewardStageV = nextRewardStage.get()
  let noEliteBattlePass = !hasEliteBattlePass.get()
  return unlockToShow.get().map(function(stageData, stageIdx) {
    let { stage, isPremium = false } = stageData
    let { reward = null, count = 0 } = getOneRewardByStageData(stageData, mappedItems)
    let isReceived = (isPremium ? premiumRewarded : basicRewarded) > stage
    local progressVal = null
    local progressState = null
    let currentStageCompleted = isLoop ? currentStage : nextRewardStageV ?? currentStage
    if (stageIdx < currentStageCompleted)
      progressState = isPremium && noEliteBattlePass
        ? RewardState.INACTIVE
        : RewardState.COMPLETED
    else if (stageIdx < currentStage)
      progressState = isPremium && noEliteBattlePass
        ? RewardState.INACTIVE
        : RewardState.ACQUIRED
    else {
      progressVal = stageIdx == currentStage && interval != 0
        ? (current - required + interval).tofloat() / interval
        : 0
      progressState = RewardState.IN_PROGRESS
    }
    let isLooped = stage >= total
    return { reward, count, stageIdx, isPremium, isReceived,
      progressState, progressVal, isLooped }
  })
})


function curItemUpdate(rewardIdx = null){
  rewardIdx = rewardIdx ?? nextRewardStage.get() ?? nextStage.get()
  curItem.set({
    reward = getOneRewardByStageData(combinedUnlocks.get()?[rewardIdx], itemsMapping.get())?.reward
    stageIdx = rewardIdx
  })
}

function openBPwindow(rewardIdx = null){
  if (isSeasonEnds.get())
    return showMsgbox(loc("bp/seasonEndsText"))

  curItemUpdate(rewardIdx)
  isOpened.set(true)
  isVisible.set(true)
}

return {
  RewardState
  unlockToShow
  combinedRewards
  isOpened
  isVisible
  openBPwindow
  curItem
  curItemUpdate
}