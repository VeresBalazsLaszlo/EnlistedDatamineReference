require ecs
require sound_utils.modules.sound_player_common


[es(tag=sound, on_event=EventOnApplyTornWound)]
def human_torn_wound_sound(evt : Event;
                           @shared_comp human_torn_wound_sound__path : Object;
                           is_watched_sound : bool;
                           sound_tags : Object;
                           transform : float3x4)
  play_path(human_torn_wound_sound__path, sound_tags, is_watched_sound, transform[3])
