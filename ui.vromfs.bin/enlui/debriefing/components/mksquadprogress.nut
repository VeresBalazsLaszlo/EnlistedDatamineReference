import "%ui/components/battleHeroAwardIcon.nut" as mkBattleHeroAwardIcon
from "%enlSqGlob/battleHeroesAwards.nut" import combineMultispecialistAward
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/cursors.nut" import setTooltip, withTooltip
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/defcomps.nut" import progressBar
from "%ui/components/squadsUiComps.nut" import mkSquadIcon, mkSquadSpecIconFields, isSquadPremium
from "%ui/style/designConst.nut" import gap, slotBaseSize, soldierLvlColor, smallPadding, activeTxtColor, defTxtColor
from "%ui/debriefing/components/mkExpTooltipText.nut" import mkSquadExpTooltipText
from "%ui/ui_library.nut" import *

const trigger = "content_anim"

const TIME_TO_NEXT_SQUAD = 0.5
const UNLOCK_ADD_EXP_TIME = 1.0

let squadCardSize = [slotBaseSize[0], hdpx(136)]
let heroAwardSize = [hdpxi(50), hdpxi(50)]

let colon = loc("ui/colon")

let squadIconStyle = {
  size = hdpx(77)
  margin = const [hdpx(3), 0, 0, 0]
}

let squadStatsCfg = [
  { stat = "awardScore", locId = "debriefing/score"},
].map(@(s) { toString = @(v) v.tostring() }.__update(s))

function mkSquadTooltipText(squad, result) {
  let textList = squadStatsCfg.map(@(s)
    "".concat(loc(s.locId), colon, s.toString(squad?[s.stat] ?? s?.defaultValue ?? 0)))
  let expText = mkSquadExpTooltipText(squad, result)
  if (expText != null)
    textList.append(expText)
  return "\n".join(textList)
}

let mkAwards = @(awards) combineMultispecialistAward(awards).map(@(award)
  withTooltip(mkBattleHeroAwardIcon(award, heroAwardSize).__update({
    size = [pw(100.0 / awards.len()), heroAwardSize[1]] }),
    @() loc($"debriefing/award_{award?.id ?? award}")))

let mkShowAnim = @(duration) [{
  prop = AnimProp.opacity, from = 1, to = 1, duration,
  play = true, easing = InOutCubic, trigger
}]

let mkHideAnim = @(duration) [{
  prop = AnimProp.opacity, from = 0, to = 0, duration,
  play = true, easing = InOutCubic, trigger
}]

let mkProgressAnim = @(animDelay) [
  { prop = AnimProp.scale, from = [0, 1], to = [0, 1], play = true,
    duration = animDelay, trigger }
  { prop = AnimProp.scale, from = [0, 1], to = [1, 1], play = true,
    duration = UNLOCK_ADD_EXP_TIME, easing = OutCubic, delay = animDelay, trigger }
]

function mkProgress(wasLevel, wasExp, addExp, toLevelExp, squad, result, awards, mkAppearAnimations, animDelay) {
  let isNewLevel = wasExp + addExp >= toLevelExp
  let isMaxLevel = toLevelExp == 0
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on ? mkSquadTooltipText(squad, result) : null)
    children = [
      {
        size = FLEX_H
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
         isNewLevel && !isMaxLevel
            ? {
                rendObj = ROBJ_TEXT
                color = soldierLvlColor
                text = loc("debriefing/new_level")
                transform = true
                animations = mkAppearAnimations(animDelay + UNLOCK_ADD_EXP_TIME, function() {
                  sound_play("ui/debriefing/squad_progression_appear")
                })
              }.__update(fontSub)
            : isMaxLevel
            ? {
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                size = FLEX_H
                halign = ALIGN_CENTER
                color = soldierLvlColor
                transform = true
                text = loc("debriefing/max_level")
                animations = mkAppearAnimations(animDelay + UNLOCK_ADD_EXP_TIME, function() {
                  sound_play("ui/debriefing/squad_progression_appear")
                })
              }.__update(fontSub)
            : {
                rendObj = ROBJ_TEXT
                color = defTxtColor
                text = loc("levelInfo", { level = wasLevel + 1 })
                opacity = isNewLevel ? 0 : 1
                animations = isNewLevel ? mkShowAnim(animDelay + UNLOCK_ADD_EXP_TIME - 0.1) : null
              }.__update(fontSub)
        ]
      }
      {
        size = FLEX_H
        children = [
          progressBar({
            value = toLevelExp > 0 ? wasExp.tofloat() / toLevelExp : 0
            addValue = toLevelExp > 0 ? addExp.tofloat() / toLevelExp : 0
            color = Color(150,150,150)
            addValueAnimations = mkProgressAnim(animDelay)
          })
          isNewLevel
            ? {
                rendObj = ROBJ_SOLID
                size = FLEX
                margin = [smallPadding, 0]
                color = soldierLvlColor
                animations = mkHideAnim(animDelay + UNLOCK_ADD_EXP_TIME)
              }
            : null
        ]
      }
      {
        size = FLEX_H
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = mkAwards(awards)
      }
    ]
  }
}

let SQUAD_CARD_PARAMS = {
  squad = null
  awards = []
  animDelay = 0
  armyId = ""
  result = {}
  mkAppearAnimations = @(_delay) null
  onFinishCb = null
}

function mkSquadProgress(p = SQUAD_CARD_PARAMS) {
  p = SQUAD_CARD_PARAMS.__merge(p)

  let res = { content = null, duration = 0 }
  let { armyId, squad = null } = p
  if (squad == null)
    return res

  let { squadId, animDelay } = p
  let {
    wasLevel = 1, wasExp = 0, exp = 0, toLevelExp = 0, icon = null, nameLocId = null
  } = squad
  let hasNewLevel = wasExp + exp >= toLevelExp
  return {
    content = {
      size = squadCardSize
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = gap
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(on ? mkSquadTooltipText(squad, p.result) : null)
      children = {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = gap
        children = [
          {
            transform = true
            animations = p.mkAppearAnimations(animDelay, @() sound_play("ui/debriefing/new_equip"))
            children = [
              mkSquadIcon(icon, squadIconStyle)
              mkSquadSpecIconFields(armyId, squadId, isSquadPremium(squad))
            ]
          }
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              {
                clipChildren = true
                size = const [FLEX, hdpx(40)]
                children = {
                  delay = [3, 2]
                  speed = hdpx(16)
                  behavior = Behaviors.Marquee
                  orientation = O_VERTICAL
                  size = FLEX
                  children = {
                    rendObj = ROBJ_TEXTAREA
                    halign = ALIGN_CENTER
                    behavior = Behaviors.TextArea
                    size = FLEX_H
                    color = activeTxtColor
                    text = loc(nameLocId)
                    transform = true
                    animations = p.mkAppearAnimations(animDelay + 0.1, p.onFinishCb)
                  }.__update(fontSub)
                }
              }
              mkProgress(wasLevel, wasExp, exp, toLevelExp, squad, p.result, p.awards,
                p.mkAppearAnimations, animDelay)
            ]
          }
        ]
      }
    }
    duration = TIME_TO_NEXT_SQUAD + (hasNewLevel ? UNLOCK_ADD_EXP_TIME : 0)
  }
}

return mkSquadProgress
