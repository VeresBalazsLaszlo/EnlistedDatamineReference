import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let fortificationRepair = mkEcsComputed({
  comps = [
    ["fortification_repair__active", ecs.TYPE_BOOL],
    ["fortification_repair__timer", ecs.TYPE_FLOAT],
    ["fortification_repair__time", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["watchedByPlr"]
})

let isRepairFortification = Computed(@() fortificationRepair.get()?.fortification_repair__active ?? false)

let repairFortificationEndTime = Computed(@() fortificationRepair.get()?.fortification_repair__timer ?? 0.0)
let repairFortificationTimeTotal = Computed(@() fortificationRepair.get()?.fortification_repair__time ?? 0.0)

return {
  isRepairFortification
  repairFortificationEndTime
  repairFortificationTimeTotal
}