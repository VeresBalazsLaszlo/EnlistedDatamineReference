import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let bipod = mkEcsComputed({
  comps = [["bipod__placeable", ecs.TYPE_BOOL], ["bipod__enabled", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
})

let isBipodPlaceable = Computed(@() bipod.get()?.bipod__placeable ?? false)
let isBipodEnabled = Computed(@() bipod.get()?.bipod__enabled ?? false)

return {
  isBipodPlaceable,
  isBipodEnabled
}
