import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defTxtColor, startBtnWidth, transpPanelBgColor, defItemBlur, highlightLineTop
  , hoverSlotBgColor, darkTxtColor
from "%ui/battlepass/bpConst.nut" import BP_INTERVAL_STARS
from "%ui/battlepass/bpState.nut" import hasReward, currentProgress, nextUnlock, seasonIndex
from "%ui/battlepass/rewardsPkg.nut" import getOneReward, mkRewardIcon, rewardIconWidth
from "%ui/battlepass/bpWindowState.nut" import openBPwindow
from "%ui/battlepass/battlePassPkg.nut" import timeTracker, dynamicSeasonBPIcon, dynamicSeasonBpBg
from "%ui/components/tasksPkg.nut" import rewardAnimBg, taskLabelSize
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/unlocks/weeklyUnlocksState.nut" import bpStarsAnimGen
from "%ui/components/textButton.nut" import soundDefault
from "%ui/unlocks/taskRewardsState.nut" import hasBattlePass, isSeasonEnds
from "%ui/battlepass/battlepass_presentation.nut" import getBpPresentation
from "%ui/ui_library.nut" import *

const starSize = hdpxi(20)
let bpButtonHeight = hdpx(80) + smallPadding * 2
local visibleStars = null
function showUnseenBPStars() {
  for (local i = 0; i < BP_INTERVAL_STARS; i++)
    anim_start($"bp_star_{i}")
}


bpStarsAnimGen.subscribe(function(_v) {
  gui_scene.resetTimeout(0.1, showUnseenBPStars)
})


let mkStar = @(idx, isFilled = false, hasRewardAnim = false, hasAppearAnim = false) function() {
  let trigger = $"bp_star_{idx}"
  let { starColor } = getBpPresentation(seasonIndex.get())
  return {
    watch = seasonIndex
    size = const [starSize, starSize]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = const [starSize, starSize]
        color = starColor
        image = Picture("ui/skin#star_level_empty.svg:{0}:{0}".subst(starSize))
      }
      !isFilled ? null
        : {
            rendObj = ROBJ_IMAGE
            size = const [starSize, starSize]
            image = Picture("ui/skin#star_level_filled.svg:{0}:{0}".subst(starSize))
            transform = true
            color = starColor
            animations = [
              { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3,
                play = hasAppearAnim, onFinish = @() sound_play("ui/debriefing/squad_star"),
                trigger }
              { prop = AnimProp.scale, from = [3,3], to = [1,1], duration = 0.5,
                play = hasAppearAnim, trigger }
              { prop = AnimProp.translate, from = [hdpx(50 + idx * 40),-hdpx(30)],
                to = [0,0], duration = 0.5, play = hasAppearAnim, trigger }
            ]
          }
      hasRewardAnim ? rewardAnimBg : null
    ]
  }
}


function rewardProgress() {
  let watch = [currentProgress, hasReward]
  let { required, current, interval } = currentProgress.get()
  if (interval == 0)
    return { watch }

  let hasRewardVal = hasReward.get()
  let starFactor = (interval / BP_INTERVAL_STARS).tointeger()
  let filledStars = current >= required || hasReward.get()
    ? BP_INTERVAL_STARS
    : clamp(((current + interval - required) / starFactor).tointeger(),
      0, BP_INTERVAL_STARS - 1)
  let visible = visibleStars ?? BP_INTERVAL_STARS
  visibleStars = hasRewardVal ? BP_INTERVAL_STARS : filledStars
  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = array(BP_INTERVAL_STARS).map(function(_, idx) {
      let isFilled = hasRewardVal || idx < filledStars
      let hasAppearAnim = isFilled && idx > visible - 1
      return mkStar(idx, isFilled, hasRewardVal, hasAppearAnim)
    })
  }
}


let titleBpBlock = @(sf) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePassUpper")
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
    }.__update(fontHeading2)
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


let mkWidgetInfo = @(sf) {
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
        dynamicSeasonBPIcon(hdpxi(65))
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          vplace = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            titleBpBlock(sf)
            rewardBpBlock
          ]
        }
      ]
    }
  ]
}

let mkBpWidgetOpen = @(onHover = null) @() {
  watch = [hasBattlePass, isSeasonEnds]
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = !hasBattlePass.get() ? null
    : isSeasonEnds.get() ? {
        size = FLEX_H
        valign = ALIGN_CENTER
        rendObj = ROBJ_WORLD_BLUR
        color = defItemBlur
        fillColor = transpPanelBgColor
        children = [
          dynamicSeasonBpBg([hdpxi(373), hdpxi(98)], 1)
          {
            size = FLEX_H
            margin = bigPadding
            halign = ALIGN_CENTER
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc("bp/seasonEndsText")
            color = defTxtColor
          }.__update(fontBody)
        ]
      }
    : watchElemState(@(sf) {
        rendObj = ROBJ_WORLD_BLUR
        size = FLEX_H
        minHeight = bpButtonHeight
        color = defItemBlur
        fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
        behavior = Behaviors.Button
        sound = soundDefault
        onClick = @() openBPwindow()
        onHover
        children = [
          timeTracker
          dynamicSeasonBpBg([hdpxi(373), hdpxi(98)], sf & S_HOVER ? 1 : 0.7)
          mkWidgetInfo(sf)
          highlightLineTop
        ]
      })
}

console_register_command(@() openBPwindow(), "ui.battlepassWindow")

return mkBpWidgetOpen
