require ecs
require soundEvent
require soundSystem
require sound_utils.modules.sound_player_common
require DagorMath


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(animchar_before_render_es, shell_fly_sound_with_transform, shell_fly_sound_with_ballistics, sound_begin_update_es), before=sound_end_update_es)]
def projectile_lifetime_sound(evt : Event;
                              projectile_lifetime_sound__path : string;
                              var projectile_lifetime_sound__event : SoundEvent&;
                              projectile__lifeTime : float;
                              projectile__minLifeTime : float;
                              projectile__exploded : bool;
                              projectile__stopped : bool;
                              transform : float3x4)
  let shouldPlay = !projectile__exploded && !projectile__stopped && projectile__lifeTime > 0. && projectile__lifeTime < projectile__minLifeTime && sound_banks_is_master_preset_loaded()
  if projectile_lifetime_sound__event |> play_or_abandon(projectile_lifetime_sound__path, transform[3], shouldPlay)
    set_var(projectile_lifetime_sound__event, "bomb_timer", cvt(projectile__lifeTime, 0., projectile__minLifeTime, 1., 0.))
