import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/items.nut" import mkItemDescFromComp
from "%ui/ui_library.nut" import *

let { anyItemComps } = require("%ui/hud/state/items.nut")

let memoizedDesc = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)

let heroFlask = mkEcsComputed({
  comps = anyItemComps.comps_ro
  comps_rq = ["flask", "watchedPlayerItem"]
})

let hasHeroFlask = Computed(@() heroFlask.get() != null)

let heroFlaskInfo = Computed(function() {
  let comp = heroFlask.get()
  return comp == null ? null : memoizedDesc(comp["item__name"], 1, comp)
})

let flaskAffectEid = mkEcsComputed({
  comps = [["flask__affectEid", ecs.TYPE_EID]]
  comps_rq = [["watchedByPlr", ecs.TYPE_EID]]
  defVal = ecs.INVALID_ENTITY_ID
})
let flaskAffectApplied = Computed(@() flaskAffectEid.get() != ecs.INVALID_ENTITY_ID)

return {
  hasHeroFlask
  flaskAffectApplied
  heroFlaskInfo
}
