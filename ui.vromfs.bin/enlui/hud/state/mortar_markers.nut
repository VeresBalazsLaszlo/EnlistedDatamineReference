import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap





let mortarMarkers = mkEcsComputedEidMap({
  comps = [["transform", ecs.TYPE_MATRIX], ["type", ecs.TYPE_STRING]]
  comps_rq = ["mortar_marker"]
  tags = "gameClient"
})

return {
  mortarMarkers
}
