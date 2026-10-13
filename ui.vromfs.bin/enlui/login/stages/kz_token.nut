from "eventbus" import eventbus_subscribe
from "app" import get_circuit
from "dagor.system" import get_arg_value_by_name
from "%ui/ui_library.nut" import *

let { login_kongzhong = @(_, _) null } = require_optional("auth.kongzhong")
let ah = require("%ui/login/stages/auth_helpers.nut")

const id = "auth_kz_token"

return {
  id

  function action(_state, cb) {
    eventbus_subscribe(id, ah.status_cb(cb))
    login_kongzhong({
      kz_token = get_arg_value_by_name("wf-token"),
      circuit = get_circuit()
    }, id)
  }
}
