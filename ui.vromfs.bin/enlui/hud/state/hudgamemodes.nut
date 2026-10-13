import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let forcedMinimalHud = Watched(false)

let noBotsModeHud = Watched(false)

ecs.register_es("forcedMinimalHud_es", {
    onInit = @(_eid, _comp) forcedMinimalHud.set(true)
    onDestroy = @(_eid, _comp) forcedMinimalHud.set(false)
  },
  { comps_rq = ["forceMinimalHud"] }
)

ecs.register_es("noBotsModeHud_es", {
    onInit = @(_eid, _comp) noBotsModeHud.set(true)
    onDestroy = @(_eid, _comp) noBotsModeHud.set(false)
  },
  { comps_rq = ["noBotsMode"] }
)

return {
  forcedMinimalHud
}