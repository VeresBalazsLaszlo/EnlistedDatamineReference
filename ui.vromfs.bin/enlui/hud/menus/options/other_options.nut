from "%ui/state/client_version.nut" import isMinimalClient
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "settings" import set_setting_by_blk_path, get_setting_by_blk_path
from "%ui/ui_library.nut" import *

const optionId = "minimizeWarnings"

let isMinimizeSystemNotifications = Watched(get_setting_by_blk_path(optionId))

let isMinimizeWarnings = Computed(@() isMinimalClient() && isMinimizeSystemNotifications.get())

let minimizeWarningsOption = optionCtor({
  optId = optionId
  name = loc("options/minimizeWarnings")
  blkPath = optionId
  widgetCtor = optionCheckBox
  defVal = false
  tab = "Game"
  isAvailable = @() true
  restart = false
  var = isMinimizeSystemNotifications
  setValue = function(v) {
    set_setting_by_blk_path(optionId, v)
    isMinimizeSystemNotifications.set(v)
  }
})

return {
  isMinimizeWarnings
  minimizeWarningsOption
}
