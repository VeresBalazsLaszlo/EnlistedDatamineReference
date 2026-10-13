import "dainput2" as dainput
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let planeShootAction = mkEcsComputed({
  comps = [["plane_input__shoot", ecs.TYPE_INT]]
})


let tutorialPlaneShootEnable = Computed(@() planeShootAction.get() != dainput.BAD_ACTION_HANDLE)

return {
  tutorialPlaneShootEnable
}
