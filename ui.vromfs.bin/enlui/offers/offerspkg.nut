from "%ui/components/formatText.nut" import mkFormatText
from "%ui/style/designConst.nut" import titleTxtColor, defTxtColor, strokeStyle
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "dagor.iso8601" import parse_unix_time
from "%ui/ui_library.nut" import *


const DESC_WIDTH = fsh(75)
const DESC_PADDING = hdpx(20)
let IMAGE_WIDTH = DESC_WIDTH - DESC_PADDING * 2


let formatText = mkFormatText({
  defTextColor = defTxtColor
  h1FontStyle = fontBody
  h2FontStyle = fontBody
  h3FontStyle = fontBody
  textFontStyle = fontSub
  noteFontStyle = fontSub
  h1Color = titleTxtColor
  h2Color = titleTxtColor
  h3Color = titleTxtColor
  emphasisColor = titleTxtColor
  padding = fsh(1)
}, {
  image = function(obj, _, style) {
    local { width = IMAGE_WIDTH, height = null } = obj
    if (width > IMAGE_WIDTH) {
      height = height != null ? IMAGE_WIDTH * height / width : SIZE_TO_CONTENT
      width = IMAGE_WIDTH
    } else
      height = height ?? SIZE_TO_CONTENT
    return {
      size = FLEX_H
      halign = ALIGN_CENTER
      clipChildren = true
      children = [
        obj.__merge({
          rendObj = ROBJ_IMAGE
          size = [width, height]
          image = Picture(obj.v)
          keepAspect = KEEP_ASPECT_FIT
          imageAffectsLayout = true
        })
        !obj?.caption ? null : {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          padding = style.padding
          halign = ALIGN_CENTER
          vplace = ALIGN_BOTTOM
          margin = const [fsh(1), fsh(3)]
          text = obj?.caption
        }.__update(fontSub, strokeStyle)
      ]
    }
  }
})

function getTableTimestamp(tName, uTables) {
  let unixTimeStr = uTables?[tName].interval.end ?? ""
  return unixTimeStr == "" ? null : parse_unix_time(unixTimeStr)
}

return {
  mkFormatText = formatText
  getTableTimestamp
}