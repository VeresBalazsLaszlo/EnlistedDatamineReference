from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import midPadding, smallPadding, defItemBlur, hoverSlotBgColor,
  panelBgColor, defTxtColor, darkTxtColor, taskProgressColor
from "%ui/components/tasksPkg.nut" import taskMinHeight, taskSlotPadding, taskHeader, rewardAnimBg
from "%ui/components/textButton.nut" import soundDefault
from "%ui/eventPass/eventPassIconPkg.nut" import tokenIconCmp
from "%ui/eventPass/taskListState.nut" import bpDailyTask, bpDailyTaskProgress
from "%ui/userstats/unlocksState.nut" import getUnlockProgress, unlockProgress
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/components/defComponents.nut" import progressBar
from "%ui/ui_library.nut" import *


const taskIconSize = hdpxi(30)

let mkEmblemImg = @(img, iSize, hasAnim, sf, color) {
  size = [iSize, iSize]
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [iSize, iSize]
      color = sf & S_HOVER ? darkTxtColor : color
      image = Picture(img)
    }
    hasAnim ? rewardAnimBg : null
  ]
}

function mkTaskEmblem(settings, unlockDesc, progress, canTakeReward = true,
  sf = 0, color = null, emblemSize = taskIconSize
) {
  let { lastRewardedStage = 0, stages = [], periodic = false } = unlockDesc
  let { hasReward = false, current, required } = progress
  let emblemImg = settings?.getTokenIcon([emblemSize, emblemSize])
  let passedProgress = lastRewardedStage <= 0 ? 0
    : stages?[lastRewardedStage - 1].progress ?? 0
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  let progBarValue = hasReward ? 1
    : !periodic && curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
    : 0
  return emblemImg == "" ? null
    : {
        size = [emblemSize + smallPadding, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = midPadding
        halign = ALIGN_CENTER
        opacity = unlockDesc.isFinished ? 0.3 : 1
        children = [
          mkEmblemImg(emblemImg, emblemSize, unlockDesc.hasReward && canTakeReward, sf, color)
          {
            size = FLEX
            children = progressBar(progBarValue, {
              size = const [FLEX, hdpx(4)]
              progressColor = color ?? taskProgressColor
            })
          }
        ]
      }
}

let mkEventTaskContent = @(
  unlockDesc, canTakeReward, textHeight, group, sf = 0, color = null
) function() {
  let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
  return {
    watch = [unlockProgress, bpEventSettings]
    size = [FLEX, textHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    group
    children = [
      mkTaskEmblem(bpEventSettings.get(),
        unlockDesc, progress, canTakeReward, sf, color)
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

function nextReward() {
  let watch = [bpDailyTask, bpDailyTaskProgress]

  let { stage = 0 } = bpDailyTaskProgress.get()
  let { stages = [] } = bpDailyTask.get()
  let nextStageInfo = stages.findvalue(@(v) v.progress == stage + 1)
  let { value = null } = nextStageInfo?.updStats.top()
  if (value == null)
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = smallPadding
    vplace = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    padding = smallPadding
    children = [
      tokenIconCmp
      {
        rendObj = ROBJ_TEXT
        text = value
      }.__update(fontSub)
    ]
  }
}

let mkUnlockSlot = kwarg(function(task, onClick = null, canTakeReward = true, color = null) {
  let textHeight = SIZE_TO_CONTENT
  let group = ElemGroup()
  return watchElemState(@(sf) {
    key = task.name
    rendObj = ROBJ_WORLD_BLUR
    size = FLEX_H
    fillColor = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
    color = defItemBlur
    minHeight = taskMinHeight
    behavior = onClick == null ? null : Behaviors.Button
    sound = soundDefault
    onClick
    group
    children = {
      size = FLEX_H
      minHeight = taskMinHeight
      flow = FLOW_HORIZONTAL
      padding = taskSlotPadding
      gap = smallPadding
      valign = ALIGN_CENTER
      group
      children = [
        mkEventTaskContent(task, canTakeReward, textHeight, group, sf, color)
        nextReward
      ]
    }
  })
})

return mkUnlockSlot
