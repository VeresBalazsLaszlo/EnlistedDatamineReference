import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let repairKits = mkEcsComputed({
  comps = [["total_kits__targetRepair", ecs.TYPE_INT]]
  comps_rq = ["watchedByPlr"]
  defVal = 0
})

return {repairKits}
