import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/designConst.nut" import activeTxtColor
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/httpPkg.nut" import getLanguageId
from "%ui/steam/steam_pkg.nut" import mkSteamLogo
from "%ui/components/openUrl.nut" import openUrl
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/ui_library.nut" import *

let bgImage = {
  en = "!ui/steam/awards_2025_en.avif"
  ru = "!ui/steam/awards_2025_ru.avif"
}

let mkCloseBtn = @(onCloseCb) fontIconButton("close", {
  skipDirPadNav = true
  onClick = onCloseCb
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  size = fsh(5)
})

let mkWindow = @(_event, onCloseCb) {
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size =  FLEX
      keepAspect = KEEP_ASPECT_FIT
      image = Picture(bgImage?[getLanguageId()] ?? bgImage.en)
      color = 0xFF808080
    }
    {
      flow = FLOW_VERTICAL
      size = const [sw(60), SIZE_TO_CONTENT]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      margin = const [0, 0, sh(15), 0]
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          color = activeTxtColor
          text = loc("steam/awards")
          margin = const [0, 0, sh(3), 0]
        }.__update(fontBody)
        {
          flow = FLOW_HORIZONTAL
          size = const [sw(40), SIZE_TO_CONTENT]
          gap = sw(20)
          halign = ALIGN_CENTER
          children = [
            Regular(loc("Close"), onCloseCb, { hotkeys=[[$"^{JB.B} | Esc" ]] })
            Primary(loc("steam/review"), function() {
              sendBigQueryUIEvent("steam_awards_confirm")
              openUrl(loc("steam/awardsLink"))
              onCloseCb()
            }, { hotkeys = [["^J:X | Enter"]] })
          ]
        }
      ]
    }
    mkCloseBtn(onCloseCb)
    mkSteamLogo([sw(35), -sh(35)])
  ]
}

return mkWindow
