import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/eventPass/eventPassState.nut" import basicProgress, premiumProgress, combinedUnlocks, nextStage, nextRewardStage, progressCounters, currentProgress
from "%ui/eventPass/eliteEventPass.nut" import hasEliteEventPass
from "%ui/battlepass/rewardsPkg.nut" import getOneReward
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/eventPass/eventTaskRewardsState.nut" import purchaseStageProgress
from "%ui/ui_library.nut" import *

let curRewardItem = mkWatched(persist, "curRewardItem", null)
let isPassWindowOpened = mkWatched(persist, "isPassWindowOpened", false)
let isPassWindowVisible = Watched(false)

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

function getMarathonStageProgress(unlockProgress) {
  let { lastRewardedStage = 0, stages = [], periodic = false,
    hasReward = false, current = 0, required = 1 } = unlockProgress
  let passedProgress = lastRewardedStage <= 0 ? 0
    : stages?[lastRewardedStage - 1].progress ?? 0
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  return hasReward ? 1
    : !periodic && curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
    : 0
}

let combinedRewards = Computed(function(){
  let { current, required, interval } = currentProgress.get()
  let mappedItems = itemsMapping.get()
  let currentStage = progressCounters.get().current
  let { isLoop, total } = progressCounters.get()
  let basicRewarded = basicProgress.get().lastRewardedStage
  let premiumRewarded = premiumProgress.get().lastRewardedStage
  let currentStageCompleted = isLoop ? currentStage : nextRewardStage.get() ?? currentStage
  let { isMarathonEvent = false } = bpEventSettings.get()
  let purchaseStageProgressVal = purchaseStageProgress.get()
  let hasElitePass = hasEliteEventPass.get()

  return unlockToShow.get().map(function(stageData, stageIdx) {
    let { stage, isPremium = false } = stageData
    let { reward = null, count = 0 } = getOneRewardByStageData(stageData, mappedItems)
    let isReceived = (isPremium ? premiumRewarded : basicRewarded) > stage
    local progressVal = null
    local progressState = null
    if (stageIdx < currentStageCompleted)
      progressState = isPremium && !hasElitePass
        ? RewardState.INACTIVE
        : RewardState.COMPLETED
    else if (stageIdx < currentStage)
      progressState = isPremium && !hasElitePass
        ? RewardState.INACTIVE
        : RewardState.ACQUIRED
    else {
      progressVal = stageIdx == currentStage && interval != 0
        ? isMarathonEvent ? getMarathonStageProgress(purchaseStageProgressVal)
        : (current - required + interval).tofloat() / interval
        : 0
      progressState = RewardState.IN_PROGRESS
    }
    let isLooped = stage >= total
    return { reward, count, stageIdx, isPremium, isReceived,
      progressState, progressVal, isLooped }
  })
})


function getRewardIdx(rewardTemplate = "") {
  local rewardIdx = null
  local state = null
  foreach (idx, r in combinedRewards.get()) {
    if (r.reward?.itemTemplate == rewardTemplate || r.reward?.crateId == rewardTemplate) {
      if (r.progressState == RewardState.COMPLETED)
        return idx
      if ((r.progressState == RewardState.IN_PROGRESS && state != RewardState.IN_PROGRESS)
          || (r.progressState == RewardState.INACTIVE && state == null)) {
        state = r.progressState
        rewardIdx = idx
      }
    }
  }
  return rewardIdx
}

function curItemUpdate(rewardIdx = null) {
  rewardIdx = rewardIdx ?? nextRewardStage.get() ?? nextStage.get()
  curRewardItem.set({
    reward = getOneRewardByStageData(combinedUnlocks.get()?[rewardIdx], itemsMapping.get())?.reward
    stageIdx = rewardIdx
  })
}

function openEventPassWindow(rewardIdx = null) {
  curItemUpdate(rewardIdx)
  isPassWindowOpened.set(true)
  isPassWindowVisible.set(true)
}

return {
  unlockToShow
  combinedRewards
  isPassWindowOpened
  isPassWindowVisible
  getRewardIdx
  openEventPassWindow
  curRewardItem
  curItemUpdate
}