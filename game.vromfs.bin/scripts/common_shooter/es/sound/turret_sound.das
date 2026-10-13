require ecs
require math.base
require soundEvent
require soundSystem
require turrets
require Gun
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_utils_events


def update_turret_sound(vel_h, vel_v : float; var event : SoundEvent&; path : string; pos : float3 const&)
  if event.enabled
    set_var(event, "velH", vel_h * RAD_TO_DEG)
    set_var(event, "velV", vel_v * RAD_TO_DEG)
    set_pos(event, pos)
  elif vel_h + vel_v > 1e-4
    event.enabled = true
    event |> play(path, pos)
    set_var(event, "velH", vel_h * RAD_TO_DEG)
    set_var(event, "velV", vel_v * RAD_TO_DEG)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE=turret_sound_group, after=sound_begin_update_es, before=sound_end_update_es)]
def turret_sound_group_update(evt : Event;
                              is_watched_sound : bool;
                              var turret_sound__event : SoundEvent&;
                              turret_sound__path : string;
                              turret_control__gunEids : EidList;
                              transform : float3x4 const&)
  if is_watched_sound && sound_banks_is_master_preset_loaded()
    var velH = 0.
    var velV = 0.
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_state : TurretState& const)
        velH = max(velH, abs(turret_state.speed.x))
        velV = max(velV, abs(turret_state.speed.y))
    update_turret_sound(velH, velV, turret_sound__event, turret_sound__path, transform[3])
  else
    abandon_play_or(turret_sound__event)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE_NOT=turret_sound_group, after=sound_begin_update_es, before=sound_end_update_es)]
def turret_sound_update(evt : Event;
                        is_watched_sound : bool;
                        turret_control__gunEids : EidList)
  if is_watched_sound
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=turret_sound_group)] (turret_state : TurretState& const;
                                                                                       gun : Gun& const;
                                                                                       var turret_sound__event : SoundEvent&;
                                                                                       turret_sound__path : string)
        if sound_banks_is_master_preset_loaded()
          let velH = abs(turret_state.speed.x)
          let velV = abs(turret_state.speed.y)
          update_turret_sound(velH, velV, turret_sound__event, turret_sound__path, gun.shootNodePos)


[es(tag=sound, REQUIRE_NOT=turret_sound_group, track=is_watched_sound)]
def turret_sound_disable(evt : Event;
                         is_watched_sound : bool;
                         turret_control__gunEids : EidList)
  if !is_watched_sound
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es] (var turret_sound__event : SoundEvent&)
        abandon_play_or(turret_sound__event)


[es(tag=sound)]
def turret_sound_on_unloaded(evt : EventOnMasterSoundPresetLoaded;
                             var turret_sound__event : SoundEvent&)
  if !evt.isLoaded
    release_play_or(turret_sound__event)
