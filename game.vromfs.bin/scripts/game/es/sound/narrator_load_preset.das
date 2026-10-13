require ecs
require game.utils.team
require player
require soundSystem
require strings


def enable_preset_impl(name : string; enable : bool)
  if sound_banks_is_preset_exist(name)
    sound_banks_enable_preset(name, enable)


def narrator_load_preset_impl(army : string; player_team : int;
                              native_lang : bool; preset_starts_with : string;
                              default_preset : string; var cur_preset : das_string&)

  var preset = ""
  if native_lang && player_team != TEAM_UNASSIGNED
    query() <| $ [es] (armyLanguage : Object)
      let language = get_string(armyLanguage, army, "")
      if !empty(language)
        preset = "{preset_starts_with}{language}"
    if empty(preset)
      query() <| $ [es] (team__id : int; team__lang : string)
        if player_team == team__id && !empty(team__lang)
          preset = "{preset_starts_with}{team__lang}"

  if !sound_banks_is_preset_exist(preset)
    preset = default_preset

  if string(cur_preset) != preset
    sound_debug("switch narrator preset from \"{string(cur_preset)}\" to \"{preset}\"")

    enable_preset_impl(string(cur_preset), false)
    cur_preset := preset
    enable_preset_impl(string(cur_preset), true)



[es(tag=sound, on_appear, track=(team, is_local, army), REQUIRE=player)]
def narrator_track_player(evt : Event; is_local : bool; army : string; team : int)
  if is_local
    query() <| $ [es] (narrator_settings__nativeLang : bool; narrator_settings__banksPresetStartsWith : string; narrator_settings__defaultPreset : string)
      query() <| $ [es] (var narrator__banksPreset : das_string&)
        narrator_load_preset_impl(army, team, narrator_settings__nativeLang, narrator_settings__banksPresetStartsWith, narrator_settings__defaultPreset, narrator__banksPreset)


[es(tag=sound, on_appear, track=narrator_settings__nativeLang)]
def narrator_track_settings(evt : Event; narrator_settings__nativeLang : bool; narrator_settings__banksPresetStartsWith : string; narrator_settings__defaultPreset : string)
  query(get_local_player_eid()) <| $ [es] (army : string; team : int)
    query() <| $ [es] (var narrator__banksPreset : das_string&)
      narrator_load_preset_impl(army, team, narrator_settings__nativeLang, narrator_settings__banksPresetStartsWith, narrator_settings__defaultPreset, narrator__banksPreset)


[es(tag=sound, on_appear, REQUIRE=narrator__banksPreset)]
def narrator_load_preset(evt : Event; var narrator__banksPreset : das_string&)
  query(get_local_player_eid()) <| $ [es] (army : string; team : int)
    query() <| $ [es] (narrator_settings__nativeLang : bool; narrator_settings__banksPresetStartsWith : string; narrator_settings__defaultPreset : string)
      narrator_load_preset_impl(army, team, narrator_settings__nativeLang, narrator_settings__banksPresetStartsWith, narrator_settings__defaultPreset, narrator__banksPreset)



[es(tag=sound, on_disappear)]
def narrator_unload_preset(evt : Event;
                           var narrator__banksPreset : das_string&)
  enable_preset_impl(string(narrator__banksPreset), false)
  narrator__banksPreset := ""
