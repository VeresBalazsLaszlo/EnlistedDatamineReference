require ecs
require soundEvent
require sound_utils.modules.sound_control_common

[es(tag=sound, track=sound_control__state)]
def loudspeaker_sound_track(evt : Event;
                            sound_control__state : int;
                            loudspeaker_sound__path : string;
                            var loudspeaker_sound__event : SoundEvent&;
                            transform : float3x4)
  release(loudspeaker_sound__event)
  if have_sound(sound_control__state)
    loudspeaker_sound__event |> play(loudspeaker_sound__path, transform[3])
