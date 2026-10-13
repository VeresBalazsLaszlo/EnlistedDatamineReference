import "%dngscripts/ecs.nut" as ecs
from "team" import TEAM_UNASSIGNED
from "%ui/hud/state/watched_hero.nut" import watchedTeam
from "%ui/hud/state/vehicle_state.nut" import isVehicleCanBeRessuplied, inGroundVehicle, inPlane, vehicleResupplyType
from "%ui/ec_to_watched.nut" import mkWatchedSetAndStorage, MK_COMBINED_STATE
from "%ui/hud/state/respawnState.nut" import vehicleInfo, showSquadSpawn
from "%ui/ui_library.nut" import *

let {
  resupply_zones_GetWatched,
  resupply_zones_UpdateEid,
  resupply_zones_DestroyEid,
  resupply_zones_State
} = mkWatchedSetAndStorage("resupply_zones_", MK_COMBINED_STATE)

let DB = ecs.g_entity_mgr.getTemplateDB()

let spawnMenuGroundVehicle = Computed(function() {
  if (!showSquadSpawn.get() || vehicleInfo.get()?.gametemplate == null)
    return false
  let vehicleTemplate = DB.getTemplateByName(vehicleInfo.get()?.gametemplate)
  return vehicleTemplate?.getCompValNullable("airplane") == null
})

let heroActiveResupplyZonesEids = Computed(function(){
  let isInPlane = inPlane.get()
  let isInGroundVehicle = inGroundVehicle.get()
  let vehicleType = vehicleResupplyType.get()
  let isSpawnMenuGroundVehicle = spawnMenuGroundVehicle.get()
  if (((!isInGroundVehicle && !isInPlane) || !isVehicleCanBeRessuplied.get()) && !isSpawnMenuGroundVehicle)
    return {}
  let heroTeam = watchedTeam.get()
  return resupply_zones_State.get().filter(function(z) {
    let {team, active, isForPlanes, isForGroundVehicles, acceptedVehicleType} = z
    return active
      && (team == TEAM_UNASSIGNED || team == heroTeam)
      && (showSquadSpawn.get()
        ? isSpawnMenuGroundVehicle && isForGroundVehicles
        : ((acceptedVehicleType == "" || acceptedVehicleType == vehicleType)
          && (
            (isInPlane && isForPlanes) ||
            (isInGroundVehicle && isForGroundVehicles)
          )))
  })
})

ecs.register_es("resupply_zones_ui_state_es",
  {
    [["onChange", "onInit"]] = @(_, eid, comp) resupply_zones_UpdateEid(eid, {
      eid
      active   = comp["active"]
      icon     = comp["zone__icon"]
      ui_order = comp["ui_order"]
      caption  = comp["zone__caption"]
      radius   = comp["sphere_zone__radius"]
      team     = comp["resupply_zone__team"]
      isForPlanes = comp.planeResupply != null
      isForGroundVehicles = comp.groundVehicleResupply != null
      acceptedVehicleType = comp.resupply_zone__type
    })
    onDestroy = @(_, eid, __) resupply_zones_DestroyEid(eid)
  },
  {
    comps_ro = [
      ["zone__icon", ecs.TYPE_STRING, ""],
      ["zone__caption", ecs.TYPE_STRING, ""],
      ["planeResupply", ecs.TYPE_TAG, null],
      ["groundVehicleResupply", ecs.TYPE_TAG, null],
      ["resupply_zone__type", ecs.TYPE_STRING, ""],
    ]
    comps_track = [
      ["active", ecs.TYPE_BOOL],
      ["resupply_zone__team", ecs.TYPE_INT],
      ["ui_order", ecs.TYPE_INT, 0],
      ["sphere_zone__radius", ecs.TYPE_FLOAT, 0],
    ],
    comps_rq = ["resupplyZone"]
  },
  { tags="gameClient" }
)


return {

  resupply_zones_GetWatched,
  heroActiveResupplyZonesEids
}
