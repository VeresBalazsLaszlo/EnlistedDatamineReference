from "%ui/login/stages/auth_helpers.nut" import status_cb
from "eventbus" import eventbus_subscribe_onehit
from "app" import get_circuit
from "%ui/ui_library.nut" import *
from "auth" import login_web, login_2step, login

const id = "auth_go"

return {
  id
  function action(state, cb) {
    eventbus_subscribe_onehit(id, status_cb(cb))

    let params = state.params.__merge({
      circuit = get_circuit()
    })
    let loginMethod = params?.session_id ? login_web
      : params?.two_step_code != null ? login_2step
      : login
    loginMethod(params, id)
  }
  actionOnReload = @(_state, cb) eventbus_subscribe_onehit(id, status_cb(cb))
}
