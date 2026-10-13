from "settings" import set_setting_by_blk_path
from "%ui/state/dirty_words_filter_state.nut" import dirtyWordsFilterState, dirtyWordsFilterStateUpdate
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "%dngscripts/platform.nut" import is_console
from "%ui/ui_library.nut" import *

let ctor = @(actionCb) function (opt, group, xmbNode) {
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
    widgetCtor = ctor(actionCb)
    var = watch
    setValue = @(v) set_setting_by_blk_path(field, v)
    blkPath = field
    hint = loc("options/dirty_words_hint")
  })

let dirtyWordsOption = is_console ? null
  : mkOption(loc("options/dirty_words"), "dirtyWordsFilterEnabled",
      dirtyWordsFilterState, dirtyWordsFilterStateUpdate)

return {
  dirtyWordsOption
}
