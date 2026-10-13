from "%gdkLib/impl/relationships.nut" import update_friends_list, update_mute_list, update_avoid_list, retrieve_related_people_list, retrieve_avoid_people_list
  , retrieve_muted_people_list, subscribe_to_relationships_change_events, ListType
from "%gdkLib/impl/user.nut" import is_any_user_active
from "%ui/gdk/userIds.nut" import xbox2uid, updateUidsMapping
from "%ui/gdk/externalIds.nut" import batch_request_uids_by_xuids
from "%ui/ui_library.nut" import *

let logX = require("%sqstd/log.nut")().with_prefix("[XBOX_RELATIONSHIPS] ")


let friendsXuids = Watched([])
let mutedXuids = Watched([])
let bannedXuids = Watched([])


function retrieve_all_lists(callback) {
  retrieve_related_people_list(function(friends_xuids) {
    retrieve_muted_people_list(function(muted_xuids) {
      retrieve_avoid_people_list(function(banned_xuids) {
        local xuidsForRequest = []
        foreach (xuids_list in [friends_xuids, muted_xuids, banned_xuids]) {
          foreach (xuid in xuids_list) {
            if (xuid not in xbox2uid && xuid not in xuidsForRequest) {
              xuidsForRequest.append(xuid)
            }
          }
        }
        batch_request_uids_by_xuids(xuidsForRequest, function(xuids2uids) {
          updateUidsMapping(xuids2uids)
          friendsXuids.set(friends_xuids)
          mutedXuids.set(muted_xuids)
          bannedXuids.set(banned_xuids)
          callback?()
        })
      })
    })
  })
}


function update_relationships_impl(fire_events, callback) {
  if (!is_any_user_active()) {
    logX("There is no active user, skipping relationships update")
    return
  }
  update_friends_list(fire_events, function(fsucc) {
    logX($"Updated friends list: {fsucc}")
    update_mute_list(fire_events, function(msucc) {
      logX($"Updated mute list: {msucc}")
      update_avoid_list(fire_events, function(asucc) {
        logX($"Updated avoid list: {asucc}")
        retrieve_all_lists(callback)
      })
    })
  })
}


function initialize_relationships() {
  friendsXuids.set([])
  mutedXuids.set([])
  bannedXuids.set([])

  update_relationships_impl(false, null)
}


function update_relationships() {
  update_relationships_impl(false, null)
}


subscribe_to_relationships_change_events(function(list, _change_type, _xuids) {
  assert(list == ListType.Friends) 
  logX("on_relationships_change_event")
  retrieve_related_people_list(function(friends_xuids) {
    local xuidsForRequest = []
    foreach (xuid in friends_xuids) {
      if (xuid not in xbox2uid && xuid not in xuidsForRequest) {
        xuidsForRequest.append(xuid)
      }
    }
    if (xuidsForRequest.len() > 0) {
      batch_request_uids_by_xuids(xuidsForRequest, function(xuids2uids) {
        updateUidsMapping(xuids2uids)
        friendsXuids.set(friends_xuids)
      })
    }
  })
})


return {
  initialize_relationships
  update_relationships

  friendsXuids
  mutedXuids
  bannedXuids
}