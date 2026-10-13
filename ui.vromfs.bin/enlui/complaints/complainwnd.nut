import "%ui/control/gui_buttons.nut" as JB
import "%ui/style/colors.nut" as colors
import "%ui/components/closeBtn.nut" as closeBtn
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%sqstd/string.nut" import clearBorderSymbols
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/msgbox.nut" import showMsgbox
from "eventbus" import eventbus_send
from "matching.errors" import INVALID_USER_ID
from "%ui/state/clientState.nut" import gameLanguage
from "%ui/getAppIdsList.nut" import getAppIdByPlatform
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

const bigGap = hdpx(10)

let combobox = require("%ui/components/combobox.nut")
let textInput = require("%ui/components/textInput.nut")

const WND_UID = "complain_window"
const MIN_COMPLAIN_SYMBOLS = 10
const headerHeight = hdpx(45)
let complainTypes = ["FOUL", "ABUSE", "CHEAT", "TEAMKILL", "BOT", "SPAM", "OTHER"]
let defaultType = complainTypes[0]

const wndWidth = hdpx(500)
let lastOpenParams = persist("lastOpenParams", @() {})

function close() {
  removeModalWindow(WND_UID)
  lastOpenParams.clear()
}

let header = @(name) {
  size = const [FLEX, headerHeight]
  rendObj = ROBJ_SOLID
  color = colors.WindowHeader
  valign = ALIGN_CENTER
  padding = bigGap
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("complain/header", { name = name })
    }.__update(fontHeading2)
    closeBtn({ onClick = close })
  ]
}

let mkSubmitButton = @(cantSubmitReason, trySubmit) @() {
  watch = cantSubmitReason
  size = FLEX_H
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  xmbNode = XmbNode()
  children = [
    {
      size = FLEX_H
      minHeight = hdpx(20)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = colors.TextInactive
      text = cantSubmitReason.get() ?? " "
    }.__update(fontSub)
    Regular(loc("btn/send"), trySubmit, { isEnabled = cantSubmitReason.get() == null})
  ]
}

function complainWnd(sessionId, userId, name, platform) {
  let curType = Watched(defaultType)
  let complainText = Watched("")
  let cantSubmitReason = Computed(@()
    clearBorderSymbols(complainText.get()).len() < MIN_COMPLAIN_SYMBOLS
      ? loc("msg/complain/needDetailedComment")
      : null)

  function trySubmit() {
    set_kb_focus(null)

    if (cantSubmitReason.get() != null) {
      showMsgbox(cantSubmitReason.get())
      return
    }

    if (userId != INVALID_USER_ID)
      eventbus_send("penitentiary.complain", {
        userId
        name
        sessionId
        appId = getAppIdByPlatform(platform)
        complainType = curType.get()
        lang = gameLanguage.tolower()
        user_comment = clearBorderSymbols(complainText.get())
      })
    else {
      log($"[COMPLAIN] Attempt to complain on bot {name}, {sessionId}")
      log(clearBorderSymbols(complainText.get()))
    }

    showMsgbox(loc("msg/complain/complainSent"))
    close()
  }

  return {
    size = const [wndWidth, SIZE_TO_CONTENT]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = colors.WindowBlur
    padding = 2 * bigGap
    gap = bigGap

    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    stopMouse = true
    xmbNode = XmbContainer()

    children = [
      header(name)
      {
        size = const [FLEX, hdpx(40)]
        children = combobox(curType, complainTypes.map(@(t) [t, loc($"ban/reason/{t}")]))
      }
      textInput(complainText, {
        placeholder = loc("complain/inputTextPlaceholder")
        textmargin = hdpx(5)
        xmbNode = XmbNode()
        onChange = @(value) complainText.set(value)
        onReturn = trySubmit
        onEscape = close
      }.__update(fontBody))
      mkSubmitButton(cantSubmitReason, trySubmit)
    ]
  }
}

function open(sessionId, userId, name, platform) {
  lastOpenParams.sessionId <- sessionId
  lastOpenParams.userId <- userId
  lastOpenParams.name <- name
  lastOpenParams.platform <- platform
  addModalWindow({
    key = WND_UID
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = colors.ModalBgTint
    onClick = close
    children = complainWnd(sessionId, userId, name, platform)
    hotkeys = [[$"^{JB.B} | Esc", { action = close, description = loc("Cancel") }]]
  })
}

if (lastOpenParams.len() > 0)
  open(lastOpenParams.sessionId, lastOpenParams.userId, lastOpenParams.name, lastOpenParams.platform)

return open
