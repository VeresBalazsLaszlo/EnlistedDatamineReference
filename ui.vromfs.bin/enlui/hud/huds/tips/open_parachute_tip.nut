from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/state/parachute_state.nut" import canOpenParachute, isParachuteOpened
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let deployTip = tipCmp({
  inputId = "Human.Jump"
  text = loc("tips/open_parachute")
})

let showTip = Computed(@() canOpenParachute.get()
  && !isParachuteOpened.get()
  && isAlive.get())

return @() {
  watch = showTip
  children = showTip.get() ? deployTip : null
}
