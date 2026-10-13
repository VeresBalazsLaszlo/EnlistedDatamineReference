from "%ui/contacts/externalIdsManager.nut" import searchContactByExternalId
from "%ui/gdk/userIds.nut" import updateUidsMapping
from "%ui/ui_library.nut" import *

let logX = require("%sqstd/log.nut")().with_prefix("[EXTERNAL_IDS] ")
let netUtils = require("%ui/netUtils.nut")

let cachedDataXuids = persist("cachedDataXuids", @() { cachedNulls = {} })


function request_xuid_for_user(uid, callback) {
  if (uid in cachedDataXuids.cachedNulls) {
    logX($"UserID {uid} was requested already and doesn't have known xuid")
    callback?(uid, null)
    return
  }

  netUtils.request_full_userinfo(uid.tointeger(), function(response) {
    let xuid = response?.live_xuid
    if (xuid) {
      updateUidsMapping({ [xuid] = uid })
      logX($"UserID {uid} has known xuid {xuid}")
    } else {
      cachedDataXuids.cachedNulls[uid] <- true
      logX($"UserID {uid} doesn't have known xuid -> remembering")
    }
    callback?(uid, xuid)
  })
}


function batch_request_uids_by_xuids(xuids, callback) {
  searchContactByExternalId(xuids, function(response) {
    local xbox2uid = {}
    foreach (uid, data in response) {
      let { id = null } = data
      if (id != null)
        xbox2uid[id] <- uid
    }
    callback?(xbox2uid)
  })
}


return {
  request_xuid_for_user
  batch_request_uids_by_xuids
}