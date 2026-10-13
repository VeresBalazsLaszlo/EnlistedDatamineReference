import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
import "net" as net
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "%enlSqGlob/offline_mode.nut" import disableMenu
from "dagor.debug" import logerr
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "dasevents" import sendNetEvent, EventGameSessionFinished, EventGameSessionStarted, CmdGetDebriefingResult, CmdGetBattleResult, EventSwitchToMenu
from "gameevents" import EventOnDisconnectedFromServer
from "%ui/components/msgbox.nut" import showMsgbox
from "dagor.workcycle" import setInterval, resetTimeout, clearTimer
from "%dngscripts/globalState.nut" import nestWatched
from "dagor.time" import get_time_msec
from "%ui/state/login_state.nut" import logOut
from "%ui/userstats/userstat.nut" import forceRefreshUnlocks, refreshUserstats
from "%ui/ui_library.nut" import *
from "nestdb" import ndbRead, ndbWrite, ndbExists

let { get_pipeline_compilation_queue_length = @() 0 } = require_optional("loading_ui") ?? {}

let levelLoaded = nestWatched("levelLoaded", false)
let levelIsLoading = nestWatched("levelIsLoading", false)
let levelLoadingStartedTime = nestWatched("levelLoadingStartedTime", -1)
local prevPipelineQueue = -1
local pipelineGraceDeadline = 0

function getGlobalState(key, def=null){
  let curval = ndbExists(key) ? ndbRead(key) : def
  let res = Watched(curval)
  ndbWrite(key, curval)
  function set(val){
    ndbWrite(key, val)
    res.set(val)
  }
  return [res, set]
}

let [isInBattleState, isInBattleStateSet] = getGlobalState("isInBattleState", disableMenu)
let currentLevelBlk = mkEcsComputed({ comps = [["level__blk", ecs.TYPE_STRING]] })
local firstLoadingOfMainMenu = true
let [isInMainMenuState, isInMainMenuStateSet] = getGlobalState("isInMainMenuState", false)
let [isRealBattleStarted, isRealBattleStartedSet] = getGlobalState("isRealBattleStarted", false)

function setIsInMainMenuState(is_in_menu) {
  if (is_in_menu)
    firstLoadingOfMainMenu = false
  isInMainMenuStateSet(is_in_menu)
}

let isCheckRequired = nestWatched("isCheckRequired", false)

let uiDisabled = mkEcsComputed({ comps = [["ui__disabled", ecs.TYPE_BOOL]], defVal = false })
let dbgLoading = mkWatched(persist, "dbgLoading", false)

console_register_command(function() {
  dbgLoading.set(!dbgLoading.get())
}, "ui.loadingDbg")

const JoiningWatchdogTime = 30
const LoadingWatchdogTimeMs = 150_000 
const PipelineCompilationGraceMs = 30_000
const LoadingWatchdogMaxTimeMs = 1_800_000

let connErrMessages = freeze({
  [net.DC_CONNECTION_CLOSED] = loc("ConnErr/CONNECTION_CLOSED"),
  [net.DC_CONNECTION_LOST] = loc("ConnErr/CONNECTION_LOST"),
  [net.DC_CONNECTION_STOPPED] = loc("ConnErr/CONNECTION_CLOSED"),
  [net.DC_CONNECTION_ATTEMPT_FAILED] = loc("ConnErr/CONNECT_FAILED"),
  [net.DC_NET_PROTO_MISMATCH] = loc("ConnErr/CONNECT_FAILED_PROTO_MISMATCH"),
  [net.DC_SERVER_FULL] = loc("ConnErr/SERVER_FULL"),
  [net.DC_KICK_GENERIC] = loc("ConnErr/WAS_KICKED_OUT"),
  [net.DC_KICK_INACTIVITY] = loc("ConnErr/KICK_AFK"),
  [net.DC_KICK_ANTICHEAT] = loc("ConnErr/KICK_EAC"),
  [net.DC_KICK_FRIENDLY_FIRE] = loc("ConnErr/KICK_KILLING_TEAMMATES"),
  [net.DC_KICK_VOTE] = loc("ConnErr/DC_KICK_VOTE"),
  [net.DC_COMPLAINTS] = loc("ConnErr/DC_COMPLAINTS"),
})

function setNotInBattle(){
  isCheckRequired.set(false)
  if (isRealBattleStarted.get())
    return
  isInBattleStateSet(false)
}

if (isCheckRequired.get()){
  resetTimeout(JoiningWatchdogTime, setNotInBattle)
}

function isInBattleStateUpdate(is_in_battle) {
  isInBattleStateSet(is_in_battle)
  clearMemoizeCaches()
  if (is_in_battle) {
    isCheckRequired.set(true)
    resetTimeout(JoiningWatchdogTime, setNotInBattle)
  }
  else{
    isCheckRequired.set(false)
    clearTimer(setNotInBattle)
  }
  return isInBattleState
}

function loadingWatchdog(){
  log("Loading time WATCHDOG check")
  let llst = levelLoadingStartedTime.get()
  if (levelLoaded.get() || !levelIsLoading.get() || llst <=0) {
    log("Loading time WATCHDOG: game loaded!!")
    clearTimer(loadingWatchdog)
    return
  }
  let now = get_time_msec()
  let queueLength = get_pipeline_compilation_queue_length()
  if (queueLength > 0 && queueLength < prevPipelineQueue)
    pipelineGraceDeadline = min(llst + LoadingWatchdogMaxTimeMs, now + PipelineCompilationGraceMs)
  prevPipelineQueue = queueLength

  if (max(llst + LoadingWatchdogTimeMs, pipelineGraceDeadline) <= now) {
    logerr($"Loading time: took too much time, pipeline compilation queue = {queueLength}")
    clearTimer(loadingWatchdog)
    levelLoadingStartedTime.set(-1)
    let playerEid = localPlayerEid.get()
    if ( playerEid != ecs.INVALID_ENTITY_ID) {
      ecs.g_entity_mgr.sendEvent(playerEid, CmdGetDebriefingResult())
      if (net.has_network()) {
        sendNetEvent(playerEid, CmdGetBattleResult())
      }
    }
    defer(switch_to_menu_scene)
    isInBattleStateUpdate(false)
    showMsgbox(loc("ConnErr/UNKNOWN")) 
  }
}

function setLoadingWatchDog(isLoading=false) {
  log($"set loading time WATCHDOG, isLoading = {isLoading}, levelIsLoading.get() = {levelIsLoading.get()}" )
  if (isLoading) {
    log("loading time WATCHDOG: start")
    clearTimer(loadingWatchdog)
    setInterval(1, loadingWatchdog)
    if (levelLoadingStartedTime.get()<=0)
      levelLoadingStartedTime.set(get_time_msec())
  }
  else if (!isLoading) {
    log("loading time WATCHDOG: stop")
    clearTimer(loadingWatchdog)
    levelLoadingStartedTime.set(-1)
  }
}

ecs.register_es(
  "script_game_launcher_es",
  {
    [EventSwitchToMenu] = @(_evt, _eid, _comp) switch_to_menu_scene(),
    [EventGameSessionFinished] = function() {
      isInBattleStateUpdate(false)
      setLoadingWatchDog(false)
      isRealBattleStartedSet(false)
    },
    [EventGameSessionStarted] = function() {
      levelIsLoading.set(true)
      setLoadingWatchDog(true)
      isInBattleStateUpdate(true)
      isRealBattleStartedSet(true)
    },
    [EventOnDisconnectedFromServer] = function onDisconnectedFromServer(evt, _eid, _comp) {
      isRealBattleStartedSet(false)
      setLoadingWatchDog(false)
      switch_to_menu_scene()
      isInBattleStateUpdate(false)

      let err_code = evt[0]
      let msgText = loc("network/disconnect_message").subst({
        err = connErrMessages?[err_code] ?? loc("ConnErr/UNKNOWN")
      })
      if (err_code == net.DC_COMPLAINTS)
        logOut()
      showMsgbox(msgText)
    },
  }
)

if (levelIsLoading.get()) {
  clearTimer(loadingWatchdog)
  setInterval(1, loadingWatchdog)
}

ecs.register_es("level_is_loading_ui_es",
  {
    [["onChange","onInit"]] = function(_eid, comp) {
      let isLoading = comp["level_is_loading"]
      setLoadingWatchDog(isLoading)
      levelIsLoading.set(isLoading)
    }
    onDestroy = function(...) {
      levelIsLoading.set(false)
      clearTimer(loadingWatchdog)
    }
  },
  {comps_track = [["level_is_loading", ecs.TYPE_BOOL]]}
)

function refresh() {
  refreshUserstats()
  forceRefreshUnlocks()
}

function levelLoadedSet(v) {
  levelLoaded.set(v)
  if (v) {
    if (!firstLoadingOfMainMenu)
      gui_scene.resetTimeout(1.0, refresh)
    setIsInMainMenuState(!isInBattleState.get())
  }
  else {
    gui_scene.clearTimer(refresh)
    setIsInMainMenuState(false)
  }
}

ecs.register_es("level_state_ui_es",
  {
    [["onChange","onInit"]] = function(_eid, comp)  {
      let lvlLoaded = comp["level__loaded"]
      levelLoadedSet(lvlLoaded)
      if (lvlLoaded) {
        setLoadingWatchDog(false)
      }
      else {
        setLoadingWatchDog(true)
      }
    }
    onDestroy = function(...) {
      levelLoadedSet(false)
      setLoadingWatchDog(true)
    }
  },
  {comps_track = [["level__loaded", ecs.TYPE_BOOL]]}
)


return {
  uiDisabled
  dbgLoading
  isInBattleState
  isInBattleStateUpdate
  isInMainMenuState

  levelIsLoading,
  levelLoaded,
  currentLevelBlk
}
