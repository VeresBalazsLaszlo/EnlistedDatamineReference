import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *



let activeBombs = mkEcsComputedEidMap({
  comps = [
    ["ownerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
  ]
  comps_rq = ["hud_bomb_marker"]
  comps_filter = [
    ["projectile__exploded", ecs.TYPE_BOOL],
    ["projectile__stopped", ecs.TYPE_BOOL]
  ]
  filter = "and(projectile__stopped, eq(projectile__exploded, false))"
})

let active_bombs_Set = Computed(@() activeBombs.get().map(@(_, eid) eid))



let active_bombs_GetWatched = @(eid) Computed(function(prev) {
  let row = activeBombs.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return { bombOwnerEid = row.ownerEid, maxDistance = row.hud_marker__max_distance }
})

return {
  active_bombs_Set, active_bombs_GetWatched
}
