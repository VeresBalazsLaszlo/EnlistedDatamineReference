import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let heroCurrentGunEid = mkEcsComputed({
  comps = [["human_weap__currentGunEid", ecs.TYPE_EID]]
  comps_rq = ["hero"]
  defVal = ecs.INVALID_ENTITY_ID
})



let is_engineer = Computed(@()
  ecs.obsolete_dbg_get_comp_val(heroCurrentGunEid.get(), "currentPreviewId", null) != null)



let respawnIconRows = mkEcsComputedEidMap({
  comps = [["team", ecs.TYPE_INT], ["respawnIconType", ecs.TYPE_STRING]]
  comps_filter = [["respawn_icon__isHidden", ecs.TYPE_BOOL]] 
  filter = "eq(respawn_icon__isHidden, false)"
})


let respawnPreviewRows = mkEcsComputedEidMap({
  comps = [["previewTeam", ecs.TYPE_INT]]
  comps_rq = ["respawnObject", "builder_server_preview"]
})


let respawn_markers = Computed(function() {
  let res = {}
  foreach (eid, row in respawnIconRows.get()) {
    if (row.respawnIconType != "human")
      continue
    
    let isCustom = ecs.obsolete_dbg_get_comp_val(eid, "autoRespawnSelector", null) == null
    res[eid] <- {team = row.team, isCustom}
  }
  foreach (eid, team in respawnPreviewRows.get())
    res[eid] <- {team, isCustom = true}
  return res
})

let engineer_buildings_markers = mkEcsComputedEidMap({
  comps = [
    ["minimap__visibleForAll", ecs.TYPE_BOOL, false],
    ["builder_info__team", ecs.TYPE_INT],
    ["buildByPlayer", ecs.TYPE_EID],
    ["building_menu__image", ecs.TYPE_STRING],
    ["minimap__anyTeam", ecs.TYPE_BOOL, false],
  ]
})

return{
  respawn_markers
  engineer_buildings_markers
  is_engineer
}
