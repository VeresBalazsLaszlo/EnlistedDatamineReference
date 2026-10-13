import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/userstats/userstat.nut" import setStatsModes, refreshUserstats, setLbStatsModes, refreshLbUserstats
from "%ui/leaderboard/lbStateBase.nut" import setLbHandler
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/meta/curCampaign.nut" import allArmiesList
from "%ui/leaderboard/lbStateBase.nut" import lbClient
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let lbStatsModes = nestWatched("lbStatsModes", [])

function setupUserstatsModes() {
  let regularModes = [].extend(allArmiesList.get(), const ["main_game", "squads", "lone_fighter"])
  setStatsModes(regularModes)
}

lbStatsModes.subscribe(function(v) {
  setLbStatsModes(v)
  refreshLbUserstats()
})

function requestLbModes() {
  if (userInfo.get() != null)
    lbClient.request("cmn_get_global_leaderboard_modes")
}

setLbHandler("cmn_get_global_leaderboard_modes", function(result) {
  if (!result?.modes && !result?.modesEmpty){
    log("cmn_get_global_leaderboard_modes: no modes", result)
    gui_scene.resetTimeout(300, requestLbModes)
    return
  }

  let modes = [].extend(result?.modes ?? [], result?.modesEmpty ?? [])
  if (modes.len() == 0)
    log("cmn_get_global_leaderboard_modes: empty modes in the result")
  else
    lbStatsModes.set(modes)
})

function updateAllStats(val) {
  if (val == null)
    return

  setupUserstatsModes()
  refreshUserstats()
  requestLbModes()
}

subscribeAndInit(updateAllStats, userInfo)

return {
  lbStatsModes
}