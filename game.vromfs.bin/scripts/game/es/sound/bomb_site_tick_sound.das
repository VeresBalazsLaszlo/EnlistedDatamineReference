require ecs
require DagorMath
require soundEvent
require soundSystem
require enlisted.events_enlisted
require sound_utils.modules.sound_player_common


[es(tag=sound, after=sound_begin_update_es, before=sound_end_update_es)]
def bomb_site_tick_sound(info : ParallelUpdateFrameDelayed;
                         bomb_site__explosionTimeEnd : float;
                         bomb_site__timeToExplosion : float;
                         bomb_site_tick_sound__path : string;
                         var bomb_site_tick_sound__event : SoundEvent&;
                         transform : float3x4)
  let shouldPlay = bomb_site__explosionTimeEnd > 0. && sound_banks_is_master_preset_loaded()
  if bomb_site_tick_sound__event |> play_or_release(bomb_site_tick_sound__path, transform[3], shouldPlay)
    let t = cvt(info.curTime, bomb_site__explosionTimeEnd - bomb_site__timeToExplosion, bomb_site__explosionTimeEnd, 0., 1.)
    set_var(bomb_site_tick_sound__event, "explosive_timer", t)
