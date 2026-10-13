import "%ui/userstats/serverTime.nut" as serverTime
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/unlocks/taskListState.nut" import receiveTaskRewards
from "%ui/unlocks/weeklyUnlocksState.nut" import weeklyTasks, saveFinishedWeeklyTasks, triggerBPStarsAnim
from "%ui/unlocks/unseenUnlocksState.nut" import seenUnlocks, markUnlockSeen, markUnlocksOpened
from "%ui/userstats/unlocksState.nut" import getUnlockProgress, unlockProgress
from "%ui/userstats/userstat.nut" import unlockRewardsInProgress
from "%ui/style/designConst.nut" import smallPadding, defTxtColor, bigPadding, activeTxtColor, taskProgressColor, midPadding, rowBg
from "%ui/components/tasksPkg.nut" import mkTaskEmblem, taskHeader, taskDescription, mkGetTaskRewardBtn, statusBlock, completedSign
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/battlepass/battlepass_presentation.nut" import getBpPresentation
from "%ui/ui_library.nut" import *

const taskSlotHeight = hdpxi(100)
const emblemSize = hdpxi(50)


const timerSize = hdpxi(18)
let timerIcon = {
  rendObj = ROBJ_IMAGE
  size = const [timerSize, timerSize]
  image = Picture($"ui/skin#battlepass/boost_time.svg:{timerSize}:{timerSize}")
  color = taskProgressColor
}

function mkTaskExpireTimer(expireTime) {
  let expireText = Computed(function() {
    let expireSec = expireTime - serverTime.get()
    return expireSec <= 0 ? "" : secondsToStringLoc(expireSec)
  })
  return @() {
    watch = expireText
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    children = expireText.get() == "" ? null
      : [
          {
            rendObj = ROBJ_TEXT
            text = loc("unlock/expireHeader")
            color = activeTxtColor
          }.__update(fontSub)
          {
            flow = FLOW_HORIZONTAL
            gap = midPadding
            valign = ALIGN_CENTER
            children = [
              timerIcon
              {
                rendObj = ROBJ_TEXT
                text = expireText.get()
                color = taskProgressColor
              }.__update(fontSub)
            ]
          }
        ]
  }
}

function mkWeeklyTaskSlot(task, idx, isUnseen, isRewardSingle) {
  let { name, isCompleted = false, isFinished = false, hasReward = false, activity = null } = task
  let { end_timestamp = 0, active = false } = activity
  let hasExpireTimer = active && !isFinished
  let timeLeft = isCompleted ? completedSign
    : hasReward ? mkGetTaskRewardBtn(task, receiveTaskRewards, unlockRewardsInProgress
        isRewardSingle ? { hotkeys = [["^J:X | Enter | Space", { skip = true }]] } : {})
    : !active ? {
        rendObj = ROBJ_TEXT
        text = loc("notActive")
        color = defTxtColor
        padding = midPadding
      }.__update(fontBody)
    : hasExpireTimer ? mkTaskExpireTimer(end_timestamp)
    : null

  let bgColor = rowBg(0, idx)
  function onHover(on) {
    if (isUnseen)
      hoverHoldAction("markUnlockSeen", name, markUnlockSeen)(on)
  }
  return function() {
    let seasonColor = getBpPresentation(seasonIndex.get()).taskColor
    let progress = getUnlockProgress(task, unlockProgress.get())
    return {
      watch = [seasonIndex, unlockProgress]
      size = const [FLEX, taskSlotHeight]
      padding = smallPadding
      rendObj = ROBJ_SOLID
      color = bgColor
      xmbNode = XmbNode()
      behavior = Behaviors.Button
      onHover
      children = [
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_CENTER
          children = [
            {
              padding = bigPadding
              children = mkTaskEmblem(task, progress, true, Watched(false),
                false, 0, seasonColor, emblemSize)
            }
            {
              size = FLEX_H
              flow = FLOW_VERTICAL
              children = [
                taskHeader(task, progress, true, 0, {
                  color = seasonColor
                }.__update(fontBody))
                taskDescription(task?.localization.description)
              ]
            }
            timeLeft
          ]
        }
        statusBlock(task)
        isUnseen ? smallUnseenNoBlink : null
      ]
    }
  }
}


return {
  key = "weeklyBlock"
  size = FLEX
  padding = bigPadding
  onAttach = saveFinishedWeeklyTasks
  onDetach = function() {
    markUnlockSeen((seenUnlocks.get()?.unseenWeeklyTasks ?? {}).keys())
    triggerBPStarsAnim()
    markUnlocksOpened((seenUnlocks.get()?.unopenedWeeklyTasks ?? {}).keys())
  }
  children = makeVertScroll(function() {
    let unseen = seenUnlocks.get()?.unseenWeeklyTasks ?? {}
    let tasks = (clone weeklyTasks.get())
      .sort(@(a, b) b.hasReward <=> a.hasReward
        || (b?.activity.active ?? false) <=> (a?.activity.active ?? false)
        || a.isCompleted <=> b.isCompleted
        || (a?.meta.taskListPlace ?? 0) <=> (b?.meta.taskListPlace ?? 0))
    let isRewardSingle = tasks.reduce(@(res, val) val.hasReward ? res + 1 : res, 0) == 1
    return {
      watch = [weeklyTasks, seenUnlocks]
      size = FLEX_H
      flow = FLOW_VERTICAL
      xmbNode = XmbContainer({
        canFocus = false
        scrollSpeed = 5
        isViewport = true
        wrap = false
      })
      children = tasks.map(@(task, idx)
        mkWeeklyTaskSlot(task, idx, task.name in unseen, isRewardSingle))
    }
  })
}
