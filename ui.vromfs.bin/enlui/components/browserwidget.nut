import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/colors.nut" import TextDefault, BtnBdDisabled, ModalBgTint
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let {Browser = null} = require_optional("browser.behaviors")

let { browser_go_back = @() null,
        browser_reload_page = @() null,
        can_use_embeded_browser = @() false } = require_optional("browser")

let windowTitle = Watched(null)
let canGoBack = Watched(false)
let isBrowserClosed = Watched(true)

const WND_UID = "webbrowser_window"


function handleBrowserEvent(val) {
  if ("canGoBack" in val)
    canGoBack.set(!!val.canGoBack)
  if ("title" in val)
    windowTitle.set(val.title ?? "")
}

eventbus_subscribe("browser_event", handleBrowserEvent)

let windowTitleHeader = @() {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  watch = windowTitle
  text = windowTitle.get()
  color = TextDefault
  size = FLEX_H
  padding = const [hdpx(5), hdpx(20)]
}

let controlPanel = {
  size = const [FLEX, hdpx(35)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    fontIconButton("arrow-left", {
      padding = hdpx(5)
      onClick = browser_go_back
      watch = canGoBack
      isEnabled = @() canGoBack.get()
      iconColor = @(_) canGoBack.get() ? null : BtnBdDisabled
    })
    fontIconButton("refresh", {
      padding = hdpx(5)
      onClick = browser_reload_page
    })
    windowTitleHeader
    fontIconButton("close", {
      padding = hdpx(5)
      onClick = function(){
        removeModalWindow(WND_UID)
        isBrowserClosed.set(true)
      }
    })
  ]
}

function showBrowser(url = "") {
  if (can_use_embeded_browser()) {
    isBrowserClosed.set(false)
    addModalWindow({
      key = WND_UID
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = ModalBgTint
      onClick = @() null
      children = {
        clipChildren = true
        flow = FLOW_VERTICAL
        
        
        size = const [hdpx(1200), hdpx(768)]
        rendObj = ROBJ_SOLID
        color = Color(20,20,20,255)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          controlPanel
          {
            size = FLEX
            rendObj = ROBJ_BROWSER
            behavior = Browser
            defaultUrl = url != "" ? url : null
          }
        ]
      }
    })
  } else {
    showMsgbox(loc("error/CANNOT_DISPLAY_WEBBROWSER"))
  }
}

return {
  showBrowser
  isBrowserClosed
}