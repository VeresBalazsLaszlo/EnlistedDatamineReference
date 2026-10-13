require ecs
require soundEvent
require sound_utils_net.modules.sound_desc_common


[es(tag=sound, on_appear, REQUIRE_NOT=clientSide)]
def shell_launch_sound(evt : Event;
                       shell_launch_sound__name : string;
                       shell__owner : EntityId;
                       transform : float3x4)
  query(shell__owner) <| $ [es] (is_watched_sound : bool)
    oneshot("{get_watched_sound_event_folder(is_watched_sound)}/{shell_launch_sound__name}", transform[3])
