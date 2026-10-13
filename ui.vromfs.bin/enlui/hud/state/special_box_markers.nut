import "%dngscripts/ecs.nut" as ecs
from "%ui/ec_to_watched.nut" import mkWatchedSetAndStorage
from "%ui/ui_library.nut" import *

let {
  special_box_markers_Set,
  special_box_markers_GetWatched,
  special_box_markers_UpdateEid,
  special_box_markers_DestroyEid
} = mkWatchedSetAndStorage("special_box_markers_")

let getPlayerNameQuery = ecs.SqQuery("getPlayerNameQuery", { comps_ro = [["name", ecs.TYPE_STRING]] })

ecs.register_es(
  "special_box_markers_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      if (!comp.paid_loot__alreadyUsed)
        special_box_markers_UpdateEid(eid, {
          image = comp.special_box_hud__iconImage
          offsetY = comp.special_box_hud__offsetY
          ownerEid = comp.special_weapon_box__ownedByPlayer
          ownerName = getPlayerNameQuery(comp.special_weapon_box__ownedByPlayer, @(_eid, compPlayer) compPlayer.name)
          minDistanceToShow = comp.special_box_hud__minDistanceToShow
          maxDistanceToShow = comp.special_box_hud__maxDistanceToShow
        })
      else
        special_box_markers_DestroyEid(eid)
    }
    onDestroy = @(_, eid, __) special_box_markers_DestroyEid(eid)
  },
  {
    comps_rq = ["paid_loot_special_box", "transform"]
    comps_track = [
      ["paid_loot__alreadyUsed", ecs.TYPE_BOOL],
      ["special_weapon_box__ownedByPlayer", ecs.TYPE_EID]
    ]
    comps_ro = [
      ["special_box_hud__iconImage", ecs.TYPE_STRING],
      ["special_box_hud__offsetY", ecs.TYPE_FLOAT],
      ["special_box_hud__minDistanceToShow", ecs.TYPE_FLOAT],
      ["special_box_hud__maxDistanceToShow", ecs.TYPE_FLOAT]
    ]
  }
)

return {
  special_box_markers_Set
  special_box_markers_GetWatched
}