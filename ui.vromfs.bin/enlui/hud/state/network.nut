import "%dngscripts/ecs.nut" as ecs
from "connectivity" import CONNECTIVITY_OK
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *












let connectivity = mkEcsComputed({
  comps = [["ui_state__connectivity", ecs.TYPE_INT]]
  defVal = CONNECTIVITY_OK
})

return {
  connectivity
}
