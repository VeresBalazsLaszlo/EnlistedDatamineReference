from "%ui/hud/state/items.nut" import mkItemDescFromComp
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let { anyItemComps } = require("%ui/hud/state/items.nut")

let memoizedGasMaskDescription = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)

let heroGasMask = mkEcsComputed({
  comps = anyItemComps.comps_ro
  comps_rq = ["gasMask", "watchedPlayerItem"]
})

let hasHeroGasMask = Computed(@() heroGasMask.get() != null)
let gasMaskInfo = Computed(function() {
  let comp = heroGasMask.get()
  return comp == null ? null : memoizedGasMaskDescription(comp["item__name"], 1, comp)
})

return { hasHeroGasMask, gasMaskInfo }
