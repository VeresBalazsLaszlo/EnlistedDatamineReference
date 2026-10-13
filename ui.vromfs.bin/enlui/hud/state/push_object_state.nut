import "%ui/hud/state/machinegunner_state.nut" as isMachinegunner
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/actions_state.nut" import lookAtVehicle, lookAtShip, lookAtPushableObject
from "%ui/hud/state/health_state.nut" import isDowned
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let canPush = mkEcsComputed({
  comps = [["push_object__canPush", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let showPushObjectTip = Computed(@() !isMachinegunner.get() && !inVehicle.get()
                                  && !isDowned.get() && (lookAtVehicle.get() || lookAtShip.get())
                                  && lookAtPushableObject.get() && canPush.get())

return { showPushObjectTip }
