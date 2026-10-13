import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/special_box_markers.nut" import special_box_markers_GetWatched, special_box_markers_Set
from "dagor.math" import Point2
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/style.nut" import TEAM0_COLOR_FG, DEFAULT_TEXT_COLOR
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/ui_library.nut" import *

let defaultIconSize = [fsh(3.5).tointeger(), fsh(3.5).tointeger()]
let mkSvg = memoize(function(img, size) {
  return $"!ui/uiskin/{img}.svg:{size[0]}:{size[1]}:K"
})

let makeIcon = memoize(function(image, size, isForLocalPlayer) {
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    color = isForLocalPlayer ? TEAM0_COLOR_FG : DEFAULT_TEXT_COLOR
    image = Picture(mkSvg(image, size))
  }
})

let makeText = memoize(function(text) {
  return freeze({
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = const [0, fsh(3.5)]
    fontSize = hdpx(18)
    text = text
  })
})

let opx = Point2(0.5, 0.8)
function ctor(eid) {
  let state = special_box_markers_GetWatched(eid)
  return function() {
    let info = state.get()
    let watch = [state]
    let iconSize = defaultIconSize
    let ownerName = remap_others(info.ownerName)
    let minDistanceToShow = info.minDistanceToShow
    let maxDistanceToShow = info.maxDistanceToShow
    if (info.ownerEid == ecs.INVALID_ENTITY_ID)
      return { watch }
    let isBoxForLocalPlayer = info.ownerEid == localPlayerEid.get()
    return {
      watch
      data = {
        eid
        minDistance = minDistanceToShow
        maxDistance = maxDistanceToShow
        yOffs = info.offsetY
        distScaleFactor = 0.5
        clampToBorder = false
        opacityRangeX = opx
        opacityRangeY = opx
        opacityCenterRelativeDist = 0.05
        opacityCenterMinMult = 1.0
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = true
      key = eid
      behavior = Behaviors.OverlayTransparency
      sortOrder = eid
      children = [makeIcon(info.image, iconSize, isBoxForLocalPlayer) makeText(ownerName)]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)

return {
  special_box_markers_ctor = {
    watch = special_box_markers_Set
    ctor = @() memoizedMap(special_box_markers_Set.get()).values()
  }
}