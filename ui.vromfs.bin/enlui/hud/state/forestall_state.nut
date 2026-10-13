import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "dagor.math" import Point3 as Point3
from "%ui/ui_library.nut" import *

let forestall = mkEcsComputed({
  comps = [
    ["forestallPos", ecs.TYPE_POINT3],
    ["forestallOpacity", ecs.TYPE_FLOAT],
    ["target_lock__selectedEntity", ecs.TYPE_EID],
  ]
  comps_rq = ["heroVehicle"]
  tags = "gameClient"
})


let forestallMarkActive = Computed(@()
  (forestall.get()?.target_lock__selectedEntity ?? ecs.INVALID_ENTITY_ID) != ecs.INVALID_ENTITY_ID)
let forestallMarkPos = Computed(@() forestall.get()?.forestallPos ?? Point3(0, 0, 0))
let forestallMarkOpacity = Computed(@() forestall.get()?.forestallOpacity ?? 1.0)

return {
  forestallMarkActive
  forestallMarkPos
  forestallMarkOpacity
}
