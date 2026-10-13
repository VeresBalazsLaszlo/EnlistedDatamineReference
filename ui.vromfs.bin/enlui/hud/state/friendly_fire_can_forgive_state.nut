import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let canForgivePlayers = mkEcsComputed({
  comps = [["friendly_fire__canForgivePlayers", ecs.TYPE_OBJECT]]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = {}
})

return canForgivePlayers
