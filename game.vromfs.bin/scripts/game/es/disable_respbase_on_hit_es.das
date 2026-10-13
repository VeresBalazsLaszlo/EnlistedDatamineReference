require ecs
require common_shooter.events_common_shooter
require math
require math.base

[es(tag=server)]
def disable_respbase_on_hit_es(evt : EventOnEntityHit)
  if evt.victim == evt.offender
    return

  query(evt.victim) <| $ [es] (transform : float3x4;
                               spawn_immunity__initialPos : float3 const&;
                               spawn_immunity__immuneDistance : float;
                               lastRespawnBaseEid : ecs::EntityId)
    if distance_sq(spawn_immunity__initialPos, transform[3]) <= square(spawn_immunity__immuneDistance)
      ecs::query(lastRespawnBaseEid) <| $ [es(REQUIRE=temporaryRespawnbase)] (var active : bool&; respawnBaseGroup : int)
        var needDeactivate = true
        find_query() <| $ [es(REQUIRE=respawn_activator__radius)] (respawn_activator__groupId : int)
          if respawn_activator__groupId == respawnBaseGroup
            needDeactivate = false
          return !needDeactivate
        if needDeactivate
          active = false
