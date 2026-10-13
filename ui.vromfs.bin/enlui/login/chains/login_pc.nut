import "steam" as steam
import "wegame" as wegame
import "gfn" as gfn
from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "dagor.system" import get_arg_value_by_name
from "%ui/ui_library.nut" import *

let login_cb = require("%ui/login/login_cb.nut")
let login_steam_cb = require("%ui/login/login_cb_steam.nut")
let login_wegame_cb = require("%ui/login/login_cb_wegame.nut")
let login_gfn_cb = require("%ui/login/login_cb_gfn.nut")

let auth_result = require("%ui/login/stages/auth_result.nut")
let global_token = require("%ui/login/stages/globalToken.nut")
let char_stage = require("%ui/login/stages/char.nut")
let online_settings = require("%ui/login/stages/online_settings.nut")
let eula = require("%ui/login/stages/eula.nut")
let matching = require("%ui/login/stages/matching.nut")
let fake_login = require("%ui/login/stages/fake.nut")
let dmm_login = require("%ui/login/stages/dmm.nut")
let go_login = require("%ui/login/stages/go.nut")
let save_login = require("%ui/login/stages/save_login_data.nut")
let steam_stages = require("%ui/login/stages/steam_stages.nut")
let wegame_login = require("%ui/login/stages/wegame.nut")
let gfn_login = require("%ui/login/stages/gfn.nut")

if (disableRemoteNetServices) {
  return {
    stages = [fake_login]
    onSuccess = login_cb.onSuccess
    onInterrupt = login_cb.onInterrupt
  }
}

let isDMMLogin = get_arg_value_by_name("dmm_user_id") != null

if (isDMMLogin){
  return {
    stages = [
      dmm_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_cb.onSuccess
    onInterrupt = login_cb.onInterrupt
  }
}

if (steam.is_running()) {
  return {
    stages = [].extend(steam_stages).append(
      auth_result
      char_stage
      online_settings
      eula
      matching
    )
    onSuccess = login_steam_cb.onSuccess
    onInterrupt = login_steam_cb.onInterrupt
  }
}


if (wegame.is_running()) {
  return {
    stages = [
      wegame_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_wegame_cb.onSuccess
    onInterrupt = login_wegame_cb.onInterrupt
  }
}

if (gfn.is_running()) {
  return {
    stages = [
      gfn_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_gfn_cb.onSuccess
    onInterrupt = login_gfn_cb.onInterrupt
  }
}


return {
  stages = [
    go_login
    auth_result
    global_token
    char_stage
    online_settings
    eula
    matching
    save_login
  ]
  onSuccess = login_cb.onSuccess
  onInterrupt = login_cb.onInterrupt
}
