import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let isMachinegunner = mkEcsComputed({
  comps = [["human_attached_gun__isAttached", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = false
})

return isMachinegunner
