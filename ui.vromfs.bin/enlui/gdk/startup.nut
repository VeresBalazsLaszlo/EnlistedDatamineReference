from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "eventbus" import eventbus_subscribe, eventbus_send
from "%gdkLib/activation.nut" import hasActivationData, resetActivationData, get_activation_data, register_activation_callback
from "%gdkLib/display.nut" import isDimAllowed
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/login/login_chain.nut" import currentStage, doAfterLoginOnce
from "%ui/squad/squadManager.nut" import isInSquad, leaveSquadSilent
from "%ui/gdk/crossplayChecks.nut" import joinSquadWithChecks, joinRoomWithChecks, SquadActions
from "%ui/gdk/relationships.nut" import initialize_relationships, update_relationships
from "%gdkLib/impl/app.nut" import register_unconstrain_callback
from "%gdkLib/crossnetwork.nut" import init_crossnetwork, shutdown_crossnetwork
from "%ui/state/roomState.nut" import leaveRoom, isInRoom
from "%ui/gdk/privileges.nut" import try_resolve_multiplayer_privilege
from "%ui/gdk/activity_export.nut" import ActivityType, parse_connection_string
from "frp" import this_subscriber_call_may_take_up_to_usec, get_slow_subscriber_threshold_usec
from "%ui/ui_library.nut" import *

let MSquadAPI = require("%ui/squad/squadAPI.nut")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[STARTUP] ")


function do_login() {
  logX("do_login")
  init_crossnetwork()
  initialize_relationships()
}


function do_logout() {
  logX("do_logout")
  shutdown_crossnetwork()
}


isLoggedIn.subscribe(function(v) {
  isDimAllowed.set(!v)
  this_subscriber_call_may_take_up_to_usec(10 * get_slow_subscriber_threshold_usec())
  if (!v) {
    resetActivationData()
    if (isInBattleState.get())
      switch_to_menu_scene()
    do_logout()
  } else {
    do_login()
  }
})


function try_leave_squad(cb = null) {
  logX($"try_leave_squad, isInSquad.get() {isInSquad.get()}")
  if (isInSquad.get()) {
    leaveSquadSilent(cb)
  }
  else
    cb?()
}


function try_leave_room(cb = null) {
  logX($"try_leave_room, isInRoom.get() {isInRoom.get()}")
  if (isInRoom.get()) {
    leaveRoom(cb)
  } else
    cb?()
}


function leave_everything(cb = null) {
  try_leave_squad(function(...) {
    try_leave_room(function(...) {
      cb?()
    })
  })
}


function join_squad_impl(connection_string, invitations) {
  let squadId = connection_string
  logX($"Trying to join squad {squadId}")
  if (!invitations.contains(squadId.tointeger())) {
    logX("Invitation wasn't found, requesting squad join")
    joinSquadWithChecks(squadId, SquadActions.REQUEST_JOIN_SQUAD)
  }
  else {
    logX("Invitation was found, accepting")
    joinSquadWithChecks(squadId, SquadActions.ACCEPT_SQUAD_INVITE)
  }
}


function join_squad(connection_string) {
  logX("Fetching MSquad info for invitations check")
  MSquadAPI.getSquadInfoCall({
    onAnyResult = function(data) {
      if (data.error != 0 && data?.error_id != "NOT_SQUAD_MEMBER") {
        logX("Failed to get invitations info, skipping join")
        return
      }
      let invitations = data?.invites ?? []
      join_squad_impl(connection_string, invitations)
    }
  })
}


function complete_activation_impl(activationData) {
  try_resolve_multiplayer_privilege(function(resolved) {
    if (resolved) {
      let parsed = parse_connection_string(activationData)
      if (parsed.type == ActivityType.Group)
        leave_everything(@() join_squad(parsed.connection))
      else if (parsed.type == ActivityType.Room)
        leave_everything(@() joinRoomWithChecks(parsed.connection))
    }
    resetActivationData()
  })
}


function complete_activation() {
  let activationData = get_activation_data()
  if (currentStage.get()) {
    logX("Activated during login process, activation will be handled after login completion")
    doAfterLoginOnce(@() complete_activation_impl(activationData))
  } else {
    logX("Regular activation")
    complete_activation_impl(activationData)
  }
}


function activation_handler() {
  if (isInBattleState.get()) {
    eventbus_send("ipc.onInviteAccepted", null)
  } else {
    logX("Check squad invite in menu")
    complete_activation()
  }
}

eventbus_subscribe("ipc.onBattleExitAccept",  function(_) {
  defer(function() {
    switch_to_menu_scene()
    logX("Check squad invite without loading vrom")
    complete_activation()
  })
})

if (hasActivationData()) {
  logX("Check squad invite on loading vrom")
  complete_activation()
}

function updateStatesIfLoggedIn() {
  if (!isLoggedIn.get())
    return

  update_relationships()
}


function application_constrain_event_handler() {
  updateStatesIfLoggedIn()
}


register_activation_callback(activation_handler)
register_unconstrain_callback(application_constrain_event_handler)

updateStatesIfLoggedIn()
