import "%ui/components/faComp.nut" as faComp
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/textButton.nut" import Primary
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding, midPadding, bigPadding, commonBtnHeight, accentColor
  , darkTxtColor, miniPadding, taskProgressColor
from "%ui/components/unlocksText.nut" import getDescription
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/unlocks/unlocks_utils.nut" import getStageByIndex
from "%ui/components/defComponents.nut" import progressBar
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let hoveredTxtStyle = { color = darkTxtColor }.__update(fontSub)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSub)
let taskProgressTxtStyle = { color = accentColor }.__update(fontSub)


let waitingSpinner = spinner(hdpx(24))
const starSize = hdpxi(22)
const taskMinHeight = hdpx(56)
const statusWidth = hdpx(24)
let taskSlotPadding = [miniPadding, smallPadding]
let taskDescPadding = [midPadding, smallPadding, bigPadding,
  hdpx(24) + statusWidth + midPadding * 2]


let blinkAnimation = {
  animations = [{
    prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true,
    loop = true, easing = Blink
  }]
}

let rewardAnimBg = {
  rendObj = ROBJ_IMAGE
  size = pw(100)
  image = Picture("ui/skin#tasks/completed_task_sign.avif")
  transform = { scale = [3, 3] }
}.__update(blinkAnimation)


let taskLabelSize = [hdpxi(8), hdpxi(18)]
let mkTaskLabel = @(labelName) labelName == null ? null : {
  size = taskLabelSize
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  image = Picture($"ui/skin#tasks/{labelName}.svg:{taskLabelSize[0]}:{taskLabelSize[1]}")
  vplace = ALIGN_TOP
}


let isDailyTask = @(task) task.table == "daily" || task?.meta.daily_unlocks_for_battlepass != null
let isRankUnlock = @(task) (task?.meta.rank_unlock ?? 0) > 0
  && (task?.stages[0].updStats[0].value ?? 0) == 0
let isWeeklyTask = @(task) task?.meta.weekly_unlock ?? false
let isAchievementTask = @(task) task?.meta.achievement ?? false
let isEventTask = @(task) task?.meta.event_unlock ?? (task?.meta.event_group != null) 
let getUnlockLimit = @(task) task?.meta.unlock_limit ?? 0
let getProgressDiv = @(task) task?.meta.descProgressDiv.tointeger() ?? 0


let mkFaIcon = @(name, color = 0xFFFFFF, fontSize = fontSub.fontSize)
  faComp(name, {fontSize, color})
let completedUnlockIcon = mkFaIcon("check", taskProgressColor)
let canceledUnlockIcon = mkFaIcon("times", darkTxtColor)
let rerollUnlockIcon = {
  rendObj = ROBJ_IMAGE
  size = [starSize, starSize]
  image = Picture("ui/skin#tasks/rerool_icon.svg:{0}:{0}".subst(starSize))
  color = darkTxtColor
}

let mkTaskTextArea = @(text, sf, style = {}) {
  size = const [pw(75), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  key = text
}.__update(sf & S_HOVER ? hoveredTxtStyle : defTxtStyle, style)

let statusIcon = @(unlockDesc, hasWaitIcon = Watched(false), canReroll = false)
  function() {
    local statusObj
    if (hasWaitIcon.get())
      statusObj = waitingSpinner
    else if (!isEventTask(unlockDesc)) {
      let { isCompleted = false, isFinished = false, isCanceled = false } = unlockDesc
      let hasCompletedMark = isFinished || isCompleted
      statusObj = isCanceled ? canceledUnlockIcon
        : hasCompletedMark ? completedUnlockIcon
        : canReroll ? rerollUnlockIcon
        : null
    }

    let res = { watch = hasWaitIcon }
    return statusObj == null ? res
      : res.__update({
          children = statusObj
        })
  }


function statusBlock(unlockDesc) {
  let { isCompleted = false, isFinished = false, isCanceled = false } = unlockDesc
  let statusObj = isCanceled ? canceledUnlockIcon
    : isFinished || isCompleted ? completedUnlockIcon
    : null

  return {
    pos = const [-statusWidth, 0]
    size = const [statusWidth, statusWidth]
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = statusObj
    animations = [{
      prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
    }]
  }
}


function getDescriptionText(task, progress, durationValue) {
  let unlockTxt = getDescription(task, progress, (task?.locParams ?? {})
    .__merge({ duration = secondsToStringLoc(durationValue) }))

  let addTexts = []
  let { lastRewardedStage = 0, stages = [] } = task
  if (stages.len() > 1) {
    let curStage = min(lastRewardedStage + 1, stages.len())
    addTexts.append(loc("stageText", { progress = $"{curStage}/{stages.len()}" }))
  }

  let unlockLimit = getUnlockLimit(task)
  let { isCompleted = false, hasReward = false } = progress
  let descProgressDiv = getProgressDiv(task)

  local { required, current, stage = 0 } = progress
  if (descProgressDiv > 0 && required != null && current != null) {
    current = current / descProgressDiv
    required = required / descProgressDiv
  }

  if (!isCompleted && !hasReward && (unlockLimit == 0 || stage < unlockLimit)) {
    local curStageCurrent, curStageRequired
    if (task?.periodic ?? false) {
      let loopIndex = task.startStageLoop - 1
      if (stage > loopIndex)
        stage = loopIndex + (stage - loopIndex) % (stages.len() - loopIndex)
      let interval = stages[stage].progress
      curStageCurrent = current + interval - required
      curStageRequired = interval
    } else {
      let passedProgress = stages?[lastRewardedStage - 1].progress ?? 0
      curStageCurrent = current - passedProgress
      curStageRequired = required - passedProgress
    }
    if (curStageRequired > 1)
      addTexts.append(loc("progressText", { progress = $"{curStageCurrent}/{curStageRequired}" }))
  }

  return addTexts.len() == 0
    ? unlockTxt
    : "{0} ({1})".subst(unlockTxt, ", ".join(addTexts))
}

let taskHeader = @(unlockDesc, progress, canTakeReward = true, sf = 0, textStyle = {})
  function() {
    let { isCompleted, isFinished, hasReward = false } = progress
    if (isDailyTask(unlockDesc) && isCompleted) {
      let locId = isCompleted && !canTakeReward ? "finishedTaskText" : "completeTaskText"
      return mkTaskTextArea(utf8ToUpper(loc(locId)), sf,
        { animations = hasReward && canTakeReward ? blinkAnimation.animations : []}.__update(
          sf & S_HOVER ? hoveredTxtStyle : hasReward && canTakeReward ? titleTxtStyle : defTxtStyle))
    }

    let unlockWatch = mkCountdownTimerPerSec(Watched(unlockDesc?.completeAt ?? 0))
    let unlockTxt = getDescriptionText(unlockDesc, progress, unlockWatch.get())
    return mkTaskTextArea(unlockTxt, sf)
      .__update({ watch = unlockWatch }, isEventTask(unlockDesc) && isFinished ? titleTxtStyle
        : sf & S_HOVER ? hoveredTxtStyle
        : defTxtStyle, textStyle)
  }


let taskDescription = @(description, sf = 0, style = {})
(description ?? "") == "" ? null
  : mkTaskTextArea(description, sf, style)


let btnSize = [hdpx(230), commonBtnHeight]

let mkGetTaskRewardBtn = @(task, cb, inProgressWatch, btnOverride = {}) @() {
  watch = inProgressWatch
  children = (inProgressWatch.get()?[task.name] ?? false)
    ? waitingSpinner
    : Primary(loc("bp/getNextReward"), @() cb(task), {
        key = "btnReceiveReward"
        size = [SIZE_TO_CONTENT, btnSize[1]]
        minWidth = btnSize[0]
      }.__update(btnOverride))
}


let mkEmblemImg = @(img, iSize, hasAnim, sf, color) {
  size = [iSize, iSize]
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [iSize, iSize]
      color = sf & S_HOVER ? darkTxtColor : color
      image = Picture("{0}.svg:{1}:{1}".subst(img, iSize))
    }
    hasAnim ? rewardAnimBg : null
  ]
}

let mkEmblemImgReward = @(img, iSize, color) {
  size = [iSize, iSize]
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [iSize, iSize]
      color
      image = Picture("{0}.svg:{1}:{1}".subst(img, iSize))
    }
    rewardAnimBg
  ]
}


function mkEmblemQty(unlockDesc) {
  let { lastRewardedStage = 0, isFinished = false } = unlockDesc
  let stage = isFinished
    ? getStageByIndex(unlockDesc, lastRewardedStage - 1)
    : getStageByIndex(unlockDesc, lastRewardedStage)
  let count = (stage?.updStats[0].value ?? 1).tointeger()
  return count <= 1 ? null
    : {
        rendObj = ROBJ_TEXT
        text = count
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        pos = [midPadding, smallPadding]
      }.__update(taskProgressTxtStyle)
}


function getTaskEmblemImg(unlockDesc, isCompleted) {
  if (isRankUnlock(unlockDesc))
    return isCompleted
      ?  "ui/skin#tasks/goblet_filled"
      :  "ui/skin#tasks/goblet_empty"
  if (isDailyTask(unlockDesc) || isWeeklyTask(unlockDesc))
    return isCompleted
      ? "ui/skin#star_level_filled"
      : "ui/skin#star_level_empty"
  if (isAchievementTask(unlockDesc) || isEventTask(unlockDesc))
    return isCompleted
      ? "ui/skin#tasks/medal_filled"
      : "ui/skin#tasks/medal_empty"
  return ""
}

function mkTaskEmblem(unlockDesc, progress, canTakeReward = true,
  hasWaitIcon = Watched(false), canReroll = false, sf = 0, color = null,
  emblemSize = starSize
) {
  let { lastRewardedStage = 0, stages = [], periodic = false } = unlockDesc
  let { hasReward = false, current, required } = progress
  let emblemImg = getTaskEmblemImg(unlockDesc, current >= required)
  let passedProgress = lastRewardedStage <= 0 ? 0
    : stages?[lastRewardedStage - 1].progress ?? 0
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  let progBarValue = hasReward ? 1
    : !periodic && curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
    : 0
  let sIcon = statusIcon(unlockDesc, hasWaitIcon, canReroll)
  return emblemImg == "" ? null
    : {
        size = [emblemSize + smallPadding, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = midPadding
        halign = ALIGN_CENTER
        opacity = unlockDesc.isFinished ? 0.3 : 1
        children = [
          {
            children = [
              sf & S_HOVER ? sIcon
                : mkEmblemImg(emblemImg, emblemSize, unlockDesc.hasReward && canTakeReward, sf, color)
              mkEmblemQty(unlockDesc)
            ]
          }
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


let taskImageSize = [hdpx(100), hdpx(100)]
let mkTaskImage = @(img) {
  size = taskImageSize
  rendObj = ROBJ_IMAGE
  image = Picture(img)
}


let completedSign = {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  padding = midPadding
  valign = ALIGN_CENTER
  children = [
    faComp("check", {
      color = taskProgressColor
      fontSize = hdpx(28)
    })
    {
      rendObj = ROBJ_TEXT
      text = loc("finishedTaskText")
      color = taskProgressColor
    }.__update(fontBody)
  ]
}

return freeze({
  mkTaskLabel
  rewardAnimBg
  taskLabelSize
  taskHeader
  taskDescription
  taskDescPadding
  taskMinHeight
  mkEmblemImgReward
  taskSlotPadding
  mkTaskEmblem
  statusBlock
  mkGetTaskRewardBtn
  getTaskEmblemImg
  completedUnlockIcon
  mkTaskTextArea
  getProgressDiv
  getDescriptionText
  mkTaskImage
  completedSign
})
