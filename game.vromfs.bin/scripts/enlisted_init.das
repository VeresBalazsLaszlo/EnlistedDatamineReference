options no_aot = true//since this is merely loader
require game.navmesh_rebuild_events
require game.es.vehicle.vehicle_events
require game.events_game
require game.es.player_events
require enlisted.events_enlisted
require enlisted.game.es.context_command_common
require enlisted.game.es.squad_behaviour_command_common
require enlisted.game.es.terraform.terraform_common
require common_shooter.es.hit_result_common
require game.es.hangar_hitcam_common
require app
require ecs
require DagorSystem
require ECSGlobalTags


def private load_ui_events() : bool
  var ok = true
  if ecs_has_tag("ui") || is_in_aot()
    ok = load_das("%scripts/game/es/ui/ui_events.das") && ok
  return ok


def private load_sound_events() : bool
  var ok = true
  ok = load_das("%danetlibs/sound/human_sounds/modules/human_sounds_events.das") && ok
  ok = load_das("%danetlibs/sound/human_sounds_net/modules/human_sounds_net_events.das") && ok
  ok = load_das("%danetlibs/sound/human_net_speech/modules/human_net_speech_events.das") && ok
  ok = load_das("%danetlibs/sound/net_narrator/modules/net_narrator_events.das") && ok
  return ok


def private load_nut_binds() : bool
  var ok = true
  ok = load_das("%scripts/game/es/respawn_base_common_quirrel.das") && ok
  ok = load_das("%scripts/game/es/soldier_info_cache_binds_quirrel.das") && ok
  ok = load_das("%scripts/game/es/team_binds_quirrel.das") && ok
  ok = load_das("%scripts/game/es/sandbox_config_binds_quirrel.das") && ok
  return ok

[init]
def load
  var ok = true
  if is_in_aot() || (get_DAGOR_DBGLEVEL() > 0 && get_TARGET_PC() != 0 && find_index(get_command_line_arguments(), "--das-no-linter") == -1)
    ok = load_das("%danetlibs/dascript_base/linter.das") && ok

  if (!is_in_aot() && get_DAGOR_DBGLEVEL() > 0 && get_DAGOR_ADDRESS_SANITIZER() == 0 && get_DAGOR_THREAD_SANITIZER() == 0
      && ecs_has_tag("render") && !has_value(get_command_line_arguments(), "--das-no-debugger"))
    ok = load_das_debugger("%danetlibs/dascript_base/debugger_debug.das") && ok

  if ecs_has_tag("inside_tools")
    return

  ok = load_nut_binds() && ok
  ok = load_ui_events() && ok
  ok = load_sound_events() && ok

  if is_in_aot()
    assert(ok)
