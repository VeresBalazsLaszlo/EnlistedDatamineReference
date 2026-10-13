import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let underWater = mkEcsComputed({
  comps = [
    ["underWaterStartTime", ecs.TYPE_FLOAT],
    ["underWaterMaxTime", ecs.TYPE_FLOAT],
  ]
  
  comps_rq = ["vehicleWithWatched", ["last_driver", ecs.TYPE_EID]]
})

let vehicleUnderWaterEndTime = Computed(function() {
  let state = underWater.get()
  let startTime = state?.underWaterStartTime ?? -1.0
  return startTime > 0 ? startTime + state.underWaterMaxTime : -1.0
})
let vehicleUnderWaterMaxTime = Computed(@() underWater.get()?.underWaterMaxTime ?? -1.0)

return {
  vehicleUnderWaterEndTime
  vehicleUnderWaterMaxTime
}
