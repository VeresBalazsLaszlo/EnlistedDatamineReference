require ecs
require ecs.safe
require game.es.events
require DagorDataBlock
require pathfinder

[es(tag=server, on_event=EventLevelLoaded)]
def custom_pathfinder_weights_init_es(evt : Event)
  query() <| $ [es] (custom_pathfinder_weights__navMeshIdx : int;
                     custom_pathfinder_weights__params : Object)
    using() <| $(var blk : DataBlock)
      for param in custom_pathfinder_weights__params
        let paramName = param.key
        let valFloat = param.value as float
        let valBool = param.value as bool
        if valFloat != null
          blk |> set(paramName, *valFloat)
        elif valBool != null
          blk |> set(paramName, *valBool)
      override_pathfinder_weights_ex(custom_pathfinder_weights__navMeshIdx, blk)
