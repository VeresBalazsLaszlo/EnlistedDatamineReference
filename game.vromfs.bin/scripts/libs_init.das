
//THIS FILE CREATED BY CODEGEN, DON'T CHANGE THIS!!! USE setup_libs.py INSTEAD!!!


options no_aot = true
require danetlibs.pathfinder.pathfinder_init
require danetlibs.verify_ecs.verify_ecs_init
require danetlibs.navmesh_phys.navmesh_phys_init
require danetlibs.sound.sound_utils.sound_utils_init
require danetlibs.sound.sound_utils_net.sound_utils_net_init
require danetlibs.sound.common_sounds.common_sounds_init
require danetlibs.sound.environment_sounds.environment_sounds_init
require danetlibs.sound.door_sounds.door_sounds_init
require danetlibs.sound.human_sounds.human_sounds_init
require danetlibs.sound.human_sounds_net.human_sounds_net_init
require danetlibs.sound.human_speech.human_speech_init
require danetlibs.sound.human_net_speech.human_net_speech_init
require danetlibs.sound.vehicle_sounds.vehicle_sounds_init
require danetlibs.sound.vehicle_sounds_net.vehicle_sounds_net_init
require danetlibs.sound.ship_sounds.ship_sounds_init
require danetlibs.sound.plane_sounds.plane_sounds_init
require danetlibs.sound.weapon_sounds.weapon_sounds_init
require danetlibs.sound.narrator.narrator_init
require danetlibs.sound.net_narrator.net_narrator_init
require danetlibs.render_debug.render_debug_init
require danetlibs.wounds.wounds_init
require danetlibs.native_dasevents.native_dasevents_init
require danetlibs.animation_test_behaviour.animation_test_behaviour_init
require danetlibs.blood_decals.blood_decals_init
require danetlibs.frame_graph_renderer.frame_graph_renderer_init
require danetlibs.light_flicker.light_flicker_init
require danetlibs.node_collapser.node_collapser_init
require danetlibs.flash_blind.flash_blind_init
require danetlibs.swarm.swarm_init
require danetlibs.dm.dm_init
require danetlibs.ai.ai_init
require danetlibs.weapons.weapons_init
require danetlibs.package_physobj.package_physobj_init
require danetlibs.package_aircraft.package_aircraft_init
require danetlibs.package_soldier.package_soldier_init
require danetlibs.package_vehicle.package_vehicle_init
require danetlibs.damage_decals.damage_decals_init
require danetlibs.tank_cockpit.tank_cockpit_init
require danetlibs.heat_sources.heat_sources_init
require danetlibs.weaponry_hit_fx.weaponry_hit_fx_init
require danetlibs.puddles_manager.puddles_manager_init
require danetlibs.blood_puddles.blood_puddles_init
require danetlibs.local_tone_mapping.local_tone_mapping_init
require danetlibs.phys_vars.phys_vars_init
require danetlibs.paint_color.paint_color_init
require danetlibs.dascript_load_stats.dascript_load_stats_init
require danetlibs.animchar_attach.animchar_attach_init
require gameLibs.daeditorPlotDebug.daeditorPlotDebug_init
require gameLibs.anim.motionMatching.motionMatching_init
require gameLibs.anim.animReplay.animReplay_init
require gameLibs.route_prober.route_prober_init
require gameLibs.console_commands.console_commands_init
require gameLibs.imgui_daeditor.imgui_daeditor_init
require gameLibs.assets_import.assets_import_init

def load_libs() : bool
  var ok = true
  ok = load_pathfinder("%danetlibs/pathfinder") && ok
  ok = load_verify_ecs("%danetlibs/verify_ecs") && ok
  ok = load_navmesh_phys("%danetlibs/navmesh_phys") && ok
  ok = load_sound_utils("%danetlibs/sound/sound_utils") && ok
  ok = load_sound_utils_net("%danetlibs/sound/sound_utils_net") && ok
  ok = load_common_sounds("%danetlibs/sound/common_sounds") && ok
  ok = load_environment_sounds("%danetlibs/sound/environment_sounds") && ok
  ok = load_door_sounds("%danetlibs/sound/door_sounds") && ok
  ok = load_human_sounds("%danetlibs/sound/human_sounds") && ok
  ok = load_human_sounds_net("%danetlibs/sound/human_sounds_net") && ok
  ok = load_human_speech("%danetlibs/sound/human_speech") && ok
  ok = load_human_net_speech("%danetlibs/sound/human_net_speech") && ok
  ok = load_vehicle_sounds("%danetlibs/sound/vehicle_sounds") && ok
  ok = load_vehicle_sounds_net("%danetlibs/sound/vehicle_sounds_net") && ok
  ok = load_ship_sounds("%danetlibs/sound/ship_sounds") && ok
  ok = load_plane_sounds("%danetlibs/sound/plane_sounds") && ok
  ok = load_weapon_sounds("%danetlibs/sound/weapon_sounds") && ok
  ok = load_narrator("%danetlibs/sound/narrator") && ok
  ok = load_net_narrator("%danetlibs/sound/net_narrator") && ok
  ok = load_render_debug("%danetlibs/render_debug") && ok
  ok = load_wounds("%danetlibs/wounds") && ok
  ok = load_native_dasevents("%danetlibs/native_dasevents") && ok
  ok = load_animation_test_behaviour("%danetlibs/animation_test_behaviour") && ok
  ok = load_blood_decals("%danetlibs/blood_decals") && ok
  ok = load_frame_graph_renderer("%danetlibs/frame_graph_renderer") && ok
  ok = load_light_flicker("%danetlibs/light_flicker") && ok
  ok = load_node_collapser("%danetlibs/node_collapser") && ok
  ok = load_flash_blind("%danetlibs/flash_blind") && ok
  ok = load_swarm("%danetlibs/swarm") && ok
  ok = load_dm("%danetlibs/dm") && ok
  ok = load_ai("%danetlibs/ai") && ok
  ok = load_weapons("%danetlibs/weapons") && ok
  ok = load_package_physobj("%danetlibs/package_physobj") && ok
  ok = load_package_aircraft("%danetlibs/package_aircraft") && ok
  ok = load_package_soldier("%danetlibs/package_soldier") && ok
  ok = load_package_vehicle("%danetlibs/package_vehicle") && ok
  ok = load_damage_decals("%danetlibs/damage_decals") && ok
  ok = load_tank_cockpit("%danetlibs/tank_cockpit") && ok
  ok = load_heat_sources("%danetlibs/heat_sources") && ok
  ok = load_weaponry_hit_fx("%danetlibs/weaponry_hit_fx") && ok
  ok = load_puddles_manager("%danetlibs/puddles_manager") && ok
  ok = load_blood_puddles("%danetlibs/blood_puddles") && ok
  ok = load_local_tone_mapping("%danetlibs/local_tone_mapping") && ok
  ok = load_phys_vars("%danetlibs/phys_vars") && ok
  ok = load_paint_color("%danetlibs/paint_color") && ok
  ok = load_dascript_load_stats("%danetlibs/dascript_load_stats") && ok
  ok = load_animchar_attach("%danetlibs/animchar_attach") && ok
  ok = load_daeditorPlotDebug("%gameLibs/daeditorPlotDebug") && ok
  ok = load_motionMatching("%gameLibs/anim/motionMatching") && ok
  ok = load_animReplay("%gameLibs/anim/animReplay") && ok
  ok = load_route_prober("%gameLibs/route_prober") && ok
  ok = load_console_commands("%gameLibs/console_commands") && ok
  ok = load_imgui_daeditor("%gameLibs/imgui_daeditor") && ok
  ok = load_assets_import("%gameLibs/assets_import") && ok

  return ok

[export]
def test_all
  let ok = load_libs()
  assert(ok)

