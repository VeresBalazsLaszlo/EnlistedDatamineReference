import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/designConst.nut" import navHeight, footerContentHeight, smallPadding, contentGap, maxContentWidth
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *


let wndBottomPadding = footerContentHeight + smallPadding

let wndHeader = @(closeAction) {
  size = [FLEX, navHeight]
  valign = ALIGN_BOTTOM
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  children = Regular(loc("BACK"), closeAction,
    { hotkeys = [[ $"^{JB.B} | Esc", { description = loc("BackBtn") } ]] })
}


let commonWndParams = {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = contentGap
  padding = [0,0, wndBottomPadding, 0]
}


return {
  commonWndParams
  wndHeader
}
