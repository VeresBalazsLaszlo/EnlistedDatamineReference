import "%enlSqGlob/userInfo.nut" as userInfo
from "%gdkLib/mpa.nut" import JoinRestriction, set_activity, clear_activity, send_invitations
from "%ui/state/queueState.nut" import availableSquadMaxMembers
from "%ui/squad/squadState.nut" import isInSquad, isSquadLeader, squadId, squadLen
from "%ui/state/roomState.nut" import isInRoom, room, roomMembers
from "%ui/gameModes/gameModeState.nut" import currentGameMode
from "%ui/gdk/activity_export.nut" import ActivityType, make_connection_string, set_update_activity_fn, set_clear_activity_fn, set_send_invite_fn
from "%ui/ui_library.nut" import *

let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[ACTIVITY] ")


let ActivityNames = [
  "Unknown",
  "InSquad",
  "InRoom",
  "Idle"
]


enum CurrentActivity {
  Unknown = 0,
  InSquad = 1,
  InRoom = 2,
  Idle = 3
}


let activityState = Computed(function() {
  if (userInfo.get()) {
    if (isInRoom.get())
      return CurrentActivity.InRoom
    if (isInSquad.get())
      return CurrentActivity.InSquad
    return CurrentActivity.Idle
  }
  return CurrentActivity.Unknown
})


function update_activity_in_squad(callback) {
  logX("Update squad activity")
  let maxMembers = availableSquadMaxMembers.get()
  let currentMembers = squadLen.get()
  let sessionId = squadId.get().tostring()
  let validGroupSize = ((currentGameMode.get()?.maxGroupSize ?? 1) > 1)
  let connectionString = make_connection_string(ActivityType.Group, sessionId)
  if (isSquadLeader.get() && validGroupSize) {
    set_activity(connectionString, JoinRestriction.InviteOnly, maxMembers, currentMembers, sessionId, true, function(success) {
      logX($"Activity updated: {success}")
      callback?(success)
    })
  } else {
    logX("Skip setting activity because of unmet requirements")
    callback?(true)
  }
}


function update_activity_in_room(callback) {
  logX("Update room activity")
  let maxMembers = room.get()?.public.maxPlayers ?? 1
  let currentMembers = roomMembers.get()?.len() ?? 1
  let sessionId = room.get()?.roomId.tostring() ?? ""
  let connectionString = make_connection_string(ActivityType.Room, sessionId)
  set_activity(connectionString, JoinRestriction.Public, maxMembers, currentMembers, sessionId, true, function(success) {
    logX($"Activity updated: {success}")
    callback?(success)
  })
}


function update_activity_idle(callback) {
  logX("Update idle activity")
  let maxMembers = availableSquadMaxMembers.get()
  let currentMembers = 1
  let sessionId = userInfo.get()?.userIdStr ?? ""
  let validGroupSize = ((currentGameMode.get()?.maxGroupSize ?? 1) > 1)
  let connectionString = make_connection_string(ActivityType.Group, sessionId)
  if (validGroupSize) {
    set_activity(connectionString, JoinRestriction.InviteOnly, maxMembers, currentMembers, sessionId, true, function(success) {
      logX($"Activity updated: {success}")
      callback?(success)
    })
  } else {
    logX("Skip setting activity because of unmet requirements")
    callback?(true)
  }
}


function update_activity(callback = null) {
  logX($"Update <{ActivityNames[activityState.get()]}> activity")
  if (activityState.get() == CurrentActivity.InSquad)
    return update_activity_in_squad(callback)
  if (activityState.get() == CurrentActivity.InRoom)
    return update_activity_in_room(callback)
  if (activityState.get() == CurrentActivity.Idle)
    return update_activity_idle(callback)

  logX("Activity state is \"Unknown\", so there is no need to update it")
  callback?(false)
}


function send_invite(xuid, invite_data, callback) {
  logX($"Send invite to {xuid}")
  send_invitations(invite_data, [xuid], true, function(success) {
    callback?(success)
  })
}


activityState.subscribe(function(v) {
  logX($"Activity changed to: {ActivityNames[v]}")
  if (v == CurrentActivity.Unknown)
    return clear_activity(null)
  update_activity()
})


currentGameMode.subscribe(function(_) {
  update_activity()
})


set_update_activity_fn(update_activity)
set_clear_activity_fn(clear_activity)
set_send_invite_fn(send_invite)
