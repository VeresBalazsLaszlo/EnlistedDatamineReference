import "%dngscripts/platform.nut" as platform
from "%ui/voiceChat/voice_settings.nut" import voice_modes, voice_activation_modes, voiceRecordingEnable, voiceRecordingEnabledGeneration, voiceRecordVolume, voiceActivationMode, voicePlaybackVolume
  , voiceChatMode, setRecordingEnabled
from "eventbus" import eventbus_subscribe, eventbus_send
from "%ui/voiceChat/voiceChatGlobalState.nut" import voiceChatRestricted
from "%ui/voiceChat/voiceState.nut" import on_room_disconnect
from "%ui/state/sound_state.nut" import soundRecordDevice
from "%ui/state/appState.nut" import levelIsLoading, levelLoaded
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let voiceApi = require_optional("voiceApi")

if (voiceApi == null)
  return null

let tempDisableVoice = platform.is_sony ? Computed(@() levelIsLoading.get() || !levelLoaded.get()) : Watched(false)

function onVoiceChat(new_value) {
  if (voiceChatRestricted.get()) {
    new_value = voice_modes.off
    log("Voice chat restriction is in effect")
  }

  log($"Voice chat mode changed to '{new_value}'")
  if (new_value == voice_modes.off) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(false)
    eventbus_send("voice.reset_speaking", null)
  } else if (new_value == voice_modes.micOff) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(true)
  } else if (new_value == voice_modes.on) {
    voiceApi.enable_mic(true)
    voiceApi.enable_voice(true)
  } else {
    log("Wrong value set for voiceChatMode: ", new_value)
  }
}

voiceChatRestricted.subscribe(@(_val) onVoiceChat(voiceChatMode.get()))

tempDisableVoice.subscribe(function(val) {
  if (val) {
    onVoiceChat(voice_modes.off)
  }
  else {
    onVoiceChat(voiceChatMode.get())
  }
})

let voiceSettingsDescr = {
  [voiceRecordVolume] = @(val) voiceApi.set_record_volume(val),
  [voicePlaybackVolume] = @(val) voiceApi.set_playback_volume(val),
  [voiceRecordingEnable] = @(val) voiceApi.set_recording(val),
  [voiceChatMode] = onVoiceChat
}

foreach (watched, handler in voiceSettingsDescr)
  handler(watched.get())
foreach (watched, handler in voiceSettingsDescr)
  watched.subscribe(handler)

function recordDeviceHandler(dev){
  voiceApi.set_record_device(dev?.id ?? -1)
  setRecordingEnabled(voiceRecordingEnable.get())
}
subscribeAndInit(recordDeviceHandler, soundRecordDevice)


voiceRecordingEnabledGeneration.subscribe(@(...) voiceApi.set_recording(voiceRecordingEnable.get()) )


eventbus_subscribe("voice.on_peer_stop_speaking", @(data) eventbus_send("voice.hide_speaking", data.name))
eventbus_subscribe("voice.on_peer_start_speaking",
  function(data) {
    if (voiceChatMode.get() != voice_modes.off && !tempDisableVoice.get() &&
      !voiceChatRestricted.get()) {
      eventbus_send("voice.show_speaking", data.name)
    }
  })

eventbus_subscribe("voice.on_peer_left", @(data) eventbus_send("voice.hide_speaking", data.name))
eventbus_subscribe("voice.on_room_disconnect",
  function(data) {
    on_room_disconnect(data.uri)
    eventbus_send("voice.reset_speaking", null)
  })
eventbus_subscribe("voice.on_room_connect",
  function(data) {
    if (!data.success)
      return
    onVoiceChat(voiceChatMode.get())
    if (voiceActivationMode.get() == voice_activation_modes.always)
      setRecordingEnabled(true)
    else
      setRecordingEnabled(voiceRecordingEnable.get())
  })

voiceActivationMode.subscribe(function(value) {
  if (value == voice_activation_modes.always)
    setRecordingEnabled(true)
})

function voice_start_test() {
  voiceApi.join_echo_room()
  setRecordingEnabled(true)
}

function voice_stop_test() {
  voiceApi.leave_echo_room()
  setRecordingEnabled(false)
}

function mute_player(player_name) {
  voiceApi.mute_player_by_name(player_name)
}

function unmute_player(player_name) {
  voiceApi.unmute_player_by_name(player_name)
}

console_register_command(voice_start_test, "voice.start_test")
console_register_command(voice_stop_test, "voice.stop_test")
console_register_command(mute_player, "voice.mute_player")
console_register_command(unmute_player, "voice.unmute_player")
