import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *


let landingZones = mkEcsComputedEidMap({
  comps = [
    ["zone__icon", ecs.TYPE_STRING, ""],
    ["sphere_zone__radius", ecs.TYPE_FLOAT, 0.0]
  ]
  comps_rq = ["landingZone"]
  comps_filter = [["landing_zone__isAvailable", ecs.TYPE_BOOL]]
  filter = "landing_zone__isAvailable"
  tags = "gameClient"
})

let landing_zones_Set = Computed(@() landingZones.get().map(@(_, eid) eid))



let landing_zones_GetWatched = memoize(@(eid) Computed(function(prev) {
  let row = landingZones.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return { eid, icon = row.zone__icon, radius = row.sphere_zone__radius }
}))

return {
  landing_zones_GetWatched,
  landing_zones_Set
}
