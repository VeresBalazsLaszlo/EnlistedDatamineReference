import "%ui/components/gamepadImgByKey.nut" as gamepadImgByKey
import "%ui/control/gui_buttons.nut" as JB
import "%ui/helpers/locByPlatform.nut" as locByPlatform
from "%ui/style/fontsStyle.nut" import fontSub
from "%sqstd/timers.nut" import debounce
from "%ui/style/designConst.nut" import panelBgColor, hoverPanelBgColor, defBdColor, titleTxtColor, hoverTxtColor, midPadding, smallPadding
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

let defTxtStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let hoverTxtStyle = freeze({ color = hoverTxtColor }.__update(fontSub))
const CONTEXT_UID = "contextMenu"

let activeBtn = gamepadImgByKey.mkImageCompByDargKey(JB.A, {
  height = defTxtStyle.fontSize*1.6
  halign = ALIGN_CENTER
})

const sound = {
  click  = "ui/button_click"
  hover  = "ui/menu_highlight"
  active = "ui/button_action"
}

let listItem = @(text, action) watchElemState(@(sf) {
  watch = isGamepad
  behavior = Behaviors.Button
  clipChildren = true
  rendObj = ROBJ_SOLID
  color = sf & S_HOVER ? hoverPanelBgColor : panelBgColor
  size = FLEX_H
  padding = midPadding
  onClick = action
  sound
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      size = FLEX_H
      scrollOnHover = true
      speed = hdpx(93)
      text
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    isGamepad.get() && (sf & S_HOVER)
      ? {size = const [SIZE_TO_CONTENT, 0], vplace = ALIGN_CENTER, valign = ALIGN_CENTER, hplace = ALIGN_RIGHT, children = activeBtn}
      : null
  ]
})

function mkMenu(width, actions) {
  let visibleActions = actions.filter(@(a) a?.isVisible.get() ?? true)
  let autoHide = debounce(@() modalPopupWnd.remove(CONTEXT_UID), 0.01)
  return function() {
    if (visibleActions.len() == 0)
      autoHide() 

    return {
      watch = actions.map(@(a) a?.isVisible).filter(@(w) w != null)
      size = [width, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = {
        rendObj = ROBJ_SOLID
        size = const [FLEX, hdpx(1)]
        color = defBdColor
      }
      children = visibleActions.map(@(item) listItem(
        item?.text ?? locByPlatform(item?.locId),
        function() {
          item.action()
          modalPopupWnd.remove(CONTEXT_UID)
        }))
    }
  }
}

function addContextMenu(x, y, width, actions) {
  if (actions.findvalue(@(a) a?.isVisible.get() ?? true) == null)
    return null 

  modalPopupWnd.add([x, y], {
    uid = CONTEXT_UID
    rendObj = ROBJ_SOLID
    padding = smallPadding
    color = defBdColor
    popupHalign = ALIGN_LEFT
    popupValign = y > sh(75) ? ALIGN_BOTTOM : ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    moveDuration = min(0.12 + 0.03 * actions.len(), 0.3) 
    children = mkMenu(width, actions)
  })
}

let closeLatestContextMenu = @() modalPopupWnd.remove(CONTEXT_UID)

return {
  addContextMenu
  closeLatestContextMenu
}