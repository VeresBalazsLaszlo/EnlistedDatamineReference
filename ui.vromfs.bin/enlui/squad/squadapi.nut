from "%ui/matchingClient.nut" import matchingCall, matchingSubscribe, matchingRequest
from "%ui/ui_library.nut" import *

function reportError(resp) {
  if (resp.error == 0)
    return false
  log(resp)
  return true
}

let STANDARD_CB_PARAMS = {
  onAnyResult = null 
  onSuccess = null   
  onFailure = null   
}

local makePerformCallback = @(cbParams = STANDARD_CB_PARAMS)
  function(resp) {
    cbParams = STANDARD_CB_PARAMS.__merge(cbParams)
    let isSuccess = !reportError(resp)
    if (cbParams.onAnyResult)
      cbParams.onAnyResult(resp)
    else if (isSuccess && cbParams.onSuccess)
      cbParams.onSuccess(resp)
    else if (!isSuccess && cbParams.onFailure)
      cbParams.onFailure(resp)
  }

return {
  createSquad = @()
    matchingRequest("msquad.create_squad")
  onCreateSquad = @(cbParams)
    matchingSubscribe("msquad.create_squad", makePerformCallback(cbParams))

  disbandSquad = @()
    matchingCall("msquad.disband_squad")

  getSquadInfo = @(context)
    matchingRequest("msquad.get_info", null, context)
  onGetSquadInfo = @(cbParams)
    matchingSubscribe("msquad.get_info", makePerformCallback(cbParams))
  getSquadInfoCall = @(cbParams)
    matchingCall("msquad.get_info", makePerformCallback(cbParams))

  setMemberData = @(data)
    matchingCall("msquad.set_member_data",null, data)

  getMemberData = @(userId)
    matchingRequest("msquad.get_member_data", { userId })
  onGetMemberData = @(cbParams)
    matchingSubscribe("msquad.get_member_data", makePerformCallback(cbParams))

  invitePlayer = @(userId)
    matchingRequest("msquad.invite_player", { userId })
  onInvitePlayer = @(cbParams)
    matchingSubscribe("msquad.invite_player",makePerformCallback(cbParams))

  revokeInvite = @(userId)
    matchingCall("msquad.revoke_invite", null, { userId })

  dismissMember = @(userId)
    matchingCall("msquad.dismiss_member", null, { userId })

  transferSquad = @(userId)
    matchingRequest("msquad.transfer_squad", { userId })
  onTransferSquad = @(cbParams)
    matchingSubscribe("msquad.transfer_squad", makePerformCallback(cbParams))

  setSquadData = @(data)
    matchingRequest("msquad.set_squad_data", data)
  onSetSquadData = @(cbParams)
    matchingSubscribe("msquad.set_squad_data", makePerformCallback(cbParams))

  acceptMembership = @(userId)
    matchingCall("msquad.accept_membership", null, { userId })

  denyMembership = @(userId) 
    matchingCall("msquad.deny_membership", null, { userId })

  acceptInvite = @(squadId)
    matchingRequest("msquad.accept_invite", { squadId })
  onAcceptInvite = @(cbParams)
    matchingSubscribe("msquad.accept_invite", makePerformCallback(cbParams))

  rejectInvite = @(squadId)
    matchingCall("msquad.reject_invite", null, { squadId })

  requestMembership = @(squadId)
    matchingCall("msquad.request_membership", null, { squadId })

  requestJoin = @(userId)
    matchingRequest("msquad.join_player", { userId })
  onRequestJoin = @(cbParams)
    matchingSubscribe("msquad.join_player", makePerformCallback(cbParams))

  revokeMembershipRequest = @(squadId) 
    matchingCall("msquad.revoke_membership_request", null, { squadId })

  leaveSquad = @(cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.leave_squad", makePerformCallback(cbParams))

  getSquads = @(players, context)
    matchingRequest("msquad.get_squads", { players }, context)
  onGetSquads = @(cbParams)
    matchingSubscribe("msquad.get_squads", makePerformCallback(cbParams))

  getRoomData = @(roomId)
    matchingRequest("mrooms.get_room", { roomId })
  onGetRoomData = @(cbParams)
    matchingSubscribe("mrooms.get_room", makePerformCallback(cbParams))
}
