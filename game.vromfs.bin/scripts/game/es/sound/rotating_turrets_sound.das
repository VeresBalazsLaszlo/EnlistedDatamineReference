require ecs
require DaWeapons
require sound_utils.modules.sound_player_common
require soundEvent
require DagorMath


[es(tag=sound, track=(is_watched_sound, sound_preset__isLoaded), REQUIRE=(is_watched_sound, sound_preset__isLoaded))]
def rotating_turrets_sound_toggle(evt : Event;
                                  var rotating_turrets_sound__event : SoundEvent&)
  abandon_play_or(rotating_turrets_sound__event)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=sound_begin_update_es, before=sound_end_update_es)]
def rotating_turrets_sound_update(evt : Event;
                                  sound_preset__isLoaded : bool;
                                  @shared_comp rotating_turrets_sound__path : Object;
                                  var rotating_turrets_sound__event : SoundEvent&;
                                  rotating_turrets_sound__omegaLoThreshold : float;
                                  var rotating_turrets_sound__omega : float&;
                                  turret_control__gunEids : EidList;
                                  is_watched_sound : bool;
                                  sound_tags : Object;
                                  transform : float3x4)

  var omega = 0.
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (rotate_turret__curOmega, rotate_turret__omegaMax : float)
      omega = max(omega, safediv(rotate_turret__curOmega, rotate_turret__omegaMax))

  let acc = omega - rotating_turrets_sound__omega
  rotating_turrets_sound__omega = omega

  if !sound_preset__isLoaded
    return

  let threshold = acc >= 0. ? 0. : rotating_turrets_sound__omegaLoThreshold
  let shouldPlay = omega > threshold
  if rotating_turrets_sound__event.enabled != shouldPlay
    rotating_turrets_sound__event.enabled = shouldPlay
    if shouldPlay
      abandon(rotating_turrets_sound__event)
      rotating_turrets_sound__event |> reset(sound_player_common::play_path(rotating_turrets_sound__path, sound_tags, is_watched_sound, transform[3], false))
    else
      keyoff(rotating_turrets_sound__event)

  if is_valid_handle_value(rotating_turrets_sound__event)
    if is_playing(rotating_turrets_sound__event)
      set_var(rotating_turrets_sound__event, "omega", omega)
      set_pos(rotating_turrets_sound__event, transform[3])
    else
      release(rotating_turrets_sound__event)
