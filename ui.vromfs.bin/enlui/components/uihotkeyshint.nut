import "%ui/components/parseDargHotkeys.nut" as parseDargHotkeys
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/control/formatInputBinding.nut" import buildElems
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/style.nut" import HUD_TIPS_HOTKEY_FG
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/ui_library.nut" import *

function mkHintRow(hotkeys, params = {}) {
  let textFunc = params?.textFunc ?? @(text) {
    rendObj = ROBJ_TEXT
    text
    color = HUD_TIPS_HOTKEY_FG
    font = params?.font ?? fontSub.font
    fontSize = params?.fontSize ?? fontSub.fontSize
  }
  let noWatchGamepad = params?.column != null
  return function() {
    let watch = noWatchGamepad ? null : isGamepad
    let isGamepadV = noWatchGamepad ? params.column == 1 : isGamepad.get()
    let rowTexts = parseDargHotkeys(hotkeys)?[isGamepadV ? "gamepad" : "kbd"] ?? []
    if (rowTexts.len() == 0)
      return { watch }

    return {
      watch
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      vplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = buildElems(rowTexts, { textFunc })
    }.__update(params)
  }
}

function mkHotkey(hotkey, action, params = {}) {
  function hotkeyAction() {
    action?()
    if (!params?.silenced)
      sound_play("ui/enlist/button_click")
  }
  return {
    children = mkHintRow(hotkey, params)
    hotkeys = [[hotkey, { action = hotkeyAction, description = { skip = true }}]]
  }.__merge(params)
}

return {
  mkHintRow
  mkHotkey
}