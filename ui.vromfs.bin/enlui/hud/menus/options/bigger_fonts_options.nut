from "settings" import set_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "%ui/state/biggerFontsState.nut" import biggerFontsState, biggerFontsStateUpdate
from "%dngscripts/platform.nut" import is_ps4
from "%ui/ui_library.nut" import *

let optionBiggerFontsCtor = @(actionCb) function (opt, group, xmbNode) {
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
    widgetCtor = optionBiggerFontsCtor(actionCb)
    var = watch
    setValue = @(v) set_setting_by_blk_path(field, v)
    blkPath = field
    reload = !is_ps4
    restart = is_ps4
  })

let biggerFontsOption = mkOption(loc("options/biggerFonts"),
  "highReadabilityEnabled", biggerFontsState, biggerFontsStateUpdate)

return {
  biggerFontsOption
}
