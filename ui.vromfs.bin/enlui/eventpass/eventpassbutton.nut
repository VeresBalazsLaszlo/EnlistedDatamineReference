import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/components/colorize.nut" as colorize
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defTxtColor, startBtnWidth, transpPanelBgColor, defItemBlur, highlightLineTop
  , hoverSlotBgColor, darkTxtColor, activeTxtColor, attentionTxtColor
from "%ui/eventPass/eventPassState.nut" import hasReward, currentProgress, nextUnlock
from "%ui/battlepass/rewardsPkg.nut" import getOneReward, mkRewardIcon, rewardIconWidth
from "%ui/eventPass/eventPassWindowState.nut" import openEventPassWindow
from "%ui/eventPass/eventPassIconPkg.nut" import timeTracker, eventPassIcon, dynamicSeasonBg, tokenIconCmp
from "%ui/components/tasksPkg.nut" import taskLabelSize
from "%ui/components/textButton.nut" import soundDefault
from "%ui/eventPass/eventTaskRewardsState.nut" import hasBattlePass
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *

let bpButtonHeight = hdpx(80) + smallPadding * 2

function rewardProgress() {
  let { required, current, interval } = currentProgress.get()
  let value = current >= required || hasReward.get()
    ? interval
    : clamp(current - required + interval, 0, interval)

  return {
    watch = [currentProgress, hasReward]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        text = "{0}/{1}".subst(value, colorize(attentionTxtColor, interval))
        color = hasReward.get() ? attentionTxtColor : activeTxtColor
        behavior = Behaviors.TextArea
      }.__update(fontBody)
      tokenIconCmp
    ]
  }
}

let titleBpBlock = @(sf, tittleLocId) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(tittleLocId)
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
      lineSpacing = hdpx(-4)
    }.__update(fontBody)
    rewardProgress
  ]
}


function rewardBpBlock() {
  let item = nextUnlock.get()
  let { reward = null } = getOneReward(item?.rewards ?? {}, itemsMapping.get())
  let cardIcon = mkRewardIcon(reward, rewardIconWidth)
  return {
    watch = [nextUnlock, itemsMapping]
    size = [SIZE_TO_CONTENT, bpButtonHeight]
    padding = [0, taskLabelSize[0], 0, 0]
    valign = ALIGN_CENTER
    children = cardIcon
  }
}


let mkWidgetInfo = @(sf, tittleLocId) {
  size = FLEX_H
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
  }]
  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      valign = ALIGN_CENTER
      padding = [smallPadding, 0, smallPadding, bigPadding]
      children = [
        eventPassIcon(hdpxi(65))
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          vplace = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            titleBpBlock(sf, tittleLocId)
            rewardBpBlock
          ]
        }
      ]
    }
  ]
}

let mkEventPassButton = @() {
  watch = [hasBattlePass, bpEventSettings]
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = !hasBattlePass.get() ? null : watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR
    size = FLEX_H
    minHeight = bpButtonHeight
    color = defItemBlur
    fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    behavior = Behaviors.Button
    sound = soundDefault
    onClick = @(_) openEventPassWindow()
    children = [
      timeTracker
      dynamicSeasonBg([hdpxi(373), hdpxi(98)], sf & S_HOVER ? 1 : 0.7)
      mkWidgetInfo(sf, bpEventSettings.get().passTitle)
      highlightLineTop
    ]
  })
}

console_register_command(@() openEventPassWindow(), "ui.eventPassWindow")

return mkEventPassButton
