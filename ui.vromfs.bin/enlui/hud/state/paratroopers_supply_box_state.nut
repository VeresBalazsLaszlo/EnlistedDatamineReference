import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


let selectedSupplyBoxEid = mkEcsComputed({
  comps = [["human_paratroopers_supply_box__selectedEid", ecs.TYPE_EID]]
  comps_rq = ["watchedByPlr"]
  defVal = ecs.INVALID_ENTITY_ID
})

let showParatroopersSupplyBoxTip = Computed(@() selectedSupplyBoxEid.get() != ecs.INVALID_ENTITY_ID)


return { showParatroopersSupplyBoxTip }
