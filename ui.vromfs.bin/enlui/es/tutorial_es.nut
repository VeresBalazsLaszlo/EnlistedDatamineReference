import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import CmdTutorialHint
from "dagor.localize" import loc

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

ecs.register_es("cmd_tutorial_hint_event_es",
  { [CmdTutorialHint] = function(evt, _eid, _comp) {
      let data = evt.data
      playerEvents.pushEvent({event=data["event"], unique=data["unique"], text=loc(data["text"]), hotkey=data["hotkey"], ttl=data["ttl"]})
    }
  },
  { comps_rq = ["player"] },
  { tags = "gameClient" }
)

ecs.register_es("clear_tutorial_hints",
  {
    onDestroy = @(...) playerEvents.clearEvents()
  },
  { comps_rq = ["tutor_stage__displayHint"]}
)
