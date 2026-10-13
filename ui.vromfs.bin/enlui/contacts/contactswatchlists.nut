from "%enlSqGlob/crossnetwork_state.nut" import canCrossnetworkChatWithAll, canCrossnetworkChatWithFriends
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/contacts/contactPresence.nut" import isContactOnline, onlineStatus
from "%ui/ui_library.nut" import *

const isInternalContactsAllowed = true

let predefinedContactsList = ["approved", "myRequests", "requestsToMe", "rejectedByMe", "myBlacklist", "meInBlacklist"]

let contactsLists = predefinedContactsList
  .reduce(function(res, name) {
    console_print($"registerList {name}")
    res[name] <- nestWatched($"contact_list_{name}", {})
    return res
  },
  {})

let approvedUids = isInternalContactsAllowed ? contactsLists.approved : Watched({})
let psnApprovedUids = Watched({})
let xboxApprovedUids = Watched({})
let steamApprovedUids = Watched({})
let myRequestsUids = contactsLists.myRequests
let requestsToMeUids = contactsLists.requestsToMe
let rejectedByMeUids = contactsLists.rejectedByMe
let myBlacklistUids = contactsLists.myBlacklist
let psnBlockedUids = Watched({})
let xboxBlockedUids = Watched({})
let xboxMutedUids = Watched({})
let meInBlacklistUids = contactsLists.meInBlacklist

let friendsUids = Computed(@() {}.__update(approvedUids.get(), psnApprovedUids.get(), xboxApprovedUids.get(), steamApprovedUids.get()))
let blockedUids = Computed(@() {}.__update(myBlacklistUids.get(), psnBlockedUids.get(), xboxBlockedUids.get()))

let friendsOnlineUids = Computed(@()
  friendsUids.get().filter(@(_, userId) isContactOnline(userId, onlineStatus.get())).keys()
)

let getCrossnetworkChatEnabled = @(userId) userId.tostring() in friendsUids.get()
  ? canCrossnetworkChatWithFriends.get()
  : canCrossnetworkChatWithAll.get()


return {
  contactsLists
  approvedUids
  psnApprovedUids
  xboxApprovedUids
  steamApprovedUids
  myRequestsUids
  requestsToMeUids
  rejectedByMeUids
  myBlacklistUids
  psnBlockedUids
  xboxBlockedUids
  xboxMutedUids
  meInBlacklistUids
  friendsUids
  blockedUids
  friendsOnlineUids
  getCrossnetworkChatEnabled
  isInternalContactsAllowed
}