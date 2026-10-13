import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let markerComps = [
  ["team", ecs.TYPE_INT],
  ["vehicle__mapIcon", ecs.TYPE_STRING],
  ["vehicle_marker_ui__gropmateNickFrames", ecs.TYPE_STRING_LIST, null],
  ["vehicle_marker_ui__gropmateNames", ecs.TYPE_STRING_LIST, null],
  ["vehicle_marker_ui__isEmpty", ecs.TYPE_BOOL, false],
  ["vehicle_marker_ui__hasGroupmates", ecs.TYPE_BOOL, false],
  ["vehicle_marker_ui__hasSquadmates", ecs.TYPE_BOOL, false],
  ["repairable__repairRequired", ecs.TYPE_BOOL, false],
  ["attached_ammo_box__hasAmmo", ecs.TYPE_BOOL, false],
  ["attached_ammo_box__markerIcon", ecs.TYPE_STRING, null],
]


let mkMarkerRows = @(comps_rq) mkEcsComputedEidMap({
  comps = markerComps
  comps_rq
  comps_filter = [["isAlive", ecs.TYPE_BOOL]]
  filter = "isAlive"
  tags = "gameClient"
})

let vehicleRows = mkMarkerRows(["vehicle_seats__seatEids"])

let tankRows = mkMarkerRows(["vehicle_seats__seatEids", "isTank"])



let mkTeamSet = @(rows) Computed(function() {
  let team = localPlayerTeam.get()
  let res = {}
  foreach (eid, row in rows.get())
    if (row.team == team)
      res[eid] <- eid
  return res
})



let mkRowWatch = @(rows) @(eid) Computed(@() rows.get()?[eid])

return {
  vehicle_markers_Set = mkTeamSet(vehicleRows)
  vehicle_markers_GetWatched = mkRowWatch(vehicleRows)
  tank_markers_Set = mkTeamSet(tankRows)
  tank_markers_GetWatched = mkRowWatch(tankRows)
}
