import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/spinner.nut" as spinner
import "%ui/components/fontIconButton.nut" as fontIconButton
import "auth" as auth
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/login/login_chain.nut" import startLogin
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/designConst.nut" import commonBtnHeight, midPadding, maxContentWidth
from "%ui/components/textButton.nut" import Regular
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/ui_library.nut" import *

let defLoginCb = require("%ui/login/login_cb.nut")
let textInput = require("%ui/components/textInput.nut")

const LOGIN_WND_UID = "login_back_window"
let newNick = Watched("")
local nickToShowIfInvalid = ""
const WE_GAME_ID = "auth_wegame"
let isLoginInProgress = Watched(false)
let additionalTxt = Watched("")
let wndHeaderTxt = Watched("")
let waitingSpinner = spinner()

function loginWithNick(){
  isLoginInProgress.set(true)
  nickToShowIfInvalid = newNick.get()
  startLogin({ nick = newNick.get() })
  removeModalWindow(LOGIN_WND_UID)
}

let inputOptions = {
  size = [FLEX, commonBtnHeight]
  textmargin = hdpx(7)
  colors = { backGroundColor = Color(0, 0, 0, 255) }
  valignText = ALIGN_CENTER
  margin = 0
  onReturn = loginWithNick
}.__update(fontBody)

let wndHeader = {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  vplace = ALIGN_TOP
  children = [
    @(){
      watch = wndHeaderTxt
      rendObj = ROBJ_TEXT
      text = wndHeaderTxt.get()
    }.__update(fontHeading2)
    @(){
      watch = additionalTxt
      rendObj = ROBJ_TEXTAREA
      size = const [sw(100), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      maxWidth = maxContentWidth - hdpx(100)
      behavior = Behaviors.TextArea
      text = additionalTxt.get()
    }.__update(fontBody)
  ]
}

let inputBlock = @(){
  watch = [newNick, isLoginInProgress]
  rendObj = ROBJ_SOLID
  padding = hdpx(20)
  size = const [FLEX, sh(50)]
  vplace = ALIGN_CENTER
  color = Color(0,0,0, 210)
  gap = hdpx(20)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = isLoginInProgress.get() ? waitingSpinner : [
    wndHeader
    {
      size = const [hdpx(500), SIZE_TO_CONTENT]
      children = textInput(newNick, inputOptions)
    }
    Regular(loc("Ok"), loginWithNick, {
      vplace = ALIGN_BOTTOM
      isEnabled = newNick.get() != ""
    })
  ]
}

let wndContent = @(){
  watch = safeAreaBorders
  size = FLEX
  children = [
    fontIconButton("power-off", {
      onClick = exitGameMsgBox
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.get()[1]
      hotkeys = [[$"^{JB.B} | Esc"]]
    })
    inputBlock
  ]
}

let mkNickInputWnd = {
  key = LOGIN_WND_UID
  onClick = @() null
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture("ui/stalingrad_login_screen_blured.avif")
  keepAspect = KEEP_ASPECT_FILL
  children = wndContent
}

function onInterrupt(state) {
  isLoginInProgress.set(false)
  additionalTxt.set(state?.stageResult?[WE_GAME_ID]?.message ?? "")
  if (state?.status == auth.YU2_NOT_FOUND){
    wndHeaderTxt.set(loc("wegame/pasteNick"))
    addModalWindow(mkNickInputWnd)
    state.params.needShowError <- @(...) false
  }
  else if (state?.status == auth.YU2_UPDATE){
    addModalWindow(mkNickInputWnd)
    wndHeaderTxt.set(loc("wegame/invalidNick", {nick = nickToShowIfInvalid}))
    state.params.needShowError <- @(...) false
  }

  defLoginCb.onInterrupt(state)
}

return {
  onSuccess = @(state) defLoginCb.onSuccess(state)
  onInterrupt
}
