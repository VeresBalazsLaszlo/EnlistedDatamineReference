from "%ui/hud/state/mortar.nut" import isMortarMode
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  inputId = "Mortar.SwitchShellType"
  text = loc("controls/switchMortarShellType")
})

return @() {
  watch = isMortarMode
  children = isMortarMode.get() ? tip : null
}
