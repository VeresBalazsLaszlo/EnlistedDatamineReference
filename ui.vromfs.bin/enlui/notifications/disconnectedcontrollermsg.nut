from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/colors.nut" import MenuBgOverlay
from "%ui/control/controllerDisconnected.nut" import controllerDisconnected
from "%ui/components/modalWindows.nut" import removeModalWindow, addModalWindow
from "%dngscripts/platform.nut" import is_sony
from "%ui/ui_library.nut" import *

const WND_UID = "disconnectedControllerMsg"

let close = @() removeModalWindow(WND_UID)

function open() {
  addModalWindow({
    key = WND_UID
    zOrder = Layers?.Blocker ?? 100

    rendObj = ROBJ_SOLID
    onClick = @() null
    valign = ALIGN_CENTER
    color = MenuBgOverlay
    halign = ALIGN_CENTER
    children = {
      size = const [sw(50), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc(is_sony ? "sony/controllerDisconnected" : "xbox/controllerDisconnected")
    }.__update(fontBody)
  })
}

if (controllerDisconnected.get())
  open()
controllerDisconnected.subscribe(@(d) d ? open() : close())
