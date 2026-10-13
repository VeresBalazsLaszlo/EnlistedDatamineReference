import "%dngscripts/ecs.nut" as ecs
from "string" import startswith
from "%ui/helpers/time.nut" import secondsToStringLoc
from "dasevents" import CmdHeroLogEvent, CmdLogEvent, CmdHeroLogExEvent, CmdHeroLogClear
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

function onCmdHeroLogEvent(evt, _eid, _comp){
  playerEvents.pushEvent({event=evt.event, text = loc(evt.text), myTeamScores=false, sound=evt.sound, ttl = evt.ttl > 0 ? evt.ttl : null})
}

function onCmdLogDasEvent(evt){
  local eventData = clone(evt.data.getAll())
  evt.data.getAll().each(function(slot, key) {
    if (startswith(key, "_requiresTime/"))
      eventData[key] <- secondsToStringLoc(slot)
    else if (typeof(slot)=="string")
      eventData[key] <- loc(slot, eventData)
  })
  playerEvents.pushEvent({event=evt.event, text = loc(evt.text, eventData), myTeamScores=false, sound=evt.sound, ttl = evt.ttl > 0 ? evt.ttl : null})
}

ecs.register_es("cmd_hero_log_event_es",
  { [CmdHeroLogEvent] = onCmdHeroLogEvent },
  { comps_rq = ["hero"] }
)

ecs.register_es("cmd_hero_log_ex_event_es",
  { [CmdHeroLogExEvent] = function onCmdHeroLogExEvent(evt, _eid, _comp) {
      local eventData = clone(evt.data.getAll())
      evt.data.getAll().each(function(slot, key) {
        if (startswith(key, "_requiresTime/"))
          eventData[key] <- secondsToStringLoc(slot)
        else if (typeof(slot)=="string")
          eventData[key] <- loc(slot, eventData)
      })
      let evtTtl = eventData?.ttl ?? 0
      let e = {event=evt.event, text=loc(evt.key, eventData), myTeamScores=false, ttl = evtTtl > 0 ? evtTtl : null}
      playerEvents.pushEvent(e)
    }
  },
  { comps_rq = ["hero"] }, {tags="gameClient"}
)

ecs.register_es("cmd_player_log_event_es",
  { [CmdHeroLogEvent] = function onCmdPlayerLogEvent(evt, eid, comp) {
      if (!comp.is_local)
        return
      onCmdHeroLogEvent(evt, eid, comp)
    },
    [CmdLogEvent] = function onCmdLogEvent(evt, _eid, comp) {
      if (!comp.is_local)
        return
      onCmdLogDasEvent(evt)
    },
    [CmdHeroLogClear] = function(_evt, _eid, comp) {
      if (!comp.is_local)
        return
      playerEvents.clearEvents()
    }
 },
  {comps_ro = [["is_local", ecs.TYPE_BOOL]], comps_rq = ["possessed"] }
)