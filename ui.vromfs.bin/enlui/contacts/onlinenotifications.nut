import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/contacts/contactsWatchLists.nut" import friendsOnlineUids, myRequestsUids, requestsToMeUids
from "%ui/contacts/contact.nut" import getContact, getContactNick
from "%ui/state/appState.nut" import isInBattleState
from "settings" import save_settings, get_setting_by_blk_path, set_setting_by_blk_path
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/state/incognitoState.nut" import incognitoState
from "%ui/ui_library.nut" import *

const FRIEND_NOTIFICATION = "hasFriendOnlineNotification"
let hasFriendOnlineNotification = Watched(get_setting_by_blk_path(FRIEND_NOTIFICATION) ?? true)
hasFriendOnlineNotification.subscribe(function(v) {
  set_setting_by_blk_path(FRIEND_NOTIFICATION, v)
  save_settings()
})

let friendsOnlineCache = Watched(null)
let isNotificationDisabled = @() !isLoggedIn.get()
  || !hasFriendOnlineNotification.get()
  || isInBattleState.get()
  || incognitoState.get()


function fillFriendsCache(friends) {
  if (friendsOnlineCache.get() == null) {
    let cache = friends.reduce(@(res, f) res.__update({ [f] = true }), {})
    friendsOnlineCache.set(cache)
    return
  }
  let toAdd = []
  let toDelete = []

  foreach(contact in friends) {
    if (contact not in friendsOnlineCache.get())
      toAdd.append(contact)
  }

  foreach(contact, _v in friendsOnlineCache.get())
    if (!friendsOnlineUids.get().contains(contact)
      && contact not in myRequestsUids.get()
      && contact not in requestsToMeUids.get()
    )
      toDelete.append(contact)

  if (toAdd.len() > 0 || toDelete.len() > 0)
    friendsOnlineCache.mutate(function(cache) {
      toDelete.each(@(v) cache.$rawdelete(v))
      toAdd.each(@(v) cache[v] <- true)
    })
  if (isNotificationDisabled())
    return

  toAdd.each(function(contact) {
    if (userInfo.get()?.userId != contact)
      addPopup({
        id = $"{contact}_online_alert"
        text = loc("contact/onlineNotif", { contact = getContactNick(getContact(contact)) })
        needPopup = true
        styleName = "silence"
      })
  })
}


function fillCacheByRequest(players) {
  if (friendsOnlineCache.get() == null)
    friendsOnlineCache.set({})
  friendsOnlineCache.mutate(@(v) players.each(@(_, uid) v[uid] <- true))
}

friendsOnlineUids.subscribe(fillFriendsCache)
foreach (v in [myRequestsUids, requestsToMeUids])
  v.subscribe(fillCacheByRequest)


return hasFriendOnlineNotification
