import "%ui/control/gui_buttons.nut" as JB
import "%ui/style/cursors.nut" as cursors
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/components/textButton.nut" import Regular
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/helpers/gradients.nut" import mkTwoSidesGradientX
from "%ui/style/designConst.nut" import smallPadding
from "%ui/ui_library.nut" import *

let msgbox = require("%ui/components/mkMsgbox.nut")("msgbox")

const bgColor = 0XEE1F242A
const rootColor = 0XFF1F242A
const minContentHeight = fsh(32)

let decorImg = mkTwoSidesGradientX({
  centerColor = 0x77FFFFFF
  sideColor = 0x11FFFFFF
  isAlphaPremultiplied = false
})

let decorObj = {
  size = [FLEX, smallPadding]
  rendObj = ROBJ_IMAGE
  image = decorImg
}

let eventHandlersStopper = {
  ["HUD.ChatInput"] = @(_event) EVENT_BREAK
}

let msgboxStyling = {
  rootUpperDecor = decorObj
  rootLowerDecor = decorObj

  Root = {
    behavior = DngBhv.ActivateActionSet
    actionSet = "StopInput"
    rendObj = ROBJ_WORLD_BLUR_PANEL
    stopMouse = true
    stopHotkeys = true
    fillColor = rootColor
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = const [sw(100), SIZE_TO_CONTENT]
    minHeight = fsh(40)
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.25,
        play = true, easing = OutCubic }
      { prop = AnimProp.scale,  from = [1, 0], to = [1,1], duration = 0.2,
        play = true, easing = OutQuintic }
    ]
  }
  moveMouseCursor = isGamepad
  closeKeys = $"{JB.B} | Esc"
  leftKeys = "L.Shift Tab | R.Shift Tab"
  rightKeys = "Tab"
  activateKeys = "Space | Enter"

  closeTxt = loc("Close")

  BgOverlay = {
    size = const [sw(100), sh(100)]
    color = bgColor
    rendObj = ROBJ_SOLID
    stopMouse = true
    cursor = cursors.normal
    zOrder = Layers.MsgBox
    sound = {
      hover  = "ui/menu_highlight"
      click  = "ui/button_click_inactive"
    }
    eventHandlers = eventHandlersStopper
    animations = [
      { prop=AnimProp.opacity, from=1, to=0, duration=0.15, playFadeout=true, easing=OutCubic }
      { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
    ]
  }

  button = function(desc, on_click) {
    let addKey = {key = desc?.key ?? desc}
    return Regular(desc?.text ?? "???", on_click, (desc?.customStyle!=null) ? desc.customStyle.__merge(addKey) : addKey)
  }

  messageText = function(params) {
    local text = params?.text
    if (isObservable(text))
      text = text.get()

    return {
      size = FLEX_H
      minHeight = minContentHeight
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      margin = const [fsh(2), 0, 0, 0]
      children = [
        {
          size = const [sw(60), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text
        }.__update(params?.fontStyle ?? fontHeading2)
        params?.children
      ]
    }
  }
}

let genData = @(p) typeof p == "table" ? p : { text = p }

let addDefOkButton = @(p) "buttons" in p ? p : p.__merge({
  buttons = [{ text = loc("Close"), isCancel = true,
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }]
})

let msgText = @(p) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  minHeight = minContentHeight
  padding = const [fsh(2), 0]
  children = p.content
}

function showMessageWithStyle(p, msgStyle) {
  msgStyle = msgStyle.__merge({messageText = msgText})
  msgbox.showMsgbox(addDefOkButton(p), msgStyle)
}

function showContentOnPictureBg(p) {
  let msgStyle = clone msgboxStyling
  msgStyle.Root = msgboxStyling.Root.__merge({ rendObj = null })
  msgStyle.BgOverlay = msgboxStyling.BgOverlay.__merge({
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      size = const [SIZE_TO_CONTENT, sh(100)]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      color = null
      keepAspect = KEEP_ASPECT_FIT
      image = p?.bgImage
    }
  })
  showMessageWithStyle(p, msgStyle)
}

function showMessageWithContent(p, customStyle = null) {
  showMessageWithStyle(p, customStyle ?? msgboxStyling)
}


function showMsgboxWithCloseButton(params) {
  params = genData(params)
  let originalMessageText = msgboxStyling.messageText
  let style = msgboxStyling.__merge({
    messageText = @(textParams) {
      size = FLEX_H
      children = [
        {
          flow = FLOW_HORIZONTAL
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          children = [
            params?.topPanel
            fontIconButton("close", {
              onClick = @() textParams?.handleButton(params?.onButtonCloseCb)
              size = fsh(5)
              hotkeys = [[JB.B, { description = { skip = true } }]]
            })
          ]
        }
        originalMessageText(textParams)
      ]
    }
  })
  msgbox.showMsgbox(addDefOkButton(params), style)
}

let showMsgbox = @(params, style = msgboxStyling)
  msgbox.showMsgbox(addDefOkButton(genData(params)), style)

return freeze(msgbox.__merge({
  showMsgbox
  showMessageWithContent
  showContentOnPictureBg
  showMsgboxWithCloseButton
  msgboxStyling
  decorObj
}))
