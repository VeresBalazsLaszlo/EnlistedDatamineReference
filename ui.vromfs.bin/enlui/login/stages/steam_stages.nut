from "eventbus" import eventbus_subscribe_onehit
from "%ui/ui_library.nut" import *

let go_login = require("%ui/login/stages/go.nut")
let { login_steam = null } = require_optional("auth.steam")
let ah = require("%ui/login/stages/auth_helpers.nut")

const AUTH_STEAM = "auth_steam"
const STEAM_LINK = "steam_link"

return [
  {
    id = AUTH_STEAM
    function action(state, cb) {
      eventbus_subscribe_onehit(AUTH_STEAM, ah.status_cb(cb))
      login_steam?(state.params.onlyKnown, AUTH_STEAM)
    }
    actionOnReload = @(_state, cb) eventbus_subscribe_onehit(AUTH_STEAM, ah.status_cb(cb))
  }
  {
    id = go_login.id
    action = @(_params, cb) cb({})
    actionOnReload = @(_state, _cb) null
  }
  {
    id = STEAM_LINK
    action = @(_params, cb) cb({})
    actionOnReload = @(_state, cb) eventbus_subscribe_onehit(STEAM_LINK, ah.status_cb(cb))
  }
]
