from "%ui/meta/clientApi.nut" import update_profile, get_all_configs
from "%ui/meta/configs.nut" import updateAllConfigs
from "%ui/ui_library.nut" import *

let updateList = [
  { id = "update_profile", request = update_profile }
  { id = "get_all_configs", request = get_all_configs,
    onSuccess = @(r) updateAllConfigs(r?.configs) }
]
let ALL = (1 << updateList.len()) - 1

function startRequest(data, idx, shared) {
  let { id, request, onSuccess = @(_) null } = data
  request(function cb(res) {
    if (shared.isFailed)
      return 
    shared.result[id] <- res
    if (res?.error != null) {
      shared.isFailed = true
      shared.result.error <- res.error
      shared.onAllFinishCb(shared.result)
      return
    }
    onSuccess(res)
    shared.current += 1 << idx
    if (shared.current == ALL)
      shared.onAllFinishCb(shared.result)
  }, shared.token)
}

return {
  id = "pServerProfileAndConfigs"
  function action(processState, cb) {
    let { auth_result, external_auth = null } = processState.stageResult
    let token = external_auth?.globalJwt ?? external_auth?.globalToken ?? auth_result.token
    let shared = { current = 0, result = {}, onAllFinishCb = cb, isFailed = false, token }
    updateList.each(@(data, idx) startRequest(data, idx, shared))
  }
}