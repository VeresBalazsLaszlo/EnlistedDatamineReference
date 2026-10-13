import "%dngscripts/ecs.nut" as ecs
from "dasevents" import EventOnGunBlocksShoot
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

ecs.register_es("gun_blocked_es", {
  [EventOnGunBlocksShoot] = function(evt, _eid, _comp){
    playerEvents.pushEvent({event="gun_blocked", text = loc(evt.reason), myTeamScores=false})
  },
}, { comps_rq = ["hero"] }, {tags="gameClient"})
