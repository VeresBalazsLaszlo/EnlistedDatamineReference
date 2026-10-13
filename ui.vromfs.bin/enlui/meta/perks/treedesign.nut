from "%ui/style/designConst.nut" import squadSlotBgIdleColor, positiveTxtColor, attentionTxtColor
from "%ui/ui_library.nut" import *

const darkColor = Color(49, 56, 65)
const lightColor = Color(250, 250, 250)
let treeBgColor = squadSlotBgIdleColor
const pointsBgColor = Color(64, 73, 85)
const inactiveColor = mul_color(lightColor, 0.4)

enum NodeElements {
  OUTER = 0
  INNER = 1
  ICON  = 2
  POINTS_BG = 3
  POINTS_BORDER = 4
  POINTS_TEXT = 5
}

enum NodeState {
  TIER_LOCKED = 0
  INACTIVE = 1
  UNLOCKED = 2
  FULL = 3
}

enum DiffState {
  NONE = 0
  UNAVAILABLE = 1
  PARTIAL = 2
  FULL = 3
}

let colors = {
  [NodeState.TIER_LOCKED] = @(_, isHover) {
    [NodeElements.OUTER] = isHover ? lightColor : treeBgColor,
    [NodeElements.INNER] = isHover ? lightColor : darkColor,
    [NodeElements.ICON] = isHover ? darkColor : treeBgColor,
    [NodeElements.POINTS_BG] = isHover ? lightColor : pointsBgColor,
    [NodeElements.POINTS_BORDER] = darkColor,
    [NodeElements.POINTS_TEXT] = isHover ? darkColor : lightColor
  },

  [NodeState.INACTIVE] = @(_, isHover) {
    [NodeElements.OUTER] = isHover ? lightColor : inactiveColor,
    [NodeElements.INNER] = isHover ? lightColor : darkColor,
    [NodeElements.ICON] = isHover ? darkColor : inactiveColor,
    [NodeElements.POINTS_BG] = isHover ? lightColor : pointsBgColor,
    [NodeElements.POINTS_BORDER] = darkColor,
    [NodeElements.POINTS_TEXT] = isHover ? darkColor : lightColor
  },

  [NodeState.UNLOCKED] = @(iconColor, isHover) {
    [NodeElements.OUTER] = lightColor,
    [NodeElements.INNER] = isHover ? iconColor : darkColor,
    [NodeElements.ICON] = isHover ? darkColor : iconColor,
    [NodeElements.POINTS_BG] = isHover ? iconColor : pointsBgColor,
    [NodeElements.POINTS_BORDER] = darkColor,
    [NodeElements.POINTS_TEXT] = isHover ? darkColor : lightColor
  },

  [NodeState.FULL] = @(iconColor, isHover) {
    [NodeElements.OUTER] = iconColor,
    [NodeElements.INNER] = isHover ? iconColor : darkColor,
    [NodeElements.ICON] = isHover ? darkColor : iconColor,
    [NodeElements.POINTS_BG] = isHover ? iconColor : pointsBgColor,
    [NodeElements.POINTS_BORDER] = isHover ? darkColor : iconColor,
    [NodeElements.POINTS_TEXT] = isHover ? darkColor : iconColor
  }
}

let diffColors = {
  [DiffState.FULL] = {
    [NodeElements.OUTER] = positiveTxtColor,
    [NodeElements.POINTS_BG] = positiveTxtColor,
    [NodeElements.POINTS_BORDER] = positiveTxtColor,
    [NodeElements.POINTS_TEXT] = darkColor
  },
  [DiffState.PARTIAL] = {
    [NodeElements.OUTER] = positiveTxtColor,
    [NodeElements.POINTS_BG] = attentionTxtColor,
    [NodeElements.POINTS_BORDER] = attentionTxtColor,
    [NodeElements.POINTS_TEXT] = darkColor
  },
  [DiffState.UNAVAILABLE] = {
    [NodeElements.OUTER] = attentionTxtColor,
    [NodeElements.POINTS_BG] = attentionTxtColor,
    [NodeElements.POINTS_BORDER] = attentionTxtColor,
    [NodeElements.POINTS_TEXT] = darkColor
  }
}



function getColorParams(isTierAvailable, hasUnlocked, hasAvailable, diffPoints) {

  let iconState = hasUnlocked == hasAvailable ? NodeState.FULL
    : hasUnlocked > 0 ? NodeState.UNLOCKED
    : !isTierAvailable ? NodeState.TIER_LOCKED
    : NodeState.INACTIVE

  let borderState = diffPoints == null ? DiffState.NONE
    : hasAvailable == 0 || diffPoints >= hasAvailable ? DiffState.FULL
    : diffPoints == 0 ? DiffState.UNAVAILABLE
    : DiffState.PARTIAL

  return {
    colorFn = colors[iconState]
    highlight = diffColors?[borderState] ?? {}
  }
}

function getColors(iconColor, isActive, colorParams) {
  let { colorFn, highlight } = colorParams
  return colorFn(iconColor, isActive).__update(highlight)
}

return {
  darkColor
  lightColor
  treeBgColor
  getColorParams
  getColors
  NodeElements
}
