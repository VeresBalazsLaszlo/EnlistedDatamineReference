import "%dngscripts/ecs.nut" as ecs
from "net" import get_sync_time
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/hud/state/player_state_es.nut" import localPlayerNamePrefixIcon
from "%ui/hud/state/local_player.nut" import localPlayerName, localPlayerTeam
from "dasevents" import EventTeamRoundResult, EventTeamTokens, EventSaveZombieModeBattleTime, CmdGetDebriefingResult, broadcastNetEvent
from "%ui/helpers/remap_nick.nut" import remap_nick
from "app" import get_session_id
from "%ui/state/missionParams.nut" import missionParams
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/ui_library.nut" import *

let battleResult = nestWatched("battle_result", null)
let teamTokens = nestWatched("team_tokens", -1)
let battleTimeOfZombieMode = nestWatched("battleTimeOfZombieMode", -1)

let psnMatchIdQuery = ecs.SqQuery("psnMatchInfoQuery", {comps_ro=[["psn_external_match_id", ecs.TYPE_STRING]]})
let getPsnMatchId = @() psnMatchIdQuery.perform(@(_, comp) comp.psn_external_match_id) ?? ""

let teamComps = {
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__winSubtitle", ecs.TYPE_STRING],
    ["team__loseSubtitle", ecs.TYPE_STRING],
    ["team__deserterSubtitle", ecs.TYPE_STRING, ""],
    ["team__winTitle", ecs.TYPE_STRING],
  ]
}

let teamsQuery = ecs.SqQuery("debriefingTeamQuery", teamComps)

let objectiveTokensQuery = ecs.SqQuery("objectiveTokensQuery", {
  comps_rq = ["localPlayer"]
  comps_ro = [["player__objectiveTokens", ecs.TYPE_INT, -1]]
})

let isZombieEventQuery = ecs.SqQuery("debriefingIsZombieEventQuery", {
  comps_rq = ["zombie_travel_mode"]
})

let isGunGameEventQuery = ecs.SqQuery("debriefingIsGunGameQuery", {
  comps_rq = ["gun_game__levelsCount"]
})


enum STATUS {
  WIN,
  LOSE,
  FINISHED_EARLY,
  DESERTER
}

let langsByStatus = {
  [STATUS.WIN]        = { titleLocId = "debriefing/victory", subtitleCompId = "team__winSubtitle"},
  [STATUS.LOSE]       = { titleLocId = "debriefing/defeat", subtitleCompId = "team__loseSubtitle"},
  [STATUS.FINISHED_EARLY] = { titleLocId = "debriefing/finished_early" },
  [STATUS.DESERTER]   = { titleLocId = "debriefing/deserter", subtitleCompId = "team__deserterSubtitle"},
}














function setResult(comp, status) {
  let result = {
    status = status
    title = loc(langsByStatus[status].titleLocId)
    subtitle = loc(comp?[langsByStatus[status]?.subtitleCompId]) ?? ""
    success = status == STATUS.WIN
    fail = status == STATUS.LOSE
    deserter = status == STATUS.DESERTER
    finishedEarly = status == STATUS.FINISHED_EARLY
    time = get_sync_time()
    who = status == STATUS.WIN ? loc(comp["team__winTitle"]) : ""
  }

  local isZombieEvent = false
  isZombieEventQuery.perform(function(_eid, _comp) {
    isZombieEvent = true
  })

  local isGunGameEvent = false
  isGunGameEventQuery.perform(function(_eid, _comp) {
    isGunGameEvent = true
  })

  if (isZombieEvent) {
    local tokens = teamTokens.get()
    local objectiveTokens = -1
    objectiveTokensQuery.perform(function(_eid, plComp) {
      objectiveTokens = plComp["player__objectiveTokens"]
    })
    let popupInfo = []

    local maxBattleTime = battleTimeOfZombieMode.get() > 0 ? battleTimeOfZombieMode.get() : get_sync_time()
    popupInfo.append({
      statTxt = loc("debriefing/awards/battleTime")
      statVal = secondsToStringLoc(maxBattleTime)
    })
    if (objectiveTokens >= 0) {
      popupInfo.append({
        statTxt = loc("debriefing/awards/objective_tokens")
        statVal = objectiveTokens
      })
      result.objectiveTokens <- objectiveTokens
    }
    if (tokens >= 0) {
      popupInfo.append({
        statTxt = loc("debriefing/awards/tokens")
        statVal = tokens
      })
      result.tokens <- tokens
      result.popupInfo <- popupInfo
    }
  }

  battleResult.set({
    sessionId = get_session_id()
    psnMatchId = getPsnMatchId() ?? ""
    playerName = remap_nick(localPlayerName.get())
    playerNamePrefixIcon = localPlayerNamePrefixIcon.get()
    missionName = missionParams.get().name
    missionType = missionParams.get().type
    missionId = missionParams.get().missionId
    result
    isTeamsUnitedInStatistics = isGunGameEvent
    isAllEnemiesInStatistics  = isGunGameEvent
    isSquadsProgressHidden    = isGunGameEvent
  })
}

function onTeamRoundResult(evt, _eid, comp) {
  if (localPlayerTeam.get() != evt.team || localPlayerTeam.get() != comp["team__id"])
    return

  let status = evt.isWon
    ? STATUS.WIN
    : STATUS.LOSE
  log($"[DEBRIEFING] Receive battle result via onTeamRoundResult, status:{status}")
  setResult(comp, status)
}

function onGetBattleResult(_evt, _eid, playerComp) {
  let status = playerComp["scoring_player__isGameFinished"]
    ? STATUS.FINISHED_EARLY
    : STATUS.DESERTER
  teamsQuery.perform(
    function(_eid, comp) {
      if (localPlayerTeam.get() != comp["team__id"])
        return

      log($"[DEBRIEFING] Receive battle result via onGetBattleResult, status:{status}")
      setResult(comp, status)
    })
}

ecs.register_es("roundresult_debriefing_es",
  {
    [EventTeamRoundResult] = onTeamRoundResult,
  },
  teamComps
)

function onGetTeamTokens(evt, _eid, _comps) {
  teamTokens.set(evt.tokens)
}

function onGetZombieModeBattleTime(evt, _eid, _comp) {
  battleTimeOfZombieMode.set(evt.battleTime)
}

ecs.register_es("team_tokens_es",
  {
    onInit = function(_eid, _comp) {
      teamTokens.set(0)
      battleTimeOfZombieMode.set(-1)
    },
    [EventTeamTokens] = onGetTeamTokens,
    [EventSaveZombieModeBattleTime] = onGetZombieModeBattleTime
  },
  {
    comps_rq = ["zombie_travel_mode"]
  }
)

ecs.register_es("deserter_debriefing_es",
  {
    [CmdGetDebriefingResult] = onGetBattleResult,
  },
  {
    comps_rq = ["player"]
    comps_ro = [["scoring_player__isGameFinished", ecs.TYPE_BOOL, false]]
  })

console_register_command(function() {
  broadcastNetEvent(EventTeamRoundResult({ team = localPlayerTeam.get(), isWon = true }))
}, "ui.broadcast_win")

console_register_command(function() {
  broadcastNetEvent(EventTeamRoundResult({ team = localPlayerTeam.get(), isWon = false }))
}, "ui.broadcast_defeat")

return battleResult
