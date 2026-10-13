import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import isOwnerInMobileRespawn
from "%ui/ui_library.nut" import *

let isMobileRespawnCloseToCapzone = mkEcsComputed({
  comps = [["human_vehicle__heroMobRespCloseToCapzone", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = false
})

let isMobileRespawnCloseToCapzoneTip = tipCmp({
  text = loc("tips/mobileSpawnCloseToCapzone")
  style = { color = Color(200,40,40,110) }
})

return @() {
  watch = [isMobileRespawnCloseToCapzone, isOwnerInMobileRespawn]
  children = (isMobileRespawnCloseToCapzone.get() && isOwnerInMobileRespawn.get()) ? isMobileRespawnCloseToCapzoneTip : null
}
