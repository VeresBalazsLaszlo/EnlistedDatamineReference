from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/huds/crosshair_state_es.nut" import isAiming
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  inputId = "HUD.SetMark"
  text = loc("controls/HUD.SetMark")
})

let isPreventReloadingVisible = Computed(@() isAiming.get() && isAlive.get())

return @() {
  watch = isPreventReloadingVisible
  children = isPreventReloadingVisible.get() ? tip : null
}
