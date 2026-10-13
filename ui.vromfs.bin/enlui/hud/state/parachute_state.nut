import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let canOpenParachute = mkEcsComputed({
  comps = [["human_parachute__canDeploy", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = false
})


let heroParachuteDeployed = mkEcsComputed({
  comps = [["human_parachute__canDeploy", ecs.TYPE_BOOL, false]]
  comps_rq = ["hero", "parachuteDeployed"]
})
let isParachuteOpened = Computed(@() heroParachuteDeployed.get() != null)

return {
  canOpenParachute
  isParachuteOpened
}
