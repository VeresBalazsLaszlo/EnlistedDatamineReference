from "settings" import set_setting_by_blk_path
from "%ui/state/incognitoState.nut" import incognitoState, incognitoStateUpdate
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "%dngscripts/platform.nut" import is_xbox
from "%ui/ui_library.nut" import *

let isOptionAvailable = !is_xbox

let optionIncognitoCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

let mkOption = @(title, field, watch, actionCb)
  optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionIncognitoCtor(actionCb)
    var = watch
    setValue = @(v) set_setting_by_blk_path(field, v)
    blkPath = field
  })

let incognitoOption = !isOptionAvailable ? null
  : mkOption(loc("options/incognito"), "incognitoEnabled", incognitoState, incognitoStateUpdate)

return {
  incognitoOption
}
