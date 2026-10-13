import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let showFuel = Watched(false)
let showFuelIfLessPct = Watched(10.0)

let planeSeatNext = mkEcsComputed({
  comps = [["plane__seatNext", ecs.TYPE_INT]]
  comps_rq = ["heroVehicle"]
  defVal = -1
})

function checkFuelLevel(_evt, _eid, comp) {
  let fuelPct = comp["plane_view__fuel_pct"]
  let isLeaking = comp["plane_view__fuel_leak"]
  showFuel.set(isLeaking || fuelPct < showFuelIfLessPct.get())
}

ecs.register_es("plane_fuel_es", {
  onUpdate = checkFuelLevel
},
{
  comps_ro = [
    ["plane_view__fuel_pct", ecs.TYPE_FLOAT],
    ["plane_view__fuel_leak", ecs.TYPE_BOOL],
  ],
  comps_rq = ["vehicleWithWatched"]
},
{ updateInterval=5.0, tags="ui", after="*", before="*" })

return {showFuel, planeSeatNext}