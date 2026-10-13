import "%darg/darg_library.nut" as darg_library
import "%dngscripts/platform.nut" as platform
from "%enlSqGlob/library_logs.nut" import console_print, vlog
from "console" import console_register_command
from "settings" import get_setting_by_blk_path
from "math" import fabs, max
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%dngscripts/globalState.nut" import nestWatched
from "app" import reload_overlay_ui_scripts
from "%sqstd/frp.nut" import Computed
from "daRg" import sw, sh

let debugSafeAreaList = nestWatched("debugSafeAreaList", false)
let debugSafeAreaAmount = nestWatched("debugSafeAreaAmount", null)


let showSafeArea = nestWatched("showSafeArea",  false)


const blkPath = "video/safeArea"
let safeAreaList = (platform.is_xbox) ? [0.9, 0.95, 1.0]
  : platform.is_sony ? [require("sony").getDisplaySafeArea()]
  : debugSafeAreaList.get() ? [0.9, 0.95, 1.0]
  : [1.0]
let canChangeInOptions = @() safeAreaList.len() > 1

function validate(val) {
  if (safeAreaList.contains(val))
    return val
  local res = null
  foreach (v in safeAreaList)
    if (res == null || fabs(res - val) > fabs(v - val))
      res = v
  return res
}
let safeAreaDefault = @() canChangeInOptions() ? validate(get_setting_by_blk_path(blkPath) ?? safeAreaList.top())
  : safeAreaList.top()

let storedAmount = mkOnlineSaveData("safeAreaAmount", safeAreaDefault,
  @(value) canChangeInOptions() ? validate(value) : safeAreaDefault())

let storedAmountWatch = storedAmount.watch

function setAmount(val) {
  storedAmount.setValue(val)
  debugSafeAreaAmount.set(null)
}

let safeAreaAmount = Computed(@() debugSafeAreaAmount.get() ?? storedAmountWatch.get() ?? 1.0)
let safeAreaHorPadding = Computed(@() sw(100*(1-safeAreaAmount.get())/2))
let safeAreaVerPadding = Computed(@() sh(100*(1-safeAreaAmount.get())/2))

console_register_command(@() showSafeArea.modify(@(v) !v), "ui.safeAreaShow")

console_register_command(
  function(val = 0.9) {
    if (val > 1.0 || val < 0.9) {
      vlog(@"SafeArea is supported between 0.9 (lowest visible area) and 1.0 (full visible area).
This range is according console requirements. (Resetting to use in options = '{0}')".subst(storedAmountWatch.get()))
      debugSafeAreaAmount.set(null)
      return
    }
    debugSafeAreaAmount.set(val)
    reload_overlay_ui_scripts()
  }, "ui.safeAreaSet"
)

console_register_command(function() {
  debugSafeAreaList.modify(@(v) !v)
  let actionText = debugSafeAreaList.get() ? "added" : "removed"
  console_print($"SafeArea options {actionText}. Reload UI for changes.")
  reload_overlay_ui_scripts()
}, "ui.showDebugSafeAreaList")


let safeAreaBorders = Computed(function() {
  let verScreenPadding = safeAreaVerPadding.get()
  let horScreenPadding = safeAreaHorPadding.get()
  let fsh = @(i) darg_library.fsh(i)*safeAreaAmount.get()
  let defBorders = [0, fsh(4), fsh(4), fsh(4)]
  return [max(verScreenPadding, defBorders[0]), max(horScreenPadding, defBorders[1]), max(verScreenPadding, defBorders[2]), max(horScreenPadding, defBorders[3])]
})

return {
  safeAreaCanChangeInOptions = canChangeInOptions
  safeAreaBlkPath = blkPath
  safeAreaVerPadding
  safeAreaHorPadding
  safeAreaSetAmount = setAmount
  safeAreaAmount
  showSafeArea
  safeAreaList
  safeAreaBorders,
  safeAreaSize = Computed(@() [sw(100) - safeAreaBorders.get()[1] - safeAreaBorders.get()[3], sh(100) - safeAreaBorders.get()[0] - safeAreaBorders.get()[2]])
}
