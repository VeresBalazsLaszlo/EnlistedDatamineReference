import "%ui/control/gui_buttons.nut" as JB
import "%ui/profile/anoPlayerCardUi.nut" as anoPlayerCardUi
from "%ui/profile/anoProfileState.nut" import isAnoProfileOpened
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/profile/profilePkg.nut" import PROFILE_WIDTH
from "%ui/components/textButton.nut" import Regular
from "%ui/style/designConst.nut" import blurBgColor, bigOffset, bigPadding
from "%ui/ui_library.nut" import *

let anoProfileWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = safeAreaBorders
  size = FLEX
  padding = safeAreaBorders.get()
  halign = ALIGN_CENTER
  color = blurBgColor
  children = {
    size = const [PROFILE_WIDTH, FLEX]
    flow = FLOW_VERTICAL
    padding = [bigOffset, 0]
    gap = bigPadding
    children = [
      anoPlayerCardUi()
      Regular(loc("BackBtn"), @() isAnoProfileOpened.set(false), {
        hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
        hplace = ALIGN_RIGHT
      })
    ]
  }
}

function open() {
  sceneWithCameraAdd(anoProfileWindow, "events")
}

function close() {
  sceneWithCameraRemove(anoProfileWindow)
}

if (isAnoProfileOpened.get())
  open()

isAnoProfileOpened.subscribe(@ (v) v ? open() : close())
