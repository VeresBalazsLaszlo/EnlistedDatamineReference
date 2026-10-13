import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/colors.nut" import WindowTransparent
from "%ui/style/designConst.nut" import titleTxtColor, commonBtnHeight
from "%ui/components/defcomps.nut" import noteTextArea, txt
from "%ui/gameModes/sandbox/customMissionState.nut" import modDownloadShowProgress, modDownloadMessage
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

let waitingSpinner = spinner()
let defaultSize = [hdpx(432), hdpx(324)]

let queueTitle = noteTextArea({
  size = FLEX_H
  text = loc("mods/Downloading")
  halign = ALIGN_CENTER
  color = titleTxtColor
}).__update(fontBody)

let queueContent = @(message) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  fillColor = Color(10,10,10,10)
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = txt({
      text = loc(message)
      color = titleTxtColor
    }).__update(fontBody)
}

let closeButton = Regular(loc("Ok"),
  function(){
    modDownloadShowProgress.set(false)
    modDownloadMessage.set("")
  },
  {
    size = [SIZE_TO_CONTENT, commonBtnHeight]
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    hotkeys = [[$"^{JB.B} | Enter | Space | Esc", { skip = true }]]
  }
)


let infoContainer = @(text) {
  size = defaultSize
  gap = hdpx(20)
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  fillColor = WindowTransparent
  borderRadius = hdpx(2)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  transform = true
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
  children = text == ""
    ? [
        queueTitle
        {
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = waitingSpinner
        }
      ]
    : [
        queueTitle
        queueContent(text)
        closeButton
      ]
}

return function queueWaitingInfo() {
  if (!modDownloadShowProgress.get() && modDownloadMessage.get() == "")
    return {
      watch = [modDownloadShowProgress, modDownloadMessage]
    }

  return {
    watch = [modDownloadShowProgress, modDownloadMessage]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    stopMouse = true
    fillColor = Color(10,10,10,10)
    size = const [sw(100), sh(100)]
    children = infoContainer(modDownloadMessage.get())
  }
}