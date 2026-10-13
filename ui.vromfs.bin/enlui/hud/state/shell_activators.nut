import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let shellActivators = mkEcsComputedEidMap({
  comps = [
    ["ownerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0],
    ["hud_marker__icon", ecs.TYPE_STRING, "killlog/kill_explosion.svg"]
  ]
  comps_rq = ["on_create__spawnActivatedShellBlk"]
})

let shell_activators_Set = Computed(@() shellActivators.get().map(@(_, eid) eid))



let shell_activators_GetWatched = @(eid) Computed(function(prev) {
  let row = shellActivators.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return {
    ownerEid = row.ownerEid,
    maxDistance = row.hud_marker__max_distance,
    icon = row.hud_marker__icon
  }
})

return {
  shell_activators_Set, shell_activators_GetWatched
}
