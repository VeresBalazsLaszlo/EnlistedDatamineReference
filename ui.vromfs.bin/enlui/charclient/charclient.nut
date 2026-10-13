import "%enlSqGlob/userInfo.nut" as userInfo
import "char" as low_level_client
from "console" import register_command as console_register_command
from "matching.errors" import INVALID_USER_ID
from "%ui/charClient/appIdMapping.nut" import construct_known_project_id
from "app" import get_circuit_conf


let circuitConf = get_circuit_conf()
let logC = require("%enlSqGlob/library_logs.nut").with_prefix("[CHAR CLIENT] ")


function addPublisherToHeaders(headers) {
  if (circuitConf?.publisher)
    headers.publisher <- circuitConf.publisher
  return headers
}

function char_request(action, data, callback, auth_token = null, add_publisher = false) {
  if (userInfo.get() == null && auth_token == null) {
    logC("User is logout skip char_request")
    return
  }

  auth_token = auth_token ?? userInfo.get()?.token
  assert(auth_token != null, "No auth token provided for char request")
  let headers = {token = auth_token, projectid = construct_known_project_id()}

  if (add_publisher)
    addPublisherToHeaders(headers)

  let request = {
    headers
    action
  }

  if (data)
    request["data"] <- data

  low_level_client.request(request, function(result) {
    if (result?.error != null)
      callback({
        result = {
          success = false,
          error = result.error,
          errorDetails = result?.details
        }})
    else
      callback(result)
  })
}

function char_host_request(action, userid, data, callback) {
  let request = {
    headers = { userid }
    action = action
  }

  if (data)
    request["data"] <- data

  low_level_client.request(request, callback)
}

function perform_contact_action(action, request, params) {
  let { success = null, failure = null } = params
  logC("perform_contact_action", request)

  char_request(action, request, function(result) {
    logC("char_request", result)

    let subResult = result?.result
    if (subResult != null)
      result = subResult

    if ("success" in result && !result.success)
      failure?(result?.error)
    else
      success?()
  })
}

function perform_single_contact_action(request, params) {
  perform_contact_action("cln_change_single_contact_json", request, params)
}

function contacts_add(id, params = {}) {
  let request = {
    friend = {
      add = [id]
    }
  }

  perform_single_contact_action(request, params)
}

function perform_contacts_for_requestor(action, apprUid, group, params = {}, requestAddon = {}) {
  if (apprUid == INVALID_USER_ID) {
    logC($"try perform action {action} for invalid contact, group {group}")
    return
  }

  let request = {
    apprUid = apprUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}

function perform_contacts_for_approver(action, requestorUid, group,
    params = {}, requestAddon = {}) {

  if (requestorUid == INVALID_USER_ID) {
    logC($"try perform action {action} for invalid contact, group {group}")
    return
  }

  let request = {
    requestorUid = requestorUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}


function contacts_get() {
  char_request("cln_get_contact_lists_ext", null, function(result) {
    logC("cln_get_contact_lists_ext", result)
  })
}

function leaderboard_get() {
  let request = {
    category = "relativePlayerPlace",
    valueType = "value_total",
    gameMode = "game_test"
    count = 10,
    start = 0
  }

  char_request("cln_get_leaderboard_json", request, function(result) {
    logC("cln_get_leaderboard_json", result)
  })
}

function leaderboard_host_push() {
  let request = {
    nick = "__",
    data = {
      arcade = {
        each_player_session = 1
        each_player_victories = 1
        finalSessionCounter = 1
        flyouts = 1
        ground_spawn = 1
        position = 1
        relativePosition = 1000
        time_pvp_played = 41
      }
    }
  }

  char_host_request("hst_leaderboard_player_set", 666, request, function(result) {
    if (result)
      logC("hst_leaderboard_player_set result", result)
    else
      logC("Ok")
  })
}


function contacts_search(nick) {
  let request = {
    nick = nick
    max_count = 10
    ignore_case = true
  }

  char_request("cln_find_users_by_nick_prefix_json", request, function(result) {
    logC("cln_find_users_by_nick_prefix_json result", result)
  })
}


console_register_command(contacts_get, "char.contacts_get")
console_register_command(contacts_add, "char.contacts_add")
console_register_command(contacts_search, "char.contacts_search")
console_register_command(leaderboard_get, "char.leaderboard_get")
console_register_command(leaderboard_host_push, "char.leaderboard_host_push")

return {
  low_level_client
  char_request
  addPublisherToHeaders

  contacts_request_for_contact = @(id, group, params = {})
    perform_contacts_for_requestor("cln_request_for_contact", id, group, params)

  contacts_cancel_request = @(id, group, params = {})
    perform_contacts_for_requestor("cln_cancel_request_for_contact", id, group, params)

  contacts_approve_request = @(id, group, params = {})
    perform_contacts_for_approver("cln_approve_request_for_contact", id, group, params)

  contacts_break_approval_request = @(id, group, params = {})
    perform_contacts_for_approver("cln_break_approval_contact", id, group, params)

  contacts_reject_request = @(id, group, params = {})
    perform_contacts_for_approver("cln_reject_request_for_contact", id, group, params, {silent="on"})

  contacts_add_to_blacklist = @(id, group, params = {})
    perform_contacts_for_approver("cln_blacklist_request_for_contact", id, group, params)

  contacts_remove_from_blacklist = @(id, group, params = {})
    perform_contacts_for_approver("cln_remove_from_blacklist_for_contact", id, group, params)
}
