import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let isReplay = Watched(false)

ecs.register_es("replay_state_ui_es", {
    onInit    = @(_evt, _eid, _comp) isReplay.set(true)
    onDestroy = @(_evt, _eid, _comp) isReplay.set(false)
  },
  { comps_rq=["replayIsPlaying"] },
  { tags="playingReplay" }
)

return {
  isReplay
}
