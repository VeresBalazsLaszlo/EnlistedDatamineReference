import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let heroVehicle = mkEcsComputed({
  comps = [
    ["human_vehicle__isInHatch", ecs.TYPE_BOOL],
    ["human_vehicle__canHoldWeapon", ecs.TYPE_BOOL],
    ["human_vehicle__isHoldingGunPassenger", ecs.TYPE_BOOL]
  ]
  comps_rq = ["hero"]
})

let isInHatch = Computed(@() heroVehicle.get()?.human_vehicle__isInHatch ?? false)
let canHoldWeapon = Computed(@() heroVehicle.get()?.human_vehicle__canHoldWeapon ?? false)
let isHoldingGunPassenger = Computed(@() heroVehicle.get()?.human_vehicle__isHoldingGunPassenger ?? false)

return {
  isInHatch
  canHoldWeapon
  isHoldingGunPassenger
}
