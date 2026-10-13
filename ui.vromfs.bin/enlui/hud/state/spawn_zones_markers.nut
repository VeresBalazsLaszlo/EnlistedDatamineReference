import "%dngscripts/ecs.nut" as ecs
from "%ui/ec_to_watched.nut" import mkWatchedSetAndStorage, MK_COMBINED_STATE
from "ecs.computed" import mkEcsComputed
from "dasevents" import EventUpdateIcon

let {
  spawnZonesGetWatched,
  spawnZonesUpdateEid,
  spawnZonesDestroyEid,
  spawnZonesState
} = mkWatchedSetAndStorage("spawnZones", MK_COMBINED_STATE)

let isFreeTankSpawnsAvailable = mkEcsComputed({
  comps = [["respawner__freeTankSpawnAvailable", ecs.TYPE_BOOL]]
  comps_rq = ["localPlayer"]
  defVal = false
})

ecs.register_es("spawn_zones_markers",
  {
    [["onInit", "onChange", EventUpdateIcon]] = function(eid,comp){
      if (comp["respawn_icon__isHidden"]){
        spawnZonesDestroyEid(eid)
        return
      }
      let isCustom = ecs.obsolete_dbg_get_comp_val(eid, "autoRespawnSelector", null) == null
      let isFreeTankSpawn = comp["respawn_icon__freeTankSpawn"] != null
      spawnZonesUpdateEid(eid, {
                                  iconType = comp.respawnIconType,
                                  selectedGroup = comp.selectedGroup,
                                  forTeam = comp.team,
                                  isCustom,
                                  isMobileSpawn = comp["mobileRespawnSelector"] != null,
                                  isFreeTankSpawn,
                                  iconIndex = comp["respawn_icon__iconIndex"],
                                  additiveAngle = comp["respawn_icon__additiveAngle"],
                                  isActive = comp["respawn_icon__active"] && (isFreeTankSpawnsAvailable.get() || !isFreeTankSpawn),
                                  isPlayerSpawn = comp["respawn_icon__isPlayerSpawn"],
                                  activateAtTime = comp["respawn_icon__activateAtTime"],
                                  enemyAtRespawn = comp["respawn_icon__isEnemyAtRespawn"],
                                  playersCount = comp["respawn_icon__playersCount"],
                                  isOccupied = comp["respawn_icon__isOccupied"],
                                  additionalInfo = comp["respawn_icon__additionalInfo"]
                                }
                              )
    }

    function onDestroy(_evt, eid, _comp){
      spawnZonesDestroyEid(eid)
    }
  },
  {
    comps_ro = [
      ["mobileRespawnSelector", ecs.TYPE_TAG, null],
      ["respawn_icon__freeTankSpawn", ecs.TYPE_TAG, null],
      ["respawnIconType", ecs.TYPE_STRING],
      ["selectedGroup", ecs.TYPE_INT],
      ["team", ecs.TYPE_INT],
      ["respawn_icon__additionalInfo", ecs.TYPE_STRING, ""]
    ]
    comps_track = [
      ["respawn_icon__iconIndex", ecs.TYPE_INT],
      ["respawn_icon__additiveAngle", ecs.TYPE_FLOAT],
      ["respawn_icon__active", ecs.TYPE_BOOL],
      ["respawn_icon__isHidden", ecs.TYPE_BOOL],
      ["respawn_icon__activateAtTime", ecs.TYPE_FLOAT],
      ["respawn_icon__isEnemyAtRespawn", ecs.TYPE_BOOL],
      ["respawn_icon__isPlayerSpawn", ecs.TYPE_BOOL],
      ["respawn_icon__playersCount", ecs.TYPE_INT],
      ["respawn_icon__isOccupied", ecs.TYPE_BOOL]
    ]
  }
)

return {spawnZonesGetWatched, spawnZonesState, isFreeTankSpawnsAvailable}