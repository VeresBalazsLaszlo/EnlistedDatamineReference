import "statsd" as statsd
from "app" import launch_network_session
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/state/appState.nut" import isInBattleStateUpdate, isInBattleState
from "%ui/ui_library.nut" import *
from "%ui/matchingClient.nut" import matchingCall

let lastGame = nestWatched("lastGame", null)
let extraGameLaunchParams = nestWatched("extraGameLaunchParams", {})

function startGame(params) {
  console_print("Launching game client...")
  params = params.__merge(extraGameLaunchParams.get())
  if ((params?.modHash ?? "") != "" && params?.modId == null)
    params.modId <- "blob";
  log("starting game with params", params.filter(@(_,k) k!="authKey" && k!="encKey" && k!="modFile"))

  if (isInBattleState.get()) {
    log("startGame: game is already running")
    return
  }

  matchingCall("mpresence.set_presence", null, { scene = params?.scene ?? "" })
  isInBattleStateUpdate(true) 
  statsd.send_counter("game_launch", 1)
  lastGame.set(params)
  launch_network_session(params)
}

return {
  startGame
  lastGame
  extraGameLaunchParams
}
