from "%ui/hud/state/aircraft_markers.nut" import aircraft_markers_Set, aircraft_markers_GetWatched
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid
from "%ui/style/unit_colors.nut" import MAP_COLOR_TEAMMATE, MAP_COLOR_ENEMY, MAP_COLOR_UNIDENTIFIED
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

let iconSz = [hdpxi(15), hdpxi(15)]
let iconImg = Picture("ui/skin#aircraft_icon.svg:{0}:{1}".subst(iconSz[0], iconSz[1]))

const heroColor = Color(200,200,0,250)

function mkAircraftMapMarker(eid) {
  let isHeroPlane = Computed(@() controlledVehicleEid.get() == eid)
  let state = aircraft_markers_GetWatched(eid)
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = false
    dirRotate = true
  })
  let isFriendly = Computed(@() state.get()?.team == localPlayerTeam.get())
  let colorState = Computed(@() isHeroPlane.get()
            ? heroColor
            : !state.get().isIdentified
              ? MAP_COLOR_UNIDENTIFIED
              : isFriendly.get()
                ? MAP_COLOR_TEAMMATE
                : MAP_COLOR_ENEMY
             )
  return function() {
    return {
      data
      transform = true
      children = {
        rendObj = ROBJ_IMAGE
        size = iconSz
        color = colorState.get()
        image = iconImg
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = {
          rotate=45.0
        }
      }
      watch = colorState
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkAircraftMapMarker)
return {
  watch = aircraft_markers_Set
  ctor = @(_) memoizedMap(aircraft_markers_Set.get()).values()
}