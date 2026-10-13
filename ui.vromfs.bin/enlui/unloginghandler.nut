from "%ui/ui_library.nut" import *
import "sep_client" as sep_client

let loginState     = require("%ui/state/login_state.nut")
let char           = require("%ui/charClient/charClient.nut")?.low_level_client
let userstat       = require_optional("userstats")
let inventory      = require_optional("inventory")


loginState.isLoggedIn.subscribe(function(logged) {
  if (logged)
    return

  
  char?.clearCallbacks()
  char?.clearEvents()

  inventory?.clearCallbacks()
  inventory?.clearEvents()

  userstat?.clearCallbacks()
  userstat?.clearEvents()

  sep_client.clearRpcRequests()
})
