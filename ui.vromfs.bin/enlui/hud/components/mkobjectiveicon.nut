import "%ui/components/fontawesome.map.nut" as fa
import "%ui/hud/components/capzone_images.nut" as capzone_images
from "%ui/style/fontsStyle.nut" import fontHeading1, fontawesome
from "dagor.debug" import logerr
from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG
from "%ui/ui_library.nut" import *

let ZONE_TEXT_COLOR = Color(80,80,80,20)

let transformCenterPivot = const { pivot = [0.5, 0.5] }

const defZoneBaseSize = hdpx(24)

let defaultCorrect = @(fontSize) [fontSize*0.04+1, fontSize*0.05]
let lettersCorrection = {
  B = defaultCorrect,
  D = defaultCorrect,
  F = defaultCorrect,
  [fa["forward"]] = @(fontSize) [fontSize*0.2, -fontSize*0.03],
  [fa["shield"]] = @(fontSize) [fontSize*0.1, fontSize*0.05],
  [fa["close"]] = @(fontSize) [fontSize*0.12, -fontSize*0.04],
  [fa["check"]] = @(fontSize) [fontSize*0.1, -fontSize*0.04],
}
function mkPosOffsetForLetterVisPos(letter, fontSize){

  return lettersCorrection?[letter](fontSize) ?? [0, fontSize*0.05]
}

function zoneBase(text_params={}, params={}) {
  let {text} = text_params
  if (text == null)
    return null
  let {color = ZONE_TEXT_COLOR} = params
  let fontSize = (params?.size ?? defZoneBaseSize) * 1.1

  let children = {
    rendObj = ROBJ_TEXT
    color
    pos = mkPosOffsetForLetterVisPos(text, fontSize)
    animations = params?.animAppear ?? params?.baseZoneAppearAnims
    transform = transformCenterPivot
  }.__update(text_params, { fontSize })
  return {
    transform = transformCenterPivot
    size = SIZE_TO_CONTENT
    halign  = ALIGN_CENTER
    valign = ALIGN_CENTER
    children
  }
}

function zoneFontAwesome(symbol, params) {
  return zoneBase({
    text = fa[symbol]
    padding = const [0,0,hdpx(2)]
    valign = ALIGN_CENTER
    key = symbol
  }.__update(fontawesome), params)
}

let getPicture = memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.contains("/")) {
    imagename = name.endswith(".svg") ? "{0}:{1}:{1}".subst(name, iconSz.tointeger()) : name
  } else if (name in capzone_images) {
    imagename = "{0}:{1}:{1}".subst(capzone_images[name], iconSz.tointeger())
  }

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return Picture(imagename)
})


let mkZoneIcon = memoize(function(icon, iconSz, animations){
  let image = getPicture(icon, iconSz)
  if (image == null)
    return null
  return {
    rendObj = ROBJ_IMAGE
    size = iconSz
    halign  = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = 0xFFFFFFFF
    transform = transformCenterPivot
    image
    animations
  }
})

let mkZoneToCaptureIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("shield",
  { size = iconSz, color = TEAM1_COLOR_FG, animAppear}), 1)
let mkZoneCapturedIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("check",
  { size = iconSz, color = TEAM0_COLOR_FG, animAppear}), 1)
let mkZoneToDefendIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("shield",
  { size = iconSz, color = TEAM0_COLOR_FG, animAppear}), 1)
let mkZoneFailedIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("close",
  { size = iconSz, color = TEAM1_COLOR_FG, animAppear}), 1)

let mkZoneTitle = memoize(@(text, iconSz, titleSize, animAppear) zoneBase({ text }.__update(fontHeading1),
    { size = titleSize > 0 ? [fsh(titleSize), fsh(titleSize)] : iconSz, animAppear}))

function mkObjectiveIcon(zoneData, iconSz, heroTeam, params={}) {
  let { animAppear = null, baseZoneAppearAnims = null } = params
  let { icon = null, bombPlantingTeam, attackTeam, trainTriggerable = null,
    active = null, capTeam = null, capzoneTwoChains = null, owningTeam = null, titleSize, title
  } = zoneData
  let iconWidth = iconSz

  let zoneToCaptureIcon = mkZoneToCaptureIcon(iconWidth, iconSz, animAppear)
  let zoneCapturedIcon = mkZoneCapturedIcon(iconWidth, iconSz, animAppear)
  let zoneToDefendIcon = mkZoneToDefendIcon(iconWidth, iconSz, animAppear)
  let zoneFailedIcon = mkZoneFailedIcon(iconWidth, iconSz, animAppear)

  let zoneIcon = mkZoneIcon(icon, iconSz, animAppear ?? baseZoneAppearAnims)
  let activeIcon = freeze({
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      zoneIcon
      mkZoneTitle(title, iconSz, titleSize, animAppear)
    ]
  })

  let attackTeamId = bombPlantingTeam > -1 ? bombPlantingTeam : attackTeam
  let isDefendZone = attackTeamId > -1 && attackTeamId != heroTeam
  let isAttackZone = attackTeamId > -1 && attackTeamId == heroTeam
  return (trainTriggerable || active)
    ? activeIcon
    : isAttackZone
      ? (capTeam == heroTeam ? zoneCapturedIcon : zoneToCaptureIcon)
      : isDefendZone
        ? ((capTeam ?? 0) > 0 && capTeam != heroTeam ? zoneFailedIcon : zoneToDefendIcon)
        : capzoneTwoChains
          ? (owningTeam == heroTeam ? zoneToDefendIcon : ((owningTeam ?? 0) > 0) ? zoneToCaptureIcon : zoneIcon)
          : zoneIcon
}

return {
  mkObjectiveIcon
}