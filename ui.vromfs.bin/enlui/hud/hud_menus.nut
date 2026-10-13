import "%ui/hud/pieMenu.ui.nut" as pieMenu
import "%ui/hud/huds/squad_soldiers_menu.ui.nut" as squadSoldiersMenu
import "%ui/hud/huds/overlays/enlisted_briefing.nut" as briefing
import "dainput2" as dainput
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/offline_mode.nut" import disableMenu
from "%ui/hud/chat.ui.nut" import showChatInput
from "%ui/hud/state/briefingState.nut" import showBriefing
from "%ui/hud/menus/players.nut" import playersMenuUi, showPlayersMenu
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/ct_hud_menus.nut" import hudMenus, openMenu
from "%ui/hud/huds/scores.nut" import scoresMenuUi, showScores
from "%ui/hud/menus/big_map.nut" import showBigMap, bigMap
from "%ui/hud/state/pie_menu_state.nut" import showPieMenu, pieMenuLayer
from "%ui/hud/state/building_tool_menu_state.nut" import showBuildingToolMenu
from "%ui/hud/state/building_tool_state.nut" import isBuildingToolMenuAvailable
from "%ui/hud/state/squad_soldiers_menu_state.nut" import showSquadSoldiersMenu, isSquadSoldiersMenuAvailable
from "%ui/hud/state/paratroopers_supply_menu_state.nut" import showSupplyMenu
from "%ui/hud/state/vehicle_repair_menu_state.nut" import showRepairMenu
from "%ui/hud/menus/artillery_menu.nut" import showArtilleryMenu
from "%ui/hud/state/hudOptionsState.nut" import showBattleChat, forceDisableBattleChat
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/control/active_controls.nut" import isGamepad
from "dasevents" import CmdResetDigitalActionStickyToggle
from "%ui/hud/menus/artillery_radio_map.nut" import artilleryMap, showArtilleryMap
from "%ui/debriefing/debriefingState.nut" import debriefingShow, debriefingData
from "%ui/hud/state/gun_game_state.nut" import isGunGameMode
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/hud/menus/controls_setup.nut" import showControlsMenu
from "videomode" import set_frame_generation_suppressed
from "%ui/ui_library.nut" import *
from "types" import Function

let buildingToolMenu = require("%ui/hud/huds/building_tool_menu.ui.nut")
let supplyMenu = require("%ui/hud/huds/paratroopers_supply_menu.ui.nut")
let repairMenu = require("%ui/hud/huds/vehicle_repair_menu.ui.nut")
let { artilleryMenu } = require("%ui/hud/menus/artillery_menu.nut")
let debriefing = require("%ui/hud/menus/mk_debriefing.nut")(debriefingData)


function openBuildingToolMenu() {
  if (isBuildingToolMenuAvailable.get())
    showBuildingToolMenu.set(true)
}

function openCommandsMenu(layer) {
  if (!isReplay.get() && isAlive.get() && !isGunGameMode.get()){
    showPieMenu.set(true)
    pieMenuLayer.set(layer)
  }
}

function openSquadSoldiersMenu() {
  if (isSquadSoldiersMenuAvailable.get())
    showSquadSoldiersMenu.set(true)
}

isSquadSoldiersMenuAvailable.subscribe(function(isAvailable) {
  if (!isAvailable)
    showSquadSoldiersMenu.set(false)
})

let isUIShown = keepref(Computed(@() showChatInput.get() || showBriefing.get() || showBigMap.get()
  || showPieMenu.get() || showBuildingToolMenu.get() || showSquadSoldiersMenu.get()
  || showSupplyMenu.get() || showRepairMenu.get() || showBattleChat.get()
  || showArtilleryMenu.get() || showArtilleryMap.get() || showPlayersMenu.get() || showScores.get()
  || debriefingShow.get() || showSettingsMenu.get() || showControlsMenu.get()))
isUIShown.subscribe(@(v) set_frame_generation_suppressed(v))

let groups = {
  debriefing = 1
  gameHud   = 3
  chatInput = 4
  pieMenu   = 5
}
let showChatInputAct = Computed(@() !forceDisableBattleChat.get() && showChatInput.get())
let showPieMenuAct = Computed(@() showPieMenu.get() && !isReplay.get() && isAlive.get())

let huds = [
  {
    show = showBuildingToolMenu
    menu = buildingToolMenu
    holdToToggleDurMsec = @() isGamepad.get() ? -1 : null
    close = @() showBuildingToolMenu.set(false)
    open = openBuildingToolMenu
    event = "HUD.BuildingToolMenu"
    group = groups.pieMenu
    id = "BuildingToolMenu"
  },
  {
    show = showPieMenuAct,
    open = @() openCommandsMenu(1),
    close = @() showPieMenu.set(false)
    menu = pieMenu
    holdToToggleDurMsec = @() -1
    event = "HUD.CommandsMenu"
    group = groups.pieMenu
    id = "PieMenu"
  },
  {
    show = showPieMenuAct,
    open = @() openCommandsMenu(2),
    close = @() showPieMenu.set(false)
    holdToToggleDurMsec = @() -1
    event = "HUD.QuickChat"
    group = groups.pieMenu
    id = "QuickChat"
  },
  {
    show = showSquadSoldiersMenu
    menu = squadSoldiersMenu
    open = openSquadSoldiersMenu
    holdToToggleDurMsec = @() -1
    close = @() showSquadSoldiersMenu.set(false)
    event = "HUD.SquadSoldiersMenu"
    group = groups.pieMenu
    id = "SquadSoldiersMenu"
  },
  {
    show = showChatInputAct
    open = function() {
      if (showBattleChat.get())
        showChatInput.set(true)
    }
    close = @() showChatInput.set(false)
    event = "HUD.ChatInput"
    group = groups.chatInput
    id = "Chat"
  },
  {
    show = showBriefing
    menu = briefing
    event = "HUD.Briefing"
    group = groups.gameHud
    id = "Briefing"
  },
  {
    show = showArtilleryMap
    menu = artilleryMap
    group = groups.gameHud
    id = "ArtilleryMap"
  },
  {
    show = showSupplyMenu
    menu = supplyMenu
    group = groups.gameHud
    id = "SupplyMenu"
  },
  {
    show = showRepairMenu
    menu = repairMenu
    group = groups.gameHud
    id = "repairMenu"
  },
  {
    show = showArtilleryMenu
    menu = artilleryMenu
    group = groups.gameHud
    id = "artilleryMenu"
  },
  {
    show = showBigMap
    menu = bigMap
    event = "HUD.BigMap"
    group = groups.gameHud
    id = "BigMap"
  },
  {
    show = showPlayersMenu
    menu = playersMenuUi
    group = groups.gameHud
    id = "Players"
  },
  {
    show = showScores
    menu = scoresMenuUi
    event = "HUD.Scores"
    group = disableMenu ? groups.debriefing : groups.gameHud
    id = "Scores"
  },
  {
    show = debriefingShow
    menu = debriefing
    group = groups.debriefing
    id = "Debriefing"
  }
]

function unstickEventWhenHudClosed(menu) {
  if (menu?.event == null || !(isObservable(menu?.show)))
    return
  menu.show.subscribe(function(val) {
    if (!val) {
      ecs.g_entity_mgr.broadcastEvent(CmdResetDigitalActionStickyToggle({
        action = dainput.get_action_handle(menu.event, 0xFFFF)
      }))
    }
  })
}

function unstickEventWhenHudOpenCommandFailed(menu) {
  if (menu?.event == null || !(isObservable(menu?.show)) || !(menu?.open instanceof Function))
    return

  let originOpenFn = menu.open
  menu.open = function() {
    originOpenFn()
    if (!menu.show.get()) {
      ecs.g_entity_mgr.broadcastEvent(CmdResetDigitalActionStickyToggle({
        action = dainput.get_action_handle(menu.event, 0xFFFF)
      }))
    }
  }
}



huds.each(unstickEventWhenHudClosed)
huds.each(unstickEventWhenHudOpenCommandFailed)
hudMenus(huds)

debriefingData.subscribe(function(val) {
  if (val != null && val.len() > 0)
    openMenu("Debriefing")
})
