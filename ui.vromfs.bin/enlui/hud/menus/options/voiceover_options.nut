from "settings" import set_setting_by_blk_path
from "%ui/state/voiceoverState.nut" import voiceoverState, voiceoverStateUpdate, isOptionAvailable
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor
from "%ui/ui_library.nut" import *

let optionVoiceoverCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, watch, actionCb) {
  let blkPath = $"gameplay/{field}"
  let setValue = @(v) set_setting_by_blk_path(blkPath, v)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionVoiceoverCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
    restart = true
  })
}

let voiceoverOption = !isOptionAvailable ? null : mkOption(loc("options/voiceover"),
  "voiceoverOriginalEnabled", voiceoverState, voiceoverStateUpdate)

return {
  voiceoverOption
}
