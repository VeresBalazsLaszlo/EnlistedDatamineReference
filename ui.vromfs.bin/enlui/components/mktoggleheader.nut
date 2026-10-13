import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, midPadding
from "%ui/ui_library.nut" import *
from "types" import String

let textColor = @(sf) sf & S_ACTIVE ? 0xFFFFFFFF
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let mkTextCtor = @(text) @(sf) {
  rendObj = ROBJ_TEXT
  size = FLEX_H
  text
  color = textColor(sf)
}.__update(fontSub)

function mkToggleHeader(isShow, textOrCtor) {
  let textCtor = textOrCtor instanceof String ? mkTextCtor(textOrCtor) : textOrCtor
  return watchElemState(@(sf) {
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [midPadding, 0, 0, 0]
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    onClick = @() isShow.set(!isShow.get())
    children = [
      textCtor(sf)
      @() faComp(isShow.get() ? "minus-square" : "plus-square", {
        watch = isShow
        size = hdpx(25)
        hplace = ALIGN_CENTER
        fontSize = hdpx(20)
        color = textColor(sf)
      })
    ]
  })
}

return mkToggleHeader