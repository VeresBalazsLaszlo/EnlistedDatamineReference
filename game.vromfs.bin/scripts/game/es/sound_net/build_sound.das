require app
require ecs
require game.utils.sound_utils
require strings


[es(on_appear, tag=server)]
def build_sound(evt : Event;
                buildSoundTag : string;
                buildByEngineerEid : EntityId;
                transform : float3x4)
  if !empty(buildSoundTag) && buildByEngineerEid != INVALID_ENTITY_ID
    broadcast_net_sound(buildByEngineerEid, "createBuilding_{buildSoundTag}", transform[3])
