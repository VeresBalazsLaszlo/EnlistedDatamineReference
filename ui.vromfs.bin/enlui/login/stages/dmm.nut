from "dagor.system" import get_arg_value_by_name
from "eventbus" import eventbus_subscribe_onehit
from "%ui/ui_library.nut" import *
from "auth" import YU2_OK, YU2_NOT_FOUND, status_string_full

let { login_dmm = null } = require_optional("auth.dmm")

function status_cb(cb) {
  return function(resultImmutable) {
    let result = clone resultImmutable
    if (result.status != YU2_OK) {
      if (result.status == YU2_NOT_FOUND) {
        result.error <- "dmmError/notRegistered"
        result.quitBtn <- true
      }
      else
        result.error <- status_string_full(result.status)
    }
    cb(result)
  }
}

const id = "auth_dmm"

return {
  id
  function action(_state, cb) {
    eventbus_subscribe_onehit(id, status_cb(cb))
    login_dmm?({
      dmm_user_id = get_arg_value_by_name("dmm_user_id")
      dmm_token = get_arg_value_by_name("dmm_token")
    }, id)
  }
}
