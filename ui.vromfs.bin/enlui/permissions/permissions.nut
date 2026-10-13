import "%dngscripts/platform.nut" as platform
from "%enlSqGlob/appInfo.nut" import isProductionCircuit
from "%ui/components/msgbox.nut" import showMsgbox
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let dbgMultiplayerPermissions = Watched(true)

local checkMultiplayerPermissions = function checkMultiplayerPermissions(callback) { 
  if (dbgMultiplayerPermissions.get())
    callback?(true)
  else {
    showMsgbox(loc("No multiplayer permissions"))
    callback?(false)
  }
}
console_register_command(function() {
  dbgMultiplayerPermissions.set(!dbgMultiplayerPermissions.get())
  console_print($"mutliplayer permissions set to: {dbgMultiplayerPermissions.get()}")
}, "feature.toggleMultiplayerPermissions")

if (platform.is_ps5) {
  let { hasPremium, requestPremiumStatusUpdate } = require("sony.user")
  eventbus_subscribe("psPlusSuggested", @(_) requestPremiumStatusUpdate(@(_) null))
  let { suggest_psplus } = require("sony.store")

  function suggestAndAllowPsnPremiumFeatures(callback) {
    if (hasPremium() || isProductionCircuit.get()) { 
      callback?(true)
      return
    }

    suggest_psplus("psPlusSuggested", {})
    callback?(false)
  }

  checkMultiplayerPermissions = suggestAndAllowPsnPremiumFeatures
} else if (platform.is_gdk) {
  let { try_resolve_multiplayer_privilege } = require("%ui/gdk/privileges.nut")
  checkMultiplayerPermissions = try_resolve_multiplayer_privilege
}

return {
  checkMultiplayerPermissions
}
