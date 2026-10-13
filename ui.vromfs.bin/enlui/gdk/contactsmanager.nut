from "%ui/gdk/relationships.nut" import friendsXuids, mutedXuids, bannedXuids
from "%ui/contacts/contactsWatchLists.nut" import xboxApprovedUids, xboxBlockedUids, xboxMutedUids, friendsUids
from "%ui/contacts/consoleUidsRemap.nut" import console2uid

let userIds = require("%ui/gdk/userIds.nut")


function get_uids(xuids) {
  local result = {}
  foreach (xuid in xuids) {
    let strxuid = xuid.tostring()
    if (strxuid in console2uid.get()) {
      result[console2uid.get()[strxuid]] <- true
    }
  }
  return result
}


friendsXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxApprovedUids.set(uids)
})


mutedXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxMutedUids.set(uids)
})


bannedXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxBlockedUids.set(uids)
})


friendsUids.subscribe(function(v) {
  userIds.friendsUids.set(v)
})