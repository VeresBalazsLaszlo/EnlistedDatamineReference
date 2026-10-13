require ecs
require DagorMath
require soundEvent
require soundSystem
require common_shooter.es.sound.gun_sound_common
require sound_utils.modules.sound_player_common


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(gun_overheat_es, sound_begin_update_es), before=sound_end_update_es)]
def gun_overheat_sound(evt : Event;
                       gun__owner : EntityId;
                       gun__overheat : float;
                       gun_overheat_sound__path : string;
                       gun_overheat_sound__gunOverheatToVar : float2;
                       var gun_overheat_sound__event : SoundEvent&)
  let shouldPlay = gun__overheat > gun_overheat_sound__gunOverheatToVar.x && is_watched_gun_sound(gun__owner) && sound_banks_is_master_preset_loaded()
  if gun_overheat_sound__event |> play_or_abandon(gun_overheat_sound__path, get_listener_pos(), shouldPlay)
    set_var(gun_overheat_sound__event, "heat", cvt(gun__overheat, gun_overheat_sound__gunOverheatToVar.x, gun_overheat_sound__gunOverheatToVar.y, 0., 1.))
