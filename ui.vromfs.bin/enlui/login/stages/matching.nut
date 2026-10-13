from "dagor.debug" import logerr
from "%ui/matchingClient.nut" import matchingLogin
from "eventbus" import eventbus_subscribe_onehit
from "%ui/ui_library.nut" import *

return {
  id = "matching"
  function action(processState, cb) {
    let { auth_result, external_auth = null } = processState.stageResult
    let { userId, name, token } = auth_result
    let { globalJwt = null, globalToken = null, globalUserId = null } = external_auth
    let mainToken = globalJwt ?? globalToken ?? token
    if (mainToken == null) {
      logerr("Matching token is null")
      log(processState.stageResult)
    }

    let uinfo = {
      userId = globalUserId ?? userId
      name
      chardToken = processState.stageResult.char.chard_token
      authJwt = mainToken
    }
    eventbus_subscribe_onehit("matching.logged_in", @(...) cb({}))
    eventbus_subscribe_onehit("matching.login_failed", cb)
    matchingLogin(uinfo)
  }
  function actionOnReload(_state, cb) {
    eventbus_subscribe_onehit("matching.logged_in", @(...) cb({}))
    eventbus_subscribe_onehit("matching.login_failed", cb)
  }
}
