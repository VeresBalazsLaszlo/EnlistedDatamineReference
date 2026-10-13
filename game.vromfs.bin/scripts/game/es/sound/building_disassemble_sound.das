require app
require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, track=(building_action__target, sound_preset__isLoaded))]
def building_disassemble_sound(evt : Event;
                               sound_preset__isLoaded : bool;
                               building_action__target : EntityId;
                               var sound_event_group : SoundEventGroup&;
                               transform : float3x4)
  reject_sound(sound_event_group, sound_hash("buildingDisassemble"))
  if sound_preset__isLoaded
    query(building_action__target) <| $ [es] (building_destroy__disassembleSound : string)
      sound_player_common::play_name_path("", building_destroy__disassembleSound, sound_hash("buildingDisassemble"), transform[3], sound_event_group)


[es(tag=sound, on_disappear, REQUIRE=building_action__target)]
def building_disassemble_sound_disappear(evt : Event;
                                         var sound_event_group : SoundEventGroup&)
  release_sound(sound_event_group, sound_hash("buildingDisassemble"))
