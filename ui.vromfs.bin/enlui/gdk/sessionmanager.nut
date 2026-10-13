from "%ui/contacts/consoleUidsRemap.nut" import uid2console
from "%ui/squad/squadState.nut" import isInSquad, squadId, subsMemberAddedEvent, subsMemberRemovedEvent
from "%ui/gdk/activity_export.nut" import ActivityType, make_connection_string, update_activity, clear_activity, send_invite

let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[SESSION_MANAGER] ")


function invite(uid, callback) {
  let xboxUid = uid2console.get()?[uid.tostring()]
  if (xboxUid == null) {
    logX($"Try invite user {uid} with unknown xbox uid")
    return
  }

  let connectionString = make_connection_string(ActivityType.Group, squadId.get().tostring())

  send_invite(xboxUid.tointeger(), connectionString, function(_) {
    callback?()
  })
}


function join(session_id, invitation_id, on_success) {
  logX($"join to session {session_id} received from {invitation_id}")
  update_activity(function(_) {
    on_success?()
  })
}


function update_data(leaderUid) {
  logX($"change leader on xbox system, notify about new leader id {leaderUid}")
  clear_activity(function(_) {
    update_activity()
  }) 
}


function create(_, callback) {
  update_activity(function(_) {
    callback?()
  })
}


function leave() {
  
  
}


subsMemberAddedEvent(function(user_id) {
  logX($"update activity ? {isInSquad.get()} on subsMemberAddedEvent {user_id}")
  update_activity()
})


subsMemberRemovedEvent(function(user_id) {
  logX($"update activity ? {isInSquad.get()} on subsMemberRemovedEvent {user_id}")
  update_activity()
})


return {
  update_data = update_data
  leave = leave
  invite = invite
  create = create
  join = join
}