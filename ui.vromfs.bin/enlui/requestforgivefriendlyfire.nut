from "net" import has_network
from "dasevents" import sendNetEvent, RequestForgiveFriendlyFire

return function forgive(localPlayerEid, eid) {
  if (has_network())
    sendNetEvent(localPlayerEid, RequestForgiveFriendlyFire({player=eid}))
}