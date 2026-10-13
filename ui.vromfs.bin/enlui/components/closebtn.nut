import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/components/faComp.nut" as faComp
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/colors.nut" import TextHighlight
from "%ui/ui_library.nut" import *

const btnActiveColor = Color(120, 120, 120, 160)
const btnDefaultColor = Color(160, 160, 160, 160)

let buttonParams = {
  onClick = @() null
  hotkeys=[[$"^{JB.B} | Esc", {description=loc("Close")}]]
  skipDirPadNav = true
  iconColor = @(sf) sf & S_ACTIVE ? btnActiveColor
    : sf & S_HOVER ? TextHighlight
    : btnDefaultColor
}

let shadowButtonParams = {
  color = Color(30, 30, 30, 150)
  pos = const [hdpx(2), hdpx(2)]
}

return @(override) {
  size = hdpx(21)
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = @(){
    watch = isGamepad
    children = !isGamepad.get()
      ? [
          faComp("close", shadowButtonParams.__merge(override))
          fontIconButton("close", buttonParams.__merge(override))
        ]
      : {behavior = Behaviors.Button}.__merge(buttonParams, override)
  }
}
