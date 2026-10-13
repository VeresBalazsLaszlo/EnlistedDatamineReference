import "%ui/components/fontIconButton.nut" as fontIconButton
import "tgbapi" as tgbapi
from "%ui/style/colors.nut" import TextDefault, BtnBdDisabled
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/components/modalWindows.nut" import addModalWindow
from "eventbus" import eventbus_subscribe
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let {Browser = null} = require_optional("browser.behaviors")

let circuitConf = get_circuit_conf()
let stub = @(...) null
let { browser_reload_page=stub, can_use_embeded_browser=stub,
  browser_go_back=stub } = require_optional("browser")

let windowTitle = Watched(null)
let canGoBack = Watched(false)

const WND_UID = "webbrowser_window"

function handleBrowserEvent(val) {
  if ("canGoBack" in val)
    canGoBack.set(!!val.canGoBack)
  if ("title" in val)
    windowTitle.set(val.title ?? "")
}

eventbus_subscribe("browser_event", handleBrowserEvent)

let WEB_LOGIN_URL = circuitConf?.webLoginUrl

let windowTitleHeader = @() {
  size = FLEX_H
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  watch = windowTitle
  halign = ALIGN_CENTER
  text = windowTitle.get()
  color = TextDefault
  padding = const [hdpx(5), hdpx(200)]
}

let buttonsBlock = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  padding = const [0, hdpx(30)]
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    fontIconButton("arrow-left", {
      onClick = browser_go_back
      watch = canGoBack
      isEnabled = @() canGoBack.get()
      iconColor = @(_) canGoBack.get() ? null : BtnBdDisabled
    })
    fontIconButton("refresh", {
      onClick = browser_reload_page
    })
    { size = FLEX }
    fontIconButton("power-off", {
      onClick = exitGameMsgBox
    })
  ]
}

let controlPanel = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, hdpx(35)]
  color = Color(0,0,0)
  valign = ALIGN_CENTER
  children = [
    buttonsBlock
    windowTitleHeader
  ]
}

return function showBrowser() {
  if (can_use_embeded_browser()) {
    local loginUrl = WEB_LOGIN_URL

    if (tgbapi.is_running())
      loginUrl = tgbapi.get_weblogin_url(WEB_LOGIN_URL)

    addModalWindow({
      key = WND_UID
      rendObj = ROBJ_SOLID
      flow = FLOW_VERTICAL
      Color = Color(0,0,0)
      onClick = @() null
      children = [
        controlPanel
        {
          size = FLEX
          rendObj = ROBJ_BROWSER
          behavior = Browser
          defaultUrl = loginUrl
        }
      ]
    })
  } else {
    showMsgbox(loc("error/CANNOT_DISPLAY_WEBBROWSER"))
  }
}
