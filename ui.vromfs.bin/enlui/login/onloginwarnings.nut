import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/state/login_state.nut" import isLoggedIn
from "settings" import get_setting_by_blk_path
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/style/designConst.nut" import defTxtColor, disabledTxtColor
from "%ui/ui_library.nut" import *

local isEnableSoundModWarningShown = false

let warningIcon = freeze({
  valign = ALIGN_BOTTOM
  children = [
    faComp("gear", {
      fontSize = hdpx(90)
      color = disabledTxtColor
    })
    faComp("wrench", {
      fontSize = hdpx(100)
      color = defTxtColor
    })
  ]
})


function showEnableSoundModWarning() {
  showMessageWithContent({
    content = {
      flow = FLOW_HORIZONTAL
      gap = sh(3)
      valign = ALIGN_CENTER
      children = [
        warningIcon
        {
          maxWidth = sh(90)
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("msg/enableSoundModWarning")
          color = defTxtColor
        }.__update(fontBody)
      ]
    }
    buttons = [{ text = loc("btn/confirm"), isCurrent = true,
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}]
  })
}

isLoggedIn.subscribe(function(res) {
  if (!res)
    return

  if (!isEnableSoundModWarningShown
      && get_setting_by_blk_path("sound/enableMod")
      && get_setting_by_blk_path("incorrectExitWarning"))
    showEnableSoundModWarning()

  isEnableSoundModWarningShown = true
})

console_register_command(showEnableSoundModWarning, "triggerIsLoggedIn")
