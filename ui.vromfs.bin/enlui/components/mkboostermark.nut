import "%ui/profile/profileScene.nut" as profileScene
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import titleTxtColor, selectedTxtColor, attentionTxtColor, positiveTxtColor, smallPadding, midPadding, largePadding, mkTimerIcon
from "math" import round
from "%ui/ui_library.nut" import *

let boosterTxtColor = selectedTxtColor
const markColor = Color(68, 121, 100)
const hoverColor = Color(80, 160, 120)
let boosterIconSize = [hdpxi(30), hdpxi(35)]

let mkBoosterIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = boosterIconSize
  keepAspect = KEEP_ASPECT_FIT
  image = Picture("ui/skin#booster_icon.svg:{0}:{1}"
    .subst(boosterIconSize[0], boosterIconSize[1]))
  color
}

let mkPenaltyIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = boosterIconSize
  keepAspect = KEEP_ASPECT_FIT
  image = Picture("ui/skin#xp_down_icon.svg:{0}:{1}"
    .subst(boosterIconSize[0], boosterIconSize[1]))
  color
}

let boosterBack = @(tint = null) {
  rendObj = ROBJ_9RECT
  size = FLEX
  texOffs = [5, 15, 10, 5]
  screenOffs = [5, 15, 10, 5]
  image = Picture($"ui/skin#booster_bg.svg?Ac")
  tint
}

function mkBoosterText(expMul, expPenalty) {
  let boosterVal = round(((expMul + 1.0) * (expPenalty + 1.0) - 1.0) * 100)
  let text = boosterVal > 0
      ? $"+{boosterVal}%"
      : $"{boosterVal}%"

  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = boosterTxtColor
    text
  }.__update(fontSub)
}

let mkInfoText = @(text) "" == (text ?? "") ? null
  : {
      rendObj = ROBJ_TEXT
      color = boosterTxtColor
      text
    }.__update(fontSub)

function mkBoosterMark(expMul, expPenalty = 0.0, infoText = null, override = {}) {
  let isPenalty = (expMul + 1.0) * (expPenalty + 1.0) < 1.0
  let boosterIconCtor = isPenalty ? mkPenaltyIcon : mkBoosterIcon
  let color = expPenalty < 0 ? attentionTxtColor : positiveTxtColor
  return watchElemState(@(sf) {
    behavior = Behaviors.Button
    onClick = @() profileScene("boosters")
    eventPassThrough = false
    children = [
      boosterBack(sf & S_HOVER ? hoverColor : markColor)
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        padding = [midPadding, largePadding, midPadding, smallPadding]
        children = [
          boosterIconCtor(sf & S_HOVER ? titleTxtColor : color)
          {
            gap = smallPadding
            flow = FLOW_HORIZONTAL
            children = [
              mkBoosterText(expMul, expPenalty)
              mkInfoText(infoText)
            ]
          }
        ]
      }
    ]
  }.__update(override))
}

let mkBoostersEmpty = @(indicator = false) watchElemState(function(sf) {
  let color = sf & S_HOVER ? titleTxtColor : boosterTxtColor
  return {
    size = const [SIZE_TO_CONTENT, hdpxi(60)]
    behavior = Behaviors.Button
    onClick = @() profileScene("boosters")
    eventPassThrough = false
    children = [
      boosterBack(sf & S_HOVER ? hoverColor : markColor)
      {
        flow = FLOW_HORIZONTAL
        padding = midPadding
        children = [
          mkBoosterIcon(color)
          indicator
            ? mkTimerIcon(hdpxi(13), { color, margin = [midPadding, smallPadding] })
            : null
        ]
      }
    ]
  }
})

return {
  mkBoosterMark
  mkBoostersEmpty
}
