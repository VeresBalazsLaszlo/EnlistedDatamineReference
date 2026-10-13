import "%dngscripts/ecs.nut" as ecs
from "eventbus" import eventbus_subscribe
from "os.window" import EventWindowActivated, EventWindowDeactivated
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let steam = require_optional("steam")

let windowActive = nestWatched("windowActive", true)
let steamOverlayActive = nestWatched("steamOverlayActive", false)

ecs.register_es("os_window_activation_tracker",
  {
    [EventWindowActivated] = @(...) windowActive.set(true),
    [EventWindowDeactivated] = @(...) windowActive.set(false)
  })

eventbus_subscribe("steam.overlay_activation", @(params) steamOverlayActive.set(params.active))

if (steam) {
  steamOverlayActive.set(steam.is_overlay_active())
}

return {
  windowActive
  steamOverlayActive
}
