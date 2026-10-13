from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, CrossPlayStateWeight, CrossplayState
from "%ui/gdk/privileges.nut" import try_resolve_crossplay_privilege
from "%ui/squad/squadManager.nut" import squadMembers, tryResolveLiveCrossplayPrivilege, leaveSquadSilent, acceptSquadInvite, requestJoinSquad
from "%ui/state/roomState.nut" import joinRoom
from "%ui/gameModes/eventModesState.nut" import openCustomGameMode
from "%ui/ui_library.nut" import *

let logSq = require("%enlSqGlob/library_logs.nut").with_prefix("[SQUAD] ")
let MSquadAPI = require("%ui/squad/squadAPI.nut")

enum SquadActions {
  REQUEST_JOIN_SQUAD = "requestJoinSquad"
  ACCEPT_SQUAD_INVITE = "acceptSquadInvite"
}

function checkSquadMemberData(isDataReady) {
  if (!isDataReady)
    return

  tryResolveLiveCrossplayPrivilege(function(resolved) {
    if (!resolved)
      leaveSquadSilent()
  })
}

let squadMembersStateReady = keepref(Computed(function() {
  let membersTbl = squadMembers.get()
  if (membersTbl.len() <= 1)
    return false

  foreach (member in membersTbl) {
    let { state = {} } = member
    if (state.len() == 0) 
      return false
  }

  return true
}))
squadMembersStateReady.subscribe(checkSquadMemberData)

let actionsToFn = {
  [SquadActions.REQUEST_JOIN_SQUAD] = requestJoinSquad,
  [SquadActions.ACCEPT_SQUAD_INVITE] = acceptSquadInvite
}

function processSquadData(response) {
  let { squads = [], context = {} } = response
  let { action = null, squadId = null } = context
  let joinFn = actionsToFn?[action]
  if (joinFn == null || squadId == null) {
    logSq("Incorrect data in msquad.get_squads")
    return
  }

  if (squads.len() == 0) {
    logSq($"Squad {squadId} is not created yet, do {action}")
    joinFn?(squadId) 
    return
  }

  let { data = {} } = squads.findvalue(@(squad) squad.leader == squadId)
  let squadCrossplay = data?.crossnetworkPlay ?? CrossplayState.ALL
  if ((CrossPlayStateWeight?[crossnetworkPlay.get()] ?? 0)
        >= CrossPlayStateWeight[squadCrossplay]) {
    logSq($"Squad {squadId} created with {squadCrossplay}, compared to {crossnetworkPlay.get()}")
    joinFn?(squadId)
    return
  }

  try_resolve_crossplay_privilege(function(resolved) {
    logSq($"For squad {squadId} privileges resolved {resolved}")
    if (resolved)
      joinFn?(squadId)
  })
}


MSquadAPI.onGetSquads({
  onSuccess = processSquadData
  onFailure = function(response) {
    logSq($"Failed request msquad.get_squads: {response?.error_id}")
  }
})

let callJoinRoom = @(roomId)
  joinRoom({ roomId }, true, function(...) { openCustomGameMode() })

MSquadAPI.onGetRoomData({
  onSuccess = function(room) {
    let { roomId = null } = room
    let { crossplay = CrossplayState.ALL } = room?.public
    if (roomId == null || crossplay not in CrossPlayStateWeight) {
      logSq("Incorrect data in mrooms.get_room result")
      return
    }

    if ((CrossPlayStateWeight?[crossnetworkPlay.get()] ?? 0)
        >= CrossPlayStateWeight[crossplay]) {
      callJoinRoom(roomId)
      return
    }

    try_resolve_crossplay_privilege(function(resolved) {
      if (resolved)
        callJoinRoom(roomId)
    })
  }
  onFailure = function(response) {
    logSq($"Failed request mrooms.get_room: {response?.error_id}")
  }
})

function joinSquadWithChecks(squadIdStr, action) {
  let squadId = squadIdStr.tointeger()
  logSq($"Joining squad SquadId: {squadId}")
  MSquadAPI.getSquads([squadId], { action, squadId })
}

function joinRoomWithChecks(roomIdStr) {
  let roomId = roomIdStr.tointeger()
  logSq($"Joining room RoomID: {roomId}")
  MSquadAPI.getRoomData(roomId)
}

return {
  joinSquadWithChecks
  joinRoomWithChecks
  SquadActions
}
