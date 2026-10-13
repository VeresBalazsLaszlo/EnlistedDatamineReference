require ecs
require game.utils.sound_utils


[es(tag=server, on_event=EventObjectiveActivated)]
def zombie_objective_activated_net_sound(evt : Event;
                                         zombie_objective_activated_net_sound__desc : string;
                                         transform : float3x4)
  broadcast_scene_net_sound(zombie_objective_activated_net_sound__desc, transform[3])
