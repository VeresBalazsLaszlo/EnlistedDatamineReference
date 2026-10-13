import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap



let tutorialZones = mkEcsComputedEidMap({
  comps = [
    ["tutorial_zone__active", ecs.TYPE_BOOL],
    ["tutorial_zone__icon", ecs.TYPE_STRING, "waypoint"],
  ]
  comps_rq = ["tutorialZone"]
  comps_no = ["tutorial_zone__hideWaypoint"]
  filter = "tutorial_zone__active"
})

return {
  tutorialZones = tutorialZones
}
