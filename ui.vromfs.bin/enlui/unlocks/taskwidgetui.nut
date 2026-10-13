import "%ui/control/gui_buttons.nut" as JB
import "%ui/battlepass/eliteBattlePassWnd.nut" as eliteBattlePassWnd
import "%ui/unlocks/buyUnlockMsg.nut" as buyUnlockMsg
import "%ui/components/spinner.nut" as spinner
import "%ui/battlepass/battlePassButton.nut" as mkBpWidgetOpen
import "%ui/offers/offersPromoWindow.nut" as offersPromoWndOpen
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defTxtColor, disabledTxtColor, hoverTxtColor, startBtnWidth, largePadding
from "%ui/unlocks/taskListState.nut" import dailyTasksByDifficulty, receiveTaskRewards, getTotalRerolls, getLeftRerolls, isRerollInProgress, canTakeDailyTaskReward, doRerollUnlock, rewardDailyTask
from "%ui/components/tasksPkg.nut" import taskDescription, taskDescPadding, mkTaskLabel, taskLabelSize, taskHeader
from "%ui/unlocks/mkUnlockSlots.nut" import mkUnlockSlot, mkUnlockSlotReward, mkHideTrigger
from "%ui/userstats/userstat.nut" import userstatStats, unlockRewardsInProgress
from "%ui/unlocks/eventsTaskState.nut" import specialEvents, showNotActiveTaskMsgbox
from "%ui/userstats/unlocksState.nut" import isUnlockAvailable, getUnlockProgress, unlockProgress
from "%ui/components/textButton.nut" import Primary, Purchase
from "%ui/unlocks/taskRewardsState.nut" import unlockPrices, purchaseInProgress, hasBattlePass
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/unlocks/weeklyUnlocksState.nut" import rewardWeeklyTask, rewardEventTask
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let disabledTxtStyle = { color = disabledTxtColor }.__update(fontSub)
let hoveredTxtStyle = { color = hoverTxtColor }.__update(fontSub)
let headerTxtStyle = { color = defTxtColor }.__update(fontBody)
let disabledHeaderTxtStyle = { color = disabledTxtColor }.__update(fontBody)
let hoveredHeaderTxtStyle = { color = hoverTxtColor }.__update(fontBody)
const smallGap = hdpx(4)
let waitingSpinner = spinner()


let mkRerollText = @(leftRerolls, totalRerolls) {
  size = const [sw(30), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "\n".concat(
    loc("unlocks/reroll/youCanReroll"),
    loc("unlocks/reroll/info", {
      left = leftRerolls
      total = totalRerolls
    }))
}.__update(defTxtStyle)


function askForRerollConfirm(unlockDesc) {
  showMsgbox({
    text = loc("unlocks/reroll/askForConfirm")
    buttons = [
      { text = loc("Ok"), action = @() doRerollUnlock(unlockDesc),
        customStyle = { hotkeys = [["^J:X"]] } }
      { text = loc("Cancel"), isCurrent = true, isCancel = true,
        customStyle = { hotkeys = [[$"^{JB.B}"]] } }
    ]
  })
}


function openTaskMsgbox(unlockDesc, leftRerolls = 0, totalRerolls = 0) {
  let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
  let buttons = []
  if (leftRerolls > 0)
    buttons.append({
      text = loc("btn/rerollUnlock")
      action = @() askForRerollConfirm(unlockDesc)
      isCurrent = true
      customStyle = { hotkeys = [["^J:X"]] }
    })
  buttons.append({ text = loc("Close"), isCancel = true, customStyle = {hotkeys = [[$"^{JB.B}"]]} })

  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      size = const [sh(100), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      margin = const [0,0,fsh(5),0]
      gap = fsh(5)
      children = [
        taskHeader(unlockDesc, progress, true, 0, {
          halign = ALIGN_CENTER
        }.__update(headerTxtStyle))
        taskDescription(unlockDesc.localization.description, 0, { halign = ALIGN_CENTER})
        leftRerolls > 0 ? mkRerollText(leftRerolls, totalRerolls) : null
      ]
    }
    buttons
  })
}


local curTimeout = null
let mkDailyTasksBlock = @(
  tasksListVal, stats, canTakeReward, isCompletedHidden, onHover, isHeightFixed
) {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = smallGap
    children = tasksListVal.map(@(tasks, taskStype) {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = smallGap
        children = tasks.reduce(function(acc, task) {
          let leftRerolls = getLeftRerolls(task, stats)
          let totalRerolls = getTotalRerolls(task, stats)
          let onClick = !task.hasReward
            ? @() openTaskMsgbox(task, leftRerolls, totalRerolls)
            : canTakeReward
              ? function() {
                  if (curTimeout != null)
                    return
                  anim_start(mkHideTrigger(task))
                  sound_play("ui/reward_receive")
                  curTimeout = gui_scene.setTimeout(0.5, function() {
                    curTimeout = null
                    receiveTaskRewards(task)
                  })
                }
              : @() showMsgbox({
                  text = loc("unlocks/dailyTasksLimitOnReward")
                  buttons = [
                    {
                      text = loc("bp/buyBattlePass")
                      action = eliteBattlePassWnd
                      isCurrent = true
                    }
                    {
                      text = loc("Cancel"), isCancel = true,
                      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
                    }
                  ]
                })
          if (!isCompletedHidden || !task.isCompleted)
            acc.append(mkUnlockSlot({
              task
              onClick
              onHover
              hasWaitIcon = isRerollInProgress
              rerolls = leftRerolls
              rightObject = taskStype == "hardTasks"
                ? mkTaskLabel("main_task_lable")
                : { size = [taskLabelSize[0], FLEX] }
              canTakeReward
              isHeightFixed
            }))
          return acc
        }, [])
      }
    ).values()
}

let hasDailyTasks = Computed(function() {
  let { easyTasks = [], hardTasks = [] } = dailyTasksByDifficulty.get()
  return easyTasks.len() > 0 || hardTasks.len() > 0
})

let mkDailyTasksUi = @(isCompletedHidden = false, onHover = null, isHeightFixed = false)
  function() {
    let watch = [hasDailyTasks, canTakeDailyTaskReward, userstatStats, dailyTasksByDifficulty]

    if (!hasDailyTasks.get())
      return { watch }

    let canTakeReward = canTakeDailyTaskReward.get()
    let stats = userstatStats.get()?.stats
    return {
      watch
      flow = FLOW_VERTICAL
      gap = largePadding
      children = [
        {
          size = [startBtnWidth, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = mkDailyTasksBlock(dailyTasksByDifficulty.get(), stats, canTakeReward,
            isCompletedHidden, onHover, isHeightFixed)
        }
      ]
    }
  }

let rewardTask = Computed(@() rewardDailyTask.get() ?? rewardWeeklyTask.get() ?? rewardEventTask.get())

let mkDailyTasksUiReward = @(onHover = null) function() {
  let res = {
    watch = [rewardTask, hasBattlePass]
  }

  if (!hasBattlePass.get() && !rewardTask.get())
    return res

  let { event_unlock = false, event_group = null } = rewardTask.get()?.meta
  let forcedCb = !event_unlock || event_group == null ? null
    : @() offersPromoWndOpen(event_group)

  return res.__update({
    size = [startBtnWidth, SIZE_TO_CONTENT]
    children = rewardTask.get()
      ? mkUnlockSlotReward(rewardTask.get(), forcedCb)
      : mkBpWidgetOpen(onHover)
  })
}


const btnHeight = hdpxi(46)
const btnMinWidth = hdpxi(200)

function mkBtnBuyTask(task) {
  let hasBlockedByRequirement = Computed(function() {
    let pRequirement = task?.purchaseRequirement ?? ""
    return pRequirement == "" ? false
      : !(unlockProgress.get()?[pRequirement].isCompleted ?? false)
  })
  return function() {
    let watch = [purchaseInProgress, hasBlockedByRequirement]

    if (hasBlockedByRequirement.get())
      return { watch }

    return {
      watch
      size = const [SIZE_TO_CONTENT, btnHeight]
      valign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      margin = bigPadding
      children = purchaseInProgress.get()?[task.name] ? waitingSpinner
        : Purchase(loc("bp/Purchase"),
            @() buyUnlockMsg(task),
            {
              key = "buyBtnTask"
              size = const [SIZE_TO_CONTENT, btnHeight]
              minWidth = btnMinWidth
              hotkeys = [["^J:Y", { description = { skip = true }}]]
            })
    }
  }
}


let mkBtnReceiveReward = @(task) @() {
  watch = unlockRewardsInProgress
  size = const [SIZE_TO_CONTENT, btnHeight]
  valign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  margin = bigPadding
  children = unlockRewardsInProgress.get()?[task.name] ? waitingSpinner
    : Primary(loc("bp/getNextReward"),
        @() receiveTaskRewards(task),
        {
          key = "btnReceiveReward"
          size = const [SIZE_TO_CONTENT, btnHeight]
          minWidth = btnMinWidth
          hotkeys = [["^J:X", { description = { skip = true }}]]
        })
}


local lastActiveIdx = 0

const MAIN_EVENT_TASK_PLACE = 1
function mkEventTask(task, taskPrice, idx, isActive, isMainActive) {
  let { isCompleted, hasReward, isFinished, step, totalSteps, meta = null } = task
  let { currency = "", price = 0 } = taskPrice
  let isMain = meta?.taskListPlace == MAIN_EVENT_TASK_PLACE
  let onClick = isActive ? null : showNotActiveTaskMsgbox
  let isPurchasable = isMainActive && !isCompleted && price > 0 && currency != ""
  lastActiveIdx = isActive ? idx + 1 : lastActiveIdx
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      mkUnlockSlot({
        task
        isAllRewardsVisible = true
        onClick
        hasDescription = !isFinished && isActive
        bottomBtn = !isActive ? null
          : hasReward ? mkBtnReceiveReward(task)
          : isPurchasable ? mkBtnBuyTask(task)
          : null
        customDescription = !isMain && idx >= lastActiveIdx
            ? taskDescription(loc("unlocks/blockedByPrevious"), 0, {
                margin = taskDescPadding
              })
          : isFinished
            ? taskDescription(utf8ToUpper(loc("finishedTaskText")), 0, {
                margin = taskDescPadding
              })
          : null
        rightObject = mkTaskLabel(isMain ? "main_task_lable" : null)
      })
      totalSteps <= 1 ? null : {
        flow = FLOW_VERTICAL
        size = const [hdpx(12), FLEX]
        halign = ALIGN_CENTER
        gap = bigPadding
        children = [
          {
            rendObj = ROBJ_TEXT
            text = step
          }.__update(isActive ? hoveredHeaderTxtStyle : disabledHeaderTxtStyle)
          step >= totalSteps ? null
            : {
                rendObj = ROBJ_SOLID
                size = [smallPadding, FLEX]
              }.__update(isActive ? hoveredTxtStyle : disabledTxtStyle)
        ]
      }
    ]
  }
}


let eventTasksUi = @(eventId, tasksCount = -1) function() {
  let res = { watch = [specialEvents, unlockPrices, unlockProgress] }
  let eUnlocks = specialEvents.get()?[eventId].unlocks
  if (eUnlocks == null)
    return res
  local activeTasksCount = 0
  let uProgress = unlockProgress.get()
  let isMainActive = eUnlocks?[0].activity.active ?? true
  let children = []
  foreach (idx, task in eUnlocks) {
    let isActive = isUnlockAvailable(uProgress, task)
    if (isActive)
      activeTasksCount++
    if (tasksCount > 0 && activeTasksCount > tasksCount)
      break
    children.append(mkEventTask(task, unlockPrices.get()?[task.name], idx, isActive, isMainActive))
  }
  return res.__update({
    size = FLEX_H
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    gap = bigPadding
    valign = ALIGN_CENTER
    children
  })
}


return {
  hasDailyTasks
  mkDailyTasksUiReward
  mkDailyTasksUi
  eventTasksUi
}
