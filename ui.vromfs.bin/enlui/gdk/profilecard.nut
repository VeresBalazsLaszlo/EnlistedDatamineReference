from "%gdkLib/impl/user.nut" import show_profile_card
from "%ui/gdk/externalIds.nut" import request_xuid_for_user
from "%ui/gdk/userIds.nut" import uid2xbox
from "eventbus" import eventbus_subscribe

const eventNameUid = "showXboxUserInfo"
const eventNameXuid = "showXboxUserInfoXuid"


function show_user_info_xuid(live_xuid) {
  if (live_xuid)
    show_profile_card(live_xuid.tointeger(), null)
}


function show_user_info_uid(userId) {
  let uid = userId.tostring()
  if (uid in uid2xbox.get()) {
    show_user_info_xuid(uid2xbox.get()[uid])
  } else {
    request_xuid_for_user(uid, function(_, xuid) {
      show_user_info_xuid(xuid)
    })
  }
}


eventbus_subscribe(eventNameUid, @(msg) show_user_info_uid(msg.userId.tointeger()))
eventbus_subscribe(eventNameXuid, @(msg) show_user_info_xuid(msg.xuid.tointeger()))
