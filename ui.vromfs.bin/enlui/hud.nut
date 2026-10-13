import "%ui/hud/huds/vote_kick_menu.ui.nut" as voteToKickMenu
import "%ui/hud/hud_under.nut" as hud_under
import "%ui/hud/huds/enlisted_turret_crosshair.nut" as turretCrosshair
import "%ui/hud/huds/vehicle_crosshair.nut" as vehicleCrosshair
import "%ui/hud/huds/forestall.ui.nut" as forestall
import "%ui/hud/huds/kill_marks.nut" as killMarks
import "%ui/hud/huds/zone_pointers.nut" as zonePointers
import "%ui/hud/huds/resupply_pointers.nut" as resupplyPointers
import "%ui/hud/huds/aircraft_respawn_landing_pointers.nut" as landingPointers
import "%ui/hud/menus/respawn.nut" as respawn
import "%ui/hud/huds/tips/all_tips.nut" as all_tips
import "%ui/hud/hud_layout.nut" as hudLayout
import "%ui/hud/replay/replay_hud_layout.nut" as replayHudLayout
import "%ui/hud/huds/tips/network_error.nut" as network_error
import "%ui/hud/huds/perf_stats.nut" as perfStats
import "%ui/hud/tutorial/huds/tutorial_zone_pointers.nut" as tutorialZonePointers
from "%darg/helpers/inspector.nut" import inspectorRoot
from "%ui/control/active_controls.nut" import lastActiveControlsType
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu, mkSettingsMenuUi
from "%ui/hud/menus/controls_setup.nut" import controlsMenuUi, showControlsMenu
from "%ui/hud/menus/game_menu.nut" import gameMenu, showGameMenu
from "%ui/hud/ct_hud_menus.nut" import menusUi
from "%ui/hud/state/hudFlagsState.nut" import hudFlags
from "%ui/hud/huds/hit_marks.nut" import posHitMarks
from "%ui/hud/tutorial/missionTutorialsUI.nut" import missionTutorialUi, controlTutorialUi
from "%ui/hud/state/pie_menu_state.nut" import showPieMenu
from "videomode" import set_frame_generation_suppressed
from "%ui/ui_library.nut" import *

let { HUD_FLAGS } = require("%ui/hud/state/hudFlagsState.nut")
let {crosshairOverheat, crosshairReload, crosshairHitmarks, crosshairForbidden, crosshairOverlayTransparency, crosshair}
  = require("%ui/hud/huds/crosshair.nut")
let crosshairImmunity = require("%ui/hud/huds/immunity_crosshair.nut")



let HUD_ELEMENTS = [
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = zonePointers }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL | HUD_FLAGS.SQUAD_SPAWN, comp = zonePointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.TUTORIAL, comp = tutorialZonePointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = resupplyPointers }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = landingPointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = hud_under }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = hud_under }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.SHOW_TIPS, comp = all_tips }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = hudLayout }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = hudLayout }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = forestall }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = crosshairImmunity }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = killMarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = posHitMarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = turretCrosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.TUTORIAL | HUD_FLAGS.VEHICLE_CROSSHAIR, comp = vehicleCrosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.NO_TUTORIAL, comp = vehicleCrosshair }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.NO_REPLAY, comp = respawn }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.NO_REPLAY, comp = controlTutorialUi }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.NO_REPLAY, comp = missionTutorialUi }
  { flags = HUD_FLAGS.REPLAY, comp = replayHudLayout }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER, comp = crosshairForbidden }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairOverheat }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairReload }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.FULL, comp = crosshairHitmarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairOverlayTransparency }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = crosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = network_error }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = perfStats }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = network_error }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = perfStats }
]

let mkHudElement = @(element) ((hudFlags.get() & element.flags) == element.flags) ? element.comp : null
function hud() {
  return {
    watch = hudFlags
    size = FLEX
    children = HUD_ELEMENTS.map(mkHudElement)
  }
}

let settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu.set(false)
})

foreach(ev in [showGameMenu, showSettingsMenu, showControlsMenu]) {
  ev.subscribe(function(v) {set_frame_generation_suppressed(v)})
}

function gameMenus(){
  local children
  if (showGameMenu.get())
    children = [gameMenu, voteToKickMenu]
  else if (showSettingsMenu.get())
    children = settingsMenuUi
  else if (showControlsMenu.get())
    children = controlsMenuUi

  return {
    size = FLEX
    children
    eventHandlers = {["HUD.GameMenu"] = @(_event) showGameMenu.set(!showGameMenu.get())}
    watch = [showSettingsMenu, showControlsMenu, showGameMenu]
  }
}

function HudRoot() {
  return {
    size = FLEX
    children = [hud, menusUi, gameMenus, inspectorRoot]
    watch = lastActiveControlsType
  }
}

showGameMenu.subscribe(function(v) {
  if (v)
    showPieMenu.set(false)
})

return HudRoot
