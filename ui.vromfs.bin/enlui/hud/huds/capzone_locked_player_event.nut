import "%dngscripts/ecs.nut" as ecs
from "dasevents" import EventCapZoneEnter
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

ecs.register_es("show_capzone_locked_message_on_enter", {
  [EventCapZoneEnter] = function(evt, _eid, comp) {
    if (comp.capzone__locked && evt.visitor == controlledHeroEid.get())
      playerEvents.pushEvent({event="zone_capture_blocked_log", text = loc("capture/BlockedCaptureLocked")})
  }
},
{comps_ro=[["capzone__locked", ecs.TYPE_BOOL]]})
