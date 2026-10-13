from "auth" import convert_external_jwt_to_auth_jwt
from "%ui/login/stages/auth_helpers.nut" import status_cb
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()

let globalAppPermId = circuitConf?.globalAppPermId ?? -1
return {
  id = "external_auth"
  function action(state, cb) {
    if (globalAppPermId < 0) {
      cb(state)
      return
    }
    status_cb(cb)(convert_external_jwt_to_auth_jwt(globalAppPermId))
  }
}
