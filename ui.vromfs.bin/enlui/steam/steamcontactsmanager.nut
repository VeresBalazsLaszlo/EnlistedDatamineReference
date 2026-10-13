from "%ui/contacts/contactsWatchLists.nut" import steamApprovedUids
from "%ui/contacts/externalIdsManager.nut" import searchContactByExternalId
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/contacts/consoleUidsRemap.nut" import updateUids
from "%ui/contacts/contact.nut" import updateContact
from "%ui/ui_library.nut" import *

let { get_friends_ids = @()[] } = require_optional("steam")


function onReceiveFriendsData(result) {
  let st2Uid = {}
  let newFriendsList = {}
  foreach (uid, data in result) {
    if ("error" in data)
      return

    let uidStr = uid.tostring()
    st2Uid[data.id] <- uidStr
    newFriendsList[uidStr] <- true
    updateContact(uidStr, $"{data.nick}@steam")
  }

  updateUids(st2Uid)
  steamApprovedUids.set(newFriendsList)
}

let updateFriendsList = @() searchContactByExternalId(get_friends_ids(), onReceiveFriendsData)

let needRequestContacts = keepref(Computed(@() !isInBattleState.get() && isLoggedIn.get()))
needRequestContacts.subscribe(@(v) v ? updateFriendsList() : null)

console_register_command(updateFriendsList, "steam.updateFriends")