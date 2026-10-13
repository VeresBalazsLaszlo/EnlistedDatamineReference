import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let redeployAt = mkEcsComputed({
  comps = [["redeploy__atTime", ecs.TYPE_FLOAT]]
  comps_rq = ["watchedByPlr"]
  defVal = -1.0
})



let parachuteRedeploy = mkEcsComputed({
  comps = [["redeploy__atTime", ecs.TYPE_FLOAT]]
  comps_rq = ["watchedByPlr", "parachuteDeployed"]
})
let isParachuteDeployed = Computed(@() parachuteRedeploy.get() != null)

let redeployBattleareaTip = tipCmp({
  text = loc("tips/parachute_battlearea_redeploy")
})

let redeployOutsideTip = tipCmp({
  text = loc("tips/outside_battle_area_redeploy")
})

let showTip = Computed(@() redeployAt.get() > 0.0
  && isAlive.get())

return @() {
  watch = [showTip, isParachuteDeployed]
  children = !showTip.get() ? null
    : isParachuteDeployed.get() ? redeployBattleareaTip
    : redeployOutsideTip
}
