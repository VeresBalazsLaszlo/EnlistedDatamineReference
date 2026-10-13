from "%ui/components/textButton.nut" import FARegular, Regular
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/style/designConst.nut" import smallPadding
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/ui_library.nut" import *

let changeButtonStyle = {
  size = hdpxi(48)
}

let tb = @(key, action) @() {
  watch = isGamepad
  isHidden = !isGamepad.get()
  vplace = ALIGN_CENTER
  children = mkHotkey(key, action)
}

function mkCounter(maxCount, countWatched, step = 1, showBtnAllItems = false, allItemsOptions = {}) {
  let decCount = @() countWatched.get() > step ? countWatched.modify(@(v) v - step) : null
  let incCount = @()
    countWatched.get() + step <= maxCount ? countWatched.modify(@(v) v + step) : null

  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      tb("^J:LB", decCount)
      FARegular("minus", decCount, changeButtonStyle)
      @() {
        rendObj = ROBJ_TEXT
        watch = countWatched
        fontSize = hdpx(30)
        minWidth = hdpx(40)
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        margin = [0, smallPadding]
        text = countWatched.get()
      }.__update(fontHeading2)
      FARegular("plus", incCount, changeButtonStyle)
      tb("^J:RB",  incCount)
      !showBtnAllItems ? null
        : Regular(loc("btn/upgrade/allItems"), @() countWatched.set(maxCount), allItemsOptions)
    ]
  }
}

return {
  mkCounter
}
