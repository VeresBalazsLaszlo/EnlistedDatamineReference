import "steam" as steam
import "epic" as epic
from "%enlSqGlob/userInfoState.nut" import userInfo, userInfoUpdate, userPermissionsUpdate
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/components/modalWindows.nut" import hideAllModalWindows
from "eventbus" import eventbus_subscribe
from "auth" import token_renew_event, YU2_OK
from "%ui/ui_library.nut" import *

let isSteamRunning = nestWatched("isSteamRunning", steam.is_running())
let isSteamFirstOpen = mkWatched(persist, "isSteamFirstOpen", true)
let isSteamConnectionLost = mkWatched(persist, "isSteamConnectionLost", false)
let isEpicRunning = nestWatched("isEpicRunning", epic.is_running())
let isLoggedIn = Computed(@() userInfo.get() != null)

function logOut() {
  println("logout")
  hideAllModalWindows()
  userInfoUpdate(null)
  userPermissionsUpdate({})
}

console_register_command(logOut, "app.logout")

eventbus_subscribe(token_renew_event, function(res) {
  if (res?.status == YU2_OK)
    return

  println($"logout due to auth token renew failure: {res?.status}")
  if (isSteamRunning.get())
    isSteamConnectionLost.set(true)
  logOut()
})

isSteamConnectionLost.subscribe(function(v) {
  if (v)
    isSteamFirstOpen.set(true)
})

return {
  logOut
  isLoggedIn
  isSteamRunning
  isEpicRunning
  isSteamFirstOpen
  isSteamConnectionLost
}
