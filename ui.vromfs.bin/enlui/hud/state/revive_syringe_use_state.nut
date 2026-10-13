import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let syringeUse = mkEcsComputed({
  comps = [
    ["human_inventory__reviveSyringeStart", ecs.TYPE_FLOAT],
    ["human_inventory__reviveSyringeEnd", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["watchedByPlr"]
})

let syringeUseStart = Computed(@() syringeUse.get()?.human_inventory__reviveSyringeStart ?? -1.0)
let syringeUseEnd = Computed(@() syringeUse.get()?.human_inventory__reviveSyringeEnd ?? -1.0)


return {
  reviveSyringeStartTime = syringeUseStart
  reviveSyringeEndTime = syringeUseEnd
}
