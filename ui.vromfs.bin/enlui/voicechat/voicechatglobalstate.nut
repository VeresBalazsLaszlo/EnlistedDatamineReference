import "%dngscripts/platform.nut" as platform
from "%dngscripts/globalState.nut" import nestWatched
from "settings" import get_setting_by_blk_path

function is_voice_chat_available() {
  let isAvailableByBlk = get_setting_by_blk_path("voiceChatAvailable") ?? true
  return isAvailableByBlk && (platform.is_pc || platform.is_sony || platform.is_xbox)
}
let voiceChatEnabled = nestWatched("voiceChatEnabled", is_voice_chat_available())
let voiceChatEnabledUpdate = @(v) voiceChatEnabled.set(v)
let voiceChatRestricted = nestWatched("voiceChatRestricted", false)
let voiceChatRestrictedUpdate = @(v) voiceChatRestricted.set(v)
return {
  voiceChatEnabled, voiceChatEnabledUpdate,
  voiceChatRestricted, voiceChatRestrictedUpdate
}
