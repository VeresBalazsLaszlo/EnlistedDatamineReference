import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/scoring_players.nut" as scoringPlayers
import "%ui/hud/state/friendly_fire_can_forgive_state.nut" as canForgivePlayers
import "%ui/hud/components/mkScoresStatistics.nut" as mkScoresStatistics
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontBody
from "team" import TEAM_UNASSIGNED, FIRST_GAME_TEAM
from "%ui/hud/state/teams.nut" import teams
from "%ui/components/std.nut" import lightgray
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid, localPlayerGroupId, localPlayerUserId, localPlayerGroupMembers, localPlayerIsInActiveOpenGroup
from "%ui/hud/state/team_scores.nut" import myScore, enemyScore, anyTeamFailTimer
from "%ui/hud/state/capZones.nut" import visibleZoneGroups, whichTeamAttack
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/state/missionParams.nut" import missionParams
from "%ui/hud/state/interactive_state.nut" import removeInteractiveElement, hudIsInteractive, switchInteractiveElement
from "%ui/state/safeArea.nut" import safeAreaVerPadding
from "%ui/hud/components/capzone.nut" import capzoneWidget
from "%enlSqGlob/missionType.nut" import getMissionType, MissionType
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "app" import get_session_id
from "%ui/components/uiHotkeysHint.nut" import mkHintRow
from "%ui/components/controlHudHint.nut" import controlHudHint
from "%ui/control/active_controls.nut" import isGamepad
from "matching.errors" import INVALID_USER_ID
from "dasevents" import sendNetEvent, CmdVoteToKick
from "%ui/hud/state/vote_kick_state.nut" import voteToKickEnabled
from "%ui/hud/state/replay_state.nut" import isReplay
from "videomode" import set_frame_generation_suppressed
from "%ui/hud/state/gun_game_state.nut" import isGunGameMode
from "%ui/contacts/contactsWatchLists.nut" import friendsUids
from "%ui/ui_library.nut" import *

let showScores = mkWatched(persist, "showScores", false)
let teamsSlotsQuery = ecs.SqQuery("teamsSlotsQuery", {comps_ro = [["teamsSlots", ecs.TYPE_INT_LIST]]})
let getTeamsSlots = @() teamsSlotsQuery.perform(@(_eid, comp) comp.teamsSlots.getAll().map(@(v) v+FIRST_GAME_TEAM))

function getScoresTeams() {
  let teamsV = {}
  foreach (team in teams.get())
    if ((team?["team__id"] ?? TEAM_UNASSIGNED) != TEAM_UNASSIGNED)
      teamsV[team["team__id"].tostring()] <- {
        armyId = team?["team__armyId"]
        teamId = team["team__id"]
        armies = team?["team__armies"]
      }

  return teamsV
}

let titleText = {
  size = FLEX_H
  rendObj = ROBJ_TEXT
}.__update(fontBody)

let zoneParams = {
  customBack = @(_v) null
  canHighlight = false
  animAppear = []
  animActive = []
  margin = 0
}

function mkTeamScore(isMyTeam) {
  let scoreWatch = isMyTeam ? myScore : enemyScore
  let isDefend = Computed(@() whichTeamAttack.get() != -1
    && (whichTeamAttack.get() == localPlayerTeam.get()) != isMyTeam)
  let halign = isMyTeam ? ALIGN_LEFT :ALIGN_RIGHT
  return function() {
    let showMyTeamScores = getMissionType() == MissionType.ASSAULT
    if (showMyTeamScores || !isDefend.get())
      return titleText.__merge({
        watch = [scoreWatch, isDefend]
        halign = halign
        text = scoreWatch.get() == null ? null
          : loc("teamHeader/score", { score = (1000.0 * scoreWatch.get() + 0.5).tointeger() })
      })

    return {
      watch = [visibleZoneGroups, isDefend]
      size = FLEX_H
      halign = halign
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = visibleZoneGroups.get().reduce(@(res, v) res.extend(v), [])
        .map(@(zEid) capzoneWidget(zEid, zoneParams))
    }
  }
}

let mkCapzoneTimer = @() titleText.__merge({
  halign = ALIGN_CENTER
  color = lightgray
  text = anyTeamFailTimer.get() > 0 ? secondsToStringLoc(anyTeamFailTimer.get()) : loc("multiplayerscores/title")
  watch = anyTeamFailTimer
})

let title = {
  size = const [FLEX, hdpx(40)]
  valign = ALIGN_CENTER
  children = [
    mkTeamScore(true)
    mkCapzoneTimer
    mkTeamScore(false)
  ]
}

const interactiveKey = "scores"
let eventHandlers = {
  ["HUD.Interactive"] = function onHudInteractive(_event) {
    switchInteractiveElement(interactiveKey)
  },
  ["HUD.Interactive:end"] = function onHudInteractiveEnd(event) {
    if (showScores.get() && ((event?.dur ?? 0) > 500 || event?.appActive == false)){
      removeInteractiveElement(interactiveKey)
    }
  }
}
showScores.subscribe(function(v) {
  set_frame_generation_suppressed(v)
  if (!v)
    removeInteractiveElement(interactiveKey)
})

let hintTextFunc = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = DEFAULT_TEXT_COLOR
}.__update(fontBody)

function makeHintRow(hotkeys, text) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [mkHintRow(hotkeys,{textFunc=hintTextFunc})].append(hintTextFunc(text))
  }
}

const HUD_INTERACTIVE_HOTKEY = "HUD.Interactive"

function mkHudHint() {
  return @() {
    watch = hudIsInteractive
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(3)
    children = [
      controlHudHint({
        id = HUD_INTERACTIVE_HOTKEY
        height = ph(100)
      }),
      hintTextFunc(hudIsInteractive.get() ? loc("scoring/nonInteractiveMode") : loc("scoring/interactiveMode"))
    ]
  }
}

let interactiveTip = @() {
  watch = [isGamepad, hudIsInteractive, isReplay]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = fsh(2.5)
  size = const [FLEX, fontH(250)]

  children = !isReplay ? [
                mkHudHint(),
                hudIsInteractive.get()
                  ? makeHintRow($"^{JB.A} | M:0", loc("ui/cursor.activate"))
                  : null,
                hudIsInteractive.get() && isGamepad.get()
                  ? makeHintRow("^J:L.Thumb.hv", loc("ui/cursor.navigation"))
                  : null
              ]
            : localPlayerIsInActiveOpenGroup.get() ? hintTextFunc(loc("scoring/currentPlayerInOpenGroup"))
            : null
}
function mkContextMenuButton(playerData) {
  let buttons = []
  let userid = playerData.player?.userid ?? INVALID_USER_ID
  let canKick = (voteToKickEnabled.get()
    && !playerData.isLocal
    && !playerData.disconnected
    && !playerData.roomOwner
    && playerData.isAlly
    && userid != INVALID_USER_ID)
  if (canKick)
    buttons.append({
      text = loc("btn/vote_to_kick")
      action = function(_playerUid) {
        showScores.set(false)
        sendNetEvent(localPlayerEid.get(), CmdVoteToKick({
          voteYes=true
          accused=playerData.eid
        }))
      }
    })
  return buttons
}

function scoresMenuUi() {
  return {
    size = FLEX
    halign = ALIGN_CENTER
    padding = [safeAreaVerPadding.get() + fsh(5), 0, safeAreaVerPadding.get(), 0]
    flow = FLOW_VERTICAL
    eventHandlers = eventHandlers
    watch = [
      scoringPlayers, localPlayerTeam, localPlayerEid, isReplay, missionParams,
      hudIsInteractive, safeAreaVerPadding, localPlayerGroupMembers, canForgivePlayers,
      voteToKickEnabled, friendsUids, isGunGameMode
    ]
    behavior = DngBhv.ActivateActionSet
    actionSet = "Scores"
    sound = {
      attach = "ui/stat_on"
      detach = "ui/stat_off"
    }
    children = [
      { size = const [0, flex(1)] }
      mkScoresStatistics(scoringPlayers.get(), {
        localPlayerEid = localPlayerEid.get()
        localPlayerGroupId = localPlayerGroupId.get()
        localPlayerUserId = localPlayerUserId.get()
        localPlayerGroupMembers = localPlayerGroupMembers.get()
        canForgivePlayers = canForgivePlayers.get()
        myTeam = isReplay.get() ? 1 : localPlayerTeam.get()
        teams = getScoresTeams()
        sessionId = get_session_id()
        title = isGunGameMode.get() ? null : title
        showBg = true
        scrollIsPossible = true
        interactiveTip = interactiveTip
        isInteractive = hudIsInteractive.get() || isReplay.get()
        showDisconnected = true
        teamsSlots = getTeamsSlots()
        hotkeys = [[$"^{JB.B} | Esc", {
          action = @() showScores.set(false)
          description = loc("Close"),
          inputPassive = true
        }]]
        mkContextMenuButton = mkContextMenuButton
        isReplay = isReplay.get()
        missionType = missionParams.get().type
        isTeamsUnited = isGunGameMode.get()
        isAllEnemies = isGunGameMode.get()
        friends = friendsUids.get()
      })
      { size = const [0, flex(3)] }
    ]
  }
}

return {
  showScores
  scoresMenuUi
}
