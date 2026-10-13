import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *



let isPractice = Watched(false)

ecs.register_es("practice_state_es", {
    onInit    = @(_evt, _eid, _comp) isPractice.set(true)
    onDestroy = @(_evt, _eid, _comp) isPractice.set(false)
  },
  { comps_rq = ["isPractice"] }
)
return {
  isPractice
}
