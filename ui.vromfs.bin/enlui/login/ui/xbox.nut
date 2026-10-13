import "%ui/style/colors.nut" as colors
import "%ui/login/ui/background.nut" as background
import "%ui/components/progressText.nut" as progressText
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/components/textButton.nut" import Regular
from "%ui/login/ui/eulaUrlView.nut" import bottomEulaUrl
from "%ui/login/login_chain.nut" import startLogin, currentStage
from "%ui/login/ui/loginUiParams.nut" import loginBlockOverride
from "%ui/ui_library.nut" import *

let loginDarkStripe = require("%ui/login/ui/loginDarkStripe.nut")


let loginButtonRedrawCounter = Watched(0)
let isFirstOpen = mkWatched(persist, "isFirstOpen", true)

function loginBtnAction() {
  loginButtonRedrawCounter.modify(@(v) v + 1)
  if (currentStage.get() == null)
    startLogin({})
}


function loginBtn() {
  return {
    size = const [FLEX, hdpx(70)]
    watch = loginButtonRedrawCounter
    children = Regular(loc("Login"), loginBtnAction,
      { size = const [FLEX, hdpx(70)], key = "loginBtn_{0}".subst(loginButtonRedrawCounter.get()), halign = ALIGN_CENTER
        hotkeys = [["^J:Y", { description = { skip = true }}]]
      }.__update(fontHeading2))
  }
}

let descriptionBlock = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = colors.BtnTextNormal
  text
}.__update(fontBody)

let loginFormChildren = [
  loginBtn
  {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      descriptionBlock(loc("login/needConstantInternetMessage"))
    ]
  }
]

function loginRoot() {
  let children = isFirstOpen.get()
    ? [progressText(loc("loggingInProcess"))]
    : currentStage.get() ? [progressText(loc("loggingInProcess"))] : loginFormChildren

  return {
    watch = [ currentStage, loginBlockOverride ]
    flow = FLOW_VERTICAL
    pos = const [-sw(15), 0]
    gap = hdpx(25)
    children = children
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = function() {
      if (isFirstOpen.get() && currentStage.get() == null) {
        isFirstOpen.set(false)
        loginBtnAction()
      }
    }
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
