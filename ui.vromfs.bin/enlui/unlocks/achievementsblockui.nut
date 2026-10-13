import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/components/colorize.nut" as colorize
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/unlocks/taskListState.nut" import achievementsList, receiveTaskRewards
from "%ui/userstats/unlocksState.nut" import getUnlockProgress, unlockProgress
from "%ui/userstats/userstat.nut" import unlockRewardsInProgress
from "%ui/unlocks/mkUnlockSlots.nut" import mkTaskRewards
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/unlocks/unseenUnlocksState.nut" import seenUnlocks, markUnlocksOpened
from "%ui/components/defComponents.nut" import progressBar
from "%ui/style/designConst.nut" import smallPadding, bigPadding, taskProgressColor,
  rowBg, accentTitleTxtColor
from "%ui/components/tasksPkg.nut" import mkTaskImage, taskHeader, taskDescription,
  mkGetTaskRewardBtn, completedSign
from "%ui/ui_library.nut" import *


let mkTextarea = @(txt, override = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = txt
}.__update(fontBody, override)


const statusRowWidth = hdpx(250)
function mkAchievementStatus(task, progress, isRewardSingle) {
  let { lastRewardedStage = 0, stages = [], periodic = false } = task
  let { current, required, hasReward = false, isCompleted = false } = progress

  if (hasReward)
    return mkGetTaskRewardBtn(task, receiveTaskRewards, unlockRewardsInProgress,
      isRewardSingle ? { hotkeys = [["^J:X | Enter | Space", { skip = true }]] } : {})

  if (isCompleted)
    return completedSign

  let passedProgress = lastRewardedStage <= 0 ? 0 : (stages?[lastRewardedStage - 1].progress ?? 0)
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  let progBarValue = periodic || curStageRequired <= 0 ? 0
    : curStageCurrent.tofloat() / curStageRequired

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkTextarea(loc("progressInPercent", {
        progress = colorize(taskProgressColor, (progBarValue * 100).tointeger())
      }))
      progressBar(progBarValue, {
        size = const [FLEX, hdpx(4)]
        progressColor = taskProgressColor
      })
    ]
  }
}

let mkAchievementSlot = @(task, idx, isRewardSingle)
  function() {
    let progress = getUnlockProgress(task, unlockProgress.get())
    return {
      watch = [unlockProgress, itemsMapping]
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      padding = smallPadding
      rendObj = ROBJ_SOLID
      color = rowBg(0, idx)
      children = [
        mkTaskImage(task.iconUrl)
        {
          size = FLEX
          flow = FLOW_VERTICAL
          valign = ALIGN_CENTER
          children = [
            taskHeader(task, progress, true, 0, { color = accentTitleTxtColor }.__update(fontBody))
            taskDescription(task.localization.description, 0, {
              size = const [FLEX, SIZE_TO_CONTENT]
            })
          ]
        }
        {
          vplace = ALIGN_CENTER
          children = mkTaskRewards(task, itemsMapping.get(), true)
        }
        {
          size = const [statusRowWidth, FLEX]
          padding = [0, smallPadding]
          valign = ALIGN_CENTER
          children = mkAchievementStatus(task, progress, isRewardSingle)
        }
      ]
    }
  }


function achievementsBlockUI() {
  return {
    key = "achievementsBlock"
    size = FLEX
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    padding = bigPadding
    onDetach = @() markUnlocksOpened((seenUnlocks.get()?.unopenedAchievements ?? {}).keys())
    children = makeVertScroll(function() {
      let achievements = achievementsList.get()
      let isRewardSingle = achievements.reduce(@(res, val) val.hasReward ? res + 1 : res, 0) == 1
      return {
        watch = achievementsList
        size = FLEX_H
        flow = FLOW_VERTICAL
        minHeight = ph(100)
        rendObj = ROBJ_WORLD_BLUR_PANEL
        xmbNode = XmbContainer({
          canFocus = false
          scrollSpeed = 5
          isViewport = true
          wrap = false
        })
        children = achievements.map(@(task, idx) mkAchievementSlot(task, idx, isRewardSingle))
      }
    }, {
      needReservePlace = false
      styling = thinStyle
    })
  }
}

return achievementsBlockUI