import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/designConst.nut" import activeTxtColor
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/httpPkg.nut" import getLanguageId
from "%ui/steam/steam_pkg.nut" import mkSteamLogo
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

let bgImages = {
  en = "!ui/steam/{0}.avif"
  ru = "!ui/steam/{0}_ru.avif"
}

let mkCloseBtn = @(onCloseCb) fontIconButton("close", {
  skipDirPadNav = true
  onClick = onCloseCb
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  size = fsh(5)
})

let mkShading = @(vplace = ALIGN_TOP) {
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  opacity = 0.4
  size = const [FLEX, sh(20)]
  vplace
}

let mkWindow = @(event, onCloseCb) function() {
  let bgImage = (bgImages?[getLanguageId()] ?? bgImages.en).subst(event)
  return {
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = FLEX
        keepAspect = KEEP_ASPECT_FIT
        image = Picture(bgImage)
      }
      mkShading(ALIGN_TOP)
      mkShading(ALIGN_BOTTOM)
      {
        flow = FLOW_VERTICAL
        size = const [sw(60), SIZE_TO_CONTENT]
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        margin = const [0, 0, sh(5), 0]
        children = [
          {
            rendObj = ROBJ_TEXTAREA
            size = FLEX_H
            behavior = Behaviors.TextArea
            color = activeTxtColor
            text = loc($"steam/{event}")
            margin = const [0, 0, sh(3), 0]
          }.__update(fontBody)
          Regular(loc("Close"), onCloseCb, { hotkeys=[[$"^{JB.B} | Esc" ]] })
        ]
      }
      mkCloseBtn(onCloseCb)
      mkSteamLogo([sw(35), -sh(40)])
    ]
  }
}

return mkWindow
