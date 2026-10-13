import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap


let fortificationPreviewForwardArrows = mkEcsComputedEidMap({
  comps = [["additionalYawRotation", ecs.TYPE_FLOAT]]
  comps_rq = ["builder_preview", "showForwardDirectionArrow"]
  comps_no = ["builder_server_preview"]
  comps_filter = [["semi_transparent__visible", ecs.TYPE_BOOL]]
  filter = "semi_transparent__visible"
})

return {
  fortificationPreviewForwardArrows
}
