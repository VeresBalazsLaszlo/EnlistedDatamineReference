from "settings" import set_setting_by_blk_path
from "%ui/state/harmonizationNickState.nut" import harmonizationNickState, harmonizationNickStateUpdate
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "%ui/ui_library.nut" import *

let optionHarmonizationNickCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, watch, actionCb) {
  let blkPath = $"{field}"
  let setValue = @(v) set_setting_by_blk_path(blkPath, v)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionHarmonizationNickCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

let harmonizationNickOption = mkOption(loc("options/harmonizationNick"),
  "harmonizationNickEnabled", harmonizationNickState,
  harmonizationNickStateUpdate)

return {
  harmonizationNickOption
}