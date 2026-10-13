from "%sqstd/timers.nut" import debounce
from "%ui/unlocks/taskRewardsState.nut" import seasonEndTime, basicUnlockId, basicUnlock, basicProgress, premiumUnlockId, premiumUnlock, premiumProgress
  , unlockPrices, purchaseInProgress, doReceiveRewards, doBuyUnlock, nextBasicStage, nextPremiumStage
  , seasonIndex, premiumStage0Unlock
from "%ui/battlepass/eliteBattlePass.nut" import hasEliteBattlePass, premRewardsAllowed
from "%ui/userstats/userstat.nut" import receiveUnlockRewardsAllUp, unlockRewardsInProgress
from "%ui/ui_library.nut" import *

const BP_PREMIUM_STAT = "battle_pass_stage"

let combinedUnlocks = Computed(function() {
  let basicRewards = basicUnlock.get()?.stages ?? []
  let premRewards = premiumUnlock.get()?.stages ?? []
  local premIdx = 0
  local premProgress = 0
  let res = []
  foreach (basicStage, basic in basicRewards) {
    foreach (stat in basic?.updStats ?? []){
      premProgress += stat?.name == BP_PREMIUM_STAT ? (stat?.value ?? 0).tointeger() : 0
    }
    res.append(basic.__merge({
      stage = basicStage
    }))
    for (local premStage = premIdx; premStage < premRewards.len(); ++premStage) {
      let premium = premRewards[premStage]
      if (premium.progress > premProgress)
        break
      res.append(premium.__merge({
        stage = premStage
        isPremium = true
      }))
      ++premIdx
    }
  }
  return res
    .map(function(r) {
      let rewards = r?.rewards ?? {}
      if ("currencyRewards" in r) {
        rewards.__update(r.currencyRewards)
        r.$rawdelete("currencyRewards")
      }
      if (rewards.len() > 0)
        r.rewards <- rewards.map(@(val) val.tointeger())
      return r
    })
    .filter(@(r) r?.rewards != null)
})

let combinedUnlocksGrid = Computed(function() {
  local lastIdx = 0
  local lastProgress = 0
  local stepProgress = 0
  let res = array(combinedUnlocks.get().len())
  foreach (idx, unlock in combinedUnlocks.get())
    if (!(unlock?.isPremium ?? false)) {
      let { progress } = unlock
      if (idx == lastIdx) {
        res[idx] = progress
      } else {
        stepProgress = (progress - lastProgress).tofloat() / (idx - lastIdx)
        for (local i = lastIdx; i <= idx; ++i)
          res[i] = (lastProgress + (i - lastIdx) * stepProgress + 0.5).tointeger()
      }
      lastIdx = idx
      lastProgress = progress
    }
  for (; lastIdx < res.len(); ++lastIdx) {
    res[lastIdx] = lastProgress.tointeger()
    lastProgress += stepProgress
  }
  return res
})

let clampStage = @(stage, total, full) stage < full ? stage
  : full > total ? total + (stage - total) % (full - total)
  : full - 1

function countRewards(rewards, from = 0, to = null) {
  local count = 0
  let last = to ?? rewards.len()
  for (local i = from; i < last; ++i) {
    let item = rewards[i]
    if (item?.rewards || item?.currencyRewards)
      ++count
  }
  return count
}

function getRewardsCount(rewards, startIdx, lastIdx, loop, full) {
  let rewardsLen = rewards.len()
  let rewardsLoop = rewards.slice(rewardsLen - loop, rewardsLen)
  let rewardsCountInLoop = countRewards(rewardsLoop)

  let countRewardsInLoop = max(0, lastIdx - rewardsLen)
  local countLoop = countRewardsInLoop / loop
  local countLastLoop = countRewardsInLoop % loop

  if (startIdx > full) {
    let countAll = lastIdx - startIdx
    countLoop = countAll / loop
    countLastLoop = countAll % loop
  }

  let rewardsCountLastLoop = countRewards(rewardsLoop, 0, countLastLoop)
  let rewardsCount = countRewards(rewards, startIdx, countRewardsInLoop > 0 ? full : lastIdx)
  let rewardsCountLoop = rewardsCountInLoop * countLoop

  return rewardsCount + rewardsCountLoop + rewardsCountLastLoop
}

let progressCounters = Computed(function() {
  let fullUnlocks = combinedUnlocks.get()
  let full = fullUnlocks.len()
  let { startStageLoop = 0, periodic = false } = basicUnlock.get()
  let loopIndex = startStageLoop - 1
  let loop = max(1, full - loopIndex)
  let total = periodic ? loopIndex : full

  let { current, lastRewardedStage } = basicProgress.get()
  let interval = (combinedUnlocksGrid.get()?[1] ?? 1) - (combinedUnlocksGrid.get()?[0] ?? 1)
  let stageCurrent = current / (interval > 0 ? interval : 3)

  let rewarded = max(lastRewardedStage, premiumProgress.get().lastRewardedStage)
  let isLoop = rewarded > total || stageCurrent > full

  let basicRewards = basicUnlock.get()?.stages ?? []
  let premRewards = premiumUnlock.get()?.stages ?? []

  let allowedFreeRewarded = getRewardsCount(
    basicRewards,
    0,
    lastRewardedStage,
    loop,
    full)
  local allowedPremRewarded = getRewardsCount(
    premRewards,
    premiumProgress.get().lastRewardedStage,
    stageCurrent,
    loop,
    full)
  let allowedBasic = getRewardsCount(
    basicRewards,
    lastRewardedStage,
    stageCurrent,
    loop,
    full)

  let hasReward0Unlock = premiumStage0Unlock.get()?.hasReward ?? false

  let rewards0Unlock = !hasReward0Unlock ? 0
    : (premiumStage0Unlock.get()?.stages[0].rewards.len() ?? 0)

  allowedPremRewarded += rewards0Unlock
  let allowedReward = hasEliteBattlePass.get() ? allowedBasic + allowedPremRewarded : allowedBasic

  let stageCurrentInLoop = (stageCurrent - total) % loop + total
  let stageByProgress = combinedUnlocksGrid.get().findindex(@(p) p > current) ?? stageCurrentInLoop
  let stageRewardedInLoop = (rewarded - total) % loop + total

  return {
    rewarded = isLoop ? stageRewardedInLoop : rewarded
    current = isLoop ? stageCurrentInLoop : stageByProgress
    isLoop
    total
    full
    loop
    reward = allowedReward
    allowedFreeRewarded
    allowedPremRewarded
    isCompleted = stageByProgress >= total
  }
})

let currentProgress = Computed(function() {
  let { total, full } = progressCounters.get()
  local { current, required, stage } = basicProgress.get()
  stage = clampStage(stage, total, full)
  let interval = (combinedUnlocksGrid.get()?[stage] ?? 0)
    - (combinedUnlocksGrid.get()?[stage - 1] ?? 0)
  return {
    current = clampStage(current, required - interval, required)
    required
    interval
  }
})

function isWorthlessReward(stage) {
  let { rewards = {}, currencyRewards = {} } = stage
  return rewards.len() == 0 && currencyRewards.len() == 0
}

let hasReward = Computed(@() basicProgress.get().hasReward
  || (hasEliteBattlePass.get() && premiumProgress.get().hasReward))

let findStageIdx = @(stages, stageIdx, isPremium)
  stages.findindex(@(s) s.stage >= stageIdx && (s?.isPremium ?? false) == isPremium) 

let nextRewardInfo = Computed(function() {
  let stages = combinedUnlocks.get()
  local unlockId = null
  local stageIdx = null
  local isReadyToReceive = true
  let { total, full } = progressCounters.get()
  if (basicProgress.get().hasReward && (!premiumProgress.get().hasReward || !premRewardsAllowed.get())) {
    unlockId = basicUnlockId.get()
    stageIdx = findStageIdx(stages, clampStage(basicProgress.get().lastRewardedStage, total, full), false)
  } else if (premiumProgress.get().hasReward && hasEliteBattlePass.get()) {
    unlockId = premiumUnlockId.get()
    stageIdx = findStageIdx(stages, clampStage(premiumProgress.get().lastRewardedStage, total, full), true)
    isReadyToReceive = premRewardsAllowed.get()
  }
  return { unlockId, stageIdx, isReadyToReceive }
})

let nextRewardStage = Computed(@() nextRewardInfo.get().stageIdx)
let nextStage = Computed(function() {
  let { rewarded, total, full } = progressCounters.get()
  let res = clampStage(rewarded, total, full)
  return max(res, nextRewardStage.get() ?? res) 
})

let nextUnlock = Computed(@() combinedUnlocks.get()?[nextStage.get()])

let nextUnlockPrice = Computed(@() (basicProgress.get().hasReward
  || basicProgress.get().isFinished
  || !hasEliteBattlePass.get())
    ? null
    : unlockPrices.get()?[basicUnlockId.get()])

let receiveRewardInProgress = Computed(@() basicUnlockId.get() in unlockRewardsInProgress.get()
  || premiumUnlockId.get() in unlockRewardsInProgress.get())

let buyUnlockInProgress = Computed(@() basicUnlockId.get() in purchaseInProgress.get())

function receiveAllRewards() {
  let unlocksToRewards = []
  if (basicProgress.get().hasReward)
    unlocksToRewards.append({ name = basicUnlockId.get() })
  if (hasEliteBattlePass.get())
    unlocksToRewards.append({ name = premiumUnlockId.get() })

  if (unlocksToRewards.len() > 0)
    receiveUnlockRewardsAllUp(unlocksToRewards)
}

function buyNextStage() {
  if (nextUnlockPrice.get())
    doBuyUnlock(basicUnlockId.get())
}

let curWorthlessRewardId = keepref(Computed(@() !hasReward.get() || receiveRewardInProgress.get() ? null
  : isWorthlessReward(nextPremiumStage.get()) && hasEliteBattlePass.get() ? premiumUnlockId.get()
  : isWorthlessReward(nextBasicStage.get()) ? basicUnlockId.get()
  : null))

let tryReceiveReward = debounce(@(id) doReceiveRewards(id), 0.01)
curWorthlessRewardId.subscribe(tryReceiveReward)

return {
  seasonEndTime
  basicProgress
  premiumProgress
  combinedUnlocks
  progressCounters
  currentProgress
  nextStage
  nextRewardStage
  nextUnlock
  hasReward
  nextUnlockPrice
  receiveRewardInProgress
  buyUnlockInProgress
  receiveAllRewards
  buyNextStage
  seasonIndex
}
