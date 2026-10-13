import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontawesome, fontBody
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/designConst.nut" import defBdColor, panelBgColor, defTxtColor, defItemBlur, commonBtnHeight, midPadding, smallPadding
  , titleTxtColor, hoverSlotBgColor, darkTxtColor
from "%ui/currency/premiumComp.nut" import premiumBtnSize
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/ui_library.nut" import *
from "types" import Function, Array

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")


const WND_UID = "main_menu_header_buttons"

let defSize = premiumBtnSize
let fillBgColor = @(sf) sf & S_ACTIVE ? 0xFF3B516A
  : sf & S_HOVER ? hoverSlotBgColor
  : panelBgColor

function close(cb = null) {
  cb?()
  modalPopupWnd.remove(WND_UID)
}

const btnSound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}

let hotkeyOnHover = freeze({
  size = [fontBody.fontSize, SIZE_TO_CONTENT]
  children = mkImageCompByDargKey(JB.A, { height = fontBody.fontSize })
})

let widthHotkeyOnHover = freeze({size = [calc_comp_size(hotkeyOnHover)[0], 0]})

let mkMenuButton = @(btn, needMoveCursor) (btn?.len() ?? 0) > 0
  ? watchElemState(function(sf) {
      return {
        watch = isGamepad
        rendObj = ROBJ_SOLID
        color = fillBgColor(sf)
        size = [FLEX, commonBtnHeight]
        minWidth = SIZE_TO_CONTENT
        behavior = Behaviors.Button
        sound = btnSound
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        onClick = @() close(btn.cb)
        valign = ALIGN_CENTER
        padding = midPadding
        children = [
          isGamepad.get() && (sf & S_HOVER) ? hotkeyOnHover : null
          {
            rendObj = ROBJ_TEXT
            text = btn?.name ?? ""
            color =  (sf & S_ACTIVE) || (sf & S_HOVER) ? titleTxtColor : defTxtColor
          }.__update(fontBody)
          isGamepad.get() && !(sf & S_HOVER) ? widthHotkeyOnHover : null
        ]
      }.__update(!needMoveCursor ? {} : {
        key = "selected_menu_elem"
        onAttach = @() move_mouse_cursor("selected_menu_elem", false)
      })
    })
  : {
      rendObj = ROBJ_SOLID
      size = const [FLEX, hdpx(1)]
      color = defBdColor
    }


let mkMenuButtons = @(buttons, watch) function(){
  local children = (buttons instanceof Function ? buttons() : buttons)
    .map(@(btn, idx) mkMenuButton(btn, isGamepad.get() && idx == 0))
  return {
    watch = [isGamepad].extend(watch)
    minWidth = fsh(27.5)
    flow = FLOW_VERTICAL
    children
  }
}

let openMenu = @(event, content) modalPopupWnd.add(event.targetRect, {
  uid = WND_UID
  padding = 0
  margin = const [hdpx(6), 0]
  popupHalign = ALIGN_RIGHT
  popupBg = {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = defItemBlur
  }
  hotkeys = [[
    $"^J:Start | {JB.B} | Esc",
    { action = @() close(), description = loc("Cancel") }
  ]]
  children = content
})


let mkbars = @(sf) {
  rendObj = ROBJ_TEXT
  text = fa["bars"]
  color = sf & S_HOVER ? darkTxtColor : defTxtColor
}.__update(fontawesome)

function mkDropMenuBtn(buttons, watch) {
  let watchTo = !(watch instanceof Array) ? [watch] : watch
  let menuButtonsUi = mkMenuButtons(buttons, watchTo)
  let onClick = @(event) openMenu(event, menuButtonsUi)
  let gamepadBtn = mkImageCompByDargKey("J:Start", { height = defSize/1.5})
  return watchElemState(function(sf) {
    return {
      watch = isGamepad
      rendObj = ROBJ_SOLID
      behavior = Behaviors.Button
      onClick
      sound = btnSound
      size = [defSize, defSize]
      hotkeys = [[ "^J:Start | Esc", { description = { skip = true } } ]]
      children = {
        fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
        size = [defSize, defSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = isGamepad.get() ? gamepadBtn : mkbars(sf)
      }
      color = fillBgColor(sf)
    }
  })
}


return mkDropMenuBtn