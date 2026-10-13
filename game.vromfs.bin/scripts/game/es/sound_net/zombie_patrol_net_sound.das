require ecs
require game.utils.sound_utils


[es(tag=server, on_appear)]
def zombie_patrol_spawn_net_sound(evt : Event;
                                  zombie_patrol_spawn_net_sound__desc : string)
  broadcast_scene_net_sound(zombie_patrol_spawn_net_sound__desc, float3(0., 0., 0.))
