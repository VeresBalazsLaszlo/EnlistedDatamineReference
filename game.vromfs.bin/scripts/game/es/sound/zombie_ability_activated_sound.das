require ecs
require soundEvent


[es(tag=sound, track=zombie_ability__activated)]
def zombie_ability_activated_sound(evt : Event;
                                   zombie_ability__activated : bool;
                                   zombie_ability_activated_sound__path : string;
                                   transform : float3x4)
  if zombie_ability__activated
    oneshot(zombie_ability_activated_sound__path, transform[3])
