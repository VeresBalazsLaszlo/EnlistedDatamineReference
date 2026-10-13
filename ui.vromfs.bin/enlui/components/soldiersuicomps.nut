import "%ui/components/fontawesome.map.nut" as fa
import "%ui/components/soldiersPresentation.nut" as soldiersPresentation
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/colorize.nut" as colorize
from "%ui/style/fontsStyle.nut" import fontBody, fontawesome
from "%ui/style/designConst.nut" import gap, bigGap, defTxtColor, soldierLockedLvlColor, msgHighlightedTxtColor
from "%ui/components/soldierClasses.nut" import getClassCfg, getKindCfg
from "%ui/components/blinkingIcon.nut" import blinkingIcon
from "%ui/components/defcomps.nut" import txt, note
from "%ui/soldiers/model/config/soldierResideConfig.nut" import soldierResideCountry
from "%ui/ui_library.nut" import *

const PERK_ALERT_SIGN = "caret-square-o-up"
const ITEM_ALERT_SIGN = "dropbox"
const UPGRADE_ALERT_SIGN = "angle-double-up"

const iconSize = hdpxi(26)

let formatIconName = memoize(function(icon, width, height = null) {
  if (icon.endswith(".svg")) {
    log("getting svg icon for soldiers")
    return $"{icon}:{width.tointeger()}:{(height ?? width).tointeger()}"
  }
  return $"{icon}?Ac"
})

let mkAlertIcon = @(icon, unseenWatch = Watched(true), hasBlink = false)
  function() {
    let res = { watch = unseenWatch }
    return !unseenWatch.get() ? res
      : res.__update(blinkingIcon(icon), hasBlink ? {} : { animations = null })
  }

let mkLevelIcon = @(fontSize = hdpx(10), color = msgHighlightedTxtColor, fName = "star") {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
  text = fa[fName]
  font = fontawesome.font
  fontSize
  color
}

let mkIconBar = @(level, color, fontSize, fName = "star-o", hasBlink = false) level > 0
  ? mkLevelIcon(fontSize, color, fName).__update({
      key = $"l{level}fnm{fName}b{hasBlink}"
      text = "".join(array(level, fa[fName]))
      color
      animations = hasBlink
        ? [ { prop = AnimProp.opacity, from = 0.5, to = 1, duration = 0.7, play = true, loop = true, easing = Blink} ]
        : null
    })
  : null

let mkHiddenAnim = @(p = {})
  { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }.__update(p)

function mkAnimatedLevelIcon(guid, color, fontSize) {
    let trigger = $"{guid}lvl_anim"
    return {
      children = [
        mkLevelIcon(fontSize, color, "star-o")
        mkLevelIcon(fontSize, color, "star").__update({
          transform = true
          animations = [
            mkHiddenAnim({ duration = 0.9, play = false, trigger })
            { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
              easing = InOutCubic, delay = 0.8, trigger }
            { prop = AnimProp.scale, from = [3,3], to = [1,1], duration = 0.8,
              easing = InOutCubic, delay = 0.8, trigger }
          ]
        })
      ]
    }
  }

function levelBlock(level = 1, maxLevel = 1, fontSize = hdpx(12)) {
  return {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = [
      mkIconBar(level, msgHighlightedTxtColor, fontSize, "star")
      mkIconBar(max(maxLevel - level, 0), soldierLockedLvlColor, fontSize)
    ]
    animations = [ mkHiddenAnim() ]
  }
}

let mkUnknownClassIcon = @(iSize) {
  rendObj = ROBJ_TEXT
  size = [iSize.tointeger(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = "?"
  color = defTxtColor
}.__update(fontBody)

let getKindIcon = memoize(@(img, sz) Picture("ui/skin#{0}:{1}:{1}".subst(img, sz.tointeger())))
let getClassIcon = memoize(@(img, sz) Picture("{0}:{1}:{1}".subst(img, sz.tointeger())))

function kindIcon(sKind, iSize, forceColor = null) {
  if (sKind == null)
    return mkUnknownClassIcon(iSize)

  let { icon = "" } = getKindCfg(sKind)
  if (icon == "")
    return mkUnknownClassIcon(iSize)

  let sClassColor = forceColor ?? defTxtColor
  return {
    rendObj = ROBJ_IMAGE
    size = [iSize, iSize]
    color = sClassColor
    image = getKindIcon(icon, iSize)
  }
}

function classIcon(armyId, sClass, iSize, override = {}) {
  let { getIcon } = getClassCfg(sClass)
  let icon = getIcon(armyId) ?? ""
  if (icon == "")
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [iSize, iSize]
    keepAspect = KEEP_ASPECT_FIT
    image = getClassIcon(icon, iSize)
  }.__update(override)
}

let kindName = @(sKind) note({
  text = loc(getKindCfg(sKind).locId)
  vplace = ALIGN_CENTER
  color = defTxtColor
})

function className(sClass, count = 0) {
  let classTxt = loc(getClassCfg(sClass).locId)
  return note({
    text = count <= 1 ? classTxt : $"{classTxt} {loc("common/amountShort", { count })}"
    vplace = ALIGN_CENTER
    color = defTxtColor
  })
}

function calcExperienceData(soldier, expToLevel) {
  let { level = 1, maxLevel = 1, exp = 0 } = soldier
  let expToNextLevel = level < maxLevel ? (expToLevel?[level] ?? 0) : 0
  return { level, maxLevel, exp, expToNextLevel }
}

function classTooltip(armyId, sClass, sKind, tierMapsHint = null,
  locPerkPoints = null
) {
  let classCfg = getClassCfg(sClass)
  return tooltipCtor({
    flow = FLOW_VERTICAL
    size = const [hdpx(500), SIZE_TO_CONTENT]
    gap = bigGap
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = gap
        children = [
          kindIcon(sKind, iconSize)
          classIcon(armyId, sClass, iconSize)
          txt(loc(classCfg.locId))
        ]
      }
      !locPerkPoints ? null : {
        rendObj = ROBJ_TEXTAREA
        size = FLEX_H
        text = locPerkPoints
        color = defTxtColor
        behavior = Behaviors.TextArea
      }
      tierMapsHint
    ]
  })
}

let experienceTooltip = kwarg(@(level, maxLevel, exp, expToNextLevel)
  loc(level < maxLevel ? "hint/soldierLevel" : "hint/soldierMaxLevel", {
    level = colorize(msgHighlightedTxtColor, level)
    maxLevel
    exp = colorize(msgHighlightedTxtColor, exp)
    expToNextLevel
  })
)

function mkMedalIcon(country, size) {
  let heroIcon = soldiersPresentation?[country]
  return heroIcon == null ? null
    : {
        rendObj = ROBJ_IMAGE
        size = [size, size]
        image = Picture(formatIconName(heroIcon, size))
        keepAspect = KEEP_ASPECT_FIT
      }
}

function mkSoldierMedalIcon(soldierInfo, size) {
  let { basetpl = null, isHero = false } = soldierInfo
  if (!isHero || !basetpl)
    return null

  let country = soldierResideCountry.get()?[basetpl]
  return mkMedalIcon(country, size)
}

return freeze({
  mkAlertIcon
  levelBlock
  kindIcon
  kindName
  classIcon
  className
  calcExperienceData
  classTooltip
  experienceTooltip
  mkLevelIcon
  mkMedalIcon
  mkSoldierMedalIcon
  mkIconBar
  mkAnimatedLevelIcon
  mkHiddenAnim

  PERK_ALERT_SIGN
  ITEM_ALERT_SIGN
  UPGRADE_ALERT_SIGN
})
