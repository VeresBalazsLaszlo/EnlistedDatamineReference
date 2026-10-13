import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/mkQrCode.nut" as mkQrCode
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub, fontBody
from "%ui/style/colors.nut" import ModalBgTint, TextDefault, WindowBlur
from "%ui/style/designConst.nut" import bigGap
from "%ui/components/openUrl.nut" import openUrl, AuthenticationMode
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/ui_library.nut" import *

const WND_UID = "qr_window"
const URL_REFRESH_SEC = 300 
let waitingSpinner = spinner()

function close(onCloseCb = null) {
  onCloseCb?()
  removeModalWindow(WND_UID)
}

let waitInfo = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    { rendObj = ROBJ_TEXT, text = loc("xbox/waitingMessage"), color = TextDefault }.__update(fontSub)
    waitingSpinner
  ]
}

let qrWindow = kwarg(function (url, header = "", desc = "", needShowRealUrl = true) {
  let realUrl = Watched(null)
  function receiveRealUrl() {
    openUrl(url, AuthenticationMode.NOT_AUTHENTICATED, false, @(u) realUrl.set(u))
    gui_scene.resetTimeout(URL_REFRESH_SEC, receiveRealUrl)
  }

  return @() {
    watch = realUrl
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = WindowBlur
    padding = 2 * bigGap
    gap = bigGap

    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER

    onAttach = receiveRealUrl
    onDetach = @() gui_scene.clearTimer(receiveRealUrl)

    children = [
      { rendObj = ROBJ_TEXT, text = header }.__update(fontHeading2)
      desc == "" ? null : {
        rendObj = ROBJ_TEXTAREA,
        behavior = Behaviors.TextArea,
        halign = ALIGN_CENTER
        text = desc,
        maxWidth = hdpx(600)
      }.__update(fontBody)
      needShowRealUrl ? { rendObj = ROBJ_TEXT, text = url }.__update(fontSub) : null
      realUrl.get() ? mkQrCode({ data = realUrl.get() }) : waitInfo
    ]
  }
})

return @(params, onCloseCb = null) addModalWindow({
  key = WND_UID
  size = const [sw(100), sh(100)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = ModalBgTint
  onClick = @() close(onCloseCb)
  children = qrWindow(params)
  hotkeys = [[$"^{JB.B} | Esc", { action = @() close(onCloseCb), description = loc("Cancel") }]]
})