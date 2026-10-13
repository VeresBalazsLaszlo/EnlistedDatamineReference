from "%gdkLib/impl/presence.nut" import subscribe_to_device_change_events, subscribe_to_title_change_events, retrieve_presences_for_users, subscribe_to_presence_update_events, set_presence, start_monitoring, stop_monitoring, DeviceType
from "%gdkLib/impl/app.nut" import get_title_id
from "%gdkLib/impl/user.nut" import is_any_user_active
from "%ui/state/appState.nut" import isInBattleState
from "%ui/contacts/contactPresence.nut" import updatePresences
from "%ui/contacts/consoleUidsRemap.nut" import console2uid
from "%ui/gdk/relationships.nut" import friendsXuids, mutedXuids, bannedXuids
from "%ui/ui_library.nut" import *

let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX PRESENCE] ")


let presenceStatuses = {
  ONLINE = "online"
  IN_GAME = "in_game"
}


let RELEVANT_DEVICES = [
  DeviceType.XboxOne,
  DeviceType.Scarlett,
  DeviceType.WindowsOneCore, 
]


isInBattleState.subscribe(function(v) {
  if (!is_any_user_active()) {
    logX("No active user, skip setting presence")
    return
  }
  let presence = v ? presenceStatuses.IN_GAME : presenceStatuses.ONLINE
  logX($"Set user presence: {presence}")
  set_presence(presence, function(success) {
    logX($"Set user presence succeeded: {success}")
  })
})


function on_presences_update(success, presences) {
  if (!success) {
    logX("Failed to update presences for users")
    return
  }

  let updPresences = {}
  foreach (data in presences) {
    let xuid = data.xuid.tostring()
    if (xuid not in console2uid.get())
      continue

    updPresences[console2uid.get()[xuid]] <- { online = false }

    if (!data?.activeDevices.len())
      continue

    foreach (actDev in data.activeDevices) {
      if (RELEVANT_DEVICES.contains(actDev.type)) {
        if ("activeTitles" not in actDev) {
          updPresences[console2uid.get()[xuid]].online = true
          break
        }

        foreach (actTitle in actDev.activeTitles)
          if (actTitle.titleId == get_title_id()) {
            updPresences[console2uid.get()[xuid]].online = true
            break
          }
      }
    }
  }

  logX("Update presences:", updPresences)
  updatePresences(updPresences)
}


function update_presences_for_users(xuids) {
  retrieve_presences_for_users(xuids)
}


function on_device_change_event(xuid, dev_type, logged_in) {
  logX($"on_device_change_event: {xuid}, {dev_type}, {logged_in}")
  retrieve_presences_for_users([xuid])
}


function on_title_change_event(xuid, title_id, title_state) {
  logX($"on_title_change_event: {xuid}, {title_id}, {title_state}")
  retrieve_presences_for_users([xuid])
}


friendsXuids.subscribe(function(v) {
  if (v.len() > 0) {
    retrieve_presences_for_users(v)
    start_monitoring(v)
  }
})


mutedXuids.subscribe(function(v) {
  if (v.len() > 0) {
    stop_monitoring(v)
  }
})


bannedXuids.subscribe(function(v) {
  if (v.len() > 0) {
    stop_monitoring(v)
  }
})


subscribe_to_presence_update_events(on_presences_update)
subscribe_to_device_change_events(on_device_change_event)
subscribe_to_title_change_events(on_title_change_event)


return {
  update_presences_for_users
}