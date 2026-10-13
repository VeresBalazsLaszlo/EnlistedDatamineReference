from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/defcomps.nut" import txt
from "%ui/style/designConst.nut" import defTxtColor, darkTxtColor, smallPadding, bigPadding, smallOffset, tinyOffset, accentTitleTxtColor
from "dagor.iso8601" import format_unix_time
from "%ui/ui_library.nut" import *




let rowStyle = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = tinyOffset
  valign = ALIGN_CENTER
}

let mkRowText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontSub)

let userLogStyle = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  padding = bigPadding
  gap = smallPadding
  halign = ALIGN_CENTER
}

let userLogRowStyle = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  padding = [tinyOffset, smallOffset]
}



let mkUserLogHeader = @(_isSelected, logTime, logText, sf) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [






    txt({
      text = logText
      size = FLEX_H
      color = sf & S_HOVER ? darkTxtColor : accentTitleTxtColor
    }).__update(fontSub)
    txt({
      text = format_unix_time(logTime).replace("T", " ").replace("Z", "")
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
    }).__update(fontSub)
  ]
}

return {
  rowStyle
  userLogStyle
  userLogRowStyle

  mkRowText
  mkUserLogHeader
}
