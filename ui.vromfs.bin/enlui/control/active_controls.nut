import "%dngscripts/platform.nut" as platform
import "%ui/control/controls_types.nut" as controlsTypes
from "console" import register_command as console_register_command
from "dainput2" import set_actions_binding_column_active
from "eventbus" import eventbus_send, eventbus_subscribe
from "%ui/ui_library.nut" import gui_scene, mkWatched, Computed, Watched, log

let forcedControlsType = mkWatched(persist, "forcedControlsType")
let defRaw = platform.is_pc && !platform.is_steam_deck ? 0 : 1
let lastActiveControlsTypeRaw = mkWatched(persist, "lastActiveControlsTypeRaw", defRaw)
let def = platform.isTouchPrimary
          ? controlsTypes.touch
          : platform.is_pc && !platform.is_steam_deck
            ? controlsTypes.keyboardAndMouse
            : platform.is_sony
              ? controlsTypes.ds4gamepad
              : controlsTypes.x1gamepad

let lastActiveControlsType = mkWatched(persist, "lastActiveControlType", def)
let lastInputUsed = mkWatched(persist, "lastInputUsed", defRaw)

const EV_FORCE_CONTROLS_TYPE = "forced_controls_type"
function setForcedControlsType(v){
  forcedControlsType.set(v)
}

enum ControlsTypes {
  AUTO = 0
  KB_MOUSE = 1
  GAMEPAD = 2
}

console_register_command(@(value) eventbus_send(EV_FORCE_CONTROLS_TYPE, {val=value}), "ui.debugControlsType")
eventbus_subscribe(EV_FORCE_CONTROLS_TYPE, @(msg) setForcedControlsType(msg.val))

const EV_INPUT_USED = "input_dev_used"

function update_input_types(new_val){
  let map = {
    [1] = platform.isTouchPrimary ? controlsTypes.touch : controlsTypes.keyboardAndMouse,
    [2] = controlsTypes.x1gamepad,
    
  }
  local ctype = map?[new_val] ?? def
  if (platform.is_sony && ctype==controlsTypes.x1gamepad)
    ctype = controlsTypes.ds4gamepad
  lastActiveControlsTypeRaw.set(new_val ?? defRaw)
  lastActiveControlsType.set(ctype)
}

forcedControlsType.subscribe(function(val) {
  update_input_types(val)
})

eventbus_subscribe(EV_INPUT_USED, function(msg) {
  lastInputUsed.set(msg.val)
  if ([null, 0].contains(forcedControlsType.get()))
    update_input_types(msg.val)
})

let isTouch = Computed(@() lastActiveControlsType.get() == controlsTypes.touch)
keepref(isTouch)

let isGamepad = Computed(@() forcedControlsType.get() == ControlsTypes.GAMEPAD || [
                                  controlsTypes.x1gamepad,
                                  controlsTypes.ds4gamepad
                                ].contains(lastActiveControlsType.get())
                            )
keepref(isGamepad)

const GAMEPAD_COLUMN = 1
let wasGamepad = mkWatched(persist, "wasGamepad", function() {
  let wasGamepadV = !platform.is_pc || platform.is_steam_deck
  gui_scene.setConfigProps({gamepadCursorControl = wasGamepadV})
  return wasGamepadV
}())

let enabledGamepadControls = Watched(!platform.is_pc || isGamepad.get())

if (platform.is_pc){
  wasGamepad.subscribe(@(v) enabledGamepadControls.set(v))
  let setGamePadActive = @(v) set_actions_binding_column_active(GAMEPAD_COLUMN, v && forcedControlsType.get() != ControlsTypes.KB_MOUSE)
  enabledGamepadControls.subscribe(setGamePadActive)
  forcedControlsType.subscribe(@(_) setGamePadActive(enabledGamepadControls.get()))
  setGamePadActive(isGamepad.get())
}

isGamepad.subscribe(function(v) {
  wasGamepad.modify(@(val) val || v)
  log($"isGamepad changed to = {v}")
  gui_scene.setConfigProps({gamepadCursorControl = v})
})


return freeze({
  controlsTypes
  lastActiveControlsType
  lastActiveControlsTypeRaw
  lastInputUsed
  isGamepad
  isTouch
  wasGamepad
  enabledGamepadControls
  forcedControlsType
  ControlsTypes
  setForcedControlsType
})
