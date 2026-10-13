import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, titleTxtColor, defTxtColor, defItemBlur, transpPanelBgColor, darkTxtColor, hoverSlotBgColor
  , midPadding, bigPadding, panelBgColor
from "%ui/components/tasksPkg.nut" import taskDescription, taskHeader, taskMinHeight, taskSlotPadding, mkTaskEmblem, completedUnlockIcon, getTaskEmblemImg
  , mkEmblemImgReward, mkTaskTextArea
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/battlepass/rewardsPkg.nut" import getOneReward, mkRewardIcon, prepareRewards, rewardIconWidth
from "%ui/userstats/unlocksState.nut" import getUnlockProgress, unlockProgress
from "%ui/components/textButton.nut" import soundDefault
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/unlocks/taskListState.nut" import receiveTaskRewards
from "%ui/components/unlocksText.nut" import getDescription
from "%ui/battlepass/battlepass_presentation.nut" import getBpPresentation
from "%ui/userstats/userstat.nut" import userstatTables
from "%ui/offers/offersPkg.nut" import getTableTimestamp
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/ui_library.nut" import *


const starSizeReward = hdpxi(17)
const minHeight = hdpx(60)
let mkHideTrigger = @(task) $"hide_task_{task.name}"

let mkSeasonTaskContent = @(
  unlockDesc, canTakeReward, hasWaitIcon, canReroll, textHeight, group, sf = 0
) function() {
  let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
  let color = getBpPresentation(seasonIndex.get()).taskColor
  return {
    watch = [unlockProgress, seasonIndex]
    size = [FLEX, textHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    group
    children = [
      mkTaskEmblem(unlockDesc, progress, canTakeReward, hasWaitIcon, canReroll, sf, color)
      taskHeader(unlockDesc, progress, canTakeReward, sf, {
        size = [FLEX, textHeight]
        color = sf & S_HOVER ? darkTxtColor : defTxtColor
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        orientation = O_VERTICAL
        scrollOnHover = true
        group
      }.__update(fontSub))
    ]
  }
}

let rewardBlinkStar = {
  size = [rewardIconWidth, rewardIconWidth]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = [4 * rewardIconWidth, 2 * rewardIconWidth]
    image = Picture("ui/gameImage/searchlight_earth_flare.avif")
  }
  animations = [
    { prop = AnimProp.opacity, from = 0.1, to = 1, duration = 1.5, play = true, loop = true, easing = Blink }
  ]
}


let selectedRewardLine = freeze({
  size = const [pw(90), hdpx(2)]
  pos = const [0, hdpx(4)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = hoverSlotBgColor
})

function mkRewardBlock(rewardData, isFinished = false, hasReward = false, selectedIcon = null) {
  let { reward = null, count = 1 } = rewardData
  let { icon = null } = reward
  let isSelected = selectedIcon != null && icon == selectedIcon
  return {
    halign = ALIGN_RIGHT
    children = [
      hasReward ? rewardBlinkStar : null
      mkRewardIcon(reward, rewardIconWidth, isFinished ? { opacity = 0.5 } : {})
      count == 1 ? null
        : {
            rendObj = ROBJ_TEXT
            text = loc("common/amountShort", { count })
            margin = [0, midPadding]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            fontFx = FFT_GLOW
            fontFxColor = 0xFF000000
            fontFxFactor = hdpx(32)
            color = titleTxtColor
          }.__update(fontSub)
      isSelected ? selectedRewardLine : null
    ]
  }
}


function mkAllRewardsIcons(stageData, itemsMappingVal, isFinished, selectedIcon = null) {
  let rewardsByIcon = {}
  foreach (rewardData in prepareRewards(stageData, itemsMappingVal)) {
    let key = rewardData.reward?.icon ?? "noIcon"
    if (key not in rewardsByIcon)
      rewardsByIcon[key] <- clone rewardData
    else
      rewardsByIcon[key].count += rewardData.count
  }
  return rewardsByIcon.values()
    .sort(@(a, b) b.count <=> a.count)
    .map(@(r) mkRewardBlock(r, isFinished, false, selectedIcon))
}


function mkTaskRewards(
  unlockDesc, itemsMappingVal, isAllRewardsVisible = false, rewardsAnim = null, hasBlink = false
) {
  local children
  let { personalData = {} } = unlockDesc
  let { rewards = null, boosterRewards = null } = personalData
  let { items = {} } = boosterRewards
  if (rewards != null)
    children = rewards.map(@(reward)
      mkRewardBlock(getOneReward(reward?.items ?? {}, itemsMappingVal), false, hasBlink))
  else if (items.len() > 0)
    children = mkRewardBlock(getOneReward(items, itemsMappingVal), false, hasBlink)
  else {
    let {
      stage, lastRewardedStage, isFinished, hasReward, stages = []
    } = unlockDesc
    let actualStage = isFinished ? stages.len() - 1
      : hasReward ? lastRewardedStage
      : stage
    let stageData = stages?[actualStage].rewards
    if (stageData != null)
      children = isAllRewardsVisible
        ? mkAllRewardsIcons(stageData, itemsMappingVal, isFinished)
        : mkRewardBlock(getOneReward(stageData, itemsMappingVal), isFinished, hasBlink)
  }
  return children == null ? null : {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children
  }.__update(rewardsAnim == null ? {}
    : {
        transform = true
        animations = rewardsAnim
      })
}


let animatedTasks = {}
function needShowAnim(task) {
  if (task.name in animatedTasks)
    return false

  animatedTasks[task.name] <- true
  return true
}

let mkTimer = @(task) function() {
  let watch = userstatTables
  let uTables = userstatTables.get()?.tables ?? {}
  let { table = "", activity = null } = task
  let { end_timestamp = 0 } = activity
  let time = getTableTimestamp(table, uTables) ?? end_timestamp

  if (time <= 0)
    return { watch }

  let timeLeft = Computed(@() secondsToHoursLoc(max(0, time - serverTime.get())))
  return {
    watch
    children = @() {
      rendObj = ROBJ_TEXT
      watch = timeLeft
      margin = bigPadding
      text = loc("offers/timeLeft", { time = timeLeft.get() })
    }.__update(fontSub)
  }
}

let mkUnlockSlot = kwarg(function(
  task, onClick = null, onHover = null, hasWaitIcon = Watched(false), rerolls = 0,
  isAllRewardsVisible = false, rightObject = null,
  hasDescription = false, bottomBtn = null, hasShowAnim = false,
  customDescription = null, canTakeReward = true, rewardsAnim = null,
  isHeightFixed = false, hasTimer = false
) {
  let slotHeight = isHeightFixed ? minHeight : SIZE_TO_CONTENT
  let textHeight = isHeightFixed ? minHeight - 2 * smallPadding : SIZE_TO_CONTENT
  let group = ElemGroup()

  return watchElemState(@(sf) {
    key = task.name
    rendObj = ROBJ_WORLD_BLUR
    watch = itemsMapping
    size = [FLEX, slotHeight]
    fillColor = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
    color = defItemBlur
    minHeight = taskMinHeight
    behavior = onClick == null ? null : Behaviors.Button
    sound = soundDefault
    onClick
    onHover
    group
    transform = true
    animations = (hasShowAnim && needShowAnim(task) 
      ? [{ prop = AnimProp.translate, from = [hdpx(248), 0], to = [0,0],
          duration = 0.25, play = true }]
      : []).append(
            { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.35,
              trigger = mkHideTrigger(task) },
            { prop = AnimProp.opacity, from = 0, to = 0, duration = 3,
              delay = 0.3, trigger = mkHideTrigger(task) })
    children = [
      {
        size = [FLEX, slotHeight]
        flow = FLOW_VERTICAL
        group
        children = [
          {
            size = FLEX_H
            minHeight = taskMinHeight
            flow = FLOW_HORIZONTAL
            padding = taskSlotPadding
            gap = smallPadding
            valign = ALIGN_CENTER
            group
            children = [
              mkSeasonTaskContent(task, canTakeReward, hasWaitIcon, rerolls > 0, textHeight, group, sf)
              mkTaskRewards(task, itemsMapping.get(), isAllRewardsVisible, rewardsAnim)
            ]
          }
          hasDescription
            ? taskDescription(task.localization.description, sf, {
                margin = bigPadding
                size = [pw(95), slotHeight]
                behavior = [Behaviors.TextArea, Behaviors.Marquee]
                orientation = O_VERTICAL
                scrollOnHover = true
              })
            : null
          customDescription
          bottomBtn
          hasTimer ? mkTimer(task) : null
        ]
      }
      rightObject
    ]
  })
})

let mkTaskContentReward = @(unlockDesc, sf = 0)
  function() {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
    let { taskColor } = getBpPresentation(seasonIndex.get())
    let emblemImg = getTaskEmblemImg(unlockDesc, true)
    let iconReward = sf & S_HOVER ? completedUnlockIcon
      : mkEmblemImgReward(emblemImg, starSizeReward, taskColor)

    return {
      watch = [unlockProgress, seasonIndex, itemsMapping]
      size = FLEX_H
      minHeight
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          children = [
            {
              size = FLEX_H
              flow = FLOW_VERTICAL
              gap = smallPadding
              children = [
                {
                  size = FLEX_H
                  flow = FLOW_HORIZONTAL
                  gap = smallPadding
                  valign = ALIGN_CENTER
                  children = [
                    {
                      rendObj = ROBJ_TEXT
                      halign = ALIGN_CENTER
                      color = sf & S_HOVER ? darkTxtColor : titleTxtColor
                      text = loc("completeTaskTitle")
                    }.__update(fontSub)
                    iconReward
                  ]
                }
                mkTaskTextArea(getDescription(unlockDesc, progress, unlockDesc?.locParams ?? {}), sf, {size = const [pw(100), SIZE_TO_CONTENT]})
              ]
            }
            mkTaskRewards(unlockDesc, itemsMapping.get(), false, null, true)
          ]
        }
        {
          rendObj = ROBJ_TEXT
          size = FLEX_H
          halign = ALIGN_RIGHT
          color = taskColor
          text = loc("completeTaskReward")
        }.__update(fontSub)
      ]
    }
  }


let mkUnlockSlotReward = @(task, onClick = null)
  watchElemState(@(sf) {
    key = task.name
    rendObj = ROBJ_SOLID
    size = FLEX_H
    color = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    padding = midPadding
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    sound = soundDefault
    onClick = onClick ?? function() {
      sound_play("ui/reward_receive")
      receiveTaskRewards(task)
    }
    children = mkTaskContentReward(task, sf)
  })

return {
  mkUnlockSlot
  mkUnlockSlotReward
  mkTaskRewards
  mkHideTrigger
  mkAllRewardsIcons
}
