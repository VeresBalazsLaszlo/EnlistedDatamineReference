import "%ui/control/gui_buttons.nut" as JB
import "%ui/eventPass/eventUnlockSlots.nut" as mkUnlockSlot
import "%ui/battlepass/eliteBattlePassWnd.nut" as eliteBattlePassWnd
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/style/designConst.nut" import bigPadding, defTxtColor, startBtnWidth, largePadding
from "%ui/eventPass/taskListState.nut" import dailyTasksByDifficulty, receiveTaskRewards,
  getTotalRerolls, getLeftRerolls, canTakeDailyTaskReward, doRerollUnlock
from "%ui/components/tasksPkg.nut" import taskDescription, taskHeader
from "%ui/userstats/userstat.nut" import userstatStats
from "%ui/userstats/unlocksState.nut" import getUnlockProgress, unlockProgress
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let headerTxtStyle = { color = defTxtColor }.__update(fontBody)
const smallGap = hdpx(4)


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
let mkDailyTasksBlock = @(tasksListVal, stats, canTakeReward, color) {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = smallGap
    children = tasksListVal.map(@(tasks) {
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
          if (!task.isFinished)
            acc.append(mkUnlockSlot({
              task
              onClick
              canTakeReward
              color
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

function eventTasksUi() {
  let watch = [hasDailyTasks, dailyTasksByDifficulty, userstatStats,
    canTakeDailyTaskReward, bpEventSettings]

  if (!hasDailyTasks.get())
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    gap = largePadding
    children = [
      {
        size = [startBtnWidth, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = mkDailyTasksBlock(dailyTasksByDifficulty.get(),
          userstatStats.get()?.stats,
          canTakeDailyTaskReward.get(),
          bpEventSettings.get().starColor)
      }
    ]
  }
}

return {
  eventTasksUi
}
