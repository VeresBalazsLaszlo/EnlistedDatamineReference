import "%dngscripts/platform.nut" as platform
from "%ui/voiceChat/voice_settings.nut" import voice_activation_modes, voice_modes, voicePlaybackVolume, voicePlaybackVolumeUpdate, voiceRecordVolume, voiceRecordVolumeUpdate, voiceChatMode
  , voiceChatModeUpdate, voiceActivationMode, voiceActivationModeUpdate
from "%ui/hud/menus/options/options_lib.nut" import optionSpinner, optionCtor, optionPercentTextSliderCtor, mkDisableableCtor
from "%ui/state/sound_state.nut" import soundRecordDevicesList, soundRecordDevice, soundRecordDeviceUpdate
from "%ui/voiceChat/voiceChatGlobalState.nut" import voiceChatEnabled, voiceChatRestricted
from "%ui/ui_library.nut" import *

let optPlaybackVolume = optionCtor({
  name = loc("voicechat/playback_volume")
  tab = "VoiceChat"
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "voice/playback_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05 mult = 100
  var = voicePlaybackVolume
  originalVal = voicePlaybackVolume.get()
  setValue = voicePlaybackVolumeUpdate
  restart = false
  isAvailable = @() voiceChatEnabled.get()
})

let optMicVolume = optionCtor({
  name = loc("voicechat/mic_volume")
  tab = "VoiceChat"
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "voice/record_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05 mult = 100
  var = voiceRecordVolume
  originalVal = voiceRecordVolume.get()
  setValue = voiceRecordVolumeUpdate
  restart = false
  isAvailable = @() voiceChatEnabled.get()
})

let optMode = optionCtor({
  name = loc("voicechat/mode")
  tab = "VoiceChat"
  widgetCtor = mkDisableableCtor(
    Computed(@() voiceChatRestricted.get() ? loc("voicechat/parental") : null),
    optionSpinner)
  blkPath = "voice/mode"
  defVal = voiceChatMode.get()
  var = voiceChatMode
  setValue = voiceChatModeUpdate
  originalVal = voiceChatMode.get()
  restart = false
  available = voice_modes.keys()
  valToString = @(v) loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.get()
})

let optActivationMode = optionCtor({
  name = loc("voicechat/activation_mode")
  tab = "VoiceChat"
  widgetCtor = optionSpinner
  blkPath = "voice/activation_mode"
  defVal = voiceActivationMode.get()
  var = voiceActivationMode
  setValue = voiceActivationModeUpdate
  originalVal = voiceActivationMode.get()
  restart = false
  available = voice_activation_modes.keys()
  valToString = @(v) loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.get() && platform.is_pc
})

let optRecordDevice = optionCtor({
  name = loc("voicechat/record_device")
  tab = "VoiceChat"
  widgetCtor = optionSpinner
  blkPath = "sound/record_device"
  isAvailableWatched = Computed(@() platform.is_pc && voiceChatEnabled.get() &&
                    soundRecordDevicesList.get().len() > 0)
  var = soundRecordDevice
  setValue = soundRecordDeviceUpdate
  available = soundRecordDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
  changeVarOnListUpdate = false
})

return {
  voiceChatOptions = [
    optPlaybackVolume, optRecordDevice, optActivationMode, optMode, optMicVolume
  ]
}
