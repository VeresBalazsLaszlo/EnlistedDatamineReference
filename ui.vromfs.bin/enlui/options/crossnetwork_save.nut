from "%enlSqGlob/crossnetwork_state.nut" import savedCrossnetworkPlayId, savedCrossnetworkStateUpdate
from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *

return function(val) {
  settings.mutate(@(v) v[savedCrossnetworkPlayId] <- val)
  savedCrossnetworkStateUpdate(val)
}
