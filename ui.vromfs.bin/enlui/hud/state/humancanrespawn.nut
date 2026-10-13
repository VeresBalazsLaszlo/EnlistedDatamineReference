import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let state = Watched(true)

ecs.register_es("human_can_respawn_ui_es",
  {
    onInit = @(_evt, _eid, _comp) state.set(false),
    onDestroy = @(_evt, _eid, _comp) state.set(true)
  },
  { comps_rq = ["humanSpawnDisable"] }
)

return state