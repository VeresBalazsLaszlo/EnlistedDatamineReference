import "%ui/login/buyGameAccess.nut" as buyGameAccess
import "%ui/login/ban_message.nut" as showBanMessage
from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%ui/login/login_chain.nut" import setStagesConfig
from "%ui/login/login_cb.nut" import showStageErrorMsgBox
from "%ui/components/textButton.nut" import Regular
from "%ui/login/chineseKongZhongVersion.nut" import isKZVersion
from "%ui/ui_library.nut" import *

let defConfig = require("%ui/login/defaultLoginStages.nut")
let matchingStage = require("%ui/login/stages/matching.nut")
let pServerStage = require("%ui/login/pServerLoginStage.nut")
let { KZLoginStages } = require("%ui/login/chineseKongZhongVersion.nut")


if (isKZVersion)
  require("%ui/login/initKongZhongLogin.nut")

let mkOnInterrupt = @(defOnInterrupt) function(state) {
  let err = state.stageResult?.error
  if (err == "Maintenance") {
    showStageErrorMsgBox(loc("Maintenance"), state)
    return
  }

  if (err == "WASNOT_BOUGHT_BEFORE") {
    showStageErrorMsgBox(
      loc($"error/{state.stageResult.error}", ""),
      state,
      @(_) Regular(
        loc($"{state.stageResult.error}/link/text", ""),
        buyGameAccess
      )
    )
    return
  }

  if (err == "BANNED") {
    let { details = null } = state.stageResult?.char
    if (details != null) {
      showBanMessage(details, state)
      return
    }
  }

  defOnInterrupt(state)
}

let config = function() {
  if (disableRemoteNetServices)
    return defConfig
  let res = clone defConfig
  res.stages = clone (isKZVersion ? KZLoginStages : res.stages)
  let idx = res.stages.indexof(matchingStage)
  if (idx == null || idx >= res.stages.len() - 1){
    res.stages.append(pServerStage)
  }
  else {
    res.stages.insert(idx + 1, pServerStage)
  }

  res.onInterrupt = mkOnInterrupt(res.onInterrupt)
  return res
}()

setStagesConfig(config)
