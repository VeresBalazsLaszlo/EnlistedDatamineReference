import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let isRadioMode = mkEcsComputed({
  comps = [["human_weap__radioMode", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let grenadeThrowDistMult = mkEcsComputed({
  comps = [["entity_mods__grenadeThrowDistMult", ecs.TYPE_FLOAT]]
  comps_rq = ["watchedByPlr"]
  defVal = 1.0
})

let isThrowDistanceIncreased = Computed(@() grenadeThrowDistMult.get() > 1.0)

return {
  isRadioMode
  isThrowDistanceIncreased
}
