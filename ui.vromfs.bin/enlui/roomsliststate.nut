import "math" as math
import "matching.errors" as matching_errors
from "%ui/matchingClient.nut" import matchingCall
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

const REFRESH_PERIOD = 10.0

let debugMode = mkWatched(persist, "debugMode", false)
let isRefreshEnabled = mkWatched(persist, "isRefreshEnabled", false)
let roomsList = mkWatched(persist, "roomsList", [])
let isRequestInProgress = mkWatched(persist, "isRequestInProgress", false)
let curError = Watched(null)

function listRoomsCb(response) {
  isRequestInProgress.set(false)
  if (debugMode.get())
    return
  if (response.error) {
    curError.set(matching_errors.error_string(response.error))
    roomsList.set([])
  } else {
    curError.set(null)
    roomsList.set(response.digest)
  }
}

function updateListRooms(){
  if (isRequestInProgress.get())
    return

  isRequestInProgress.set(true)
  let params = {
    group = "custom-lobby"
    cursor = 0
    count = 100
    filter = {
    }
  }
  matchingCall("mrooms.fetch_rooms_digest2", listRoomsCb, params)
}

function updateRefreshTimer(isEnabled) {
  if (isEnabled) {
    updateListRooms()
    gui_scene.setInterval(REFRESH_PERIOD, updateListRooms)
  } else
    gui_scene.clearTimer(updateListRooms)
}
subscribeAndInit(updateRefreshTimer, isRefreshEnabled)

function switchDebugMode() {
  function debugRooms() {
    let list = array(100).map(function(_) {
      let rnd = math.rand()
      let creator = $"%Username%{rnd%11}"
      return {
        roomId = rnd
        membersCnt = 2 + rnd % 25
        public = {
          creator
          hasPassword = !(rnd % 3)
        }
      }
    })
    roomsList.set(list)
  }
  debugMode.set(!debugMode.get())
  if (debugMode.get()){
    isRefreshEnabled.set(false)
    debugRooms()
  }
  else{
    isRefreshEnabled.set(true)
  }
}

console_register_command(switchDebugMode, "rooms.switchDebugMode")

return {
  list = roomsList
  error = curError
  isRequestInProgress
  isRefreshEnabled
}
