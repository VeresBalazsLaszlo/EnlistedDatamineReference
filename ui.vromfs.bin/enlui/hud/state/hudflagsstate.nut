from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/hud/state/respawnState.nut" import showSquadSpawn
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud, showSelfAwards, showTips, showGameModeHints, showPlayerUI
from "%ui/hud/menus/big_map.nut" import showBigMap
from "%ui/hud/replay/replayState.nut" import canShowGameHudInReplay
from "%ui/hud/state/tutorial_input_state_es.nut" import tutorialPlaneShootEnable
from "%ui/ui_library.nut" import *

const HUD_BIT_FULL = 1
const HUD_BIT_MINIMAL = 2 
const HUD_BIT_SHOW_AWARDS = 3
const HUD_BIT_NO_BIG_MAP = 4
const HUD_BIT_NO_HARDCORE = 5 
const HUD_BIT_NO_MINIMALIST = 6 
const HUD_BIT_NO_SQUAD_SPAWN = 7
const HUD_BIT_SQUAD_SPAWN = 8
const HUD_BIT_TUTORIAL = 9
const HUD_BIT_PLAYER = 10
const HUD_BIT_REPLAY = 11
const HUD_BIT_NO_REPLAY = 12
const HUD_BIT_GAME_HUD = 13
const HUD_BIT_NO_TUTORIAL = 14
const HUD_BIT_SHOW_TIPS = 15
const HUD_BIT_SHOW_GAME_MODE_HINTS = 16
const HUD_BIT_PLAYER_UI = 17
const HUD_BIT_VEHICLE_CROSSHAIR = 18

let HUD_FLAGS = {
  FULL = 1 << HUD_BIT_FULL
  MINIMAL = 1 << HUD_BIT_MINIMAL
  SHOW_AWARDS = 1 << HUD_BIT_SHOW_AWARDS
  NO_BIG_MAP = 1 << HUD_BIT_NO_BIG_MAP
  NO_HARDCORE = 1 << HUD_BIT_NO_HARDCORE
  NO_MINIMALIST = 1 << HUD_BIT_NO_MINIMALIST
  NO_SQUAD_SPAWN = 1 << HUD_BIT_NO_SQUAD_SPAWN
  SQUAD_SPAWN = 1 << HUD_BIT_SQUAD_SPAWN
  TUTORIAL = 1 << HUD_BIT_TUTORIAL
  PLAYER = 1 << HUD_BIT_PLAYER
  REPLAY = 1 << HUD_BIT_REPLAY
  NO_REPLAY = 1 << HUD_BIT_NO_REPLAY
  GAME_HUD = 1 << HUD_BIT_GAME_HUD
  NO_TUTORIAL = 1 << HUD_BIT_NO_TUTORIAL
  SHOW_TIPS = 1 << HUD_BIT_SHOW_TIPS
  SHOW_GAME_MODE_HINTS = 1 << HUD_BIT_SHOW_GAME_MODE_HINTS
  PLAYER_UI = 1 << HUD_BIT_PLAYER_UI
  VEHICLE_CROSSHAIR = 1 << HUD_BIT_VEHICLE_CROSSHAIR
}

let minHud = keepref(Computed(@() forcedMinimalHud.get() || minimalistHud.get()))
let showHuds = Computed(@() !(!isAlive.get() || debriefingShow.get()))

let hudFlags = Computed(@() (!minHud.get()).tointeger() << HUD_BIT_FULL
  | minHud.get().tointeger() << HUD_BIT_MINIMAL
  | showSelfAwards.get().tointeger() << HUD_BIT_SHOW_AWARDS
  | (!showBigMap.get()).tointeger() << HUD_BIT_NO_BIG_MAP
  | (!forcedMinimalHud.get()).tointeger() << HUD_BIT_NO_HARDCORE
  | (!minimalistHud.get()).tointeger() << HUD_BIT_NO_MINIMALIST
  | (!showSquadSpawn.get()).tointeger() << HUD_BIT_NO_SQUAD_SPAWN
  | showSquadSpawn.get().tointeger() << HUD_BIT_SQUAD_SPAWN
  | isTutorial.get().tointeger() << HUD_BIT_TUTORIAL
  | showHuds.get().tointeger() << HUD_BIT_PLAYER
  | isReplay.get().tointeger() << HUD_BIT_REPLAY
  | (!isReplay.get()).tointeger() << HUD_BIT_NO_REPLAY
  | (!isReplay.get() || canShowGameHudInReplay.get()).tointeger() << HUD_BIT_GAME_HUD
  | (!isTutorial.get()).tointeger() << HUD_BIT_NO_TUTORIAL
  | showTips.get().tointeger() << HUD_BIT_SHOW_TIPS
  | showGameModeHints.get().tointeger() << HUD_BIT_SHOW_GAME_MODE_HINTS
  | showPlayerUI.get().tointeger() << HUD_BIT_PLAYER_UI
  | tutorialPlaneShootEnable.get().tointeger() << HUD_BIT_VEHICLE_CROSSHAIR)

return {
  HUD_FLAGS
  hudFlags
}
