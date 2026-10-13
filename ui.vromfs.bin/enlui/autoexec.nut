import "%enlSqGlob/userInfo.nut" as userInfo
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/components/msgbox.nut" import removeAllMsgboxes
from "app" import switch_scene
from "gameevents" import EventUserLoggedIn, EventUserLoggedOut
from "%ui/ui_library.nut" import *

require("%ui/unlogingHandler.nut")
require("%ui/state/customRooms.nut")
require("%ui/registerConsoleCmds.nut")

gui_scene.setShutdownHandler(function() {
  removeAllMsgboxes()
})

let delayedLogout = persist("delayedLogout", @() { need = false })

function on_login() {
  switch_to_menu_scene()
  ecs.g_entity_mgr.broadcastEvent(EventUserLoggedIn(userInfo.get().userId, userInfo.get().name))
}

function on_logout() {
  switch_scene("gamedata/scenes/empty.blk")
  ecs.g_entity_mgr.broadcastEvent(EventUserLoggedOut())
}



isInBattleState.subscribe(
  function (active) {
    if (!active && delayedLogout.need) {
      on_logout()
      delayedLogout.need = false
    }
  }
)

isLoggedIn.subscribe(function (state) {
  if (state) {
    on_login()
  }
  else {
    if (!isInBattleState.get()) {
      on_logout()
    }
    else {
      delayedLogout.need = true
    }
  }
})
