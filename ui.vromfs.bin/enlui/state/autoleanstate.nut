from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let autoleanSettingState = mkWatched(persist, "autoleanSetting",
  get_setting_by_blk_path("gameplay/autolean_setting") ?? false)

let autoleanSettingStateUpdate = @(enable) autoleanSettingState.set(enable)

return {
  autoleanSettingState
  autoleanSettingStateUpdate
}
