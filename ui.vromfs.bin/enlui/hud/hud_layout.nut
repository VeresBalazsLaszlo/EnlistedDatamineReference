import "%ui/hud/huds/planeTakeOffTips.nut" as planeTakeOffTips
import "%ui/hud/state/hasSpectatorKeys.nut" as hasSpectatorKeys
import "%ui/hud/huds/maintenance_progress_hint.nut" as maintenanceProgress
import "%ui/hud/huds/bomb_site_progress_hint.nut" as bombSiteProgress
import "%ui/hud/huds/ammo_request_cooldown_hint.nut" as ammoRequestCooldown
import "%ui/hud/huds/vehicle_seats.ui.nut" as vehicleSeats
import "%ui/hud/huds/vehicle_change_seats.nut" as vehicleChangeSeats
import "%ui/hud/huds/push_object_tip.nut" as pushObjectTip
import "%ui/hud/huds/paratroopers_supply_box_tip.nut" as paratroopersSupplyBoxTip
import "%ui/hud/huds/grenade_rethrow_tip.nut" as grenadeRethrowTip
import "%ui/hud/huds/fortification_builder_action.nut" as fortificationAction
import "%ui/hud/huds/put_out_fire_indicator.nut" as putOutFire
import "%ui/hud/huds/squad_members.ui.nut" as squadMembersUi
import "%ui/hud/huds/vote_kick.ui.nut" as voteKickUi
import "%ui/hud/huds/artillery_order.ui.nut" as artilleryOrderUi
import "%ui/hud/huds/vehicle_repair.nut" as vehicleRepair
import "%ui/hud/huds/player_events.nut" as playerEventsRoot
import "%ui/hud/huds/tips/throw_grenade_tip.nut" as throw_grenade_tip
import "%ui/hud/huds/tips/melee_charge_tip.nut" as melee_charge_tip
import "%ui/hud/huds/tips/artillery_radio_tip.nut" as artillery_ratio_tip
import "%ui/hud/huds/friendly_fire_warning.nut" as friendly_fire_warning
import "%ui/hud/huds/tips/ammo_depleted_in_tank.nut" as ammoDepletedInTank
import "%ui/hud/huds/tips/lie_down_to_shoot_accurately_tip.nut" as lieDownToShootAccuratelyTip
import "%ui/hud/huds/tips/has_to_charge_tip.nut" as hasToChargeTip
import "%ui/hud/huds/tips/cannot_dig_at_pos.nut" as cannotDigAtPosTip
import "%ui/hud/huds/tips/lie_down_to_save_from_expl_tip.nut" as lie_down_to_save_from_expl_tip
from "%ui/hud/huds/tips/spy_detected_tip.nut" import spyDetectedTipUi as spyDetectedTip, spyCanChangeClothesTipUi as spyCanChangeClothesTip, spyClothesChangeProgress
import "%ui/hud/huds/minimap/minimap.nut" as minimap
import "%ui/hud/huds/hitcamera.ui.nut" as hitcamera
import "%ui/hud/huds/dm_panel.ui.nut" as dmPanel
import "%ui/hud/huds/fortification_repair_progress_hint.nut" as fortificationRepairProgress
import "%ui/hud/huds/battle_area_warnings_hint.nut" as outsideBattleAreaWarning
import "%ui/hud/huds/vehicle_warnings.nut" as vehicleWarnings
import "%ui/hud/huds/vehicle_steer_tip.nut" as vehicleSteerTip
import "%ui/hud/huds/tips/plane_steer_tip.nut" as planeSteerTip
import "%ui/hud/huds/tips/vehicle_resupply.nut" as vehicleResupplyTip
import "%ui/hud/huds/tips/medic_heal_tip.nut" as medicHealTip
import "%ui/hud/huds/tips/spectatorKeys_tip.nut" as spectatorKeys_tip
import "%ui/hud/huds/maintenance_hint.nut" as maintenanceHint
import "%ui/hud/huds/tips/vehicle_free_seat_tip.nut" as vehicleFreeSeatTip
import "%ui/hud/huds/tips/no_respawn_reason_tip.nut" as noRespawnTip
import "%ui/hud/huds/vehicle_hud.nut" as vehicleHud
import "%ui/hud/huds/failTimerUi.nut" as failTimerUi
import "%ui/hud/huds/game_mode.ui.nut" as gameModeBlock
import "%ui/hud/huds/zombie_objective_mode_capture.ui.nut" as zombieObjectiveModeBlock
import "%ui/hud/huds/score_awards.nut" as awards
import "%ui/hud/huds/warnings.nut" as warnings
import "%ui/hud/huds/tips/spectatorMode_tip.nut" as spectatorMode_tip
import "%ui/hud/huds/hints.nut" as hints
import "%ui/hud/huds/killLog.nut" as killLog
import "%ui/hud/huds/wave_bot_debug.ui.nut" as waveBotDebug
import "%ui/hud/huds/player_weapons.ui.nut" as playerDynamic
from "math" import rand
from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaVerPadding
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/hud/huds/enter_exit_vehicle.nut" import enterVehicleIndicator, exitVehicleIndicator
from "%ui/hud/chat.ui.nut" import chatRoot
from "%ui/hud/huds/serviceMessages.nut" import serviceMessages, hasServiceMessages
from "%ui/hud/huds/near_enemy_respawn_warnings_hint.nut" import nearEnemyRespawnHint, nearEnemyRespawnDamageHint
from "%ui/hud/huds/plane_hud.nut" import planeHud
from "%ui/hud/huds/actions.nut" import mainAction
from "%ui/hud/huds/enemy_hint.nut" import localTeamEnemyHint
from "%ui/hud/state/capZones.nut" import curCapZone
from "%ui/hud/huds/compass_zones.nut" import compassZoneCtor, compassZoneWatch
from "%ui/hud/huds/zombieObjectiveTeamBlock.nut" import zombieObjectiveTeamUi
from "%ui/hud/state/mortar.nut" import isMortarMode
from "%ui/hud/state/vehicle_state.nut" import inPlane
from "%ui/hud/menus/big_map.nut" import showBigMap
from "%ui/hud/menus/artillery_radio_map.nut" import showArtilleryMap
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud, showBattleChat
from "%ui/hud/state/hudFlagsState.nut" import hudFlags
from "%ui/hud/state/respawnState.nut" import showSquadSpawn
from "%ui/hud/huds/player_deaths.nut" import playerDeaths
from "%ui/hud/huds/team_kills.nut" import tkWarning
from "%ui/components/text.nut" import text
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode, showZombieTeamUi
from "%ui/ui_library.nut" import *

let debug_borders = mkWatched(persist, "debug_borders", false)



let vehicleActions = require("%ui/hud/huds/vehicleActions.nut")
let buildingActions = require("%ui/hud/huds/tips/building_tool_tip.nut")
let wallposterActions = require("%ui/hud/huds/tips/wallposter_tool_tip.nut")
let compassStrip = require("%ui/hud/huds/compass/mk_compass_strip.nut")({
  size = const [hdpx(220), hdpx(40)],
  compassObjects = [{watch = compassZoneWatch, childrenCtor = compassZoneCtor}] 
  globalScale = 0.8
})
let mortarTips = require("%ui/hud/huds/tips/mortar_tips.nut")
let { HUD_FLAGS } = require("%ui/hud/state/hudFlagsState.nut")

let minHud = keepref(Computed(@() forcedMinimalHud.get() || minimalistHud.get()))
let showGameMode = Computed( @() !minHud.get() || showSquadSpawn.get() || showBigMap.get())
let curCapZoneTitle = Computed(@() curCapZone.get()?.caption)
let showCurCapZoneTitle = Watched(false)
let hideCurCapZoneTitle = @() showCurCapZoneTitle.set(false)
curCapZoneTitle.subscribe(function(v){
  if ((v ?? "") == "")
    return
  showCurCapZoneTitle.set(true)
  gui_scene.resetTimeout( 6, hideCurCapZoneTitle)
})
let czTitleAnims = freeze([
  { prop=AnimProp.opacity, from=0, to=1.0, duration=0.4, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=1.0, to=0.0, duration=3, playFadeOut=true, easing=InCubic}
])

let capZoneTitle = @(){
  watch = curCapZoneTitle
  animations = czTitleAnims
  children = text(loc(curCapZoneTitle.get()))
}
let gameMode = @(){
  watch = [isZombieObjectiveMode, showGameMode, showCurCapZoneTitle]
  children = isZombieObjectiveMode.get() ? null
    : showGameMode.get() ? gameModeBlock
    : showCurCapZoneTitle.get() ? capZoneTitle
    : null
}

let actionsRoot = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = @() {
    watch = [minHud, isTutorial]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = minHud.get()
      ? [localTeamEnemyHint].extend(wallposterActions)
      : [].extend(planeTakeOffTips, buildingActions,
          [ medicHealTip, maintenanceHint, mainAction, localTeamEnemyHint, vehicleFreeSeatTip ],
          isTutorial.get() ? [] : vehicleActions, wallposterActions)
  }
}

let showMinimap = Computed(@() !forcedMinimalHud.get() && !(showArtilleryMap.get() || showBigMap.get()))

let compassAndMap = @() {
  watch = [showMinimap, forcedMinimalHud]
  flow = FLOW_HORIZONTAL
  children = [
    {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      halign = ALIGN_CENTER
      children = showMinimap.get() ? [ minimap, compassStrip ] : null
    }
    !forcedMinimalHud.get() ? dmPanel : null
  ]
}

let compassOnly = @() {
  flow = FLOW_VERTICAL
  watch = forcedMinimalHud
  children = [!forcedMinimalHud.get() ? dmPanel : null, compassStrip]
  gap = hdpx(10)
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
}

function minimap_mod() {
  local mc
  if (inPlane.get())
    mc = [compassOnly, voteKickUi, vehicleSteerTip, planeSteerTip]
  else if (isMortarMode.get())
    mc = [compassAndMap, voteKickUi, mortarTips]
  else
    mc = [compassAndMap, vehicleSteerTip, planeSteerTip, voteKickUi]
  return {
    children = mc
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = hdpx(5)
    watch = [isMortarMode, inPlane]
  }
}

let showChat = keepref(Computed(@() showBattleChat.get()))

let spectatorKeys = @() {
  watch = hasSpectatorKeys
  children = hasSpectatorKeys.get() ? spectatorKeys_tip : null
}

let chat = @() {
  size = FLEX_H
  watch = [hasServiceMessages, showChat]
  children = hasServiceMessages.get() ? serviceMessages
    : showChat.get() ? chatRoot
    : null
}


let isZombieMode = Computed(@() showGameMode.get() && isZombieObjectiveMode.get())
let showZombieTeam = Computed(@() showGameMode.get() && showZombieTeamUi.get())

let zombieObjectiveMode = @() {
  watch = showZombieTeam
  children = showZombieTeam.get() ? zombieObjectiveModeBlock : null
}

let zombieObjectiveTeam = @() {
  watch = showZombieTeam
  children = showZombieTeam.get() ? zombieObjectiveTeamUi : null
}

let vehicleSeatsUi = @() {
  watch = isZombieMode
  children = !isZombieMode.get() ? vehicleSeats : null
}

let LEFT_PANEL_TOP = [
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = zombieObjectiveMode }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = planeHud }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = vehicleHud }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = failTimerUi }
]

let LEFT_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.MINIMAL, comp = chat }
  { flags = HUD_FLAGS.FULL, comp = chat }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.TUTORIAL, comp = vehicleSeatsUi }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = squadMembersUi }
]

let LEFT_PANEL_BOTTOM = [
  {
    flags = HUD_FLAGS.NO_TUTORIAL
      | HUD_FLAGS.FULL
      | HUD_FLAGS.PLAYER_UI
      | HUD_FLAGS.NO_SQUAD_SPAWN, comp = zombieObjectiveTeam
  }
  {
    flags = HUD_FLAGS.NO_TUTORIAL
      | HUD_FLAGS.PLAYER_UI
      | HUD_FLAGS.NO_MINIMALIST
      | HUD_FLAGS.NO_SQUAD_SPAWN
      | HUD_FLAGS.NO_HARDCORE, comp = vehicleSeatsUi
  }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = artilleryOrderUi }
  {
    flags = HUD_FLAGS.NO_MINIMALIST
      | HUD_FLAGS.PLAYER_UI
      | HUD_FLAGS.NO_SQUAD_SPAWN, comp = minimap_mod
  }
]

let CENTER_PANEL_TOP = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.PLAYER_UI, comp = gameMode }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS, comp = spectatorMode_tip }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = noRespawnTip }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleChangeSeats }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = enterVehicleIndicator }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = exitVehicleIndicator }

  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = gameMode }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = hints }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = warnings }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spectatorMode_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = noRespawnTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleChangeSeats }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = enterVehicleIndicator }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = exitVehicleIndicator }
]

let CENTER_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerEventsRoot }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleRepair }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = maintenanceProgress }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationRepairProgress }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = bombSiteProgress }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = spyClothesChangeProgress }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.MINIMAL, comp = tkWarning }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = putOutFire }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationAction }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerDeaths }

  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = outsideBattleAreaWarning }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = nearEnemyRespawnHint }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = nearEnemyRespawnDamageHint }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerEventsRoot }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleWarnings }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleRepair }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = maintenanceProgress }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationRepairProgress }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = bombSiteProgress }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = spyClothesChangeProgress }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL, comp = tkWarning }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = ammoRequestCooldown }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = putOutFire }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationAction }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_AWARDS, comp = awards }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerDeaths }
]

let CENTER_PANEL_BOTTOM = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS | HUD_FLAGS.NO_BIG_MAP, comp = actionsRoot }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS, comp = artillery_ratio_tip }
  { flags = HUD_FLAGS.MINIMAL, comp = friendly_fire_warning }

  { flags = HUD_FLAGS.TUTORIAL | HUD_FLAGS.FULL, comp = playerEventsRoot }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = lieDownToShootAccuratelyTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = hasToChargeTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = cannotDigAtPosTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = ammoDepletedInTank }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = lie_down_to_save_from_expl_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.NO_BIG_MAP | HUD_FLAGS.SHOW_TIPS, comp = actionsRoot }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = throw_grenade_tip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = melee_charge_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = artillery_ratio_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = vehicleResupplyTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spectatorKeys }
  { flags = HUD_FLAGS.FULL, comp = friendly_fire_warning }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = pushObjectTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = paratroopersSupplyBoxTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = grenadeRethrowTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spyDetectedTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spyCanChangeClothesTip }
]

let RIGHT_PANEL_TOP = [
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = hitcamera }
]

let RIGHT_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.NO_BIG_MAP, comp = killLog }
  { flags = HUD_FLAGS.PLAYER_UI | HUD_FLAGS.FULL, comp = waveBotDebug }
]

let RIGHT_PANEL_BOTTOM = [
  { flags = HUD_FLAGS.NO_MINIMALIST | HUD_FLAGS.PLAYER_UI, comp = playerDynamic }
]

wlog(hudFlags, "hudFlags = ")
console_register_command(@() debug_borders.modify(@(v) !v),"ui.hud_layout_borders_debug")

let debug_borders_robj = @(db) db ? ROBJ_FRAME: null

function debug_colors(v) {
  return v ? Color(rand() % 156 + 100, rand() % 156 + 100, rand() % 156 + 100) : null
}

let mkHudElement = @(element) ((hudFlags.get() & element.flags) == element.flags) ? element.comp : null

function mpanel(childrenRemap, params={}) {
  return @() {
    size = FLEX
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    halign = ALIGN_LEFT
    rendObj = debug_borders_robj(debug_borders.get())
    watch = [debug_borders, hudFlags]
    color = debug_colors(debug_borders.get())
    borderWidth = hdpx(1)
    gap = fsh(1)
    children = childrenRemap.map(mkHudElement)
  }.__update(params)
}


let leftPanel = {
  size = FLEX
  flow = FLOW_VERTICAL
  padding = fsh(1)
  children = [
    mpanel(LEFT_PANEL_TOP, { size = flex(1) })
    mpanel(LEFT_PANEL_MIDDLE, {
      size = const [FLEX, flex(3)]
      valign = ALIGN_BOTTOM
      minHeight = SIZE_TO_CONTENT
    })
    mpanel(LEFT_PANEL_BOTTOM, {
      size = FLEX_H
      valign = ALIGN_BOTTOM
      maxHeight = flex(1)
      padding = 0
    })
  ]
}

function centerPanel() {
  return {
    size = flex(2)
    flow = FLOW_VERTICAL
    padding = fsh(1)
    children = [
      mpanel(CENTER_PANEL_TOP, {gap = hdpx(2), halign = ALIGN_CENTER, size = flex(4)})
      mpanel(CENTER_PANEL_MIDDLE, {gap = hdpx(2), halign = ALIGN_CENTER, valign = ALIGN_BOTTOM, size = flex(4)})
      mpanel(CENTER_PANEL_BOTTOM, {gap = hdpx(2), halign = ALIGN_CENTER valign = ALIGN_BOTTOM, size = flex(1.5)})
    ]
  }
}

function rightPanel() {
  return {
    size = flex(1)
    rendObj = debug_borders_robj(debug_borders.get())
    watch = [debug_borders, hudFlags]
    color = debug_colors(debug_borders.get())
    flow = FLOW_VERTICAL
    padding = fsh(1)
    children = [
      mpanel(RIGHT_PANEL_TOP, { size =const [FLEX,flex(1)] halign=ALIGN_RIGHT})
      mpanel(RIGHT_PANEL_MIDDLE, { size =const [FLEX,flex(2)] halign=ALIGN_RIGHT valign=ALIGN_CENTER})
      mpanel(RIGHT_PANEL_BOTTOM, { size =const [FLEX,flex(1)] halign=ALIGN_RIGHT valign=ALIGN_BOTTOM})
    ]
  }
}

function footer() {
  return {
    size = [FLEX, max(safeAreaVerPadding.get(), fsh(1))]
    rendObj = debug_borders_robj(debug_borders.get())
    color = debug_colors(debug_borders.get())
    watch = debug_borders
  }
}

function header() {
  return {
    size = [FLEX, max(safeAreaVerPadding.get(), fsh(1))]
    rendObj = debug_borders_robj(debug_borders.get())
    color = debug_colors(debug_borders.get())
    watch = debug_borders
    flow = FLOW_HORIZONTAL
    padding = const [0, fsh(2)]
  }
}

function HudLayout() {
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    children = [
      header
      {
        flow = FLOW_HORIZONTAL
        size = FLEX
        children = [
          @() {watch = safeAreaHorPadding, size = [max(fsh(1), safeAreaHorPadding.get()),FLEX]} 
          leftPanel
          centerPanel
          rightPanel
          @() {watch = safeAreaVerPadding, size = [max(fsh(1), safeAreaHorPadding.get()),FLEX]} 
        ]
      }
      footer
    ]
  }
}

return HudLayout
