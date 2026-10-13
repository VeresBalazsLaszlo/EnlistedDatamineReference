import "%ui/unlocks/buyUnlockMsg.nut" as buyUnlockMsg
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontBody
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, hoverBgColor, disabledTxtColor
from "%ui/unlocks/taskListState.nut" import receiveTaskRewards
from "%ui/components/tasksPkg.nut" import taskDescription, taskDescPadding, mkTaskLabel
from "%ui/unlocks/mkUnlockSlots.nut" import mkUnlockSlot
from "%ui/userstats/userstat.nut" import unlockRewardsInProgress
from "%ui/unlocks/eventsTaskState.nut" import specialEvents, showNotActiveTaskMsgbox
from "%ui/userstats/unlocksState.nut" import isUnlockAvailable, unlockProgress
from "%ui/components/textButton.nut" import Primary, Purchase
from "%ui/unlocks/taskRewardsState.nut" import unlockPrices, purchaseInProgress
from "%ui/ui_library.nut" import *

const btnHeight = hdpxi(46)
const btnMinWidth = hdpxi(200)
let waitingSpinner = spinner()

function mkBtnBuyTask(task) {
  let hasBlockedByRequirement = Computed(function() {
    let pRequirement = task?.purchaseRequirement ?? ""
    return pRequirement == "" ? false
      : !(unlockProgress.get()?[pRequirement].isCompleted ?? false)
  })
  return @() {
    watch = [purchaseInProgress, hasBlockedByRequirement]
    size = const [SIZE_TO_CONTENT, btnHeight]
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    margin = bigPadding
    children = hasBlockedByRequirement.get() ? null
      : purchaseInProgress.get()?[task.name] ? waitingSpinner
      : Purchase(loc("bp/Purchase"),
          @() buyUnlockMsg(task),
          {
            key = "buyBtnTask"
            size = const [SIZE_TO_CONTENT, btnHeight]
            minWidth = btnMinWidth
            margin = 0
          })
  }
}

let mkBtnReceiveReward = @(task) @() {
  watch = unlockRewardsInProgress
  size = const [SIZE_TO_CONTENT, btnHeight]
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  margin = bigPadding
  children = unlockRewardsInProgress.get()?[task.name] ? waitingSpinner
    : Primary(loc("bp/getNextReward"),
        @() receiveTaskRewards(task),
        {
          key = "btnReceiveReward"
          size = const [SIZE_TO_CONTENT, btnHeight]
          minWidth = btnMinWidth
          margin = 0
        })
}

local lastActiveIdx = 0

const MAIN_EVENT_TASK_PLACE = 1
function mkEventTask(task, taskPrice, idx, uProgress, isMainActive) {
  let { isCompleted, hasReward, isFinished, step = 1, totalSteps = 1, meta = null } = task
  let isActive = isUnlockAvailable(uProgress, task)
  let { currency = "", price = 0 } = taskPrice
  let isMain = meta?.taskListPlace == MAIN_EVENT_TASK_PLACE
  let onClick = isActive ? null : showNotActiveTaskMsgbox
  let isPurchasable = isMainActive && !isCompleted && price > 0 && currency != ""

  lastActiveIdx = isActive ? idx + 1 : lastActiveIdx

  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = midPadding
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
        hasTimer = !isMain
      })
      totalSteps <= 1 ? null
        : {
            flow = FLOW_VERTICAL
            size = const [hdpx(12), FLEX]
            halign = ALIGN_CENTER
            gap = midPadding
            children = [
              {
                rendObj = ROBJ_TEXT
                text = step
                color = isActive ? hoverBgColor : disabledTxtColor
              }.__update(fontBody)
              step >= totalSteps ? null
                : {
                    rendObj = ROBJ_SOLID
                    size = [smallPadding, FLEX]
                    color = isActive ? hoverBgColor : disabledTxtColor
                  }
            ]
          }
    ]
  }
}

let eventTasksUi = @(eventId) function() {
  let res = { watch = [specialEvents, unlockPrices, unlockProgress] }
  let eUnlocks = specialEvents.get()?[eventId].unlocks
  if (eUnlocks == null)
    return res

  let uProgress = unlockProgress.get()
  let isMainActive = eUnlocks?[0].activity.active ?? true
  return res.__update({
    size = FLEX_H
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    gap = fsh(2)
    valign = ALIGN_CENTER
    children = eUnlocks.map(@(task, idx)
      mkEventTask(task, unlockPrices.get()?[task.name], idx, uProgress, isMainActive))
  })
}

return {
  eventTasksUi
  mkEventTask
}
