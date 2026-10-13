import "%ui/components/msgbox.nut" as msgbox
from "settings" import get_setting_by_blk_path
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/ui_library.nut" import *

let { get_kongzhong_fcm = null } = require_optional("auth.kongzhong")

let showGuidelinesWindow = get_setting_by_blk_path("enableCommunityGuidelinesWindow") ?? false
if (!showGuidelinesWindow)
  return


const WND_UID = "GUIDELINES_WND"

let guidelinesShown = mkWatched(persist, "guidelinesShown", false)
const minWindowShowTime = 3.0

function showGuidelines() {
  if (guidelinesShown.get())
    return

  guidelinesShown.set(true)

  let showCloseButton = Watched(false)
  let activateCloseButton = @() showCloseButton.set(true)
  local guidelinesText = loc("community_guidelines")

  let fcm = get_kongzhong_fcm?()

  if (fcm == 0) {
    
    guidelinesText = "\n\n".join([guidelinesText, loc("antiaddiction_guidelines")])
  }

  msgbox.showMsgbox({
    uid = WND_UID
    text = guidelinesText
    buttons = Computed(@() showCloseButton.get() ? [{
      text = loc("Close")
    }] : [])
  },
  msgbox.msgboxStyling.__merge({
    Root = msgbox.msgboxStyling.Root.__merge({
      onAttach = @() gui_scene.resetTimeout(minWindowShowTime, activateCloseButton)
    })
    closeKeys = ""
    activateKeys = ""
  }))
}

isLoggedIn.subscribe(function(logged) {
  if (logged)
    showGuidelines()
})
