from "eventbus" import eventbus_subscribe_onehit

let { login_gfn = null } = require_optional("auth.gfn")
let ah = require("%ui/login/stages/auth_helpers.nut")

const id = "auth_gfn"

return {
  id

  function action(_state, cb) {
    eventbus_subscribe_onehit(id, ah.status_cb(cb))
    login_gfn?(id)
  }
}
