import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/local_player.nut" import localPlayerEid, localPlayerTeam
from "%ui/hud/state/engineer_map_markers.nut" import engineer_buildings_markers, is_engineer
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(18)
let mkSvg = memoize(function(img) {
  return $"!ui/uiskin/{img}.svg:{iconSz}:{iconSz}:K"
})



let noTeamsLimitsMode = mkEcsComputed({
  comps = [["chars_gun_game__groupsCount", ecs.TYPE_INT, -1]]
  comps_rq = ["usefulBoxesNoTeamsLimits"]
})
let usefulBoxesNoTeamsLimits = Computed(@() noTeamsLimitsMode.get() != null)

let size = [iconSz, iconSz]
function mkBuildingMapMarker(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = Computed(@() engineer_buildings_markers.get()?[eid])
  let watch = [is_engineer, localPlayerEid, localPlayerTeam, marker]
  return function() {
    let row = marker.get()
    if (row == null) 
      return {data, watch, transform = true}
    let image = row.building_menu__image
    let isLocalOwner = localPlayerEid.get() == row.buildByPlayer
    let isFriendly = row.minimap__anyTeam || usefulBoxesNoTeamsLimits.get()
      || is_teams_friendly(localPlayerTeam.get(), row.builder_info__team)
    let isVisible = isFriendly && (row.minimap__visibleForAll || (is_engineer.get() && isLocalOwner))
    return {
      data
      watch
      transform = true
      children = isVisible ? {
        rendObj = ROBJ_IMAGE
        size
        color = Color(255, 255, 255)
        image = image ? Picture(mkSvg(image)) : null
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      } : null
    }
  }
}
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkBuildingMapMarker(eid, transform)))
return {
  watch = engineer_buildings_markers
  ctor = @(p) memoizedMapByTransform(p?.transform)(engineer_buildings_markers.get()).values()
}
