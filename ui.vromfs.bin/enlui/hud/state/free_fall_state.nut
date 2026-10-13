import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let isFreeFall = mkEcsComputed({
  comps = [["human_freefall__isFreefall", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = false
})

return isFreeFall
