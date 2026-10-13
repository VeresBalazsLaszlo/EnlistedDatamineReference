import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let canGrenadeRethrow = mkEcsComputed({
  comps = [["grenade_rethrow__grenadeEid", ecs.TYPE_EID]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})


return { showGrenadeRethrowTip = canGrenadeRethrow }
