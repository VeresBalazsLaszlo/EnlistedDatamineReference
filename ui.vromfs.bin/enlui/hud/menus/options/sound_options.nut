from "settings" import get_setting_by_blk_path, set_setting_by_blk_path
from "%dngscripts/sound_system.nut" import sound_set_volume
from "%dngscripts/platform.nut" import is_pc, is_xboxone, is_ps4
from "%ui/state/sound_state.nut" import soundOutputDevicesList,
  soundOutputDevice, soundOutputDeviceUpdate,
  soundOcclusionState, soundOcclusionStateUpdate, SND_OCCLUSION_BLK_PATH
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionSpinner, optionCtor, optionPercentTextSliderCtor, optionCheckBox
from "%ui/hud/menus/options/sound_gameplay_options.nut" import headshotSoundOption, battleMusicOption, humanCapzoneCapturingSoundOption
from "%ui/ui_library.nut" import *

function optionVolSliderCtor(opt, group, xmbNode) {
  let optSetValue = opt.setValue 
  function setValue(val) {
    optSetValue(val)
    sound_set_volume(opt.busName, val)
  }

  opt = opt.__merge({min = 0 max = 1 unit = 0.05 mult = 100 pageScroll = 0.05 setValue = setValue })

  return optionPercentTextSliderCtor(opt, group, xmbNode)
}

function soundOption(title, field) {
  let blkPath = $"sound/volume/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? 1.0)
  return optionCtor({
    name = title
    tab = "Sound"
    widgetCtor = optionVolSliderCtor
    var = watch
    setValue
    defVal = 1.0
    blkPath
    busName = field
  })
}
let optVolumeMaster = soundOption(loc("options/volume_master"), "MASTER")
let optVolumeAmbient = soundOption(loc("options/volume_ambient"), "ambient")
let optVolumeSfx = soundOption(loc("options/volume_sfx"), "effects")
let optVolumeInterface = soundOption(loc("options/volume_interface"), "interface")
let optVolumeMusic = soundOption(loc("options/volume_music"), "music")
let optVolumeDialogs = soundOption(loc("options/volume_dialogs"), "voices")
let optVolumeGuns = soundOption(loc("options/volume_guns"), "weapon")

let optOutputDevice = optionCtor({
  name = loc("options/sound_device_out")
  tab = "Sound"
  widgetCtor = optionSpinner
  blkPath = "sound/output_device"
  isAvailableWatched = Computed(@() is_pc && soundOutputDevicesList.get().len() > 0)
  changeVarOnListUpdate = false
  var = soundOutputDevice
  setValue = soundOutputDeviceUpdate
  available = soundOutputDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
})

let isOptOcclusionDisabled = is_xboxone || is_ps4

let optOcclusion = isOptOcclusionDisabled ? null : optionCtor({
  name = loc("options/occlusion")
  tab = "Sound"
  hint = loc("options/occlusion/desc")
  widgetCtor = optionCheckBox
  blkPath = SND_OCCLUSION_BLK_PATH
  defVal = false
  restart = true
  var = soundOcclusionState
  setValue = function(v) {
    set_setting_by_blk_path(SND_OCCLUSION_BLK_PATH, v)
    soundOcclusionStateUpdate(v)
  }
})

return {
  soundOptions = [
    optOutputDevice,
    optVolumeMaster, optVolumeAmbient, optVolumeSfx,
    optVolumeInterface, optVolumeMusic, optVolumeDialogs, optVolumeGuns,
    headshotSoundOption, battleMusicOption, humanCapzoneCapturingSoundOption,
    optOcclusion
  ]
}
