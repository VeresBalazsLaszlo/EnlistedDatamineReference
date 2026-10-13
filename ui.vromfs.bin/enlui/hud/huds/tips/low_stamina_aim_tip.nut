from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/stamina_es.nut" import staminaCanAim
from "%ui/hud/huds/crosshair_state_es.nut" import isAimPressed
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  text = loc("tips/staminaTooLowToAim")
})

return @() {
  watch = [staminaCanAim, isAimPressed]
  children = (!staminaCanAim.get() && isAimPressed.get()) ? tip : null
}
