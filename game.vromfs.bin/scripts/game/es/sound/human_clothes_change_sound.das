require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, on_appear, track=(spy_soldier__clothesChangeEndTime, is_watched_sound, isAlive, sound_preset__isLoaded))]
def human_clothes_change_sound(evt : Event;
                               spy_soldier__clothesChangeEndTime : float;
                               is_watched_sound : bool;
                               isAlive : bool;
                               sound_preset__isLoaded : bool;
                               sound_tags : Object;
                               var sound_event_group : SoundEventGroup&;
                               transform : float3x4;
                               @shared_comp human_clothes_change_sound__path : Object)

  reject_sound(sound_event_group, sound_hash("clothesChange"))
  if spy_soldier__clothesChangeEndTime != -1. && isAlive && sound_preset__isLoaded
    sound_player_common::play_path(human_clothes_change_sound__path, sound_tags, is_watched_sound, transform[3], sound_hash("clothesChange"), sound_event_group)
