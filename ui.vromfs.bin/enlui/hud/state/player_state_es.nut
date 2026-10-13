import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *








let localPlayerNamePrefixIcon = mkEcsComputed({
  comps = [["namePrefixIcon", ecs.TYPE_STRING, ""]]
  comps_rq = ["player"]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = ""
})

return {
  localPlayerNamePrefixIcon
}
