from "%ui/hud/state/bomber_cockpit_state.nut" import canEnterBomberCockpit
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let bomberCockpitTip = tipCmp({
  inputId = "Plane.BomberCockpitToggle"
  text = loc("tips/bomber_cockpit")
})

return @() {
  watch = canEnterBomberCockpit
  children = canEnterBomberCockpit.get() ? bomberCockpitTip : null
}
