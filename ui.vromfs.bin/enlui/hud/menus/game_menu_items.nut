import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/allow_squad_change.nut" as allowChangeSquad
import "%ui/hud/state/armyData.nut" as armyData
import "%ui/components/colorize.nut" as colorize
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/offline_mode.nut" import app_is_offline_mode
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "%enlSqGlob/missionType.nut" import getMissionType, MissionType
from "%enlSqGlob/battleParams.nut" import earlyDesertionTime
from "%ui/hud/huds/scores.nut" import showScores
from "%ui/hud/state/briefingState.nut" import showBriefing
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "net" import has_network
from "%ui/hud/menus/players.nut" import showPlayersMenu
from "%dngscripts/platform.nut" import is_sony
from "dagor.system" import DBGLEVEL
from "dasevents" import sendNetEvent, RequestSuicide, CmdSwitchSquad, CmdGetDebriefingResult, CmdGetBattleResult
from "%dngscripts/common_queries.nut" import get_controlled_hero, find_local_player
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/replay/replayState.nut" import canShowReplayHud
from "%ui/hud/replay/replayCinematicState.nut" import isCinemaRecording, setCinemaRecording
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/hud/menus/controls_setup.nut" import showControlsMenu
from "%ui/style/designConst.nut" import attentionTxtColor
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/style/fontsStyle.nut" import fontHeading1, fontBody
from "%ui/hud/state/practice_state.nut" import isPractice
from "eventbus" import eventbus_send
from "%ui/hud/state/time_state.nut" import curTimePerSec as battleTime
from "%ui/hud/state/expScoringConfig.nut" import isDesertionPenaltyEnabled
from "%ui/ui_library.nut" import *

let entity_editor = require_optional("entity_editor")
let isSandboxEditor = @() entity_editor != null && app_is_offline_mode()


const DESERTER_PENALTY_VALUE = -20

let showExitGameMenu = mkWatched(persist, "showExitGameMenu", false)

function exitAction() {
  let playerEid = localPlayerEid.get()
  if (playerEid == ecs.INVALID_ENTITY_ID) {
    switch_to_menu_scene()
    return
  }
  ecs.g_entity_mgr.sendEvent(playerEid, CmdGetDebriefingResult())
  if (has_network()) {
    sendNetEvent(playerEid, CmdGetBattleResult())
    gui_scene.resetTimeout(2.0, switch_to_menu_scene)
  } else
    switch_to_menu_scene()
}

function msgExitBattle() {
  showExitGameMenu.set(true)
  return showMsgbox({
    text = loc("exit_game_confirmation")
    buttons = [
      { text = loc("Yes"), isCurrent = true, action = exitAction }
      { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
    onClose = @() showExitGameMenu.set(false)
  })
}

function msgDesertBattle() {
  showExitGameMenu.set(true)
  let missionType = getMissionType()
  let { hasBadDesertionStats = false } = armyData.get()
  let isDeserter = isDesertionPenaltyEnabled.get() && hasBadDesertionStats
    && (battleTime.get() ?? 0) <= (earlyDesertionTime ?? 0)

  let confirmationText = isDeserter ? loc("exitGame/penalty", {
      number = colorize(attentionTxtColor, $"{DESERTER_PENALTY_VALUE}%")
    }) : loc("exit_game_confirmation")
  return showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      size = FLEX_H
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          size = const [sw(35), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = attentionTxtColor
          text = loc("userLog/battleRes/deserter")
        }.__update(fontHeading1)
        {
          size = const [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = confirmationText
        }.__update(fontBody)
        missionType != MissionType.ZOMBIE_MODE ? null : {
          size = const [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("gameMode/penaltyWarning")
        }.__update(fontBody)
      ]
    }
    buttons = [
      { text = loc("btn/desert"), isCurrent = true, action = exitAction }
      { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
    onClose = @() showExitGameMenu.set(false)
  })
}


let btnExitGame = {
  text = !isSandboxEditor() ? loc("gamemenu/btnExitGame")
    : loc("sandboxeditor/exitSandbox", "Exit Sandbox")
  action = function() {
    if (isSandboxEditor()) {
      eventbus_send("sandbox_editor.quit", null)
      return
    }
    if (isTutorial.get() || isPractice.get()) {
      msgExitBattle()
    }
    else {
      msgDesertBattle()
    }
  }
}

let showSuicideMenu = mkWatched(persist, "showSuicideMenu", false)

let btnSuicide = {
  text = loc("gamemenu/btnSuicide")
  action = function() {
    showSuicideMenu.set(true)
    showMsgbox({
      text = loc("suicide_confirmation")
      buttons = [
        { text=loc("Yes"), action = @() sendNetEvent(get_controlled_hero(), RequestSuicide()) }
        { text=loc("No"), isCurrent = true}
      ]
      onClose = @() showSuicideMenu.set(false)
    })
  }
}


let btnShowScores = {
  text = loc("controls/HUD.Scores")
  action = @() showScores.set(true)
}

let btnBriefing = {
  text = loc("gamemenu/btnBriefing")
  action = @() showBriefing.set(true)
}

let btnChangeSquad = {
  text = loc("gamemenu/btnChangeSquad", "Change Squad")
  action = @() ecs.g_entity_mgr.sendEvent(find_local_player(), CmdSwitchSquad())
  isAvailable = @() allowChangeSquad.get()
}

let btnPlayersInSession = {
  text = loc("Players in session")
  action = @() showPlayersMenu.set(true)
  isAvailable = has_network
}

function msgExitReplay() {
  showExitGameMenu.set(true)
  return showMsgbox({
    text = loc("exit_replay_confirmation")
    buttons = [
      { text = loc("Yes"), action = exitAction }
      { text = loc("No"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
    onClose = @() showExitGameMenu.set(false)
  })
}

let btnExitReplay = {
  text = loc("replay/exitReplay")
  action = msgExitReplay
}

let btnShowReplayHud = {
  text = loc("replay/showReplayUi")
  action = @() canShowReplayHud.set(true)
}

let btnStopRecord = {
  text = loc("replay/btn/stopRecord")
  action = @() showMsgbox({
    text = loc("replay/stopRecord")
    buttons = [
      {
        text = loc("Yes")
        action = @() setCinemaRecording(false)
      }
      {
        text = loc("No")
        isCancel = true
        isCurrent = true
      }
    ]
  })
}

let needAddReplayHudBtn = Computed(@() isReplay.get() && !canShowReplayHud.get())

let btnResume = {
  text = loc("gamemenu/btnResume")
  action = @() true
}
let btnOptions = {
  text = loc("gamemenu/btnOptions")
  action = @() showSettingsMenu.set(true)
}
let btnBindKeys = {
  text = loc("gamemenu/btnBindKeys")
  action = @() showControlsMenu.set(true)
}

let getMenuItems = @() [
  btnResume,
  isCinemaRecording.get() ? btnStopRecord : btnOptions,
  btnBindKeys,
  isReplay.get() || isTutorial.get() ? null : btnSuicide,
  btnChangeSquad,
  btnShowScores,
  (DBGLEVEL > 0 || is_sony) && !isReplay.get() ? btnPlayersInSession : null,
  isReplay.get() ? null : btnBriefing,
  needAddReplayHudBtn.get() ? btnShowReplayHud : null,
  isReplay.get() ? btnExitReplay : btnExitGame
].filter(@(item) item != null && (item?.isAvailable() ?? true))

let menuItemsWatch = [allowChangeSquad, isReplay, isTutorial, needAddReplayHudBtn, isCinemaRecording]

return freeze({
  getMenuItems
  menuItemsWatch
  showExitGameMenu
  showSuicideMenu
  exitAction
  btnExitGame
  btnResume
  btnOptions
  btnBindKeys
})
