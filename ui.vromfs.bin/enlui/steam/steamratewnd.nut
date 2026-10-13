import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/designConst.nut" import defTxtColor, largePadding
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/steam/steam_pkg.nut" import mkSteamLogo
from "%ui/components/openUrl.nut" import openUrl
from "%ui/components/textButton.nut" import Regular, Primary
from "math" import round
from "%ui/steam/steamRateState.nut" import steamURL, onSteamReviewShown, onSteamLinkClick
from "%ui/ui_library.nut" import *

const steamRatioWndUID = "steam_ratio_wnd"

function closeWindow() {
  removeModalWindow(steamRatioWndUID)
}

let closeBtn = fontIconButton("close", {
  skipDirPadNav = true
  onClick = closeWindow
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  size = fsh(5)
})

let mkWindow = @() {
  size = FLEX
  children = [
    {
      flow = FLOW_VERTICAL
      size = FLEX
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = const [sw(100), round(sw(100) * (280.0/1920.0))]
          image = Picture("ui/uiskin/steam/steam_rate_bg.avif")
        }
        {
          rendObj = ROBJ_IMAGE
          size = FLEX
          keepAspect = KEEP_ASPECT_FILL
          image = Picture("ui/uiskin/steam/steam_bg.avif")
          color = 0xFF808080
        }
      ]
    }
    mkSteamLogo([largePadding, largePadding])
    {
      flow = FLOW_VERTICAL
      size = FLEX_H
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      margin = const [0, 0, sh(15), 0]
      gap = largePadding
      children = [
        {
          rendObj = ROBJ_TEXT
          color = defTxtColor
          text = loc("steam/share_msg")
          margin = const [0, 0, largePadding, 0]
        }.__update(fontBody)
        Primary(loc("steam/share"), function() {
          onSteamLinkClick()
          openUrl(steamURL)
          closeWindow()
        }, { hotkeys = [["^J:X | Enter"]] })
        Regular(loc("btn/later"), closeWindow, { hotkeys=[[$"^{JB.B} | Esc" ]] })
      ]
    }
    closeBtn
  ]
}

function openSteamReviewWnd() {
  onSteamReviewShown()
  addModalWindow({
    key = steamRatioWndUID
    size = FLEX
    onClick = @() null
    children = mkWindow()
  })
}

console_register_command(function() {
  openSteamReviewWnd()
}, "debug.show_steam_rate_wnd")

return {
  openSteamReviewWnd
}
