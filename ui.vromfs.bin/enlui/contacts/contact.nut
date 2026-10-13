from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/netUtils.nut" import request_nick_by_uid_batch
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

const invalidNickName = "????????"
let contacts = nestWatched("contacts", {})
let contactsGen = Watched(0)


contacts.subscribe(@(_) contactsGen.modify(@(v) v + 1))

let mkContact = @(uidStr, realnick)
  { userId = uidStr, uid = uidStr.tointeger(), realnick }

function updateContact(uidStr, name) {
  local contact = contacts.get()?[uidStr]
  if (contact == null) {
    contact = mkContact(uidStr, name)
    contacts.mutate(@(v) v[uidStr] <- contact)
    return contact
  }

  if (name != contact.realnick)
    contacts.mutate(@(v) v[uidStr] <- contact.__merge({ realnick = name }))
  return contact
}

let requestedUids = {}

function validateNickNames(uidsList, onFinish = null) {
  if (typeof uidsList != "array")
    uidsList = [uidsList]
  let requestContacts = []
  let contactsVal = contacts.get()
  foreach (uidInt in uidsList)
    if (uidInt not in requestedUids && uidInt.tostring() not in contactsVal) {
      requestContacts.append(uidInt)
      requestedUids[uidInt] <- true
    }
  if (requestContacts.len() == 0) {
    onFinish?()
    return
  }

  request_nick_by_uid_batch(requestContacts,
    function(result) {
      foreach (uidInt in requestContacts) {
        let uidStr = uidInt.tostring()
        let name = result?[uidStr]
        if (name)
          updateContact(uidStr, name)
        requestedUids.$rawdelete(uidInt)
      }
      onFinish?()
    })
}

let hasContact = @(userId) userId in contacts.get()

let getContact = @(userId) contacts.get()?[userId] ?? mkContact(userId, invalidNickName)

let getContactRealnick = @(userId) contacts.get()?[userId].realnick ?? invalidNickName

let getContactNick = @(contact) contact.realnick != invalidNickName
  ? remap_others(contact.realnick)
  : invalidNickName

let contactUserIds = Computed(function() {
  let res = {}
  foreach (contact in contacts.get())
    res[contact.userId] <- true
  return res
})


return {
  contacts
  contactsGen
  contactUserIds
  getContactRealnick
  hasContact
  getContact
  updateContact
  validateNickNames
  getContactNick
}
