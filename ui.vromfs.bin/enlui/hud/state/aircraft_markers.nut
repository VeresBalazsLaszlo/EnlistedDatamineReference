import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *




let aircraftMarkers = mkEcsComputedEidMap({
  comps = [
    ["team", ecs.TYPE_INT, null],
    ["hud_aircraft_marker__clampToBorder", ecs.TYPE_BOOL, false],
    ["hud_aircraft_marker__isIdentified", ecs.TYPE_BOOL, true],
  ]
  comps_rq = ["hud_aircraft_marker"]
  comps_filter = [["isAlive", ecs.TYPE_BOOL, false], ["hud_aircraft_marker__isVisible", ecs.TYPE_BOOL, true]]
  filter = "and(opt(isAlive, false), and(opt(hud_aircraft_marker__isVisible, true), ne(opt(team, -2), -1)))" 
})

let aircraft_markers_Set = Computed(@() aircraftMarkers.get().map(@(_row, eid) eid))



let aircraft_markers_GetWatched = memoize(@(eid) Computed(function(prev) {
  let row = aircraftMarkers.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return {
    team = row.team
    clampToBorder = row.hud_aircraft_marker__clampToBorder
    isIdentified = row.hud_aircraft_marker__isIdentified
  }
}))

return{
  aircraft_markers_Set,
  aircraft_markers_GetWatched,
}