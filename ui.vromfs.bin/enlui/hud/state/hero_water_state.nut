import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


let heroWaterState = mkEcsComputed({
  comps = [
    ["human_breath__isUnderWater", ecs.TYPE_BOOL, false],
    ["human_net_phys__isSwimming", ecs.TYPE_BOOL, false],
  ]
  comps_rq = ["watchedByPlr"]
})

let isUnderWater = Computed(@() heroWaterState.get()?.human_breath__isUnderWater ?? false)
let isSwimming = Computed(@() heroWaterState.get()?.human_net_phys__isSwimming ?? false)


return {
  isUnderWater
  isSwimming
}
