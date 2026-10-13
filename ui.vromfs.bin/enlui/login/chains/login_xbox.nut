import "auth" as auth
from "%gdkLib/impl/user.nut" import get_xuid
from "%ui/gdk/login.nut" import xbox_login
from "auth.xbox" import have_game_pass_subscription
from "%dngscripts/platform.nut" import is_xbox
from "%ui/ui_library.nut" import *

let loginCb = require("%ui/login/login_cb.nut")
let { sendGamePassStatusToUserstatServer = null } = require("%ui/userstats/userstat.nut")

let error_cb = @(cb, failure_loc_key, show_error, errorStr = null) @(success)
  success ? cb({}) : cb({error = failure_loc_key, needShowError = show_error, errorStr})

function login_live(state, cb) {
  let xuid = get_xuid()
  log($"login live for user {xuid}")
  state.userInfo.xuid <- xuid

  xbox_login(function(status, status_text) {
    local failure_loc_key = "FailedToConnect" 
    if (status == auth.YU2_WRONG_PARAMETER) {
      let platform_loc_prefix = is_xbox ? "xbox" : "pc"
      failure_loc_key = $"{platform_loc_prefix}/live_login_failed" 
    }
    let full_error = $"{loc(failure_loc_key)} ({status_text})"
    error_cb(cb, failure_loc_key, true, full_error)(status == auth.YU2_OK)
  })
}

function send_game_pass_status(state) {
  if (sendGamePassStatusToUserstatServer == null)
    return
  let token = state.stageResult.auth_result.token
  let haveGamePass = have_game_pass_subscription()
  log($"[XBOX] user has active subscription: {haveGamePass}")
  sendGamePassStatusToUserstatServer(haveGamePass, token)
}

function onSuccess(state) {
  loginCb.onSuccess(state)
  send_game_pass_status(state)
}

return {
  stages = [
    { id = "auth_xbox", action = login_live, actionOnReload = @(_state, _cb) null },
    require("%ui/login/stages/eula_before_login.nut"),
    require("%ui/login/stages/auth_result.nut"),
    require("%ui/login/stages/char.nut"),
    require("%ui/login/stages/online_settings.nut"),
    require("%ui/login/stages/eula.nut"),
    require("%ui/login/stages/matching.nut")
  ]
  onSuccess = onSuccess
  onInterrupt = loginCb.onInterrupt
}
