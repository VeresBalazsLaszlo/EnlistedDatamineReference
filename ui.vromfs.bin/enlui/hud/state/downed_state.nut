import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let downedEndTime = mkEcsComputed({
  comps = [["hitpoints__downedEndTime", ecs.TYPE_FLOAT, -1]]
  comps_rq = ["watchedByPlr", "isDowned"]
  defVal = -1.0
})

return {downedEndTime}
