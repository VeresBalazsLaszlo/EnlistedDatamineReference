import "%ui/hud/state/armyData.nut" as armyData
import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let allowChangeSquad = Watched(false)

ecs.register_es("allow_squad_change_state_es", {
    onInit    = @(_evt, _eid, _comp) allowChangeSquad.set(true)
    onDestroy = @(_evt, _eid, _comp) allowChangeSquad.set(false)
  },
  { comps_rq = ["allowChangeSquad"] }
)

let isChangeSquadAllowed = Computed(@() allowChangeSquad.get()
  && (armyData.get()?.squads.len() ?? 0) > 1)

return isChangeSquadAllowed