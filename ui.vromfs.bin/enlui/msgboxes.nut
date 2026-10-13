from "%ui/components/msgbox.nut" import removeAllMsgboxes, getCurMsgbox, msgboxGeneration
from "%ui/ui_library.nut" import *

gui_scene.setShutdownHandler(function sceneShutdownHandler() {
  removeAllMsgboxes()
})

let msgboxes = @() {
  size = FLEX
  children = getCurMsgbox()
  watch = msgboxGeneration
}


return {msgboxes}