from "settings" import get_setting_by_blk_path, set_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%dngscripts/platform.nut" import is_console
from "%ui/state/client_version.nut" import isMinimalClient
from "%ui/ui_library.nut" import *




let harmonizationRequired = get_setting_by_blk_path("harmonizationRequired") ?? false

let isDisabled = isMinimalClient() || is_console
let isOptionAvailable = !harmonizationRequired && !isDisabled

if (isDisabled)
  set_setting_by_blk_path("harmonizationEnabled", false)

let harmonizationState = isOptionAvailable
  ? nestWatched("harmonizationState", get_setting_by_blk_path("harmonizationEnabled") ?? false)
  : WatchedRo(false)

let harmonizationStateUpdate = @(v) harmonizationState.set(v)

let isHarmonizationEnabled = Computed(@() harmonizationRequired
  || (!isDisabled && harmonizationState.get()))

return {
  isHarmonizationEnabled
  harmonizationState
  harmonizationStateUpdate
  isOptionAvailable
}
