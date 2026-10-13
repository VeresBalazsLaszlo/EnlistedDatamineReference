require ecs
require sound_utils.modules.sound_player_common


[es(tag=sound, REQUIRE=(humanSound, watchedByPlr), on_event=RequestSuicide)]
def human_request_suicide_sound(evt : Event;
                                sound_preset__isLoaded : bool;
                                @shared_comp sound_paths : Object;
                                transform : float3x4;
                                sound_tags : Object)
  if sound_preset__isLoaded
    sound_player_common::play_path("suicide", sound_paths, sound_tags, true/*is_watched_sound*/, transform[3])
