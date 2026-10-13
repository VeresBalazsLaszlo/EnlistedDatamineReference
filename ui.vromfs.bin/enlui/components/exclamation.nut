import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/ui_library.nut" import *

let infoText = @(text) {
  size = SIZE_TO_CONTENT
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(fontSub)

let exclamation = @(text = "") {
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    faComp("exclamation-triangle", { color = defTxtColor, fontSize = fontSub.fontSize })
    text == "" ? null : infoText(text)
  ]
}

return exclamation
