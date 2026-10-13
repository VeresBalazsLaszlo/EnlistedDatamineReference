import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *


let destroyableRi = mkEcsComputedEidMap({
  comps = [["destroyable_ri__addScoreTeam", ecs.TYPE_INT]]
})

let destroyable_ri_Set = Computed(@() destroyableRi.get().map(@(_, eid) eid))

let destroyable_ri_GetWatched = @(eid) Computed(@() destroyableRi.get()?[eid] ?? -1)

return{
  destroyable_ri_Set,
  destroyable_ri_GetWatched
}