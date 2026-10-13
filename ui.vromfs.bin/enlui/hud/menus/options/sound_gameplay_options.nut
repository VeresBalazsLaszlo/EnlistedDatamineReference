from "settings" import get_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/hud/state/sound_options_state.nut" import headshotSoundEnabled, battleMusicEnabled, humanCapzoneCapturingSoundEnabled
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
  let blkPath = $"sound/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? defVal)
  return optionCtor({
    name = title
    tab = "Sound"
    widgetCtor = mkWidgetCtor(actionCb)
    var = watch
    setValue
    defVal
    blkPath
    isAvailable
  })
}

return {
  headshotSoundOption = mkOption(loc("sound/headshot_sound_enabled"), "headshot_sound_enabled",
    true, @(v) headshotSoundEnabled.set(v))
  battleMusicOption = mkOption(loc("sound/battle_music_enabled"), "battle_music_enabled",
    true, @(v) battleMusicEnabled.set(v))
  humanCapzoneCapturingSoundOption = mkOption(loc("sound/human_capzone_capturing_sound_enabled"),
    "human_capzone_capturing_sound_enabled", true, @(v) humanCapzoneCapturingSoundEnabled.set(v))
}