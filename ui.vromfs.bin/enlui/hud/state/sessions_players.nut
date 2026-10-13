import "%dngscripts/ecs.nut" as ecs
from "%ui/helpers/remap_nick.nut" import remap_others
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *



let players = mkEcsComputedEidMap({
  comps = [["name", ecs.TYPE_STRING]]
  comps_rq = ["player"]
  comps_no = ["playerIsBot"]
})
let names = Computed(@() players.get().values().map(remap_others))

return names