import "%ui/control/gui_buttons.nut" as JB
from "app" import exit_game
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/ui_library.nut" import *

function exitGameMsgBox () {
  showMsgbox({
    text = loc("msgboxtext/exitGame")
    buttons = [
      { text = loc("Yes"), isCurrent = true, action = @() exit_game() }
      { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
  })
}

return {
  exitGameMsgBox
}
