import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *


let markerRows = mkEcsComputedEidMap({
  comps = [
    ["custom_marker__icon", ecs.TYPE_STRING],
    ["custom_marker__iconSize", ecs.TYPE_POINT2],
    ["custom_marker__iconColor", ecs.TYPE_COLOR],
  ]
  comps_filter = [["custom_marker__active", ecs.TYPE_BOOL]]
  filter = "custom_marker__active"
})


let custom_markers = Computed(@() markerRows.get().map(@(row) {
  icon = row.custom_marker__icon
  size = row.custom_marker__iconSize
  color = row.custom_marker__iconColor
}))

return custom_markers
