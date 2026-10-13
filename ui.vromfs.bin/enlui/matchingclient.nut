import "%enlSqGlob/appInfo.nut" as appInfo
import "matching.errors" as matching_errors
from "%ui/components/msgbox.nut" import showMsgbox
from "matching.api" import matching_call
from "%ui/state/login_state.nut" import isSteamRunning, isLoggedIn, logOut, isSteamConnectionLost
from "eventbus" import eventbus_subscribe, eventbus_subscribe_onehit
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *
from "%ui/connectHolderR.nut" import serverResponseError, isMatchingConnected,
  activateMatchingLogin, deactivateMatchingLogin

let matchingLoginActions = []
let loginInfo = { value = null }

let debugDelay = mkWatched(persist, "debugDelay", 0)

let matchingResponseCallbacks = {}
let matchingResponseAwait = nestWatched($"matchingResponseAwait", {})

let mkEventId = @(cmd, reqId)  $"{cmd}.{reqId}"

isLoggedIn.subscribe(function(val) {
  if (!val) {
    deactivateMatchingLogin()
    loginInfo.value = null
  }
})

function netStateCall(func) {
  if (isMatchingConnected.get())
    func()
  else
    matchingLoginActions.append(func)
}

function matchingCallDeferred(cmd, cb, params) {
  let res = matching_call(cmd, params)
  if (cb == null)
    return

  let { reqId = null } = res
  if (reqId != null)
    eventbus_subscribe_onehit(mkEventId(cmd, reqId), cb)
  else
    cb(res)
}

let matchingCallImpl = @(cmd, cb = null, params = null)
  defer(@() matchingCallDeferred(cmd, cb, params))

let matchingCall = @(cmd, cb = null, params = null) debugDelay.get() <= 0
  ? matchingCallImpl(cmd, cb, params)
  : gui_scene.setTimeout(debugDelay.get(), @() matchingCallImpl(cmd, cb, params))

eventbus_subscribe("matching.login_failed", function(_result) {
  matchingLoginActions.clear()
  logOut()
})

eventbus_subscribe("matching.logged_out", function(notify) {
  matchingLoginActions.clear()
  logOut()

  if (notify != null) {
    if (notify.reason == matching_errors.DisconnectReason.ConnectionClosed && notify.message.len() == 0) {
      if (isSteamRunning.get())
        isSteamConnectionLost.set(true)
      showMsgbox({
        text = loc("error/CLIENT_ERROR_CONNECTION_CLOSED")
        buttons = [{ text = loc("Ok"), isCurrent = true }]
      })
    }
    else {
      log($"Matching server disconnect by {notify.reason} with message {notify.message}")
      showMsgbox(loc("msgboxtext/matchingDisconnect",
          { error = loc("error/{0}".subst(notify.reason_str)) }))
    }
  }
})

eventbus_subscribe("matching.logged_in", function(_reason) {
  let actions = clone matchingLoginActions
  matchingLoginActions.clear()
  foreach (act in actions)
    act()
})

function matchingLogin(userInfo = null) {
  if (userInfo)
    loginInfo.value <- {
      userId = userInfo.userId
      userName = userInfo.name
      token = userInfo.chardToken
      versionStr = appInfo.version.get()
      authJwt = userInfo.authJwt
    }

  activateMatchingLogin(loginInfo.value)
}

function onResponseCallback(cmd, response, eventId = null) {
  local context
  if (eventId != null)
    matchingResponseAwait.mutate(function(obj) {
      context = obj?[cmd].rawdelete(eventId)
    })
  foreach (cb in matchingResponseCallbacks?[cmd] ?? [])
    cb(response.__merge({ context }))
}

function matchingSubscribe(cmd, cb) {
  let subscribers = matchingResponseCallbacks?[cmd] ?? []
  if (!subscribers.contains(cb))
    subscribers.append(cb)
  matchingResponseCallbacks[cmd] <- subscribers
}

function matchingRequest(cmd, requestData = null, contextData = null) {
  let request = matching_call(cmd, requestData)
  let { reqId = null } = request
  if (reqId == null) {
    onResponseCallback(cmd, request)
    return
  }

  let eventId = mkEventId(cmd, reqId)
  matchingResponseAwait.mutate(function(obj) {
    let events = obj?[cmd] ?? {}
    events[eventId] <- contextData ?? requestData
    obj[cmd] <- events
  })
  eventbus_subscribe_onehit(eventId, @(response)
    onResponseCallback(cmd, response, eventId))
}

function restoreSubscriptions() {
  foreach (iterCmd, events in matchingResponseAwait.get()) {
    let cmd = iterCmd
    foreach (iterEventId, _ in events) {
      let eventId = iterEventId
      eventbus_subscribe_onehit(eventId, @(response)
        onResponseCallback(cmd, response, eventId))
    }
  }
}
restoreSubscriptions()

console_register_command(@(delay) debugDelay.set(delay), "matching.delay_calls")

return {
  serverResponseError
  matchingCall
  matchingLogin
  netStateCall

  matchingSubscribe
  matchingRequest
}
