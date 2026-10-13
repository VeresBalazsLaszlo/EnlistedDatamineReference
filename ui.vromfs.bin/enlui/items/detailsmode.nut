import "%ui/components/checkbox.nut" as checkbox
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import titleTxtColor
from "%ui/ui_library.nut" import *

let localSettings = require("%ui/options/localSettings.nut")("quickMatch/")


let isDetailsFull = localSettings(false, "isDetailsFull")

let detailsModeCheckbox = checkbox(isDetailsFull, {
    text = loc("showDetails")
    color = titleTxtColor
  }.__update(fontSub), {
    setValue = @(val) isDetailsFull.set(val)
    textOnTheLeft = true
    override = { hotkeys = [["^J:Start", { description = loc("showDetails") } ]]}
  }
)

return {
  isDetailsFull
  detailsModeCheckbox
}
