import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
from "%ui/hud/state/simple_markers.nut" import simple_hud_markers_GetWatched, simple_hud_markers_Set
from "dagor.math" import Point2
from "%ui/hud/state/watched_hero.nut" import watchedTeam
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadEid
from "%ui/ui_library.nut" import *

let mkSize = @(x,y) [fsh(x), fsh(y)].map(@(v) v.tointeger())
let defaultIconSize = mkSize(3.5, 3.5)
let mkSvg = memoize(function(img, size) {
  return $"!ui/uiskin/{img}.svg:{size[0]}:{size[1]}:K"
})

let mkIco = memoize(function(image, size) {
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = image!= null ? Picture(mkSvg(image, size)) : null
  }
})

let opx = Point2(0.2, 0.2)
function ctor(eid) {
  let state = simple_hud_markers_GetWatched(eid)
  return function() {
    let info = state.get()
    local watch = [watchedTeam, state]
    if (info?.visibleToSquad != null)
      watch.append(watchedHeroSquadEid)
    if (info?.team != null)
      watch.append(watchedTeam)
    let iconSize = info?.size ? mkSize(info.size.x, info.size.y) : defaultIconSize
    let isRightPlayer = info?.visibleToSquad == null || info?.visibleToSquad == watchedHeroSquadEid.get()
    let isFriendly = info?.team == null || is_teams_friendly(info?.team, watchedTeam.get())
    if (!isFriendly || !isRightPlayer)
      return {watch}
    return {
      watch
      data = {
        eid
        minDistance = info?.minDistance ?? 0.1
        maxDistance = info?.maxDistance ?? 10.0
        yOffs = info?.offsetY ?? 0.0
        distScaleFactor = 0.5
        clampToBorder = info?.clampToBorder ?? false
        opacityRangeX = info?.opacityRangeX ?? opx
        opacityRangeY = info?.opacityRangeY ?? opx
        opacityCenterRelativeDist = info?.opacityCenterRelativeDist ?? 0.05
        opacityCenterMinMult = info?.opacityCenterMinMult ?? 0.5
      }
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = true
      key = eid
      behavior = Behaviors.OverlayTransparency
      sortOrder = eid
      children = [
        mkIco(info.image, iconSize)
        info?.iconCounter != null ?
        {
          size = iconSize
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          text = info?.iconCounter
        } : null
      ]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)
return {
   useful_boxes_marker_ctor = {
     watch = simple_hud_markers_Set
     ctor = @() memoizedMap(simple_hud_markers_Set.get()).values()
   }
}
