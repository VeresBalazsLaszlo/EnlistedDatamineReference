from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/hud/menus/game_menu.nut" import showGameMenu
from "%ui/hud/state/interactive_state.nut" import hudIsInteractive
from "%ui/hud/menus/controls_setup.nut" import showControlsMenu
from "%ui/components/msgbox.nut" import hasMsgBoxes
from "%ui/components/modalWindows.nut" import hasModalWindows
from "%ui/hud/menus/players.nut" import showPlayersMenu
from "%ui/hud/state/respawnState.nut" import needSpawnMenu
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *

let isCursorNeeded = Computed(@() hudIsInteractive.get()
  || showGameMenu.get() || showSettingsMenu.get()
  || showControlsMenu.get() || hasMsgBoxes.get() || hasModalWindows.get()
  || showPlayersMenu.get() || needSpawnMenu.get()
  || (debriefingShow.get() && !isInBattleState.get())
)

return {
  isCursorNeeded
}