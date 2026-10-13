require ecs


[es(tag=server, on_appear, track=walker_agent__priorityTarget)]
def zombie_aggro_net_sound_state(evt : Event;
                                 walker_agent__priorityTarget : EntityId;
                                 var zombie_aggro_net_sound_state__isAggressive : bool&)
  zombie_aggro_net_sound_state__isAggressive ||= !!walker_agent__priorityTarget
