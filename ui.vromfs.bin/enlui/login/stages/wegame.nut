from "eventbus" import eventbus_subscribe_onehit
from "app" import get_circuit
from "%ui/ui_library.nut" import *

let { login_wegame = null } = require_optional("auth.wegame")
let ah = require("%ui/login/stages/auth_helpers.nut")

const id = "auth_wegame"

return {
  id

  function action(state, cb) {
    eventbus_subscribe_onehit(id, ah.status_cb(cb))
    login_wegame?({
      circuit = get_circuit()
    }.__update(state?.params ?? {}), id)
  }
}
