from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/matchingClient.nut" import matchingCall
from "%ui/state/login_state.nut" import isLoggedIn
from "%dngscripts/platform.nut" import is_xbox
from "%ui/ui_library.nut" import *

let isIncognitoAvailable = !is_xbox
let incognitoState = nestWatched("incognitoState",
  get_setting_by_blk_path("incognitoEnabled") ?? false)

let doRequest = @(value) matchingCall("mpresence.set_invisible_flag",
  function (response) {
    if (response.error != 0)
      log($"Error on updating incognito state to {value}")
  },
  { value }
)

function incognitoStateUpdate(value) {
  incognitoState.set(value)
  doRequest(value)
}

isLoggedIn.subscribe(function(v) {
  if (v && incognitoState.get())
    doRequest(true)
})

return {
  incognitoState
  incognitoStateUpdate
  isIncognitoAvailable
}
