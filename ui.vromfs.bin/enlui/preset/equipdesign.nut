from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, disabledTxtColor,
  disabledBgColor, panelBgColor, hoverPanelBgColor, defSlotBgColor, fullTransparentBgColor,
  commonBtnHeight, midPadding
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/ui_library.nut" import *

let defTxtStyle = { color = defTxtColor }.__update(fontBody)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontBody)
let disabledTxtStyle = { color = disabledTxtColor }.__update(fontBody)

let styles = freeze({
  rowHeight = commonBtnHeight

  closeBtnStyle = {
    padding = midPadding
    fontSize = fontBody.fontSize
    color = defTxtColor
  }

  textState = @(sf, isPrem) {
    padding = midPadding
  }.__update(sf & S_HOVER ? hoverTxtStyle
    : isPrem ? disabledTxtStyle
    : defTxtStyle)

  bgState = @(sf, isPrem) {
    fillColor = sf & S_HOVER ? hoverPanelBgColor
      : isPrem ? disabledBgColor
      : panelBgColor
  }

  innerBtnStyle = {
    style = {
      hoverPanelBgColor = fullTransparentBgColor
      defBgColor = fullTransparentBgColor
      defBdColor = fullTransparentBgColor
    }
  }

  defInputStyle = {
    padding = [0, 0, 0, midPadding]
    colors = {
      textColor = defTxtColor
      backGroundColor = defSlotBgColor
    }
  }.__update(fontBody)

  hoverInputStyle = {
    padding = [0, 0, 0, midPadding]
    colors = {
      textColor = titleTxtColor,
      backGroundColor = hoverPanelBgColor
    }
  }.__update(fontBody)

})

return styles
