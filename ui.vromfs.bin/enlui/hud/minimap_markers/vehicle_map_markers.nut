from "%ui/hud/state/vehicle_markers.nut" import vehicle_markers_Set, vehicle_markers_GetWatched
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid
from "%ui/style/unit_colors.nut" import MAP_COLOR_TEAMMATE, MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE
from "%ui/ui_library.nut" import *

let iconSz = array(2, hdpxi(15))
let mkIcon = memoize(@(icon) (icon ?? "") != ""
  ? Picture("ui/skin#{0}.svg:{1}:{2}".subst(icon, iconSz[0], iconSz[1]))
  : null)
let mkAttachedBoxIcon = memoize(function(icon) {
  let name = (icon ?? "") != "" ? icon : "building_ammo_box"
  return Picture($"!ui/uiskin/{name}.svg:{iconSz[0]}:{iconSz[1]}:K")
})

let mkData = @(eid) freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = false
})

function mkMarker(eid) {
  let data = mkData(eid)
  let markerState = vehicle_markers_GetWatched(eid)
  let watch = [markerState, controlledVehicleEid]

  return function() {
    
    let row = markerState.get()
    if (row == null || controlledVehicleEid.get() == eid)
      return { watch }
    let isEmpty = row.vehicle_marker_ui__isEmpty
    let hasAttachedAmmo = row.attached_ammo_box__hasAmmo
    if (isEmpty && !hasAttachedAmmo)
      return { watch }
    return {
      data
      watch
      transform = true
      children = {
        rendObj = ROBJ_IMAGE
        size = iconSz
        color = isEmpty ? Color(255,255,255)
              : row.vehicle_marker_ui__hasSquadmates ? MAP_COLOR_SQUADMATE
              : row.vehicle_marker_ui__hasGroupmates ? MAP_COLOR_GROUPMATE
              : MAP_COLOR_TEAMMATE
        image = mkIcon(row.vehicle__mapIcon)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = const { rotate = -90 }
        children = hasAttachedAmmo ? {
          rendObj = ROBJ_IMAGE
          size = iconSz
          image = mkAttachedBoxIcon(row.attached_ammo_box__markerIcon)
          pos = [iconSz[1] / 2, -iconSz[1] / 2]
        } : null
      }
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkMarker)
return {
  watch = vehicle_markers_Set
  ctor = @(_) memoizedMap(vehicle_markers_Set.get()).values()
}