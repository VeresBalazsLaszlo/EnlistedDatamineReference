import "%ui/login/ui/supportLink.nut" as supportLink
import "%ui/login/ui/background.nut" as background
import "%ui/components/progressText.nut" as progressText
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/login/login_chain.nut" import startLogin, currentStage, resetCurrentStage
from "%ui/state/login_state.nut" import isSteamFirstOpen
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/ui_library.nut" import *

let regInfo = require("%ui/login/ui/reginfo.nut")



function loginSteamAccount() {
  if (currentStage.get() != null)
    resetCurrentStage()

  startLogin({onlyKnown = true})
}

function onOpen() {
  if (!isSteamFirstOpen.get() || currentStage.get() != null)
    return

  isSteamFirstOpen.set(false)
  startLogin({onlyKnown = true})
}

let steamLoginBtn = Regular(loc("Login"), loginSteamAccount, fontSub)

function createLoginForm() {
  return [
    {
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = [
        steamLoginBtn
      ]
    }
    regInfo
  ]
}

let centralContainer = @(children = null, watch = null, size = null) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = size
  watch = watch
  children = children
}

function loginRoot() {
  let size = fsh(40)
  let watch = [currentStage]

  if (currentStage.get())
    return centralContainer(
      progressText(loc("loggingInProcessSteam")), watch, size)

  return centralContainer(createLoginForm(), watch, size)
}

let headerHeight = calc_comp_size({size=SIZE_TO_CONTENT children={margin = const [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(fontHeading2)})[1]*0.75

return {
  onAttach = onOpen
  size = FLEX
  children = [
    background
    loginRoot
    supportLink
    {
      size = [headerHeight, headerHeight]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.get()[1]
      children = fontIconButton("power-off", { onClick = exitGameMsgBox })
    }
  ]
}
