from "%enlSqGlob/appInfo.nut" import version, build_number
from "settings" import get_setting_by_blk_path
from "%ui/charClient/charClient.nut" import char_request
from "%sqstd/string.nut" import tostring_r
from "dagor.system" import dgs_get_settings
from "%ui/ui_library.nut" import *

let contactsGameId = get_setting_by_blk_path("contactsGameId")

let sysinfo = require_optional("sysinfo")


function char_login(auth_token, user_cb) {
  let request = {
    game =  contactsGameId
  }

  if (sysinfo) {
    local si = sysinfo.get_user_system_info()
    si.game_version <- version.get()
    si.game_build <- build_number.get()
    si.graphicsQuality <- (dgs_get_settings()?.graphics?.preset ?? "medium")
    request["sysinfo"] <- si
  }

  const add_publisher = true

  char_request?("cln_cs_login", request,
    function(result) {
      if ( typeof result != "table" ) {
        log("ERROR: invalid cln_cs_login result\n")
        user_cb({error = "INTERNAL_SERVER_ERROR"})
        return
      }

      if ("result" in result)
        result = result.result

      if ( "error" in result ) {
        log("ERROR: cln_cs_login result: {0}".subst(tostring_r(result)))
        user_cb(result)
        return
      }

      log("char_login performed for user")
      user_cb({
        penaltiesJwt = result?.penaltiesJwt
        clientPermJwt = result?.clientPermJwt
        dedicatedPermJwt = result?.dedicatedPermJwt
        chard_token = result.chardToken
        externalid = result?.externalid ?? []
      })

    },
    auth_token, add_publisher)
}

return {
  id = "char"
  action = function(processState, cb) {
    assert(contactsGameId!=null, "contactsGameId is not set in settings.blk!")
    let { auth_result, external_auth = null } = processState.stageResult
    let mainToken = external_auth?.globalJwt ?? external_auth?.globalToken ?? auth_result.token
    char_login(mainToken, cb)
  }
}
