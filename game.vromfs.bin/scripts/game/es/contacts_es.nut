import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
let { get_setting_by_blk_path } = require("settings")
let contactsGameId = get_setting_by_blk_path("contactsGameId")

let dedicated = require_optional("dedicated")
if (dedicated == null)
  return

let char = require("char")
let { CmdGetUserstats } = require("dasevents")
let { CmdSendComplaint } = require("charactions")
let { INVALID_USER_ID } = require("matching.errors")


function onCmdGetUserStats(eid, comp) {
  if (comp.userid == INVALID_USER_ID)
    return

  let request = {
    headers = {
      userid = comp.userid
      game = contactsGameId
      appid = comp.appId
    },
    action = "hst_get_chat_data"
  }


  log("request hst_get_chat_data", comp.userid, comp.appId)

  let userid = comp.userid
  char.request(request, function(result) {
    if (result) {
      let bestPenalty = result?.bestPenalty ?? ""

      let errorMsg = result?.error
      if (errorMsg)
        log($"hst_get_chat_data of {userid} returns error {errorMsg}")

      log($"bestPenalty of {userid} is {bestPenalty}")

      ecs.obsolete_dbg_set_comp_val(eid, "ban_status", bestPenalty)
    }
    else {
      ecs.obsolete_dbg_set_comp_val(eid, "ban_status", "")
      log("hst_get_chat_data return NO result")
    }
  })
}



ecs.register_es("contacts_es", {
    [CmdGetUserstats] = onCmdGetUserStats,
  },
  {
    comps_rw = [
      ["ban_status", ecs.TYPE_STRING]
    ]
    comps_ro = [
      ["userid", ecs.TYPE_UINT64],
      ["appId", ecs.TYPE_INT]
    ]
  },
  {tags = "server"}
)


function onCmdSendComplaint(evt, _eid, comp) {
  let { userid = INVALID_USER_ID, appId } = comp
  if (userid == INVALID_USER_ID)
    return

  let [ offender_userid, category, user_comment, details_json, chat_log, lang ] = evt
  let matchingModeInfo = dedicated.get_matching_mode_info()
  let session_id = matchingModeInfo?.sessionId ?? 0

  let request = {
    headers = {
      userid
      appid = appId
    }
    data = {
      offender_userid
      session_id
      category
      lang
      user_comment
      chat_log
      details_json
    }
    action = "hst_complaint"
  }

  log("CmdSendComplaint", request)

  char.request(request, function(result) {
    if (result) {
      let errorMsg = result?.error
      if (errorMsg)
        log($"hst_complaint for {userid} returns error {errorMsg}")
    }
    else {
      log("hst_complaint return NO result")
    }
  })
}


ecs.register_es("complaints_es", {
  [CmdSendComplaint] = onCmdSendComplaint
},
{
  comps_ro = [ ["userid", ecs.TYPE_UINT64], ["appId", ecs.TYPE_INT] ]
})

