import "%sqstd/math.nut" as math
import "%ui/style/colors.nut" as colors
import "%ui/components/fontawesome.map.nut" as fa
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/colorize.nut" as colorize
from "%ui/style/fontsStyle.nut" import fontSub, fontawesome
from "dagor.localize" import doesLocTextExist
from "%ui/style/cursors.nut" import setTooltip
from "%ui/style/designConst.nut" import smallPadding, midPadding, defTxtColor, msgHighlightedTxtColor
from "%ui/meta/servProfile.nut" import soldierPerks
from "%ui/meta/perks/perkTreePkg.nut" import MAX_LEVEL
from "%ui/meta/perks/perksStats.nut" import perksStatsCfg
from "%ui/meta/perks/perksSchemesConfig.nut" import perkSchemes, soldierSchemes
from "%ui/ui_library.nut" import *

let { pPointsBaseParams, pPointsList } = require("%ui/meta/perks/perksPoints.nut")

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(fontSub)

let flexTextArea = @(params) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
}.__update(fontSub, params)


let perkPointIcon = @(icon, color = defTxtColor, pPointSize = hdpxi(32)) {
  rendObj = ROBJ_IMAGE
  size = [pPointSize, pPointSize]
  image = Picture("{0}:{1}:{1}".subst(icon, pPointSize))
  color
}

let maxedStatIcon = @(color, fontSize = hdpxi(8)) {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
  text = fa["star"]
  font = fontawesome.font
  color
  fontSize
}

let maxStatAnimation = {
  transform = { scale = [0.25, 0.25], pivot = [0.5, 0.5] }
  animations = [{
      prop = AnimProp.scale, from = [0.25, 0.25], to = [1.0, 1.0],
      duration = 0.7, delay = 0.2, play = true, easing = CosineFull
    }]
  }

function getRecommendedPerks(perksId, armyId) {
  let perkSchemeId = soldierSchemes.get()?[armyId][perksId].perkSchemeId
  return perkSchemes.get()?[perkSchemeId][1].perks ?? []
}

function getRecommendedPerksCount(perksId, armyId) {
  let perksListVal = perksList.get()
  let perks = getRecommendedPerks(perksId, armyId)
  local count = 0
  foreach (perkId in perks)
    count += perksListVal?[perkId].stats.len() ?? 0
  return count
}

function getStatDescList(perkStatsTable, perk, isUnavailable = false) {
  let res = []
  let { stats = {} } = perk
  foreach (statId, statValue in stats) {
    let locId = $"stat/{statId}/desc"
    if (!doesLocTextExist(locId))
      continue
    let value = statValue * (perkStatsTable?[statId].base_power ?? 0.0)
    let statValueText = math.round_by_value(value, 0.1)
    res.append(loc(locId, {
      value = isUnavailable ? statValueText : colorize(colors.MsgMarkedText, statValueText)
    }))
  }
  return res
}

function getStatDescFull(perksId, armyId) {
  let perksStatsVal = perksStatsCfg.get()
  let perksListVal = perksList.get()
  let perks = getRecommendedPerks(perksId, armyId)
  let res = []
  foreach (perkId in perks) {
    let perkData = perksListVal?[perkId]
    let desc = perkData ? getStatDescList(perksStatsVal, perkData) : []
    res.extend(desc)
  }
  return (",\n").join(res)
}

let withSign = @(val) val > 0 ? $"+{val}" : val

function getSoldierClassPerksPoints(key) {
  let statList = []
  let { perkPointsModifications = null } = sClassesCfg.get()?[key]
  let { vitality = 0, weapon = 0, speed = 0 } = perkPointsModifications?[0] ?? perkPointsModifications 

  if (speed != 0)
    statList.append(loc("soldierClass/speed", { speed = withSign(speed) }))
  if (vitality != 0)
    statList.append(loc("soldierClass/vitality", { vitality = withSign(vitality) }))
  if (weapon != 0)
    statList.append(loc("soldierClass/weapon", { weapon = withSign(weapon) }))

  if (statList.len() == 0)
    return loc("soldierClass/noPerkPoints")

  let list = ", ".join(statList)
  return loc("soldierClass/perkPoints", { list })
}

let perkPointsInfoTooltip = {
  size = const [hdpx(400), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkText(loc("perkPointsTitle")).__update({ color = msgHighlightedTxtColor })
    flexTextArea({ text = loc("perkPointsDesc") })
  ]
}


function getPossibleStats(content, sClassesCfgVal) {
  let { soldierTierMax, soldierTierMin, soldierHasMaxStats, soldierClasses } = content
  let [ valSoldierClasses ] = soldierClasses
  let { pointsByTiers = [], perkPointsModifications = null } = sClassesCfgVal?[valSoldierClasses]

  let stats = {}
  let statsMax = pointsByTiers[min(soldierTierMax, pointsByTiers.len() - 1)]
  let rareModifications = perkPointsModifications?[0] ?? perkPointsModifications 
  foreach (statId in pPointsList) {
    let maxVal = statsMax[statId].max
      + (rareModifications?[statId] ?? 0)
    stats[statId] <- {
      maxVal
      minVal = soldierHasMaxStats ? maxVal
        : pointsByTiers[soldierTierMin][statId].min +
          (rareModifications?[statId] ?? 0)
    }
  }
  return stats
}

function possibleStatsForSoldier(sClass, sTier, hasMaxStats, sClassesCfgVal) {
  let tier = min(sTier, MAX_LEVEL)
  let soldierParams = {
    soldierClasses = [sClass]
    soldierTierMax = tier
    soldierTierMin = tier
    soldierHasMaxStats = hasMaxStats
  }
  return getPossibleStats(soldierParams, sClassesCfgVal)
}

function mkPerksPointsBlock(soldier) {
  if (soldier?.guid == null)
    return null

  return function() {
    let res = { watch = [soldierPerks, sClassesCfg] }

    let { points = {}, sTier = 0 } = soldierPerks.get()?[soldier.guid] ?? {}
    if (points.len() == 0)
      return res

    let { sClass, hasMaxStats } = soldier
    let statsForSoldier = possibleStatsForSoldier(sClass, sTier, hasMaxStats, sClassesCfg.get())

    let children = []
    foreach (pPointId in pPointsList) {
      let value = points[pPointId]
      let { icon, color } = pPointsBaseParams[pPointId]
      let maxedIcon = (statsForSoldier?[pPointId].maxVal ?? 0) != value ? null
        : {
            vplace = ALIGN_TOP
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            pos = [smallPadding, midPadding]
            size = hdpxi(8)
            children = maxedStatIcon(color, hdpx(32)).__update(maxStatAnimation)
          } 

      children.append(
        {
          rendObj = ROBJ_TEXT
          text = value
          color
        },
        maxedIcon,
        perkPointIcon(icon, color)
      )
    }

    return res.__update({
      behavior = Behaviors.Button
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      onHover = @(on) setTooltip(on ? tooltipCtor(perkPointsInfoTooltip) : null)
      skipDirPadNav = true
      children
    })
  }
}

function hasStatsMaxed(soldier) {
  if (soldier?.itemtype != "soldier" || soldier?.guid == null)
    return false

  let { points = {}, sTier = 0 } = soldierPerks.get()?[soldier.guid] ?? {}
  if (points.len() == 0)
    return false

  let { sClass, hasMaxStats } = soldier
  let statsForSoldier = possibleStatsForSoldier(sClass, sTier, hasMaxStats, sClassesCfg.get())

  foreach (pPointId, value in points) {
    if (value != (statsForSoldier?[pPointId].maxVal ?? 0))
      return false
  }
  return true
}

function statsRange(statsTable, stat, isLocked) {
  let { icon, color } = pPointsBaseParams[stat]
  let { minVal, maxVal } = statsTable[stat]
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      perkPointIcon(icon, isLocked ? defTxtColor : color)
      {
        rendObj = ROBJ_TEXT
        color = defTxtColor
        text = minVal == maxVal ? maxVal : $"{minVal}-{maxVal}"
      }
    ]
  }
}

function mkStatList(content, sClassesCfgVal, isLocked = false) {
  let stats = getPossibleStats(content, sClassesCfgVal)
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_LEFT
    size = const [SIZE_TO_CONTENT, hdpx(32)]
    gap = midPadding
    children = pPointsList.map(@(x) statsRange(stats, x, isLocked))
  }
}

return {
  flexTextArea
  getStatDescList
  perkPointIcon
  mkPerksPointsBlock
  mkStatList
  possibleStatsForSoldier
  maxedStatIcon
  hasStatsMaxed
  getSoldierClassPerksPoints
  getStatDescFull
  getRecommendedPerksCount
}
