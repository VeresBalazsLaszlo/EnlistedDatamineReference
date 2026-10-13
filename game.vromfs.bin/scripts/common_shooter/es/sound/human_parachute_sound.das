require ecs
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common


[es(tag=sound, track=human_parachute_anim__lastDeployState)]
def human_parachute_sound_open_close(evt : Event;
                                     sound_preset__isLoaded : bool;
                                     human_parachute_anim__lastDeployState : bool;
                                     human_parachute_sound__openPath : string;
                                     @shared_comp human_parachute_sound__closePath : Object;
                                     is_watched_sound : bool;
                                     sound_tags : Object;
                                     transform : float3x4)
  if human_parachute_anim__lastDeployState
    if is_watched_sound
      oneshot(human_parachute_sound__openPath)
  elif sound_preset__isLoaded
    sound_player_common::play_path(human_parachute_sound__closePath, sound_tags, is_watched_sound, transform[3])


[es(tag=sound, on_appear, track=(human_parachute_anim__lastDeployState, sound_preset__isLoaded), REQUIRE=watchedByPlr)]
def human_parachute_sound_toggle(evt : Event;
                                 sound_preset__isLoaded : bool;
                                 human_parachute_anim__lastDeployState : bool;
                                 human_parachute_sound__path : string;
                                 var sound_event_group : SoundEventGroup&;
                                 transform : float3x4)
  reject_sound(sound_event_group, sound_hash("parachute"))
  if human_parachute_anim__lastDeployState && sound_preset__isLoaded
    add_sound(sound_event_group, sound_hash("parachute"), play(human_parachute_sound__path, "", transform[3]))


[es(tag=sound, on_disappear, REQUIRE=(human_parachute_anim__lastDeployState, watchedByPlr))]
def human_parachute_sound_disappear(evt : Event;
                                    var sound_event_group : SoundEventGroup&)
  release_sound(sound_event_group, sound_hash("parachute"))


[es(tag=sound, track=isInVehicle, REQUIRE=watchedByPlr)]
def paratrooper_jump_sound(evt : Event;
                           paratrooper_jump_sound__path : string;
                           isInVehicle : bool;
                           vehicle__lastEid : EntityId;
                           transform : float3x4)
  if !isInVehicle
    query(vehicle__lastEid) <| $ [es(REQUIRE=paratroopersAircraft)] ()
      oneshot(paratrooper_jump_sound__path, transform[3])
