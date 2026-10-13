import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *



let respawnZones = mkEcsComputedEidMap({
  comps = [
    ["respawn__targetPos", ecs.TYPE_POINT3],
    ["respawn_zone__radius", ecs.TYPE_FLOAT],
  ]
  comps_filter = [["respawn_zone__showOnMinimap", ecs.TYPE_BOOL, true]]
  filter = "opt(respawn_zone__showOnMinimap, true)"
})

let respawnDamage = Computed(function() {
  let res = {}
  foreach (eid, zone in respawnZones.get())
    res[eid] <- {
      pos = zone.respawn__targetPos
      radius = zone.respawn_zone__radius
    }
  return res
})

return respawnDamage
