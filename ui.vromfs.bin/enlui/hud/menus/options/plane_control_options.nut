from "settings" import get_setting_by_blk_path
from "%ui/hud/state/preferred_plane_control_mode.nut" import planeControlModeStateUpdate
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCtor, optionSpinner
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

const MOUSE_AIM = "mouse_aim"
const SIMPLE_JOY = "simple_joy"
const DIRECT = "direct"

const mods = [MOUSE_AIM, SIMPLE_JOY, DIRECT]
let modSettings = {
  [MOUSE_AIM]  = { isMouseAimEnabled = true, isSimpleJoyEnabled = false},
  [SIMPLE_JOY] = { isMouseAimEnabled = false, isSimpleJoyEnabled = true},
  [DIRECT]     = { isMouseAimEnabled = false, isSimpleJoyEnabled = false},
}

const blkPath = "gameplay/planeControlMode"

let onlineDataMode = getOnlineSaveData(blkPath,
  @() get_setting_by_blk_path(blkPath) ?? MOUSE_AIM
)

let planeControlMode = optionCtor({
  name = loc("gameplay/planeControlMode")
  widgetCtor = optionSpinner
  tab = "Game"
  var = onlineDataMode.watch
  setValue = onlineDataMode.setValue
  available = mods
  valToString = @(s) loc($"gameplay/plane_control_mode_{s}")
  blkPath
})

function setPlaneControlMode(mode) {
  if (mode not in modSettings)
    return
  let {isMouseAimEnabled, isSimpleJoyEnabled} = modSettings[mode]
  planeControlModeStateUpdate({isMouseAimEnabled, isSimpleJoyEnabled})
}
subscribeAndInit(setPlaneControlMode, onlineDataMode.watch)

return [planeControlMode]