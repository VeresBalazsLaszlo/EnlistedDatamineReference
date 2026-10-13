import "%sonyLib/webApi.nut" as pswa
import "voiceApi" as voiceApi
import "%ui/sony/auth_friends.nut" as auth_friends
import "%ui/sony/profile.nut" as profile
from "settings" import get_setting_by_blk_path
from "%ui/sony/psn_state.nut" import psn_friendsUpdate, psn_blocked_users, psn_blocked_usersUpdate
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/contacts/contactPresence.nut" import updatePresences, presences
from "%ui/contacts/contact.nut" import updateContact, hasContact
from "eventbus" import eventbus_send
from "%ui/contacts/externalIdsManager.nut" import searchContactByExternalId
from "%ui/contacts/contactsWatchLists.nut" import psnApprovedUids, psnBlockedUids
from "%ui/contacts/consoleUidsRemap.nut" import console2uid, updateUids
from "%ui/state/appState.nut" import isInBattleState
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *


let logpsn = with_prefix("[PSN CONTACTS] ")

let gameAppId = get_setting_by_blk_path("authGameId") ?? "cr"

function psnConstructFriendsList(psn_friends, contacts) {
  let result = []
  let updPresences = {}
  let afriends = contacts?.friends ?? {}
  let uidsList = {}
  let psn2uid = {}

  foreach (f in psn_friends) {
    let friend = f
    if (friend.accountId in afriends) {
      let currentUidRaw = afriends[friend.accountId]
      if (currentUidRaw == null) {
        logpsn($"Friends mapping error: {friend.accountId} -> {currentUidRaw}")
        continue
      }
      let currentUid = currentUidRaw.tostring()

      updateContact(currentUid, $"{friend.nick}@psn")
      result.append(currentUid)
      updPresences[currentUid] <- { online = friend.online }
      psn2uid[friend.accountId] <- currentUid
      uidsList[currentUid] <- true
    }
  }

  updateUids(psn2uid)
  updatePresences(updPresences)
  psn_friendsUpdate(result)
  psnApprovedUids.set(uidsList)

  eventbus_send("PSNAuthContactsReceived", null)
}

function psnConstructBlocksList(profile_blocked, psn_contacts, callback) {
  logpsn("psnConstructBlocksList: ", psn_contacts)
  let authBlocked = psn_contacts?.blocklist ?? {}
  let authFriends = psn_contacts?.friends ?? {}
  let users2 = []
  foreach (user in profile_blocked) {
    let accountId = user.accountId
    let userId = authBlocked?[accountId] ?? authFriends?[accountId]
    if (userId != null) {
      user.userId <- userId
      users2.append(user)
    }
  }
  callback(users2)
}

function onGetPsnFriends(pfriends) {
  logpsn($"onGetPsnFriends: AUTH_GAME_ID: {gameAppId}")
  auth_friends.request_auth_contacts(gameAppId, false, @(contacts) psnConstructFriendsList(pfriends, contacts))
}

function onGetBlockedUsers(users) {
  let unblockedList = psn_blocked_users.get().filter(@(u) users.findvalue(@(u2) u.userId == u2.userId) == null)
  let blockedList = users.filter(@(u) psn_blocked_users.get().findvalue(@(u2) u.userId == u2.userId) == null)

  foreach (u in unblockedList)
    voiceApi.unmute_player_by_uid(u.userId.tointeger())

  foreach (u in blockedList)
    voiceApi.mute_player_by_uid(u.userId.tointeger())

  psn_blocked_usersUpdate(users)

  let unknownPsnUids = []
  let knownUids = []
  let updPresences = {}
  let psn2uid = {}

  foreach (user in users) {
    let { userId, accountId } = user
    if (!hasContact(userId.tostring()))
      unknownPsnUids.append(accountId)
    else
      knownUids.append(userId)

    updPresences[userId] <- { online = false }
    psn2uid[accountId] <- userId
  }

  updateUids(psn2uid)
  updatePresences(updPresences)

  searchContactByExternalId(unknownPsnUids, function(res) {
    let { result = null } = res
    if (result?.error != null) {
      logpsn($"Request for external ids returned error: {result?.error}, unknownPsnUids:",
        unknownPsnUids)
      return
    }

    
    if (unknownPsnUids.len() != res.len())
      logpsn("Requested external ids info not full", unknownPsnUids, res)

    let bl = {}
    foreach (uid in knownUids)
      bl[uid] <- true

    foreach (uidStr, _ in res)
      bl[uidStr] <- true

    psnBlockedUids.set(bl)
  })
}

function onPresenceUpdate(data) {
  let accountId = data?.accountId
  if (accountId) {
    let userId = console2uid.get()?[accountId.tostring()]
    if (userId != null && userId in presences.get())
      updatePresences({ [userId] = { online = !(presences.get()[userId]?.online ?? false) }})
  }
}

function onFriendsUpdate(_) {
  profile.request_psn_friends(onGetPsnFriends)
}

function request_blocked_users(callback) {
  logpsn($"request_blocked_users: AUTH_GAME_ID: {gameAppId}")
  profile.request_blocked_users(function(users) {
    auth_friends.request_auth_contacts(gameAppId, false, @(contacts) psnConstructBlocksList(users, contacts, callback))
  })
}

function onBlocklistUpdate(_) {
  request_blocked_users(onGetBlockedUsers)
}

function request_psn_contacts() {
  logpsn($"request_psn_contacts: AUTH_GAME_ID: {gameAppId}")
  auth_friends.request_auth_contacts(gameAppId, false, function(contacts) {
    profile.request_blocked_users(@(profile_blocked) psnConstructBlocksList(profile_blocked, contacts, onGetBlockedUsers))
    profile.request_psn_friends(@(psn_friends) psnConstructFriendsList(psn_friends, contacts))
  })
}

function eventSubscribeOutOfBattle(v) {
  if (v) {
    pswa.subscribeToPresenceUpdates(onPresenceUpdate)
    request_psn_contacts()
  }
  else {
    pswa.unsubscribeFromPresenceUpdates(onPresenceUpdate)
  }
}
let needRequestContacts = keepref(Computed(@() !isInBattleState.get() && isLoggedIn.get()))
subscribeAndInit(eventSubscribeOutOfBattle, needRequestContacts)

function initHandlers() {
  pswa.subscribeToPresenceUpdates(onPresenceUpdate)
  pswa.subscribe.friendslist(onFriendsUpdate)
  pswa.subscribe.blocklist(onBlocklistUpdate)
  request_psn_contacts()
}

function disposeHandlers() {
  pswa.unsubscribeFromPresenceUpdates(onPresenceUpdate)
  pswa.unsubscribe.friendslist(onFriendsUpdate)
  pswa.unsubscribe.blocklist(onBlocklistUpdate)
}

if (isLoggedIn.get())
  initHandlers()

isLoggedIn.subscribe(@(v) v
  ? initHandlers()
  : disposeHandlers())
