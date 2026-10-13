import "%ui/hud/huds/tips/medkit_tip.nut" as medkit_tip
import "%ui/hud/huds/tips/throwable_weapon_tip.nut" as throwable_weapon_tip
import "%ui/hud/huds/tips/tnt_tip.nut" as tnt_tip
import "%ui/hud/huds/tips/need_revive_from_teammate.nut" as revive_from_team_tip
import "%ui/hud/huds/tips/low_stamina_aim_tip.nut" as aim_stamina_tip
import "%ui/hud/huds/tips/switch_soldier_tip.nut" as switch_soldier_tip
import "%ui/hud/huds/tips/downed_grenade_usage_tip.nut" as downed_grenade_usage_tip
import "%ui/hud/huds/tips/downed_tip.nut" as downed_tip
import "%ui/hud/huds/tips/reload_tip.nut" as reload_tip
import "%ui/hud/huds/tips/medkit_usage.nut" as medkit_usage
import "%ui/hud/huds/tips/revive_syringe_usage.nut" as revive_syringe_usage
import "%ui/hud/huds/tips/low_stamina_use_flask_tip.nut" as low_stamina_use_flask_tip
import "%ui/hud/huds/tips/vehicle_underwater.nut" as vehicle_under_water
import "%ui/hud/huds/tips/burning_tip.nut" as burning_tip
import "%ui/hud/huds/tips/hold_breath_tip.nut" as hold_breath_tip
import "%ui/hud/huds/tips/redeploy_tip.nut" as redeploy_tip
import "%ui/hud/huds/tips/plane_redeploy_tip.nut" as plane_redeploy_tip
import "%ui/hud/huds/tips/prevent_reloading_tip.nut" as prevent_reloading_tip
import "%ui/hud/huds/tips/place_bipod_tip.nut" as place_bipod_tip
import "%ui/hud/huds/tips/bomber_cockpit_tip.nut" as bomber_cockpit_tip
import "%ui/hud/huds/tips/open_parachute_tip.nut" as open_parachute_tip
import "%ui/hud/huds/tips/mark_enemy_tip.nut" as mark_enemy_tip
import "%ui/hud/huds/tips/mortar_aiming_tip.nut" as mortar_aiming_tip
import "%ui/hud/huds/tips/mortar_switch_shell_type_tip.nut" as mortar_switch_shell_tip
import "%ui/hud/huds/tips/mobile_respawn_close_to_capzone_tip.nut" as is_mobile_respawn_close_to_capzone_tip
import "%ui/hud/huds/tips/gaz_mask_tip.nut" as gaz_mask_tip
import "%ui/hud/huds/tips/gas_damage_equip_mask_tip.nut" as gas_damage_equip_mask_tip
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/hud/state/tips.nut" import setTips
from "%ui/hud/huds/tips/aim_range_tips.nut" import swithAimBtnTip, aimRangeValuesTip
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/replay/replayState.nut" import canShowGameHudInReplay
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeList

let fullTips = [
  {
    pos = const [-fsh(25), fsh(25)]
    children = reload_tip
  }
  {
    pos = const [fsh(30), fsh(25)]
    gap = hdpx(2)
    children = [
      mark_enemy_tip, swithAimBtnTip,
      hold_breath_tip, downed_grenade_usage_tip, revive_from_team_tip,
      switch_soldier_tip, medkit_tip, aim_stamina_tip, low_stamina_use_flask_tip,
      place_bipod_tip, prevent_reloading_tip, throwable_weapon_tip, tnt_tip,
      mortar_aiming_tip, mortar_switch_shell_tip, open_parachute_tip, is_mobile_respawn_close_to_capzone_tip,
      gaz_mask_tip, gas_damage_equip_mask_tip, bomber_cockpit_tip
    ]
  }
  { children = medkit_usage }
  { children = revive_syringe_usage }
  { children = vehicle_under_water }
  {
    pos = const [fsh(0), fsh(5)]
    children = [downed_tip, burning_tip, redeploy_tip, plane_redeploy_tip]
  }
  {
    pos = const [fsh(-15), fsh(2)]
    children = aimRangeValuesTip
  }
]
let minTips = [
  {
    pos = const [fsh(30), fsh(25)]
    gap = hdpx(2)
    children = [medkit_tip, mortar_aiming_tip, revive_from_team_tip]
  }
  { children = medkit_usage }
  { children = revive_syringe_usage }
  { children = vehicle_under_water }
  {
    pos = const [fsh(0), fsh(5)]
    children = [downed_tip, burning_tip]
  }
]

let tutorialTips = [

  {
    pos = const [-fsh(25), fsh(25)]
    children = reload_tip
  }
  {
    pos = const [fsh(30), fsh(25)]
    gap = hdpx(2)
    children = [
      swithAimBtnTip,
      downed_grenade_usage_tip
    ]
  }
  { children = medkit_usage }
  { children = vehicle_under_water }
  {
    pos = const [fsh(0), fsh(5)]
    children = [downed_tip, burning_tip, redeploy_tip, plane_redeploy_tip]
  }
  {
    pos = const [fsh(-15), fsh(2)]
    children = aimRangeValuesTip
  }
]

function getTips(){
  if (!isAlive.get() || !canShowGameHudInReplay.get())
    return []
  else if (isTutorial.get())
    return tutorialTips
  else if (forcedMinimalHud.get() || minimalistHud.get())
    return minTips
  return fullTips
}

let setupTips = @(_ = null) setTips(getTips())
subscribeList(setupTips, canShowGameHudInReplay, isAlive, forcedMinimalHud, minimalistHud, isTutorial)
setupTips()
