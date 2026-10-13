import "%ui/login/ui/supportLink.nut" as supportLink
import "%ui/login/ui/background.nut" as background
import "%ui/components/progressText.nut" as progressText
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/login/login_chain.nut" import startLogin, currentStage
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/ui_library.nut" import *

let loginBtn = Regular(loc("Login"),
                            @() startLogin({}),
                            fontSub)

function loginRoot() {
  const size = fsh(40)
  let watch = [currentStage]

  return {
    watch
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    onAttach = @() startLogin({})
    children = currentStage.get()
      ? progressText(loc("loggingInProcess"))
      : loginBtn
  }
}

let height = calc_comp_size({size=SIZE_TO_CONTENT children={margin = const [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(fontHeading2)})[1]*0.75

return {
 size = FLEX
 children = [
  background
  loginRoot
  supportLink
  {
      size = [height, height]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.get()[1]
      children = fontIconButton("power-off", { onClick = exitGameMsgBox })
    }
 ]
}
