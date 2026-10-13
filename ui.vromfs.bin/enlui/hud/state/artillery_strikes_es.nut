import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *





let artilleryZones = mkEcsComputedEidMap({
  comps = [
    ["artillery__targetPos", ecs.TYPE_POINT3],
    ["artillery_zone__radius", ecs.TYPE_FLOAT],
  ]
  comps_filter = [["artillery_zone__showOnMinimap", ecs.TYPE_BOOL, true]]
  filter = "opt(artillery_zone__showOnMinimap, true)"
})

let artilleryStrikes = Computed(@() artilleryZones.get().map(@(zone) {
  pos = zone.artillery__targetPos
  radius = zone.artillery_zone__radius
}))

return artilleryStrikes
