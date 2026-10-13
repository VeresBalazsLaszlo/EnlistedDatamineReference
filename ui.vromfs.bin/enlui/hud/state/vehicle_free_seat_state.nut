import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let hasFreeSeat = mkEcsComputed({
  comps = [["selected_vehicle__hasFreeSeat", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = true
})

return {
  hasFreeSeat
}