import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/respawnState.nut" import needSpawnMenu, selectedRespawnGroupId, canUseRespawnbaseByType
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

let groupRespawnsGroupsQuery = ecs.SqQuery("groupRespawnGroupsQuery", {
  comps_ro=[
    ["selectedGroup", ecs.TYPE_INT],
    ["team", ecs.TYPE_INT],
    ["respawnIconType", ecs.TYPE_STRING],
  ]
})

function getRespawnGroups(forTeam, exludeEid = ecs.INVALID_ENTITY_ID) {
  let respawnGroups = {}
  groupRespawnsGroupsQuery(function(eid, comps) {
    if (comps.team == forTeam && comps.respawnIconType == canUseRespawnbaseByType.get() && exludeEid != eid)
      respawnGroups[comps.selectedGroup] <- true
  })
  return respawnGroups
}

function updateSelectedRespawnGroup(exludeEid = ecs.INVALID_ENTITY_ID) {
  if (!needSpawnMenu.get())
    return
  let respawnGroups = getRespawnGroups(localPlayerTeam.get(), exludeEid)
  let respawnType = canUseRespawnbaseByType.get()
  let playerSelectedGroupExist = (respawnGroups?[selectedRespawnGroupId.get()?[respawnType]] != null)
  if (!playerSelectedGroupExist)
    selectedRespawnGroupId.mutate(@(v) v[respawnType] <- -1)
}

needSpawnMenu.subscribe(@(_v) updateSelectedRespawnGroup())
canUseRespawnbaseByType.subscribe(@(_v) updateSelectedRespawnGroup())

ecs.register_es("respawn_priority_es", {
  [["onInit","onDestroy","onChange"]] = @(...) updateSelectedRespawnGroup()
}, {
  comps_track = [
    ["capzone__capTeam", ecs.TYPE_INT],
    ["active", ecs.TYPE_BOOL]
  ]
})

ecs.register_es("respawn_selector_reset_es", {
  onDestroy = @(_evt,eid,_comp) updateSelectedRespawnGroup(eid)
  onInit = @(...) updateSelectedRespawnGroup()
}, {
  comps_rq = ["selectedGroup"]
})
