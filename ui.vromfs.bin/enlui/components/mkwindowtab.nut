from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defTxtColor, hoverSlotBgColor, darkTxtColor, activeTxtColor
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/components/textButton.nut" import soundDefault
from "%ui/ui_library.nut" import *
from "types" import Function

let { unseenByType } = require("%ui/components/unseenComps.nut")

function mkUnseenSign(mark, isSelected) {
  let sign = unseenByType?[mark]
  return sign == null ? null
    : isSelected ? smallUnseenNoBlink
    : sign
}

function txtColor(sf, isSelected=true){
  return sf & S_ACTIVE
    ? activeTxtColor
    : sf & S_HOVER
      ? darkTxtColor
      : isSelected
        ? activeTxtColor
        : defTxtColor
}


let mkTabText = @(text, sf, isSelected)
  text instanceof Function
    ? text(sf, isSelected)
    : {
        rendObj = ROBJ_TEXT
        color = txtColor(sf, isSelected)
        text = utf8ToUpper(text)
      }.__update(fontBody)


let mkWindowTab = @(text, onClick, isSelected, override = {}, unseenMarkType = Watched(null))
  watchElemState(@(sf) {
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    sound = soundDefault
    onClick
    children = @() {
      watch = [unseenMarkType]
      rendObj = ROBJ_BOX
      borderWidth = isSelected ? [0, 0, smallPadding, 0] : 0
      fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
      padding = const [fsh(1), fsh(2)]
      borderColor = Color(255,255,255)
      children = [
        mkTabText(text, sf, isSelected)
        {
          pos = [fsh(2), -bigPadding]
          hplace = ALIGN_RIGHT
          children = mkUnseenSign(unseenMarkType.get(), isSelected)
        }
      ]
    }
  }.__update(override))

return mkWindowTab
