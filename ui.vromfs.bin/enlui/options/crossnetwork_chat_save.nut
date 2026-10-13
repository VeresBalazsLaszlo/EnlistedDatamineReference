from "%enlSqGlob/crossnetwork_state.nut" import xboxCrosschatAvailable, savedCrossnetworkChatId, savedCrossnetworkChatStateUpdate
from "%dngscripts/platform.nut" import is_gdk
from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *

let {
  check_privilege = @(...) null,
  Communications = -1
} = is_gdk ? require_optional("gdk.user") : null


return function(val, setValueFunc) {
  
  
  if (is_gdk && !xboxCrosschatAvailable.get()) {
    check_privilege(Communications, true, "")
    return
  }

  settings.mutate(@(v) v[savedCrossnetworkChatId] <- val)
  savedCrossnetworkChatStateUpdate(val)
  setValueFunc(val)
}