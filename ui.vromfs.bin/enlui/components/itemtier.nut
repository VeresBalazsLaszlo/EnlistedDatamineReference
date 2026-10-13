import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontawesome
from "%ui/style/designConst.nut" import soldierLvlColor, soldierLockedLvlColor
from "%ui/ui_library.nut" import *

const DEFAULT_PREMIUM_LEVEL = 3

let tagStars = {
  act = { color = soldierLvlColor, font = Fonts.fontawesome }
  dis = { color = soldierLockedLvlColor, font = Fonts.fontawesome }
}

let mkIconBar = @(count, color, fName, params = {}) count < 1 ? null : {
    rendObj = ROBJ_INSCRIPTION
    validateStaticText = false
    text = "".join(array(count, fa[fName]))
    font = fontawesome.font
    fontSize = hdpx(10)
    color
  }.__update(params)

let mkItemTier = @(item, itemLevelData = null, mkBg = @(v) v) function() {
  let { upgradeIdx = 0, sign = 0 } = item
  local { upgradeMax = upgradeIdx, isUpgradable = false } = isObservable(itemLevelData)
    ? itemLevelData.get()
    : itemLevelData
  local stars = upgradeIdx
  if (sign != 0 && upgradeMax == 0) {
    stars = DEFAULT_PREMIUM_LEVEL
    upgradeMax = stars
  }
  let upgradesPending = isUpgradable ? 1 : 0
  let upgradesLeft = upgradeMax - stars - upgradesPending
  let watch = itemLevelData
  return upgradeMax < 1 ? { watch }
    : mkBg({
        watch
        children = {
          hplace = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          children = [
            mkIconBar(stars, soldierLvlColor, "star")
            mkIconBar(upgradesPending, soldierLvlColor, "star-o")
            mkIconBar(upgradesLeft, soldierLockedLvlColor, "star-o")
          ]
        }
      })
}

let mkTierStars = @(count, params = {}) mkIconBar(count, soldierLvlColor, "star", params)

let mkZeroStars = @(count, params = {}) count <= 0
  ? mkIconBar(1, soldierLockedLvlColor, "star-o", params)
  : mkIconBar(count, soldierLvlColor, "star", params)

let mkTextStars = @(count) count <= 0
  ? $"<dis>{fa["star-o"]}</dis>"
  : $"<act>{"".join(array(count, fa["star"]))}</act>"

return {
  DEFAULT_PREMIUM_LEVEL
  mkTierStars
  mkZeroStars
  mkItemTier
  tagStars
  mkTextStars
}