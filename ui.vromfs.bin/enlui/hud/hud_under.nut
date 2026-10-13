from "%ui/hud/hud_markers/tank_ctor.nut" import tank_ctor
from "%ui/hud/state/hudOptionsState.nut" import hudMarkerEnable
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaVerPadding
from "%ui/ui_library.nut" import *
from "types" import Array

let { main_user_point_ctor, enemy_user_point_ctor, enemy_vehicle_user_point_ctor, enemy_building_user_point_ctor } = require("%ui/hud/hud_markers/user_points_ctor.nut")
let { user_point_mortar_dist_ctor } = require("%ui/hud/hud_markers/user_points_mortar_dist_ctor.nut")


let { teammates_markers_ctor } = require("%ui/hud/hud_markers/teammate_ctor.nut")

let { squad_order_ctor } = require("%ui/hud/hud_markers/squad_order_ctor.nut")
let { watched_hero_squad_personal_orders_ctor } = require("%ui/hud/hud_markers/squad_personal_order_ctor.nut")
let { grenade_ctor } = require("%ui/hud/hud_markers/grenade_ctor.nut")
let { bomb_ctor } = require("%ui/hud/hud_markers/bomb_ctor.nut")
let { activator_ctor } = require("%ui/hud/hud_markers/delayed_shell_activator_ctor.nut")
let { fortification_preview_forward_ctor } = require("%ui/hud/hud_markers/fortification_preview_forward_ctor.nut")
let { destroyable_ri_ctor } = require("%ui/hud/hud_markers/destroyable_score_ri_ctor.nut")
let { mine_ctor } = require("%ui/hud/hud_markers/mine_ctor.nut")
let { useful_boxes_marker_ctor } = require("%ui/hud/hud_markers/simple_marker_ctor.nut")
let { special_box_markers_ctor } = require("%ui/hud/hud_markers/special_box_markers_ctor.nut")
let { spawn_zone_ctor } = require("%ui/hud/hud_markers/spawn_zone_ctor.nut")
let { aircraft_ctor } = require("%ui/hud/hud_markers/aircraft_ctor.nut")
let { paratroopers_point_ctor } = require("%ui/hud/menus/troopers_point_chooser.nut")


function mkViewport(padding){
  return {
    sortOrder = -999
    size = [sw(100) - safeAreaHorPadding.get()*2 - padding, sh(100) - safeAreaVerPadding.get()*2 - padding]
    data = {
      isViewport = true
    }
  }
}

function layout(state, ctor, padding){
  return function() {
    let children = [mkViewport(padding)]
    let res = ctor()
    children.extend(res instanceof Array ? res : [res])
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = FLEX
      children
      watch = state
      behavior = DngBhv.Projection
      sortChildren = true
    }
  }
}

function makeMarkersLayout(stateAndCtors, padding){
  let layers = []
  foreach (sc in stateAndCtors) {
    let {watch, ctor} = sc
    layers.append(layout(watch, ctor, padding))
  }

  return @(){
    size = const [sw(100), sh(100)]
    children = layers
    watch = [safeAreaHorPadding, safeAreaVerPadding]
  }
}

const arrowsPadding = fsh(3)

function hudUnder() {
  let markersCtorsAndState = [
    destroyable_ri_ctor,
    squad_order_ctor,
    watched_hero_squad_personal_orders_ctor,
    fortification_preview_forward_ctor,
    paratroopers_point_ctor,
    spawn_zone_ctor, 
    tank_ctor
  ]

  if (hudMarkerEnable.get() && !forcedMinimalHud.get()) {
    markersCtorsAndState.append(
      aircraft_ctor,
      grenade_ctor,
      activator_ctor,
      bomb_ctor,
      mine_ctor,
      useful_boxes_marker_ctor,
      special_box_markers_ctor,
    )
  }
  if (hudMarkerEnable.get()) {
    markersCtorsAndState.append(
      main_user_point_ctor,
      enemy_user_point_ctor,
      enemy_vehicle_user_point_ctor,
      enemy_building_user_point_ctor,
      user_point_mortar_dist_ctor,
    )
  }
  markersCtorsAndState.append(teammates_markers_ctor)

  return {
    watch = [hudMarkerEnable, forcedMinimalHud]
    children = makeMarkersLayout(markersCtorsAndState, 1.2*arrowsPadding)
  }
}

return hudUnder
