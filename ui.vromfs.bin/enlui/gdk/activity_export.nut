from "%ui/ui_library.nut" import *



local update_activity_fn = null
local clear_activity_fn = null
local send_invite_fn = null


enum ActivityType {
  Unknown = 0
  Group = 1
  Room = 2
}

let ACTIVITY_PREFIXES = freeze({
  ["u"] = ActivityType.Unknown,
  ["g"] = ActivityType.Group,
  ["r"] = ActivityType.Room,
})

let to_prefix = @(activity_type) ACTIVITY_PREFIXES.findindex(@(v) v == activity_type) ?? "u"
let from_prefix = @(prefix) ACTIVITY_PREFIXES?[prefix] ?? ActivityType.Unknown

function make_connection_string(activity_type, connection_id) {
  let prefix = to_prefix(activity_type)
  return $"{prefix}{connection_id}"
}

function parse_connection_string(connection_string) {
  let prefix = connection_string.slice(0, 1)
  let atype = from_prefix(prefix)
  log($"parse_connection_string {connection_string} -> {prefix}:{atype}")
  if (atype != ActivityType.Unknown)
    return {type = atype, connection = connection_string.slice(1)}
  return {type = ActivityType.Unknown, connection = connection_string}
}


function update_activity(callback = null) {
  update_activity_fn?(callback)
}


function clear_activity(callback = null) {
  clear_activity_fn?(callback)
}


function send_invite(xuid, data, callback = null) {
  send_invite_fn?(xuid, data, callback)
}


return {
  update_activity
  clear_activity
  send_invite

  ActivityType

  make_connection_string
  parse_connection_string

  set_update_activity_fn = @(fn) update_activity_fn = fn
  set_clear_activity_fn = @(fn) clear_activity_fn = fn
  set_send_invite_fn = @(fn) send_invite_fn = fn
}
