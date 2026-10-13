import "%ui/login/ui/background.nut" as background
import "%ui/components/progressText.nut" as progressText
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/components/textButton.nut" import Regular
from "%ui/login/ui/eulaUrlView.nut" import bottomEulaUrl
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/login/login_chain.nut" import startLogin, currentStage
from "%ui/login/ui/loginUiParams.nut" import loginBlockOverride
from "%ui/ui_library.nut" import *

let loginDarkStripe = require("%ui/login/ui/loginDarkStripe.nut")



function loginBtnAction() {
  startLogin({})
}

let loginBtn = Regular(loc("Login"), loginBtnAction,
  { size = const [FLEX, hdpx(70)], halign = ALIGN_CENTER
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  }.__update(fontHeading2)
)

let isFirstOpen = mkWatched(persist, "isFirstOpen", true)

function loginRoot() {
  let children = isFirstOpen.get()
    ? [progressText(loc("loggingInProcess"))]
    : currentStage.get() ? [progressText(loc("loggingInProcess"))] : [ loginBtn ]
  return {
    watch = [ currentStage, safeAreaBorders, loginBlockOverride ]
    padding = safeAreaBorders.get()
    onAttach = function() {
      if (isFirstOpen.get() && currentStage.get() == null) {
        isFirstOpen.set(false)
        loginBtnAction()
      }
    }
    pos = const [-sw(15), 0]
    flow = FLOW_VERTICAL
    gap = hdpx(25)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }.__update(loginBlockOverride.get())
}

return {
  size = FLEX
  children = [
    background
    loginDarkStripe
    loginRoot
    bottomEulaUrl
  ]
}
