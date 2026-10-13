import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let vehicleTips = mkEcsComputed({
  comps = [
    ["vehicle__steerTips", ecs.TYPE_STRING_LIST],
    ["vehicle__steerTipDuration", ecs.TYPE_FLOAT, 15.0],
  ]
  comps_rq = ["vehicleWithWatched", "hasVehicleControl"]
})


let vehicleSteerTips = Computed(@() vehicleTips.get()?.vehicle__steerTips ?? [])
let steerTipDuration = Computed(@() vehicleTips.get()?.vehicle__steerTipDuration ?? 15.0)

return {
  vehicleSteerTips
  steerTipDuration
}
