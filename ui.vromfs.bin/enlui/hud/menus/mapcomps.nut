import "%ui/control/formatInputBinding.nut" as formatInputBinding
import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/uiHotkeysHint.nut" import mkHintRow as uiHotkeysHint
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/style/designConst.nut" import shadowStyle
from "%ui/ui_library.nut" import *

let hintTextFunc = @(text, color = DEFAULT_TEXT_COLOR) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontBody, shadowStyle)

function mkTips(keys, locId){
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = formatInputBinding.buildElems(keys, { textFunc = hintTextFunc })
      .append(hintTextFunc(loc(locId)))
  }
}

function makeHintRow(hotkeys, text) {
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [uiHotkeysHint(hotkeys,{textFunc=hintTextFunc})].append(hintTextFunc(text))
  }
}

let mouseNavTips = mkTips(["MMB"], "map/bigMapPan")
let placePointsTipGamepad = {
  size = FLEX_H
  children = [
    makeHintRow(JB.A, loc("map/place_marks/gamepad"))
  ]
}
let navGamepadHints = {
  flow = FLOW_HORIZONTAL
  gap = fsh(5)
  children = [
    mkTips(["J:LT", "J:RT"], "map/zoom")
    mkTips(["J:R.Thumb.hv"], "map/bigMapPan")
  ]
}

let placePointsTipMouse = mkTips(["RMB"], "map/place_marks/gamepad")

return {hintTextFunc, mouseNavTips, placePointsTipGamepad, navGamepadHints, mkTips, placePointsTipMouse}
