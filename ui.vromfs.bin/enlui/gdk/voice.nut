import "%enlSqGlob/userInfo.nut" as userInfo
from "%enlSqGlob/library_logs.nut" import debugTableData, with_prefix
from "eventbus" import eventbus_subscribe
from "%gdkLib/voice.nut" import subscribe_to_state_update, add_voice_chat_member, remove_voice_chat_member, update_voice_chat_member_friendship, getVoiceChatMembers
from "%ui/gdk/externalIds.nut" import request_xuid_for_user
from "%ui/contacts/contactsWatchLists.nut" import friendsUids
from "%sqstd/string.nut" import hexStringToInt
from "%ui/state/login_state.nut" import isLoggedIn

let voiceApi = require_optional("voiceApi")
let logX = with_prefix("[XBOX_VOICE] ")

let delayedChatMembers = persist("delayedChatMembers", @() {})


function set_mute_status(uid, is_muted) {
  let func = is_muted ? voiceApi.mute_player_by_uid : voiceApi.unmute_player_by_uid 
  func(uid.tointeger())
}


function on_state_update(results) {
  foreach (state in results) {
    set_mute_status(state?.uid, state?.is_muted)
  }
}


function add_user_to_chat(uid) {
  logX($"Adding user to voice chat: {uid}")
  if (userInfo.get().userId == uid) {
    logX("Skip tracking self")
    return
  }

  request_xuid_for_user(uid, function(u, xuid) {
    let ustr = u.tostring()
    let isFriend = (ustr in friendsUids.get())
    add_voice_chat_member(ustr, xuid, isFriend)
  })
}


eventbus_subscribe("voice.on_peer_joined", function(data) {
  if (!data?.uid)
    return

  let uid = hexStringToInt(data.uid) 
  logX($"voice.on_peer_joined: data.uid -> {data.uid}, uid -> {uid}, name -> {data.name}")

  if (isLoggedIn.get()) {
    add_user_to_chat(uid)
  } else {
    logX($"Delaying chat join for <{uid}>")
    delayedChatMembers[uid] <- true
  }

})


eventbus_subscribe("voice.on_peer_left", function(data) {
  if (!data?.uid)
    return

  let uid = hexStringToInt(data.uid) 
  logX($"voice.on_peer_left: data.uid -> {data.uid}, uid -> {uid}, name -> {data.name}")
  remove_voice_chat_member(uid)
})


friendsUids.subscribe(function(v) {
  foreach (uid, _ in getVoiceChatMembers()) {
    let isFriend = (uid.tostring() in v)
    update_voice_chat_member_friendship(uid, isFriend)
  }
})


isLoggedIn.subscribe(function(v) {
  if (v) {
    logX("Adding delayed chat users")
    debugTableData(delayedChatMembers)
    foreach (uid, _ in delayedChatMembers) {
      add_user_to_chat(uid)
    }
    delayedChatMembers.clear()
  }
})


subscribe_to_state_update(on_state_update)
