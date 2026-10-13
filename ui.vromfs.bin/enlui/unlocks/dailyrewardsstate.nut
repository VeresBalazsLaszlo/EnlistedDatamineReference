from "%ui/userstats/userstat.nut" import unlockRewardsInProgress, markUserLogsAsSeen
from "%ui/unlocks/taskRewardsState.nut" import doReceiveRewards
from "%ui/soldiers/model/newItemsToShow.nut" import unseenReward
from "%ui/shop/dropRouletteState.nut" import dropRoulette
from "%ui/unlocks/unlocks_utils.nut" import getStageByIndex
from "%ui/userstats/unlocksState.nut" import activeUnlocks, unlockProgress, emptyProgress, unlockLogs
from "%ui/unlocks/taskListState.nut" import dailyTasks
from "%ui/soldiers/model/cratesContent.nut" import getLoadedCrateContent, unpackCrate, crateContentWatch
from "%ui/ui_library.nut" import *
from "%ui/soldiers/model/boosters.nut" import recalcActiveBosters
from "%ui/meta/profile.nut" import commonArmy


const DAILY_AWARD_UNLOCK_ID = "every_day_award"

let specialUnlocks = [
  "every_day_award_100_days_in_row", "every_day_award_365_days_in_row",
  "every_day_award_730_days_in_row", "every_day_award_1095_days_in_row",
  "every_day_award_1460_days_in_row"
]

let isReceiveDayRewardInProgress = Computed(@()
  unlockRewardsInProgress.get()?[DAILY_AWARD_UNLOCK_ID] ?? false)

let specialUnlock = Computed(function() {
  let up = unlockProgress.get()
  return specialUnlocks.findvalue(@(u)
    (up?[u].isCompleted ?? false) && !(up?[u].isFinished ?? true))
})

let specialUnlockToReceive = Watched(null)

let dailyRewardsUnlock = Computed(@() activeUnlocks.get()?[DAILY_AWARD_UNLOCK_ID]
  .__merge(unlockProgress.get()?[DAILY_AWARD_UNLOCK_ID] ?? emptyProgress))

let needOpenDailyRewards = Watched(false)
dailyRewardsUnlock.subscribe(function(v) {
  if (v?.hasReward ?? false)
    needOpenDailyRewards.set(true)
})

function calcRewardCfg(stageData, rewardsItems, cratesContentValue) {
  let rewardsData = []
  let rewardCrate = Watched(null)
  foreach (rewardId, _ in stageData?.rewards ?? {}) {
    let rewardCfg = rewardsItems?[rewardId.tostring()]
    if (rewardCfg == null)
      continue

    rewardsData.append(rewardCfg)
    local { armyId = commonArmy.get(), crateId = "" } = rewardCfg
    if (crateId != "")
      rewardCrate.set({
        armyId
        id = crateId
        content = getLoadedCrateContent(crateId, cratesContentValue)
      })
  }
  return {
    rewardsData
    rewardCrate
  }
}

function crateReward(rewards, receivedItems, mappedItems, cratesContentValue) {
  let crates = []
  foreach (rewardId, count in rewards) {
    if (count <= 0)
      continue

    let { crateId = "" } = mappedItems?[rewardId]
    if (crateId != "")
      crates.append(crateId)
  }

  let cratesContent = []
  foreach (crateId in crates) {
    let { items = [] } = getLoadedCrateContent(crateId, cratesContentValue)
    foreach (itemTemplate, count in items)
      cratesContent.append({ count, itemTemplate })
  }

  let crateItemsData = []
  foreach (receivedItem in receivedItems) {
    let { basetpl = null, count = 1 } = receivedItem
    if (basetpl == null)
      continue

    let crateContent = cratesContent.findvalue(@(v)
      v.itemTemplate == basetpl && v.count <= count)
    if (crateContent != null)
      crateItemsData.append({
        count = crateContent.count
        itemTemplate = basetpl
      })
  }

  if (crateItemsData.len() == 0)
    return null

  return {
    cratesContent
    crateItemsData
  }
}

let boosterLogs = Computed(@() (unlockLogs.get() ?? [])
  .filter(@(blog) blog.type == "ADD_BOOSTER"))

let curBoosteredDailyTask = Computed(function() {
  let tasks = dailyTasks.get() ?? []
  let logs = boosterLogs.get().filter(@(blog)
    tasks.findvalue(@(u) u.name == blog.unlock) != null)

  if (logs.len() == 0)
    return null

  let boosterLog = logs.top()
  return tasks.findvalue(@(u) u.name == boosterLog.unlock) 
    .__merge({ boosterLog })
})

function markBoosterLogsSeen() {
  let userlogs = boosterLogs.get().map(@(b) b.id)
  if (userlogs.len() > 0)
    markUserLogsAsSeen(userlogs)
}

function receiveDayReward(receivedData) {
  if (isReceiveDayRewardInProgress.get())
    return
  doReceiveRewards(DAILY_AWARD_UNLOCK_ID)

  if (receivedData?.boosteredTask != null)
    markBoosterLogsSeen()
}

function gotoNextStageOrClose(receivedData, hasReward) {
  let { boosteredTask = null, crate = null } = receivedData
  if (hasReward)
    receiveDayReward(receivedData)
  else if (boosteredTask != null)
    markBoosterLogsSeen()

  if (crate != null) {
    recalcActiveBosters()
    let items = unseenReward.get()
    if (items.len() > 0)
      dropRoulette.set({
        crate
        items
        hasChestPreview = true
        possibleDrop = unpackCrate(crate, crateContentWatch.get(), items)
      })
  }

  if (specialUnlock.get() != null) {
    specialUnlockToReceive.set(specialUnlock.get())
    doReceiveRewards(specialUnlock.get())
  }

  needOpenDailyRewards.set(false)
}

function itemsReward(itemsForMapping, receivedItems, mappedItems) {
  let cratesContent = []
  let crateItemsData = []
  let res = { cratesContent, crateItemsData }

  foreach (rewardList in itemsForMapping)
    foreach (reward in rewardList)
      foreach (mappedItem, count in reward.items) {
        let presentation = mappedItems?[mappedItem]
        if (presentation == null)
          continue

        let { itemTemplate = null, boosterId = null } = presentation
        cratesContent.append({ itemTemplate = boosterId ?? itemTemplate, count })
      }

  foreach (receivedItem in receivedItems) {
    let { basetpl = null, sClass = null, count = 1 } = receivedItem
    if (basetpl == null)
      continue

    let item = { count, itemTemplate = basetpl }
    if (sClass != null)
      item.sClass <- sClass
    crateItemsData.append(item)
  }

  return res
}

function taskReward(boosteredTask, rewardsBoosters, mappedItems) {
  let receivedBoosters = []
  foreach (item, count in boosteredTask?.boosterLog.reward.items ?? {}) {
    let basetpl = mappedItems?[item].itemTemplate
    if (basetpl != null)
      receivedBoosters.append({ basetpl, count })
  }
  return receivedBoosters.len() == 0 ? null
    : itemsReward(rewardsBoosters, receivedBoosters, mappedItems)
        .__update({ boosteredTask })
}

function detectSameReward(rewardsBoosters, rewards, allCrates) {
  local found = ""
  foreach (boosters in rewardsBoosters)
    foreach (booster in boosters)
      foreach (itemTemplate, _ in booster.items)
        if (itemTemplate in allCrates && (found == "" || found == itemTemplate))
          found = itemTemplate
        else
          return ""

  foreach (itemTemplate, _ in rewards) 
    if (itemTemplate in allCrates && (found == "" || found == itemTemplate))
      found = itemTemplate
    else
      return ""

  return found
}

function sameCrateReward(stageData, totalItems, crateId) {
  let { rewardsBoosters = {}, rewards = {} } = stageData
  let cratesContent = []

  foreach (boosters in rewardsBoosters)
    foreach (booster in boosters)
      foreach (itemTemplate, count in booster.items)
        if (crateId == itemTemplate)
          cratesContent.append({ itemTemplate, count })

  foreach (itemTemplate, count in rewards)
    if (crateId == itemTemplate)
      cratesContent.append({ itemTemplate, count })

  return {
    cratesContent
    crateItemsData = [{ count = totalItems, itemTemplate = crateId }]
    crate = crateId
  }
}

function getReceivedItems(unlock, boosteredTask, receivedItems, mappedItems, cratesContent) {
  let { lastRewardedStage = 0, stages = [] } = unlock
  if (stages.len() == 0)
    return null

  let stageData = getStageByIndex(unlock, lastRewardedStage - 1)
  let { rewardsBoosters = {}, rewards = {} } = stageData

  if (boosteredTask != null)
    return taskReward(boosteredTask, rewardsBoosters, mappedItems)

  let numItems = receivedItems.len()
  if (numItems == 0)
    return null

  if (rewardsBoosters.len() == 0)
    return crateReward(rewards, receivedItems, mappedItems, cratesContent)

  let sameCrate = detectSameReward(rewardsBoosters, rewards, cratesContent)
  if (sameCrate != "")
    return sameCrateReward(stageData, numItems, sameCrate)

  return itemsReward(rewardsBoosters, receivedItems, mappedItems)
}

return {
  needOpenDailyRewards
  dailyRewardsUnlock
  calcRewardCfg
  getReceivedItems
  receiveDayReward
  gotoNextStageOrClose
  curBoosteredDailyTask
  isReceiveDayRewardInProgress
  specialUnlock
  specialUnlockToReceive
}
