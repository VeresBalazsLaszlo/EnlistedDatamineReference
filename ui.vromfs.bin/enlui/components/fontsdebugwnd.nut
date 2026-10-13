from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/ui_library.nut" import *

let textInput = require("%ui/components/textInput.nut")
const wndWidth = sw(80)

const WND_UID = "fontsDebugWnd"
const DEF_TXT = "The quick brown fox jumps over the lazy dog"
let isOpened = Watched(false)
let textInputWatch = Watched(DEF_TXT)
let isUpperCaseModeOne = Watched(false)
const textBlockWidth = hdpx(500)

let textValue = Computed(@() isUpperCaseModeOne.get()
  ? utf8ToUpper(textInputWatch.get())
  : textInputWatch.get())

let inputBlock = textInput.NoFrame(textInputWatch, {
  placeholder = "Введи текст..."
  onEscape = @() textInputWatch.set("")
})

let btnUpperCase = @() {
  watch = isUpperCaseModeOne
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  halign = ALIGN_CENTER
  size = const [hdpx(180), SIZE_TO_CONTENT]
  behavior = Behaviors.Button
  flow = FLOW_HORIZONTAL
  onClick = @() isUpperCaseModeOne.set(!isUpperCaseModeOne.get())
  children = {
    rendObj = ROBJ_TEXT
    text = isUpperCaseModeOne.get() ? "Uppercase Mode: ON" : "Uppercase Mode: OFF"
  }
}

let topBlock = {
  size = const [hdpx(900), SIZE_TO_CONTENT]
  vplace = ALIGN_TOP
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(20)
  flow = FLOW_HORIZONTAL
  children = [
    btnUpperCase
    inputBlock
  ]
}

let textResultBlock = @(fontStyle) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  fillColor = Color(15,15,15)
  borderColor = Color(50,50,50)
  padding = hdpx(5)
  gap = hdpx(5)
  size = const [textBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"{fontStyle[0]} size: {fontStyle[1].fontSize}px"
    }
    @() {
      watch = textValue
      rendObj = ROBJ_TEXTAREA
      size = const [textBlockWidth, SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = textValue.get()
    }.__update(typeof fontStyle[1] == "table" ? fontStyle[1] : {})
  ]
}


let wrapParams = {
  width = wndWidth
  hGap = hdpx(50)
  vGap = hdpx(50)
  halign = ALIGN_CENTER
}

let textsBlocks = @(fontStyles) {
  size = FLEX_H
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = wrap(fontStyles.map(@(style)
    textResultBlock(style)
    ), wrapParams)
}

function contentBlock(fonts) {
  let fontStylesTable = fonts.topairs().sort(@(a,b)  (a[1]?.fontSize ?? 0) <=> (b[1]?.fontSize ?? -1))
  return {
    size = const [wndWidth, FLEX]
    flow = FLOW_VERTICAL
    padding = hdpx(20)
    gap = hdpx(50)
    halign = ALIGN_CENTER
    children = [
      topBlock
      makeVertScroll(textsBlocks(fontStylesTable))
    ]
  }
}

let open = @(fonts) addModalWindow({
  key = WND_UID
  rendObj = ROBJ_SOLID
  size = FLEX
  color = 0xFF000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = contentBlock(fonts)
  onClick = @() isOpened.set(false)
})

function initFontsDebugWnd(fonts) {
  if (isOpened.get())
    open(fonts)

  isOpened.subscribe(@(v) v ? open(fonts) : removeModalWindow(WND_UID))
}

console_register_command(@() isOpened.set(!isOpened.get()), "debug.fontsDebugWnd")

return initFontsDebugWnd