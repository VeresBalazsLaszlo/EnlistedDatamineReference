import "%ui/control/controls_types.nut" as controlsTypes
from "%dngscripts/platform.nut" import platformId
from "eventbus" import eventbus_subscribe
from "dainput2" import GAMEPAD_VENDOR_SONY
from "%ui/ui_library.nut" import *

let gamepadTypeByPlatform = {
  ps4 = controlsTypes.ds4gamepad
  ps5 = controlsTypes.ds4gamepad
}
let defGamepadType = gamepadTypeByPlatform?[platformId] ?? controlsTypes.x1gamepad

let gamepadType = mkWatched(persist, "gamepadType", defGamepadType)

function setInput(msg){
  let {ctype} = msg
  gamepadType.set(ctype == GAMEPAD_VENDOR_SONY
                ? controlsTypes.ds4gamepad
                : controlsTypes.x1gamepad)
}
eventbus_subscribe("input_gamepad_type", setInput)
console_register_command(@(value) setInput({ctype=value}), "ui.changegamepad")

wlog(gamepadType, "ui.changegamepad-->")

return gamepadType