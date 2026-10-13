from "settings" import get_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/hud/state/vehicleCameraFollowState.nut" import vehicleCameraFollow
from "%ui/ui_library.nut" import *

let mkWidgetCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, defVal, actionCb, isAvailable = @() true) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? defVal)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = mkWidgetCtor(actionCb)
    var = watch
    setValue
    defVal
    blkPath
    isAvailable
  })
}

return {
  vehicleCameraFollowOption = mkOption(
    loc("gameplay/vehicle_camera_follow"), "vehicle_camera_follow", true,
    function(enabled) {
      vehicleCameraFollow.set(enabled)
      vehicleCameraFollow.trigger()
    }
  )
}