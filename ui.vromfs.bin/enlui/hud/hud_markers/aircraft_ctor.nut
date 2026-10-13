from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "dagor.math" import Point2
from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid, inPlane
from "%ui/hud/state/aircraft_markers.nut" import aircraft_markers_Set, aircraft_markers_GetWatched
from "%ui/style/unit_colors.nut" import HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_ENEMY_INNER, HUD_COLOR_ENEMY_OUTER, HUD_COLOR_UNIDENTIFIED_INNER, HUD_COLOR_UNIDENTIFIED_OUTER
from "%ui/ui_library.nut" import *

let unitIconSize = [fsh(1.1), fsh(1.5)].map(@(v) v.tointeger())

let baseIcon = @(colorOuter, colorInner) {
  key = "icon"
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}")
  size = unitIconSize
  minDistance = 0.5
  transform = { translate = [0, hdpx(-10)] }

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}")
    size = unitIconSize
  }
  markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
}

let teammateIcon = baseIcon(HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_TEAMMATE_INNER)
let enemyIcon    = baseIcon(HUD_COLOR_ENEMY_OUTER, HUD_COLOR_ENEMY_INNER)
let unidentifiedIcon = baseIcon(HUD_COLOR_UNIDENTIFIED_OUTER, HUD_COLOR_UNIDENTIFIED_INNER)
let zeroPoint = Point2(0, 0)

let opRange_hardcore = Point2(0.15, 0.35)
let mkArrow = memoize(@(color) makeArrow({ color }))
let mkData = memoize(@(minHud, inplane) {
  minDistance = 0.5
  maxDistance = minHud && inplane ? 600 : 10000
  distScaleFactor = 0.3
  yOffs = 1.2
  opacityRangeX = minHud ? opRange_hardcore : zeroPoint
  opacityRangeY = minHud ? opRange_hardcore : zeroPoint
})

function aircraft(eid) {
  let state = aircraft_markers_GetWatched(eid)
  let watch = [state, inPlane, localPlayerTeam, forcedMinimalHud]

  return function() {
    if (controlledVehicleEid.get() == eid)
      return {watch}
    let isFriendly = state.get()?.team == localPlayerTeam.get()
    let icon = !state.get().isIdentified
               ? unidentifiedIcon
               : isFriendly
                 ? teammateIcon
                 : enemyIcon
    let color = !state.get().isIdentified
                  ? HUD_COLOR_UNIDENTIFIED_INNER
                  : isFriendly
                    ? HUD_COLOR_TEAMMATE_INNER
                    : HUD_COLOR_ENEMY_INNER
    return {
      data = mkData(forcedMinimalHud.get(), inPlane.get()).__merge({eid, clampToBorder = state.get()?.clampToBorder})
      key = eid
      sortOrder = eid
      transform = true
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = [icon, mkArrow(color)]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(aircraft)
return {
  aircraft_ctor = {
    watch = aircraft_markers_Set
    ctor = @() memoizedMap(aircraft_markers_Set.get()).values()
  }
}