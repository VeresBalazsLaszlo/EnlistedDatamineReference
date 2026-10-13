import "%dngscripts/ecs.nut" as ecs
from "gameevents" import EventHeroChanged
from "%ui/ui_library.nut" import *

let respawnSelection = Watched(ecs.INVALID_ENTITY_ID)

ecs.register_es("respawn_selection_ui_es", {
  [["onChange", "onInit"]] = function(_eid, comp) {
    if (comp.is_local)
      respawnSelection.set(comp["respawner__chosenRespawn"])
  },
  [EventHeroChanged] = function onHeroChanged(evt, _eid, _comp) {
    respawnSelection.set(evt[0])
  }
}, {
  comps_ro = [["is_local", ecs.TYPE_BOOL]]
  comps_track = [["respawner__chosenRespawn", ecs.TYPE_EID]]
},
{tags="gameClient"})


return respawnSelection
