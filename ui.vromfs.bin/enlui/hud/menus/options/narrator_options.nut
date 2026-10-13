from "%ui/state/narratorState.nut" import narratorNativeLangUpdate
from "settings" import get_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/ui_library.nut" import *

let optionNarratorCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, actionCb) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? false)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionNarratorCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

return [
  mkOption(loc("gameplay/narrator_language"), "narrator_nativeLanguage", narratorNativeLangUpdate)
]