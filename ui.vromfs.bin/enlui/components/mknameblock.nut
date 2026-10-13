import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/soldiers/model/armyEffects.nut" as armyEffects
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/cursors.nut" import withTooltip
from "%ui/soldiers/model/soldierPerks.nut" import perksData
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/components/soldiersUiComps.nut" import kindIcon, classIcon, levelBlock, experienceTooltip, classTooltip, mkSoldierMedalIcon, calcExperienceData
from "%ui/style/designConst.nut" import panelBgColor, gap, midPadding, msgHighlightedTxtColor, smallPadding, noteTxtColor, defTxtColor
from "%ui/components/itemsInfo.nut" import getObjectName
from "%ui/meta/perks/perksExp.nut" import perkLevelsGrid
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/soldiers/armySquadTier.nut" import getSoldierBR
from "%ui/components/battleRatingPkg.nut" import mkBattleRating
from "%ui/soldiers/components/perksPackage.nut" import possibleStatsForSoldier, maxedStatIcon
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/ui_library.nut" import *

let { pPointsList, pPointsBaseParams } = require("%ui/meta/perks/perksPoints.nut")


let hdrAnimations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic, trigger = "hdrAnim"}
  { prop = AnimProp.translate, from =[-hdpx(70), 0], to = [0, 0], duration = 0.15, easing = OutQuad, trigger = "hdrAnim"}
]

let mkClassBonus = @(classBonusWatch) function() {
  let res = { watch = classBonusWatch }
  let bonus = 100 * classBonusWatch.get()
  if (bonus == 0)
    return res
  return withTooltip(res.__update({
      rendObj = ROBJ_TEXT
      color = msgHighlightedTxtColor
      text = loc("bonusExp/short", { value = $"+{bonus}" })
    }, fontSub),
    @() loc("tooltip/soldierExpBonus"))
}

let callnameBlock = @(callname) {
  size = FLEX_H
  behavior = Behaviors.Marquee
  delay = 1
  speed = 50
  rendObj = ROBJ_TEXT
  text = callname
  color = noteTxtColor
}.__update(fontBody)

function nameField(soldierWatch) {
  return function(){
    let { callname = "" } = soldierWatch.get()
    return {
      flow = FLOW_HORIZONTAL
      watch = soldierWatch
      size = const [flex(2), SIZE_TO_CONTENT]
      gap
      children = [
        callname != "" ? callnameBlock(callname)
        : {
            size = FLEX_H
            key = "soldierName_big"
            rendObj = ROBJ_TEXT
            text = getObjectName(soldierWatch.get())
            color = noteTxtColor
          }.__update(fontBody)
      ]
    }
  }
}

let levelBlockWithProgress = @(soldierWatch, override = {}) function() {
  let watch = [soldierWatch, perkLevelsGrid]
  let { guid = null, level = 1, maxLevel = 1 } = soldierWatch.get()
  if (guid == null)
    return { watch }

  let levelData = calcExperienceData(soldierWatch.get(), perkLevelsGrid.get().expToLevel)
  let { exp, expToNextLevel } = levelData
  let expProgress = expToNextLevel > 0 ? 100.0 * exp / expToNextLevel : 0
  let isMaxed = maxLevel == level
  return withTooltip({
      watch
      key = guid
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap
      children = [
        levelBlock(level, maxLevel, hdpx(14))
          .__update({ minWidth = hdpx(120), halign = ALIGN_CENTER })
        isMaxed ? null : {
          size = const [FLEX, hdpx(5)]
          minWidth = hdpx(120)
          children = [
            { size = FLEX, rendObj = ROBJ_SOLID, color = Color(154, 158, 177) }
            { size = [pw(expProgress), FLEX], rendObj = ROBJ_SOLID,  color = Color(47, 137, 211) }
          ]
        }
      ]
    }.__update(override),
    @() experienceTooltip(levelData))
}

let mkSoldierNameSmall = @(soldier)
  (soldier?.callname ?? "") == "" ? null : {
    size = SIZE_TO_CONTENT
    key = "soldierName_small"
    rendObj = ROBJ_TEXT
    text = getObjectName(soldier)
    color = defTxtColor
    padding = [0, smallPadding * 2]
  }.__update(fontSub)


const iconSize = hdpxi(26)
const medalSize = hdpxi(24)
let maxedStatComp = maxedStatIcon(defTxtColor)
  .__update({ vplace = ALIGN_TOP, pos = const [0, hdpxi(4)]})

function mkNameBlock(soldierWatch) {
  let perksWatch = Computed(@() perksData.get()?[soldierWatch.get()?.guid])
  let classBonusWatch = Computed(function() {
    let soldierV = soldierWatch.get()
    if (soldierV == null)
      return 0

    let { sClass, isHero = false } = soldierV
    let { heroExpBonus = 0.0 } = gameProfile.get()
    let soldierArmyId = getLinkedArmyName(soldierV)
    return (armyEffects.get()?[soldierArmyId].class_xp_boost[sClass] ?? 0.0)
      + (isHero ? heroExpBonus : 0.0)
  })
  return function() {
    let { armyId = null, sClass = null, sKind = null, hasMaxStats = false, locPerkPoints = null
      } = soldierWatch.get()
    let medal = mkSoldierMedalIcon(soldierWatch.get(), medalSize)
    let isPremium = getClassCfg(sClass)?.isPremium ?? false
    let classTooltipCb = @() classTooltip(armyId, sClass, sKind,
      mkBattleRating(getSoldierBR(soldierWatch.get()?.guid)), locPerkPoints)

    function perkPointsUi() {
      let watch = [perksList, perksWatch, sClassesCfg]
      if (perksWatch.get() == null)
        return { watch }

      let { points = {}, sTier = 1 } = perksWatch.get()
      local maxedStats = {}
      if (!hasMaxStats) {
        let possibleStats = possibleStatsForSoldier(sClass, sTier, hasMaxStats, sClassesCfg.get())
        foreach(statId, value in points) {
          if (value == (possibleStats?[statId].maxVal ?? 0))
            maxedStats[statId] <- true
        }
      }
      return {
        watch
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        margin = [0,0,0,midPadding]
        children = pPointsList.map(function(statId) {
          let { icon } = pPointsBaseParams[statId]
          let totalPoints = points?[statId] ?? 0

          return {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_TEXT
                color = defTxtColor
                text = totalPoints
              }.__update(fontSub)
              hasMaxStats || (statId in maxedStats) ? maxedStatComp : null
              {
                rendObj = ROBJ_IMAGE
                size = [iconSize, iconSize]
                image = Picture("{0}:{1}:{1}".subst(icon, iconSize))
                color = defTxtColor
              }
            ]
          }
        })
      }
    }

    return {
      watch = soldierWatch
      size = const [FLEX, hdpx(70)]
      animations = hdrAnimations
      transform = true
      rendObj = ROBJ_SOLID
      color = panelBgColor
      children = [
        isPremium ? classIcon(armyId, sClass, iconSize) : null
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          padding = [0, midPadding]
          children = [
            {
              size = FLEX
              flow = FLOW_VERTICAL
              children = [
                {
                  size = const [FLEX, ph(40)]
                  flow = FLOW_HORIZONTAL
                  gap
                  padding = [0, 0, 0, isPremium ? iconSize : 0]
                  valign = ALIGN_CENTER
                  children = [
                    withTooltip(kindIcon(sKind, medalSize), classTooltipCb)
                    perkPointsUi
                    mkSoldierNameSmall(soldierWatch.get())
                  ]
                }
                {
                  size = FLEX
                  flow = FLOW_HORIZONTAL
                  gap
                  valign = ALIGN_CENTER
                  children = [
                    isPremium ? null : classIcon(armyId, sClass, hdpx(30))
                    nameField(soldierWatch)
                    medal == null ? null : withTooltip(medal, @() loc("hero/medal"))
                  ]
                }
              ]
            }
            {
              size = FLEX_V
              flow = FLOW_VERTICAL
              halign = ALIGN_RIGHT
              children = [
                {
                  size = const [SIZE_TO_CONTENT, ph(40)]
                  valign = ALIGN_CENTER
                  children = mkClassBonus(classBonusWatch)
                }
                {
                  size = FLEX_V
                  valign = ALIGN_CENTER
                  children = levelBlockWithProgress(soldierWatch)
                }
              ]
            }
          ]
        }
      ]
    }
  }
}

return mkNameBlock