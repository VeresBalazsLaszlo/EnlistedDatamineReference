from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import bigPadding, defInsideBgColor, defTxtColor, blurBgFillColor, smallPadding
from "%ui/gameModes/eventModeStyle.nut" import rowHeight
from "%ui/ui_library.nut" import *

let setColorBySF = @(sf) sf & S_HOVER ? defInsideBgColor : blurBgFillColor

function mkOptionRow (locId, component = null, override = {},
  onClick = @() null, firstChild = null
) {
  let stateFlag = Watched(0)
  return @() {
    watch = stateFlag
    size = [FLEX, rowHeight]
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    onClick
    color = setColorBySF(stateFlag.get())
    onElemState = @(v) stateFlag.set(v)
    margin = [smallPadding, 0]
    padding = [0, bigPadding]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      firstChild
      {
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        size = FLEX
        valign = ALIGN_CENTER
        color = defTxtColor
        text = locId == null ? null : loc(locId)
      }.__update(fontBody)
      component
    ]
  }.__update(override)
}

return mkOptionRow