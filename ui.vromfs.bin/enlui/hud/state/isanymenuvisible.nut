from "%ui/hud/menus/game_menu.nut" import showGameMenu
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/hud/menus/controls_setup.nut" import showControlsMenu
from "%ui/hud/menus/game_menu_items.nut" import showExitGameMenu, showSuicideMenu
from "%ui/hud/state/respawnState.nut" import needSpawnMenu
from "%ui/ui_library.nut" import *

return Computed(@() showGameMenu.get()
  || showSettingsMenu.get()
  || showControlsMenu.get()
  || showSuicideMenu.get()
  || showExitGameMenu.get()
  || needSpawnMenu.get())