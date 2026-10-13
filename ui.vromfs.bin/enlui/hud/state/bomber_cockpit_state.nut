import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let canEnterBomberCockpit = mkEcsComputed({
  comps = [["bomber_cockpit__canToggle", ecs.TYPE_BOOL]]
  comps_rq = ["vehicleWithWatched"]
  defVal = false
})

return {
  canEnterBomberCockpit
}
