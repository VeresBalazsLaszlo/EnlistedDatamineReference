import "%enlSqGlob/userInfo.nut" as userInfo
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "%ui/sony/psn_state.nut" import psn_invitation_dataUpdate, psn_invitation_data, psn_game_intentUpdate, psn_was_logged_out, psn_was_logged_outUpdate
from "dng.sony" import check_psn_logged_in
from "%ui/squad/squadManager.nut" import acceptSquadInvite, leaveSquadSilent
from "%ui/squad/squadAPI.nut" import requestMembership
from "%ui/state/appState.nut" import isInBattleState, isInMainMenuState
from "%ui/components/msgbox.nut" import showMsgbox
from "eventbus" import eventbus_subscribe, eventbus_send
from "%ui/quickMatchQueue.nut" import leaveQueue
from "%ui/contacts/consoleUidsRemap.nut" import uid2console
from "%ui/gameModes/sandbox/customMissionState.nut" import isFullSonyClient
from "%ui/ui_library.nut" import *
from "%ui/state/roomState.nut" import leaveRoom

let MSquadAPI = require("%ui/squad/squadAPI.nut")
let loginState = require("%ui/state/login_state.nut")
let session = require("%ui/sony/session.nut")
let loginChain = require("%ui/login/login_chain.nut")
let logP = with_prefix("[PSNENV] ")
let { open_player_profile = @(...) null, PlayerAction = null } = require("sony.social")
let { requestChunkStatus = @(...) null, ChunkStatus } = require("sony.playgo")


const JOIN_SESSION_ID = "join_session_after_sony_login"

function join_session_impl(data, invitations) {
  let { session_id, invitation_id } = data
  session.join(session_id, invitation_id, function(squadId) {
    logP($"Trying to join squad {squadId}")
    if (invitations.contains(squadId.tointeger())) {
      logP("Invitation was found, accepting")
      acceptSquadInvite(squadId.tointeger())
    }
    else {
      logP("Invitation wasn't found, requesting squad membership")
      requestMembership(squadId.tointeger())
    }
  })
}

function join_session(session_data) {
  logP("Fetching MSquad info for invitations check")
  MSquadAPI.getSquadInfoCall({
    onAnyResult = function(data) {
      if (data.error != 0) {
        logP("Failed to get invitations info, skipping join")
        return
      }
      let invitations = data?.invites ?? []
      join_session_impl(session_data, invitations)
    }
  })
}
let persistActions = persist("persistActions",@() {})
persistActions[JOIN_SESSION_ID] <- join_session


function onSessionInvitation(data) {
  logP($"got invitation to {data?.session_id}: uinfo {userInfo.get()}, lstage {loginChain?.currentStage.get()}")
  if (userInfo.get() != null) {
    if (isInBattleState.get()) {
      psn_invitation_dataUpdate(data)
      eventbus_send("ipc.onInviteAccepted", null)
    } else {
      join_session(data)
    }
  } else if (loginChain.currentStage.get() != null) {
    psn_invitation_dataUpdate(data)
  } else {
    loginChain.doAfterLoginOnce(@() persistActions[JOIN_SESSION_ID](data))
    loginChain.startLogin({})
  }
}

function onGameIntent(data) {
  logP($"got game intent {data?.action}, session {data?.sessionId}, activity {data?.activityId}")
  if (data.sessionId != "") {
    onSessionInvitation({session_id = data.sessionId, invitation_id = null})
    return
  }
  psn_game_intentUpdate(data)
  if (loginState.isLoggedIn.value == null)
    loginChain.startLogin({})
}

function onResume(_) {
  if (loginChain.currentStage.get() != null) {
    loginChain.interrupt()
    return
  }
  loginState.logOut()
}

function do_logout() {
  loginState.logOut()
  showMsgbox(loc("yn1/disconnection/psn", { game = loc("title/name") }))
}


eventbus_subscribe("psn.logged_in", function(result) {
  if (!result)
    do_logout()
})


function process_logout(skip_checks) {
  if (!skip_checks) {
    if (psn_was_logged_out.get()) {
      psn_was_logged_outUpdate(false)
      check_psn_logged_in()
    }
  } else {
    do_logout()
  }
}

function onLoginStateUpdate(is_signed_in) {
  if (!is_signed_in) {
    if (loginChain.currentStage.get() != null) {
      psn_was_logged_outUpdate(true)
      return
    }
    if (userInfo.get() != null)
      process_logout(true)
  }
}

loginState.isLoggedIn.subscribe(function(v) {
  if (!v) {
    if (isInBattleState.get())
      switch_to_menu_scene()
  }
})

isInMainMenuState.subscribe(@(v) v
  ? requestChunkStatus(1, @(res) isFullSonyClient.set(res == ChunkStatus.DOWNLOADED))
  : null)

eventbus_subscribe("dng.sony.login_state_update", onLoginStateUpdate)
eventbus_subscribe("dng.sony.resume", onResume)
eventbus_subscribe("dng.sony.game_intent", onGameIntent)

loginState.isLoggedIn.subscribe(function(v) {
  if (v)
    process_logout(false)
  else
    leaveQueue()
})

eventbus_subscribe("ipc.onBattleExitAccept", function(_) {
  defer(switch_to_menu_scene)
  leaveSquadSilent(function(...) {
    if (psn_invitation_data.get() != null) {
      join_session(psn_invitation_data.get())
      psn_invitation_dataUpdate(null)
    }
  })
})

eventbus_subscribe("matching.logged_out", function(_notify) {
  leaveQueue()
  leaveRoom()
})

eventbus_subscribe("showPsnUserInfo", @(msg) open_player_profile(
  (uid2console.get()?[msg.userId.tostring()] ?? "-1").tointeger(),
  PlayerAction?.DISPLAY,
  "",
  {}
))

eventbus_subscribe("PSNAuthContactsReceived", function(_) {
  if (psn_invitation_data.get()) {
    join_session(psn_invitation_data.get())
    psn_invitation_dataUpdate(null)
  }
})
