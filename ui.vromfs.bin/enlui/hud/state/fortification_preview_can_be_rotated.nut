import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed


let fortificationPreviewCanBeRotated = mkEcsComputed({
  comps = [["semi_transparent__visible", ecs.TYPE_BOOL]]
  comps_rq = ["builder_preview", "additionalYawRotation"]
  comps_no = ["builder_server_preview"]
  defVal = false
})

return {
  fortificationPreviewCanBeRotated
}
