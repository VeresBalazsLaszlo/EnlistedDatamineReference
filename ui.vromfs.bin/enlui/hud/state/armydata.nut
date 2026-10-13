import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/offline_mode.nut" import disableMenu, app_is_offline_mode
from "%enlSqGlob/sqevents.nut" import CmdSetMySquadsData, mkCmdDevSquadsData, mkCmdGetMySquadsData, mkCmdTutorialSquadsData, mkCmdProfileJwtData
from "net" import has_network
from "eventbus" import eventbus_send, eventbus_subscribe
from "%ui/hud/state/teams.nut" import localPlayerTeamArmies
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/state/custom_profile.nut" import customProfile
from "ecs.netevent" import client_request_unicast_net_sqevent
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/ui_library.nut" import *
from "%ui/matchingClient.nut" import matchingCall
import "%ui/userstats/serverTime.nut" as serverTime


let logAd = with_prefix("[ARMY_DATA] ")

let isSandbox = app_is_offline_mode()
let devArmiesData = isSandbox ? require_optional("%enlSqGlob/data/sandbox_profile.nut") ?? {}
                              : require_optional("%enlisted_pkg_dev/game/data/dev_profile_full.nut") ?? {}

let armiesData = mkWatched(persist, "armiesData")
let armyId = mkWatched(persist, "armyId", "")


eventbus_subscribe("updateArmiesData", function(data) {
  logAd("Received army data")
  armiesData.set(data)
})

let profilesMap = {
  real = function(armies, playerEid) {
    logAd($"send real profile for {playerEid} armies:", armies)
    eventbus_send("requestArmiesData", { armies, playerEid })
  }

  composite = function(armies, playerEid) {
    logAd($"send composite profile for {playerEid} armies:", armies)
    eventbus_send("requestArmiesData", { armies, playerEid })
  }

  dev = function(_armies, playerEid) {
    logAd($"send dev profile for {playerEid}")
    
    ecs.client_send_event(playerEid, mkCmdDevSquadsData({jwt=""}))
  }

  tutorial = function(_armies, playerEid) {
    logAd($"send tutorial profile for {playerEid}")
    ecs.client_send_event(playerEid, mkCmdTutorialSquadsData({jwt=""}))
  }

  custom = function(_armies, playerEid) {
    logAd($"send custom profile for {playerEid}")
    ecs.client_send_event(playerEid, mkCmdProfileJwtData({jwt=""}))
  }
}

let profileType = Computed(function() {
  let { path = "", isJoined = false } = customProfile.get()
  if (path != "")
    return isJoined ? "composite" : "custom"

  return isTutorial.get() ? "tutorial"
    : disableMenu ? "dev"
    : "real"
})

wlog(profileType, "[ARMY_DATA] profileType changed to")

let requestArmiesCb = Computed(@() profilesMap?[profileType.get()])

let playerArmiesReceivedQuery = ecs.SqQuery("playerArmiesReceivedQuery",
  { comps_ro = [["isArmiesReceived", ecs.TYPE_BOOL]] })

let isArmiesReceived = @(playerEid)
  playerArmiesReceivedQuery(playerEid, @(_, comp) comp.isArmiesReceived) ?? false

function requestMySquadsDataFromDedicated() {
  let playerEid = localPlayerEid.get()
  if (has_network()) {
    logAd($"Request army data from online dedicated for {playerEid}")
     
    client_request_unicast_net_sqevent(playerEid, mkCmdGetMySquadsData({ a = false }))
  }
  else {
    logAd($"Request army data from local dedicated for {playerEid}")
    ecs.g_entity_mgr.sendEvent(playerEid, mkCmdGetMySquadsData({}))
  }
}

let calcArmiesData = keepref(Computed(function(prev) {
  let res = {
    teamArmies = localPlayerTeamArmies.get()
    playerEid = localPlayerEid.get()
    requestCb = requestArmiesCb.get()
  }
  return prev != FRP_INITIAL && isEqual(res, prev) ? prev : res
}))

function calcArmies(data) {
  logAd("Updated by", data)
  let { teamArmies, playerEid, requestCb } = data

  logAd("Try to calc armies teamArmies:", teamArmies, $"playerEid: {playerEid}, type: {profileType.get()}")
  if (teamArmies.len() == 0 || playerEid == ecs.INVALID_ENTITY_ID || requestCb == null)
    return

  if (isArmiesReceived(playerEid))
    requestMySquadsDataFromDedicated()
  else {
    logAd($"Request army data from profile server for armies:", teamArmies)
    requestCb(teamArmies, playerEid)
  }
}
calcArmiesData.subscribe(calcArmies)

function onSetMySquadsData(evt, _eid, comp) {
  if (!comp.is_local)
    return
  logAd("Received army data from dedicated")
  armiesData.set(evt.data)
}

ecs.register_es("player_army_id_es", {
  [["onInit", "onChange"]] = function(_eid, comp) {
    let { is_local, army } = comp
    if (is_local) {
      armyId.set(army)
      matchingCall("mpresence.set_presence", null, {
        army, sTime = serverTime.get()
      })
    }
  },
  [CmdSetMySquadsData] = onSetMySquadsData
}, {
  comps_track = [["is_local", ecs.TYPE_BOOL], ["army", ecs.TYPE_STRING]]
  comps_rq = ["player"]
})

console_register_command(requestMySquadsDataFromDedicated, "debug.updateArmyDataFromDedicated")

return Computed(@() isReplay.get() ? {}
  : armiesData.get()?[armyId.get()] ?? devArmiesData?[armyId.get()] ?? {})
