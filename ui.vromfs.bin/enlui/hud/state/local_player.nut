import "%dngscripts/ecs.nut" as ecs
from "team" import TEAM_UNASSIGNED
from "matching.errors" import INVALID_SQUAD_ID
from "net" import get_user_id
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let logObs = with_prefix("[OBSERVER]")

const INVALID_USER_ID = 0
const UNDEFINEDNAME = "?????"

let localPlayerUserId = mkWatched(persist, "localPlayerUserId", INVALID_USER_ID)
let localPlayerEid = mkWatched(persist, "localPlayerEid", ecs.INVALID_ENTITY_ID)
let localPlayerSpecTarget = mkWatched(persist, "localPlayerSpecTarget", ecs.INVALID_ENTITY_ID)
let localPlayerName = mkWatched(persist, "localPlayerName", UNDEFINEDNAME)
let localPlayerTeam = mkWatched(persist, "localPlayerTeam", TEAM_UNASSIGNED)
let localPlayerGroupId = mkWatched(persist, "localPlayerGroupId", INVALID_SQUAD_ID)
let localPlayerMemberIndex = mkWatched(persist, "localPlayerMemberIndex", 0)
let localPlayerIsInActiveOpenGroup = mkWatched(persist, "localPlayerIsInActiveOpenGroup", false)



let groupIdByEid = mkEcsComputedEidMap({ comps = [["groupId", ecs.TYPE_INT64]] })
let localPlayerGroupMembers = Computed(function() {
  let groupId = localPlayerGroupId.get()
  let res = {}
  if (groupId != INVALID_SQUAD_ID)
    foreach (eid, eidGroupId in groupIdByEid.get())
      if (eidGroupId == groupId)
        res[eid] <- true
  return res
})

let openGroupQuery = ecs.SqQuery("openGroupQuery", {comps_ro = [["player_group__id", ecs.TYPE_INT64],
                                                                ["player_group__openGroupIsActive", ecs.TYPE_BOOL]]})

localPlayerSpecTarget.subscribe(@(eid) logObs($"spectated: {eid}"))

function resetData() {
  localPlayerEid.set(ecs.INVALID_ENTITY_ID)
  localPlayerTeam.set(TEAM_UNASSIGNED)
  localPlayerUserId.set(get_user_id())
  localPlayerSpecTarget.set(ecs.INVALID_ENTITY_ID)
  localPlayerGroupId.set(INVALID_SQUAD_ID)
}

function trackComponents(eid, comp) {
  if (comp.is_local) {
    if (localPlayerEid.get() != eid)
      logObs($"[local_player_es] localPlayerEid = {eid}")
    localPlayerEid.set(eid)
    localPlayerTeam.set(comp.team)
    localPlayerName.set(comp.name)
    localPlayerUserId.set(get_user_id())
    localPlayerSpecTarget.set(comp.specTarget)
    localPlayerGroupId.set(comp.groupId)
    localPlayerMemberIndex.set(comp.player_group__memberIndex)
    localPlayerIsInActiveOpenGroup.set(false)
    openGroupQuery.perform(function(_, comps){
      if (comps.player_group__id == comp.groupId)
        localPlayerIsInActiveOpenGroup.set(comps.player_group__openGroupIsActive)
    })
  } else if (localPlayerEid.get() == eid) {
    resetData()
  }
}

function onDestroy(eid, _comp) {
  if (localPlayerEid.get() == eid)
    resetData()
}

ecs.register_es("local_player_es", {
    onChange = trackComponents
    onInit = trackComponents
    onDestroy = onDestroy
  },
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["team", ecs.TYPE_INT],
      ["name", ecs.TYPE_STRING],
      ["specTarget", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["groupId", ecs.TYPE_INT64],
      ["player_group__memberIndex", ecs.TYPE_INT]
    ]
    comps_rq = ["player"]
  }
)

return {
  localPlayerName
  localPlayerEid
  localPlayerTeam
  localPlayerUserId
  localPlayerSpecTarget
  localPlayerGroupId
  localPlayerGroupMembers
  localPlayerIsInActiveOpenGroup
}
