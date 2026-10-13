import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/ui_library.nut" import *

const SIGN_NONE = 0
const SIGN_PREMIUM = 1
const SIGN_EVENT = 2
const SIGN_BP = 3

const defIconSize  = hdpxi(22)
const defIconPath  = "!ui/icons/bp_weapon_icon.svg"
let defIconStyle = { margin = hdpx(5) }

function mkIcon(icon, iconSize = defIconSize, override = {}) {
  if (icon == null)
    return null
  let size = iconSize
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{icon}:{size}:{size}")
    fallbackImage = Picture($"{defIconPath}:{size}:{size}")
  }.__update(override)
}


function mkSpecialItemIcon(item, size = defIconSize, override = {}) {
  let armyId = getLinkedArmyName(item) ?? item?.armyId
  let { sign = 0 } = item
  let style = defIconStyle.__update(override)
  return !armyId ? null
    : sign == SIGN_PREMIUM
      ? mkIcon(armiesPresentation?[armyId].premIcon, size, style)
    : sign == SIGN_EVENT
      ? mkIcon("ui/skin#icons/event_squad_icon.svg", size, style)
    : sign == SIGN_BP
      ? mkIcon($"!ui/icons/bp_weapon_icon.svg", size, style)
    : null
}

let bpIcon = mkIcon($"!ui/icons/bp_weapon_icon.svg", defIconSize)
let eventIcon = mkIcon($"ui/skin#icons/event_squad_icon.svg", defIconSize)


return {
  mkSpecialItemIcon
  bpIcon
  eventIcon
  SIGN_NONE
  SIGN_PREMIUM
  SIGN_EVENT
  SIGN_BP
}
