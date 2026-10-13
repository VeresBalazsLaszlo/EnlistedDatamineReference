import "%dngscripts/platform.nut" as platform
import "%ui/control/gui_buttons.nut" as JB
import "%ui/mainMenu/qrWindow.nut" as qrWindow
from "%ui/hud/menus/controls_setup.nut" import showControlsMenu
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/components/openUrl.nut" import openUrl
from "%ui/supportUrls.nut" import gaijinSupportUrl, legalsUrl
from "settings" import get_setting_by_blk_path
from "%ui/state/steamState.nut" import openSteamLinkUrl, clearSteamLinkSeen
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/credits/creditsState.nut" import isCreditsDataPresent
from "%ui/credits/creditsWnd.nut" import creditsWindowOpen
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()
let SEPARATOR = {}
let GSS_URL = circuitConf?.gssUrl
  ?? get_setting_by_blk_path("gssUrl")
  ?? "https://gss.gaijin.net/"
let CBR_URL = circuitConf?.cbrUrl
  ?? get_setting_by_blk_path("cbrUrl")
  ?? "https://community.gaijin.net/issues/p/enlisted"

let btnOptions = {
  name = loc("gamemenu/btnOptions")
  id = "Options"
  cb = @() showSettingsMenu.set(true)
}
let btnControls = {
  id = "Controls"
  name = loc("gamemenu/btnBindKeys")
  cb = @() showControlsMenu.set(true)
}
let btnExit = {
  id = "Exit"
  name = loc("Exit Game")
  cb = exitGameMsgBox
}
let allowUrl = platform.is_pc
let btnGSS = GSS_URL == "" ? null : {
  id = "Gss"
  name = loc("gss")
  cb = @() allowUrl ? openUrl(GSS_URL) : qrWindow({url = GSS_URL, header = loc("gss")})
}
let btnCBR = CBR_URL == "" ? null : {
  id = "Cbr"
  name = loc("cbr")
  cb = @() allowUrl ? openUrl(CBR_URL) : qrWindow({url = CBR_URL, header = loc("cbr")})
}
let btnSupport = gaijinSupportUrl == "" ? null : {
  id = "Support"
  name = loc("support")
  cb = @() allowUrl ? openUrl(gaijinSupportUrl)
    : qrWindow({url = gaijinSupportUrl, header = loc("support")})
}

let btnLegals = legalsUrl == "" ? null : {
  id = "Legals"
  name = loc("Legals")
  cb = @() allowUrl
    ? openUrl(legalsUrl, false, platform.is_mobile )
    : qrWindow({ url = legalsUrl, header = loc("Legals") })
}

let btnCredits = !isCreditsDataPresent ? null : {
  id = "credits"
  name = loc("credits")
  cb = creditsWindowOpen
}

let btnLinkEmail = {
  id = "LinkEmail"
  name = loc("gamemenu/btnLinkAccount")
  cb = openSteamLinkUrl
}

let btnDropSeenSteamLinkMsg = {
  id = "DropSeenSteamLink"
  name = loc("gamemenu/dropSteamLink")
  cb = @() showMsgbox({
    text = loc("msgboxtext/dropSteamLink")
    buttons = [
      { text = loc("Yes"), isCurrent = true, action = @() clearSteamLinkSeen() }
      { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
  })
}

return {
  btnControls
  btnOptions
  btnExit
  btnGSS
  btnLinkEmail
  btnCBR
  btnSupport
  btnLegals
  btnCredits
  SEPARATOR
  btnDropSeenSteamLinkMsg
}
