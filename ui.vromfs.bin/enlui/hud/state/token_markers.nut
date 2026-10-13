import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *


let tokenMarkers = mkEcsComputedEidMap({
  comps = [["token_free__mapIcon", ecs.TYPE_STRING]]
  comps_rq = ["token_free__tag", "transform"]
})

let token_markers_Set = Computed(@() tokenMarkers.get().map(@(_, eid) eid))

let token_markers_GetWatched = @(eid) Computed(@() { image = tokenMarkers.get()?[eid] })

return {
  token_markers_Set
  token_markers_GetWatched
}
