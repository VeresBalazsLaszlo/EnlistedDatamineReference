options no_aot = true//since this is merely loader
require DagorConsole
require ecs
require ecs.fs
require common_shooter.common_shooter
require app
require ECSGlobalTags
require DagorDataBlock
require DagorSystem
require %scripts/libs_init
require enlisted.game.utils.sandbox_state

def private sound_override_voices_locale() : bool
  var isOriginal = false
  dgs_get_settings() |> datablock_get_block("gameplay") <| $(gameBlock)
    isOriginal = gameBlock |> datablock_getBool("voiceoverOriginalEnabled", false)

  if isOriginal
    return false

  var locale = ""
  dgs_get_settings() |> datablock_get_block("sound") <| $(soundBlock)
    locale = soundBlock |> datablock_getStr("overrideVoicesLocale", "")
  return locale != ""

def private load_sound() : bool
  var ok = true

  if ecs_has_tag("sound") || is_in_aot()
    ok = load_folder("%scripts/game/es/sound") && ok
    ok = load_folder("%scripts/game/es/sound/vehicle") && ok
    if sound_override_voices_locale() || is_in_aot()
      ok = load_das("%scripts/game/es/sound/optional/human_speech_override.das") && ok

  if ecs_has_tag("soundNet") || is_in_aot()
    ok = load_folder("%scripts/game/es/sound_net") && ok
  return ok


def private load_render() : bool
  var ok = true
  if ecs_has_tag("render") || is_in_aot()
    ok = load_folder("%scripts/game/es/render") && ok
  return ok



def private load_editor() : bool
  var ok = true
  if typeinfo builtin_module_exists(DagorEditor) || is_in_aot()
    ok = load_folder("%scripts/game/es/daEditor") && ok

  if (typeinfo builtin_module_exists(DagorImgui) && typeinfo builtin_module_exists(DagorEditor)) || is_in_aot()
    ok = load_folder("%scripts/game/es/imgui/daEditor") && ok

  return ok


def private load_ui() : bool
  var ok = true
  if ecs_has_tag("ui") || is_in_aot()
    ok = load_folder("%scripts/game/es/ui") && ok
  return ok


def private load_client() : bool
  var ok = true
  if ecs_has_tag("input") || is_in_aot() // check input as real game client tag, netClient is unset on game start
    ok = load_folder("%scripts/game/es/client") && ok
    ok = load_folder("%scripts/game/es/player/client") && ok
  return ok


def private load_input() : bool
  var ok = true
  if ecs_has_tag("input") || is_in_aot()
    ok = load_folder("%scripts/game/es/input") && ok
  return ok


def private load_tutorial() : bool
  var ok = true
  if is_in_aot() // load tutorial only on build server to verify scripts
    ok = load_folder("%scripts/tutorial") && ok
  return ok


def private load_dedicated() : bool
  var ok = true
  if (ecs_has_tag("server") && !ecs_has_tag("gameClient")) || is_in_aot()
    ok = load_folder("%dedicated/es") && ok
  return ok


def private load_dev() : bool
  var ok = true
  if ecs_has_tag("dev") || is_in_aot()
    ok = load_optional_folder("%enlisted_pkg_dev/game/es") && ok
    if ecs_has_tag("sound") || is_in_aot()
      ok = load_optional_folder("%enlisted_pkg_dev/game/es/sound") && ok
  return ok


def private load_imgui() : bool
  var ok = true
  if typeinfo builtin_module_exists(DagorImgui) || is_in_aot()
    ok = load_folder("%scripts/game/es/imgui") && ok

  return ok


def private load_replay() : bool
  var ok = true
  if ecs_has_tag("input") || is_in_aot()
    ok = load_folder("%scripts/game/es/replay") && ok
  return ok


def private load_debug() : bool
  var ok = true
  if ecs_has_tag("dev") || is_in_aot()
    ok = load_optional_folder("%scripts/game/es/debug") && ok
  return ok


def private load_sandbox() : bool
  var ok = true
  if (is_sandbox_enabled() && typeinfo builtin_module_exists(DngCamera) && typeinfo builtin_module_exists(DagorEditor)) || is_in_aot()
    ok = load_folder("%scripts/sandbox/es") && ok

    if ecs_has_tag("dev") && !is_in_aot()
      return ok

    ok = load_das_with_debugcode("%scripts/sandbox/es/editor_console.das") && ok
    ok = load_das_with_debugcode("%scripts/sandbox/es/navmesh_rebuild_console.das") && ok

    ok = load_das_with_debugcode("%scripts/game/es/devmode_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/capzone_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/common_shooter/es/capzone_area_console.das") && ok
    ok = load_das_with_debugcode("%scripts/common_shooter/es/poly_battle_area_console.das") && ok
    ok = load_das_with_debugcode("%danetlibs/render_debug/render/collision_debug.das") && ok
    ok = load_das_with_debugcode("%danetlibs/render_debug/render/draw_scene_collision_debug.das") && ok

    ok = load_das_with_debugcode("%scripts/game/es/aircraft_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/client/camera_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/engineer_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/enlisted_teleport_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/hitpoints_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/squad_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/teleport_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/weapon_spread_debug.das") && ok
  return ok


[init]
def load
  var ok = true
  if ecs_has_tag("dasWebui") || is_in_aot()
    load_optional_folder("%dngdas/remote/es")
    if typeinfo builtin_module_exists(DngWalkerai)
      load_optional_folder("%dngdas/remote/es/ai")
  load_optional_folder("%dngdas/debug/es")

  if ecs_has_tag("inside_tools")
    load_libs()
    return

  ok = load_folder("%scripts/game/es") && ok
  ok = load_folder("%scripts/game/es/ai") && ok
  ok = load_folder("%scripts/game/es/aircraft") && ok
  ok = load_folder("%scripts/game/es/effects") && ok
  ok = load_folder("%scripts/game/es/human") && ok
  ok = load_folder("%scripts/game/es/locks") && ok
  ok = load_folder("%scripts/game/es/player") && ok
  ok = load_folder("%scripts/game/es/stat_bq") && ok
  ok = load_folder("%scripts/game/es/vehicle") && ok
  ok = load_folder("%scripts/game/es/zombie") && ok
  ok = load_folder("%scripts/game/es/terraform") && ok
  ok = load_folder("%scripts/game/es/pve") && ok
  ok = load_folder("%scripts/game/es/train") && ok
  ok = load_folder("%scripts/game/es/voxel") && ok
  ok = load_editor() && ok
  ok = load_render() && ok
  ok = load_input() && ok
  ok = load_sound() && ok
  ok = load_tutorial() && ok
  ok = load_ui() && ok
  ok = load_client() && ok
  ok = load_dedicated() && ok
  ok = load_replay() && ok
  ok = load_dev() && ok
  ok = load_debug() && ok
  ok = load_imgui() && ok
  ok = load_sandbox() && ok

  ok = load_libs() && ok

  if is_in_aot()
    assert(ok)
