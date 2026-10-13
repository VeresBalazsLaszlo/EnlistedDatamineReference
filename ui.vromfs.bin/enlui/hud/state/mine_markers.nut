import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/watched_hero.nut" import watchedTeam
from "team" import TEAM_UNASSIGNED
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *


let minesByEid = mkEcsComputedEidMap({
  comps = [
    ["item__mineType", ecs.TYPE_STRING, null],
    ["item__grenadeLikeType", ecs.TYPE_STRING, null],
    ["mine__blockedToTime", ecs.TYPE_FLOAT, -1.0],
    ["mine__installBlockTime", ecs.TYPE_FLOAT, 0.0],
    ["placeable_item__ownerTeam", ecs.TYPE_INT, TEAM_UNASSIGNED]
  ]
  comps_rq = ["transform", "ui__placeableItemMarker"]
  comps_filter = [["mine__activated", ecs.TYPE_BOOL, true]]
  filter = "opt(mine__activated, true)"
})


let mine_markers_Set = Computed(function() {
  let team = watchedTeam.get()
  let res = {}
  foreach (eid, row in minesByEid.get())
    if (is_teams_friendly(row.placeable_item__ownerTeam, team))
      res[eid] <- eid
  return res
})



let mine_markers_GetWatched = memoize(@(eid) Computed(function(prev) {
  let row = minesByEid.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return {
    type = row.item__mineType ?? row.item__grenadeLikeType
    blockedToTime = row.mine__blockedToTime
    installBlockTime = row.mine__installBlockTime
  }
}))

return{
  mine_markers_Set, mine_markers_GetWatched
}
