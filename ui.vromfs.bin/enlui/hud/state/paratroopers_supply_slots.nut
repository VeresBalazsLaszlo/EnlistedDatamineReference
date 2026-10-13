import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


let slots = mkEcsComputed({
  comps = [["respawner__paratroopersSupplySlotsInfo", ecs.TYPE_ARRAY]]
  comps_rq = ["localPlayer"]
  defVal = []
})

return slots