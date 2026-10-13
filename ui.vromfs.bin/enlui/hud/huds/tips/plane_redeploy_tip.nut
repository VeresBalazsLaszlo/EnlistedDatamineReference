import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *


let planeRedeployAt = mkEcsComputed({
  comps = [["plane_landing__repairAtTime", ecs.TYPE_FLOAT]]
  comps_rq = ["vehicleWithWatched"]
  defVal = -1.0
})

let redeployTip = tipCmp({
  text = loc("tips/plane_redeploy")
  style = { color = Color(100,140,200,110) }
})

let showTip = Computed(@() planeRedeployAt.get() > 0.0
  && isAlive.get())

return @() {
  watch = showTip
  children = showTip.get() ? redeployTip : null
}
