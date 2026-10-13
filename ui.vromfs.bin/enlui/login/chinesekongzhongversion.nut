import "wegame" as wegame
from "settings" import get_setting_by_blk_path
from "dagor.system" import get_arg_value_by_name
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let auth_kz_token = require("%ui/login/stages/kz_token.nut")
let auth_result = require("%ui/login/stages/auth_result.nut")
let char_stage = require("%ui/login/stages/char.nut")
let online_settings = require("%ui/login/stages/online_settings.nut")
let eula = require("%ui/login/stages/eula.nut")
let matching = require("%ui/login/stages/matching.nut")
let circuitConf = get_circuit_conf()


let loginStagesPass = [
  auth_result
  char_stage
  online_settings
  eula
  matching
]

let loginStagesToken = [
  auth_kz_token
  auth_result
  char_stage
  online_settings
  eula
  matching
]


return {
  isKZVersion = (get_arg_value_by_name("kongzhong")) || (((get_setting_by_blk_path("isChineseVersion") ?? false) &&
    (circuitConf?.webLoginUrl ?? "") != "") &&
    !wegame.is_running())

  KZLoginStages = get_arg_value_by_name("wf-token") ? loginStagesToken : loginStagesPass
}
