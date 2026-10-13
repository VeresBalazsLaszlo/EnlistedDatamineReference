import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let gazMaskIsOn = mkEcsComputed({
  comps = [["gaz_mask__isOn", ecs.TYPE_BOOL]]
  comps_rq = ["hero"]
  defVal = false
})

let gazMaskTip = tipCmp({
  text = loc("Gaz mask is On")
  style = { fontSize = hdpxi(28), color = Color(200,40,40,110) }
})

return @() {
  watch = gazMaskIsOn
  children = gazMaskIsOn.get() ? gazMaskTip : null
}
