import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/hero_weapons.nut" import currentGunEid
from "%ui/ui_library.nut" import *


let fastTrowAvailable = mkEcsComputedEidMap({
  comps = [["gun__fastSwapAvailable", ecs.TYPE_BOOL]]
  comps_rq = ["watchedPlayerItem"]
})

let needShowThrowTip = Computed(@() currentGunEid.get() != ecs.INVALID_ENTITY_ID
  && (fastTrowAvailable.get()?[currentGunEid.get()] ?? false))

let showThrowTip = tipCmp({
  inputId = "Human.Zoom"
  text = loc("hud/throw_weapon")
  transform = {pivot=[0,0.5]}
})

return function() {
  let watch = [needShowThrowTip]
  if (!needShowThrowTip.get())
    return { watch }

  return {
    watch
    children = showThrowTip
  }
}
