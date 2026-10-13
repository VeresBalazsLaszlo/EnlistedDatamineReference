from "%ui/voiceChat/voice_settings.nut" import voice_modes, voice_activation_modes, voiceRecordVolume, voiceRecordVolumeUpdate, voiceChatMode, voiceChatModeUpdate, voicePlaybackVolume
  , voicePlaybackVolumeUpdate, voiceActivationMode, voiceActivationModeUpdate
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/voiceChat/voiceChatGlobalState.nut" import voiceChatEnabled
from "%ui/matchingClient.nut" import matchingCall
from "%ui/ui_library.nut" import *

let localSettings = require("%ui/options/localSettings.nut")("voice/", false)
let voiceApi = require_optional("voiceApi")

let initialized = nestWatched("initialized", false)
let joinedVoiceRooms = nestWatched("joinedVoiceRooms", {})

let validation_tbl = {
  voiceChatMode = @(v) voice_modes?[v] ?? voiceChatMode.get()
  voiceActivationMode = @(v) voice_activation_modes?[v] ?? voiceActivationMode.get()
}

let validate_setting = @(key, val) validation_tbl?[key](val) ?? val

function loadVoiceSettings() {
  log("loadVoiceSettings")
  let noop = { 
    voiceRecordVolume = [localSettings(voiceRecordVolume.get(), "record_volume"), voiceRecordVolumeUpdate]
    voicePlaybackVolume = [localSettings(voicePlaybackVolume.get(), "playback_volume"), voicePlaybackVolumeUpdate]
    voiceChatMode = [voiceChatEnabled.get() ? localSettings(voiceChatMode.get(), "mode") : Watched(voice_modes.off), voiceChatModeUpdate]
    voiceActivationMode = [localSettings(voiceActivationMode.get(), "activation_mode"), voiceActivationModeUpdate]
  }.each(function(v, key) {
    let [watched, update] = v
    update(validate_setting(key, watched.get()))
  })
}


if (!initialized.get() && voiceApi != null) {
  loadVoiceSettings()
  initialized.set(true)
}

function leave_voice_chat(voice_chat_id, cb = null) {
  if (voiceApi && voiceChatEnabled.get() && voice_chat_id in joinedVoiceRooms.get()) {
    matchingCall("mproxy.voice_leave_channel", function(_) { cb?() }, { channel = voice_chat_id })
    voiceApi.leave_room(joinedVoiceRooms.get()?[voice_chat_id] ?? "")
    joinedVoiceRooms.mutate(@(v) v.rawdelete(voice_chat_id))
  }
}

function join_voice_chat(voice_chat_id) {
  log($"joining voice {voice_chat_id}")
  if (voiceApi && voiceChatEnabled.get() && !(voice_chat_id in joinedVoiceRooms.get())) {
    matchingCall("mproxy.voice_join_channel",
                      function(response) {
                        debugTableData(response)
                        if (response.error == 0) {
                          if (!(voice_chat_id in joinedVoiceRooms.get()))
                            return
                          let voiceToken = response?.token
                          let voiceChan = response?.channel
                          let voiceName = response?.name
                          if (voiceToken != null && voiceChan != null && voiceName != null) {
                            log($"join into voice chat as {voiceName} channel: {voiceChan} token: {voiceToken}")
                            voiceApi.join_room(voiceName, voiceToken, voiceChan)
                            joinedVoiceRooms.mutate(@(v) v[voice_chat_id] <- voiceChan)
                            return
                          }
                        }
                        log($"failed to join voice channel {voice_chat_id}")
                      },
                      { channel = voice_chat_id })
    joinedVoiceRooms.mutate(@(v) v[voice_chat_id] <- "")
  }
}


function on_room_disconnect(voice_chat_id) {
  if (voice_chat_id in joinedVoiceRooms.get()) {
    log($"reconnect to voice room {voice_chat_id}")
    joinedVoiceRooms.mutate(@(v) v.rawdelete(voice_chat_id))
    join_voice_chat(voice_chat_id)
  }
}

return {
  leave_voice_chat
  join_voice_chat
  on_room_disconnect
}
