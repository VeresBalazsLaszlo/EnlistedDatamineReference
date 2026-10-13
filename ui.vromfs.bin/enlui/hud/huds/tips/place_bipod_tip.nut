from "%ui/hud/state/bipod_state.nut" import isBipodPlaceable, isBipodEnabled
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let placeTip = tipCmp({
  inputId = "Human.BipodToggle"
  text = loc("tips/place_bipod")
})

let showPlaceBipod = Computed(@() isBipodPlaceable.get()
  && !isBipodEnabled.get())

return @() {
  watch = showPlaceBipod
  children = showPlaceBipod.get() ? placeTip : null
}
