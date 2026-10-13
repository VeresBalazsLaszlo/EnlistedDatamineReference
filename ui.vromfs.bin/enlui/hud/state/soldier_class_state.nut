import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let heroSoldierKind = mkEcsComputed({
  comps = [["soldier__sKind", ecs.TYPE_STRING]]
  comps_rq = ["hero"]
  defVal = ""
})

return {
  heroSoldierKind
}