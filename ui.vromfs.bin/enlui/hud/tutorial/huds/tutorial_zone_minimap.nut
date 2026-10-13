from "%ui/hud/tutorial/state/tutorial_zones_state.nut" import tutorialZones
from "%ui/ui_library.nut" import *

const iconSize = hdpxi(16)

let icons = {
  waypoint = {
    image = Picture($"ui/skin#waypoint_tutorial.svg:{iconSize}:{iconSize}")
    size = iconSize
  }
}

let map_zone_pointer_ctor = @(eid, comp) function() {
  let { image, size } = icons?[comp.tutorial_zone__icon] ?? icons.waypoint
  return {
    key = eid
    data = {
      eid = eid
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {
      rotate = -90
    }
    children = {
        rendObj = ROBJ_IMAGE
        color = Color(255, 255, 255)
        image
        size
        pos = [0, -size * 0.15]
    }
  }
}

return {
  tutorialZoneMarkers = {
    watch = tutorialZones
    ctor = @(_p) tutorialZones.get().reduce(@(res, comp, eid) res.append(map_zone_pointer_ctor(eid, comp)), [])
  }
}
