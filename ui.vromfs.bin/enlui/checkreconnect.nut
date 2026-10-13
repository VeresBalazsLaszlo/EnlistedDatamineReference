import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/matchingClient.nut" import matchingSubscribe, matchingRequest, matchingLogin
from "%ui/featureFlags.nut" import allowReconnect
from "%ui/state/roomState.nut" import joinRoom, isLastMatchDisconnect
from "%ui/state/appState.nut" import isInBattleState
from "%ui/components/msgbox.nut" import showMsgbox
from "%dngscripts/globalState.nut" import nestWatched
from "app" import get_app_id
from "%ui/state/login_state.nut" import isLoggedIn
from "eventbus" import eventbus_subscribe_onehit
from "%ui/ui_library.nut" import *

let isReconnectChecking = nestWatched("isReconnectChecking", false)

matchingSubscribe("enlmm.check_reconnect", function(response) {
  isReconnectChecking.set(false)
  let roomId = response?.roomId
  if (roomId == null)
    return

  log("found reconnect for room", roomId)
  showMsgbox({
    text = loc("do_you_want_to_reconnect"),
    buttons = [
      {
        text = loc("Yes")
        action = @() joinRoom({ roomId = roomId }, false, function(...) {})
        isCurrent = true
      },
      {
        text = loc("No")
        isCancel = true
      }
    ]
  })
})

function checkReconnect() {
  if (isInBattleState.get() || !allowReconnect.get()
      || isReconnectChecking.get() || !isLoggedIn.get())
    return
  isReconnectChecking.set(true)
  matchingRequest("enlmm.check_reconnect", {appId = get_app_id()} )
}

isLastMatchDisconnect.subscribe(function(canReconnect) {
  if ((canReconnect ?? false) && isLoggedIn.get()) {
    let { userId, name, chardToken, token } = userInfo.get()
    let loginInfo = {
      userId
      name
      chardToken
      authJwt = token 
    }
    matchingLogin(loginInfo)
    eventbus_subscribe_onehit("matching.logged_in", @(...) checkReconnect())
  }
})

isLoggedIn.subscribe(function(state) {
  if (state)
    checkReconnect()
})

return checkReconnect
