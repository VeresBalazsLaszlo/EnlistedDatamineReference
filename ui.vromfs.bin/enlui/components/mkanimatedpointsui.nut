from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG
from "%sqstd/math.nut" import abs
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import smallPadding
from "%ui/ui_library.nut" import *

let mkText = @(txt, override = {}) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(fontBody, override)


let mkScoreAnimations = @(trigger) [
  { prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3],
    duration = 0.5, easing = Blink, trigger }
  { prop = AnimProp.opacity, from = 1, to = 0.7,
    duration = 0.5, easing = Blink, trigger }
]

let mkScoreDeltaAnim = @(onFinishScoreAnim, dir) [
  { prop = AnimProp.translate, from = [-hdpx(90) * dir, 0], to = [-hdpx(90) * dir, 0],
    duration = 0.7, play = true }
  { prop = AnimProp.scale, from = [1, 1], to = [1.8, 1.8],
    duration = 0.5, play = true, easing = Blink }
  { prop = AnimProp.opacity, from = 0.3, to = 1,
    duration = 0.2, play = true }
  { prop = AnimProp.translate, from = [-hdpx(90) * dir, 0], to = [-hdpx(30) * dir, 0], delay = 0.7,
    duration = 0.2, play = true, onFinish = onFinishScoreAnim }
]


let mkScoreIcon = @(iconPath, color, iconSize) {
  rendObj = ROBJ_IMAGE
  image = Picture("{0}:{1}:{1}".subst(iconPath, iconSize))
  color
  size = [iconSize, iconSize]
}


let mkScoreDeltaAnimUi = @(iconPath, isMyTeamAttacking, attackerScore, scoreAnimStack,
  scoreAnimData, onFinishScoreAnim, dir
) function() {
    let nextScoreValue = scoreAnimStack.get()?[0] ?? attackerScore.get()
    let scoreDelta = scoreAnimData.lastValue == null ? 0 : nextScoreValue - scoreAnimData.lastValue
    if (scoreAnimData.lastValue == null)
      onFinishScoreAnim()

    let watch = [isMyTeamAttacking, attackerScore, scoreAnimStack]
    if (scoreDelta == 0)
      return { watch }

    scoreAnimData.animIdx++
    let color = (scoreDelta < 0) == isMyTeamAttacking.get() ? TEAM1_COLOR_FG : TEAM0_COLOR_FG
    let signObj = mkText(scoreDelta < 0 ? "-" : "+", { color })
    return {
      watch
      size = FLEX_V
      valign = ALIGN_CENTER
      children = {
        key = $"play_score_anim_{scoreAnimData.animIdx}"
        flow = FLOW_HORIZONTAL
        gap = hdpxi(2)
        valign = ALIGN_CENTER
        children = [
          signObj
          mkScoreIcon(iconPath, color, hdpxi(18))
          mkText($"{abs(scoreDelta)}", { color }.__update(fontSub))
        ]
        transform = { pivot = [0.5, 0.5] }
        animations = mkScoreDeltaAnim(onFinishScoreAnim, dir)
      }
    }
  }


return function(id, iconPath, isMyTeamAttacking, attackerScore, dir = 1) {
  let scoreAnimData = {
    lastValue = null
    animIdx = 0
  }
  let scoreAnimStack = Watched([])

  function onFinishScoreAnim() {
    scoreAnimData.lastValue = scoreAnimStack.get()?[0] ?? attackerScore.get()
    if (scoreAnimStack.get().len() > 0)
      scoreAnimStack.mutate(@(v) v.remove(0))
  }

  attackerScore.subscribe(function(val) {
    if (scoreAnimStack.get().len() <= 1)
      scoreAnimStack.mutate(@(v) v.append(val))
    else
      scoreAnimStack.mutate(@(v) v[v.len() - 1] = val)
  })

  let scoreDeltaAnim = mkScoreDeltaAnimUi(iconPath, isMyTeamAttacking, attackerScore,
    scoreAnimStack, scoreAnimData, onFinishScoreAnim, dir)
  let animations = mkScoreAnimations(id)

  return function() {
    let color = isMyTeamAttacking.get() ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    return {
      watch = isMyTeamAttacking
      valign = ALIGN_CENTER
      children = [
        scoreDeltaAnim
        function() {
          let scoreVal = scoreAnimStack.get().len() == 0
            ? attackerScore.get()
            : scoreAnimData.lastValue ?? attackerScore.get()
          return {
            watch = [attackerScore, scoreAnimStack]
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = smallPadding
            children = [
              mkScoreIcon(iconPath, color, hdpxi(24))
              mkText(scoreVal, { color })
            ]
            transform = { pivot = [0.2, 0.5] }
            animations
          }
        }
      ]
    }
  }
}
