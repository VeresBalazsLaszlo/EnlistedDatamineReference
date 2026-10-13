from "%ui/hud/huds/mkPlayerEvents.nut" import makeItem
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

let isMinimalHud = Computed(@() forcedMinimalHud.get() || minimalistHud.get())

let showMinHudEvents = {
  building_cannot_confirm_by_enemy = true
  building_blocked_too_close_to_respawns = true
  building_blocked_too_close_to_capture_points = true
  building_cannot_confirm_when_objects_in = true
  building_blocked_underwater = true
  building_gun_not_attachable = true
  building_blocked_restricted_zone = true
}

function playerEventsRoot() {
  let events = isMinimalHud.get()
    ? playerEvents.events.get().filter(@(event) event?.event in showMinHudEvents)
    : playerEvents.events.get()
  return {
    flow   = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    size   = const [pw(80), SIZE_TO_CONTENT]
    watch = [playerEvents.events, isMinimalHud]
    children = events.map(makeItem)
  }
}


return playerEventsRoot
