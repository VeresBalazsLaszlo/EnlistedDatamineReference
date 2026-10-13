import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let isBurning = mkEcsComputed({
  comps = [["burning__isBurning", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

return {isBurning}