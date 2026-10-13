from "%ui/ui_library.nut" import *
from "%ui/options/onlineSettings.nut" import loadFromCloud, onUpdateSettings

return {
  id = "online_settings"
  function action(state, cb) {
    let { auth_result, external_auth = null } = state.stageResult
    let userId = external_auth?.globalUserId ?? auth_result.userId
    log($"load_from_cloud started for user {userId}")
    loadFromCloud(userId,
      function(result) {
        log($"load_from_cloud callback '{result}'")
        onUpdateSettings(userId)
        cb(result)
      })
  }
}
