import "%dngscripts/platform.nut" as platform
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/charClient/charClient.nut" as charClient
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkChat, canCrossnetworkChatWithAll,
  canCrossnetworkChatWithFriends
from "%ui/contacts/contactsWatchLists.nut" import getCrossnetworkChatEnabled
from "%ui/mainScene/invitationsLogState.nut" import pushNotification, removeNotify, subscribeGroup,
  removeNotifyById, InvitationsStyle, InvitationsTypes
from "%ui/contacts/contact.nut" import getContact, updateContact, validateNickNames,
  getContactNick
from "%ui/matchingClient.nut" import matchingCall
from "matching.api" import matching_listen_notify
from "eventbus" import eventbus_subscribe
from "%ui/meta/postbox.nut" import postboxSubscribe, postboxMarkRead
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/contacts/contactPresence.nut" import presences, updatePresences
from "%ui/helpers/platformUtils.nut" import canInterractCrossPlatform
from "%ui/getAppIdsList.nut" import getAppIdsList
from "%ui/restrictionWarnings.nut" import showCrossnetworkChatRestrictionMsgBox
from "matching.errors" import INVALID_USER_ID
from "%ui/state/appState.nut" import isInBattleState
from "%ui/squad/squadState.nut" import isInSquad
from "%ui/ui_library.nut" import *
from "types" import Table
from "%ui/contacts/contactsWatchLists.nut" import contactsLists


let isContactsVisible = mkWatched(persist, "isContactsVisible", false)


let logC = with_prefix("[CONTACTS STATE] ")

const isOnlineContactsSearchEnabled = true 
const isContactsEnabled = true 
const isContactsManagementEnabled = true 

const GAME_GROUP_NAME = "Enlisted"
const ADD_MODE = "add"
const DEL_MODE = "del"
const APPROVED_MAIL = "approved_mail"
const REQUESTS_TO_ME_MAIL = "requests_to_me_mail"
let getContactsInviteId = @(uid) $"contacts_invite_{uid}"

let searchContactsResults = Watched({})


local fetchContacts = null

function execContactsCharAction(userId, charAction) {
  if (userId == INVALID_USER_ID) {
    logC($"trying to do {charAction} with invalid contact")
    return
  }
  charClient[charAction](userId.tointeger(), GAME_GROUP_NAME, {
    success = function() {
      fetchContacts()
    }

    failure = function (err) {
      showMsgbox(loc(err))
    }
  })
}

subscribeGroup(APPROVED_MAIL, {
  onShow = function(notify) {
    removeNotify(notify)
    postboxMarkRead(notify.mailId)
  }
  onRemove = @(notify) postboxMarkRead(notify.mailId)
})

subscribeGroup(REQUESTS_TO_ME_MAIL, {
  onShow = function(notify) {
    removeNotify(notify)
    postboxMarkRead(notify.mailId)
    let contact = getContact(notify.fromUid)
    let user = getContactNick(contact)
    if (!canInterractCrossPlatform(user, getCrossnetworkChatEnabled(contact.uid))) {
      showCrossnetworkChatRestrictionMsgBox()
      return
    }

    showMsgbox({
      text = loc("contact/mbox_add_to_friends", { user })
      buttons = [
        { text = loc("Yes")
          action = @() execContactsCharAction(notify.fromUid, "contacts_approve_request")
          isCurrent = true
        }
        { text = loc("No")
          action = @() execContactsCharAction(notify.fromUid, "contacts_reject_request")
          isCancel = true
        }
      ]
    })
  }
  onRemove = @(notify) postboxMarkRead(notify.mailId)
})

let buildFullListName = @(name) $"#{GAME_GROUP_NAME}#{name}"

function onNotifyListChanged(body, mailId) {
  let changed = body?.changed
  if (!(changed instanceof Table)) {
    postboxMarkRead(mailId)
    return
  }

  let perUidList = {}
  function handleList(changedListObj, mode, listName) {
    if (mode not in changedListObj)
      return
    foreach (uid in changedListObj[mode]) {
      if (!(uid in perUidList))
        perUidList[uid] <- {}
      perUidList[uid][mode] <- { listName }
    }
  }

  foreach (name, _ in contactsLists) {
    let changedListObj = changed?[buildFullListName(name)]
    if (changedListObj == null)
      continue
    console_print(changedListObj)
    handleList(changedListObj, ADD_MODE, name)
    handleList(changedListObj, DEL_MODE, name)
  }

  local hasNotification = false
  foreach (uidInt, data in perUidList) {
    let uid = uidInt.tostring()
    if (data?[ADD_MODE].listName == "requestsToMe") {
      hasNotification = true
      validateNickNames(uidInt,
        function() {
          let nick = getContactNick(getContact(uid))
          if (canInterractCrossPlatform(nick, canCrossnetworkChatWithAll.get()))
            pushNotification({
              id = getContactsInviteId(uid)
              mailId
              fromUid = uid
              playerName = nick
              nType = InvitationsTypes.TO_FRIEND
              styleId = InvitationsStyle.PRIMARY
              text = loc("contact/incomingInvitation", { user = nick })
              actionsGroup = REQUESTS_TO_ME_MAIL
            })
        })
    }
    else if (data?[DEL_MODE].listName == "requestsToMe")
      removeNotifyById(getContactsInviteId(uid))
    else if (data?[DEL_MODE].listName == "approved") {
      hasNotification = true
      validateNickNames(uidInt,
        function() {
          let nick = getContactNick(getContact(uid))
          pushNotification({
            mailId
            text = loc("contact/removedYouFromFriends", { user = nick })
            isRead = true
            nType = InvitationsTypes.FRIEND_REMOVE
            playerName = nick
            actionsGroup = APPROVED_MAIL
          })
        }
      )
    }
  }
  if (!hasNotification)
    postboxMarkRead(mailId)
}

function updatePresencesByList(new_presences) {
  logC("Update presences by list: new presences:", new_presences)
  let curPresences = presences.get()
  let updPresences = {}
  foreach (p in new_presences)
    updPresences[p.userId] <- p?.update ? (curPresences?[p.userId] ?? {}).__merge(p.presences)
      : p.presences

  logC("Update presences by list: set finale states:", updPresences)
  updatePresences(updPresences)
}

function updateGroup(new_contacts, uids, name) {
  let members = new_contacts?[name] ?? []
  local hasChanges = false
  let newUids = {}
  let cnChatWatchVal = name == "approved"
    ? canCrossnetworkChatWithFriends.get()
    : canCrossnetworkChatWithAll.get()

  foreach (member in members) {
    local { uid, nick } = member
    if (!canInterractCrossPlatform(nick, cnChatWatchVal))
      continue

    let userId = uid.tostring()
    hasChanges = hasChanges || userId not in uids.get()
    updateContact(userId, nick) 
    newUids[userId] <- true
  }

  if (hasChanges || uids.get().len() != newUids.len())
    uids.set(newUids)
}

function updateAllLists(new_contacts) {
  foreach (name, uids in contactsLists)
    updateGroup(new_contacts, uids, name)
}

function onUpdateContactsCb(result) {
  if ("presences" in result)
    updatePresencesByList(result.presences)
}

fetchContacts = function(postFetchCb = null) {
  let request = {
    groups = [GAME_GROUP_NAME]
    status = contactsLists.keys()
  }
  logC(request)
  charClient?.char_request(
    "GetContacts",
    request,
    function(result) {
      if (result?.error != null) {
        logC($"GetContacts failed. Details: {result?.errorDetails}")
        return
      }
      if (result?[GAME_GROUP_NAME] == null) {
        logC($"GetContacts returned no result.")
        debugTableData(result)
        return
      }
      updateAllLists(result[GAME_GROUP_NAME])
      if (postFetchCb != null)
        postFetchCb()
    })
}

function searchContactsOnline(nick, callback = null) {
  let request = {
    nick = nick
    maxCount = 100
    ignoreCase = true
    specificAppId = ";".join(getAppIdsList())
  }
  logC(request)
  charClient?.char_request(
    "cln_find_users_by_nick_prefix_json",
    request,
    function (result) {
      if (!(result?.result?.success ?? true)) {
        searchContactsResults.set({})
        if (callback)
          callback()
        return
      }

      let myUserId = userInfo.get()?.userIdStr ?? ""
      let resContacts = {}
      foreach (uidStr, name in result)
        if ((typeof name == "string")
            && uidStr != myUserId
            && uidStr != "") {
          local a
          try {
            a = uidStr.tointeger()
          } catch(e){
            print($"uid is not an integer, uid: {uidStr}")
          }
          if (a == null)
            continue
          updateContact(uidStr, name) 
          resContacts[uidStr] <- true
        }

      searchContactsResults.set(resContacts)
      if (callback)
        callback()
    }
  )
}

matching_listen_notify("mpresence.notify_presence_update")
eventbus_subscribe("mpresence.notify_presence_update", onUpdateContactsCb)

postboxSubscribe("notify_contacts_update", function(mail_obj) {
  function handleMail() {
    console_print(mail_obj.mail.body)
    onNotifyListChanged(mail_obj.mail.body, mail_obj.mail_id)
  }
  fetchContacts(handleMail)
})

if (platform.is_sony)
  eventbus_subscribe("playerProfileDialogClosed", @(res) res?.result.wasCanceled ? null : fetchContacts())

crossnetworkChat.subscribe(@(_) fetchContacts())

isInBattleState.subscribe(function(inBattle) {
  if (inBattle)
    matchingCall("mpresence.set_presence", null, { inBattle })
  else
    matchingCall("mpresence.set_presence", null, { inBattle, scene = "", sTime = 0 })
})

isInSquad.subscribe(@(inSquad)
  matchingCall("mpresence.set_presence", null, { inSquad })
)


function updateWhenReady(uInfo) {
  let { userIdStr = null } = uInfo
  if (userIdStr == null)
    return
  updateContact(userIdStr, uInfo.name)
  fetchContacts()
}


userInfo.subscribe(@(uInfo) updateWhenReady(uInfo ?? {}))

updateWhenReady(userInfo.get() ?? {})


if (isContactsEnabled) {
  let { get_time_msec } = require("dagor.time")
  let { chooseRandom } = require("%sqstd/rand.nut")

  let fakeList = Watched([])
  fakeList.subscribe(function(f) {
    updatePresencesByList(f)
    updateAllLists({ ["approved"] = f })
  })
  function genFake(count) {
    let fake = array(count)
      .map(@(_, i) {
        nick = $"stranger{i}",
        userId = (2000000000 + i).tostring(),
        presences = { online = (i % 2) == 0 }
      })
    let startTime = get_time_msec()
    fakeList.set(fake)
    logC($"Friends update time: {get_time_msec() - startTime}")
  }
  console_register_command(genFake, "contacts.generate_fake")

  function changeFakePresence(count) {
    if (fakeList.get().len() == 0) {
      logC("No fake contacts yet. Generate them first")
      return
    }
    let startTime = get_time_msec()
    for(local i = 0; i < count; i++) {
      let f = chooseRandom(fakeList.get())
      f.presences.online = !f.presences.online
      updatePresences({ [f.userId] = f.presences })
    }
    logC($"{count} friends presence update by separate events time: {get_time_msec() - startTime}")
  }
  console_register_command(changeFakePresence, "contacts.change_fake_presence")
}

return {
  searchContactsResults
  isOnlineContactsSearchEnabled
  isContactsEnabled
  isContactsManagementEnabled

  searchContacts = @(nick, callback = null)
    isOnlineContactsSearchEnabled ? searchContactsOnline(nick, callback) : null

  execContactsCharAction
  isContactsVisible
  getContactsInviteId
}
