from "settings" import get_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/ui_library.nut" import *
from "%ui/state/autoleanState.nut" import autoleanSettingStateUpdate


let optionAutoleanCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, blkPath, actionCb) {
  let { watch, setValue } = getOnlineSaveData(blkPath, @() get_setting_by_blk_path(blkPath) ?? false)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionAutoleanCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

return [
  mkOption(loc("gameplay/autolean_setting"), "gameplay/autolean_setting", autoleanSettingStateUpdate)
]
