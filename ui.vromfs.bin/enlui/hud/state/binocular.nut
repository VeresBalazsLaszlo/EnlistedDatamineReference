import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/items.nut" import mkItemDescFromComp
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let { anyItemComps } = require("%ui/hud/state/items.nut")

let memoizedBinocularDescription = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)

let heroBinocular = mkEcsComputed({
  comps = anyItemComps.comps_ro
  comps_rq = ["binocular", "watchedPlayerItem"]
})

let hasHeroBinocular = Computed(@() heroBinocular.get() != null)
let binocularInfo = Computed(function() {
  let comp = heroBinocular.get()
  return comp == null ? null : memoizedBinocularDescription(comp["item__name"], 1, comp)
})

let isBinocularMode = mkEcsComputed({
  comps = [["human_binocular__mode", ecs.TYPE_BOOL]]
  comps_rq = [["watchedByPlr", ecs.TYPE_EID]]
  defVal = false
})

return { hasHeroBinocular, isBinocularMode, binocularInfo }
