from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/colors.nut" import ControlBgOpaque, BtnTextHover, BtnTextActive, BtnTextHilite, BtnTextNormal, BtnBgNormal, BtnBgHover, BtnBgActive
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/state/safeArea.nut" import safeAreaHorPadding
from "%ui/ui_library.nut" import *

let saSize = Computed(@() sw(100)-2*safeAreaHorPadding.get())

function tabCtor(tab, is_current, handler) {
  let grp = ElemGroup()
  let stateFlags = Watched(0)

  return function() {
    let isHover = stateFlags.get() & S_HOVER
    let isFocus = stateFlags.get() & S_KB_FOCUS
    local fillColor, textColor, borderColor
    if (is_current || isFocus) {
      textColor = isHover ? BtnTextHover : BtnTextActive
      fillColor = isHover ? BtnBgHover : BtnBgActive
    } else {
      textColor = isHover ? BtnTextHilite : BtnTextNormal
      fillColor = BtnBgNormal
    }
    borderColor = isHover ? BtnTextHilite : BtnTextNormal

    return {
      key = tab
      rendObj = ROBJ_BOX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      watch = stateFlags
      group = grp

      behavior = Behaviors.Button
      skipDirPadNav = true

      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      fillColor
      borderColor
      borderWidth = const [0, 0, hdpx(1), 0]

      onClick = handler
      onElemState = @(sf) stateFlags.set(sf)

      children = {
        rendObj = ROBJ_TEXT
        margin = const [fsh(1), fsh(2)]
        color = textColor

        text = tab.text
        group = grp
      }.__update(fontBody)
    }
  }
}


function tabsHolder(_params, children) {
  let width = min(sw(90), saSize.get())
  return makeHorizScroll({
    rendObj = ROBJ_BOX
    flow = FLOW_HORIZONTAL
    padding = const [0, hdpx(3)]
    gap = hdpx(3)
    children

    fillColor = ControlBgOpaque
    borderColor = Color(100, 100, 100, 120)
    borderWidth = const [0, 0, hdpx(1), 0]
  }, {
    size = [width, SIZE_TO_CONTENT]
    root = {
      key = "settingsHeaderRoot"
      behavior = Behaviors.Pannable
      wheelStep = 1
    }
  })
}


return function(params = {}) {
  let children = params.tabs.map(function(item) {
    return tabCtor(item, item.id == params.currentTab, @() params.onChange(item))
  })
  return tabsHolder(params, children)
}
