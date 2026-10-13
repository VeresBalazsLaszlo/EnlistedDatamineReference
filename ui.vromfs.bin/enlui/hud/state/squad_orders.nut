import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%enlSqGlob/dasenums.nut" import SquadOrder
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/ui_library.nut" import *

let squadOrders = mkEcsComputedEidMap({
  comps = [
    ["squad__ownerPlayer", ecs.TYPE_EID],
    ["squad__leader", ecs.TYPE_EID],
    ["squad__orderType", ecs.TYPE_INT],
    ["squad__orderPosition", ecs.TYPE_POINT3],
    ["squad__isAlive", ecs.TYPE_BOOL],
  ]
})

let localSquadOrder = Computed(function() {
  let v = squadOrders.get().findvalue(@(val) val.squad__ownerPlayer == localPlayerEid.get())
  if (v != null && v.squad__orderType == SquadOrder.ESO_DEFEND_POINT && v.squad__isAlive == true)
    return v.squad__orderPosition
  return null
})

return {
  localSquadOrder
}
