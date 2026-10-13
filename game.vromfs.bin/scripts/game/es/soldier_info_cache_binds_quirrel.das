require ecs.ecs_quirrel
require daslib/quirrel_boost

[quirrel_bind(module_name="das.soldier_info_cache")]
def get_soldier_info_from_cache(soldier_eid : EntityId)
  var soldierObj : Object const?
  query() <| $ [es] (soldierInfoCache : Object)
    soldierObj = get_ecs_object(soldierInfoCache, "{soldier_eid}")
  return soldierObj
