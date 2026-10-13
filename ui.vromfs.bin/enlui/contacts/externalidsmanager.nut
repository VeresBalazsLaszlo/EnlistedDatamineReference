import "%enlSqGlob/userInfo.nut" as userInfo
from "%dngscripts/platform.nut" import is_sony, is_gdk
from "%ui/state/login_state.nut" import isSteamRunning
from "%ui/contacts/contact.nut" import updateContact
from "%ui/contacts/consoleUidsRemap.nut" import updateUids
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let { char_request = null } = require("%ui/charClient/charClient.nut")

let needSetExternalId = nestWatched("needSetExternalId", true)
let logExt = with_prefix("[EXT IDS MANAGER] ")


const EXTERNAL_TYPE_STEAM  = "s"
const EXTERNAL_TYPE_PSN    = "p"
const EXTERNAL_TYPE_XBOX   = "x"

let getExtType = @() is_sony ? EXTERNAL_TYPE_PSN
  : is_gdk ? EXTERNAL_TYPE_XBOX
  : isSteamRunning.get() ? EXTERNAL_TYPE_STEAM
  : ""

let getMyExtId = @() is_sony ? require("sony.user").accountIdString
  : is_gdk ? require("gdk.user").get_xuid().tostring()
  : isSteamRunning.get() ? require("steam").get_my_id()
  : "-1"

function setExternalId() {
  let id = getMyExtId()
  let extType = getExtType()
  if (id == "-1" || extType == "") 
    return

  char_request?("cln_set_external_id_json", { id, type = extType }, @(res) logExt("Return result of set ext id", res))
}

userInfo.subscribe(function(uInfo) {
  if (uInfo == null) {
    needSetExternalId.set(true)
    return
  }

  if (needSetExternalId.get()) {
    setExternalId()
    needSetExternalId.set(false)
  }
})


function searchContactByExternalId(extIdsArray, callback = null) {
  if (extIdsArray.len() == 0) {
    callback?([])
    return
  }

  let request = {
    externalIdList = extIdsArray.map(@(v) v.tostring())
    externalIdType = getExtType()
    maxCount = extIdsArray.len()
  }

  char_request?(
    "cln_find_users_by_external_id_list_json",
    request,
    function (result) {
      let myUserIdStr = userInfo.get()?.userIdStr ?? ""

      foreach (uidStr, data in result)
        if (uidStr != myUserIdStr && uidStr != "" && data?.nick != null)
          updateContact(uidStr, data.nick)

      callback?(result)
    }
  )
}

let searchContactByInternalId = @(userid, callback = null) char_request?(
  "ano_get_external_id",
  { userid },
  function(result) {
    if (result?.externalid.len())
      updateUids({ [result.externalid[0].i] = userid })

    callback?()
  }
)

return {
  searchContactByExternalId
  searchContactByInternalId
}