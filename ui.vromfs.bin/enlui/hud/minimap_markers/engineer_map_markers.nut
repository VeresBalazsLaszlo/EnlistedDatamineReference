from "%ui/hud/state/engineer_map_markers.nut" import respawn_markers, is_engineer
from "%ui/hud/state/vehicle_state.nut" import isOwnerInMobileRespawn
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(18)
let iconImg = Picture("ui/skin#spawn_point.svg:{0}:{1}".subst(iconSz, iconSz))
let customIconImg = Picture("ui/skin#custom_spawn_point.svg:{0}:{1}".subst(iconSz, iconSz))
const customSpawnColor = Color(255, 255, 255)
const missionSpawnColor = Color(86,131,212,250)

let size = [iconSz, iconSz]
function mkRespawnMapMarker(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = Computed(@() respawn_markers.get()?[eid])
  let watch = [is_engineer, localPlayerTeam, marker, isOwnerInMobileRespawn]
  return function() {
    let row = marker.get() 
    let isCustom = row?.isCustom ?? false
    return {
      data
      watch
      transform = true
      children = localPlayerTeam.get() == row?.team && (is_engineer.get() || isOwnerInMobileRespawn.get()) ? {
        rendObj = ROBJ_IMAGE
        size
        color = isCustom ? customSpawnColor : missionSpawnColor
        image = isCustom ? customIconImg : iconImg
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      } : null
    }
  }
}

let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkRespawnMapMarker(eid, transform)))
return {
  watch = respawn_markers
  ctor = @(p) memoizedMapByTransform(p?.transform)(respawn_markers.get()).values()
}