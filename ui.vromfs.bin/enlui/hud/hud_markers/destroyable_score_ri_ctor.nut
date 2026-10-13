import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
from "dagor.math" import Point2
from "%ui/hud/state/destroyable_score_ri_markers.nut" import destroyable_ri_Set, destroyable_ri_GetWatched
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/style/unit_colors.nut" import HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_ENEMY_INNER, HUD_COLOR_ENEMY_OUTER
from "%ui/ui_library.nut" import *

let destroyableRiIconSize = [hdpxi(10), hdpxi(14)]

let picInner = Picture($"ui/skin#unit_inner.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}")
let picOuter = Picture($"ui/skin#unit_outer.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}")

let defData = freeze({
  minDistance = 0.1
  maxDistance = 1000
  distScaleFactor = 0.5
  yOffs = 0.1
  clampToBorder = false
  opacityRangeX = Point2(0.15, 0.15)
  opacityRangeY = Point2(0.15, 0.15)
})

function destroyable_ri_ctor(eid){
  let markerState = destroyable_ri_GetWatched(eid)
  let data = defData.__merge({eid})
  return function(){
    let addScoreTeam = markerState.get()
    return {
      data
      rendObj = ROBJ_IMAGE
      color = is_teams_friendly(localPlayerTeam.get(), addScoreTeam) ? HUD_COLOR_ENEMY_OUTER : HUD_COLOR_TEAMMATE_OUTER
      key = eid
      sortOrder = eid
      transform = true
      image = picOuter
      size = destroyableRiIconSize

      children = {
        rendObj = ROBJ_IMAGE
        color = is_teams_friendly(localPlayerTeam.get(), addScoreTeam) ? HUD_COLOR_ENEMY_INNER : HUD_COLOR_TEAMMATE_INNER
        image = picInner
        size = destroyableRiIconSize
      }
      markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
      watch = [localPlayerTeam, markerState]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(destroyable_ri_ctor)

return {
  destroyable_ri_ctor = {
    watch = destroyable_ri_Set
    ctor = @() memoizedMap(destroyable_ri_Set.get()).values()
  }
}