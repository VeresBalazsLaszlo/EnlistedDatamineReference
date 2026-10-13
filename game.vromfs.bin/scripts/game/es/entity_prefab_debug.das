options no_aot
require ecs
require enlisted.events_enlisted
// require game.events_game


[es(tag=dev, REQUIRE=daeditor__selected)]
def entity_prefab_update_relative_transform(info : ParallelUpdateFrameDelayed;
                                            transform aka child_transform : float3x4;
                                            entity_prefab__parentEid : EntityId;
                                            var relativeTransform : float3x4)
  query(entity_prefab__parentEid) <| $ [es(REQUIRE_NOT=daeditor__selected)] (transform aka parent_transform : float3x4)
    relativeTransform = inverse(parent_transform) * child_transform


[es(tag=dev, REQUIRE=daeditor__selected, after=entity_prefab_update_relative_transform)]
def entity_prefab_update_child_transforms(info : ParallelUpdateFrameDelayed;
                                          transform aka parent_transform : float3x4;
                                          entity_prefab__createdEntities : EidList)
  for childEid in entity_prefab__createdEntities
    query(childEid) <| $ [es] (relativeTransform : float3x4; var transform aka child_transform : float3x4)
      child_transform = parent_transform * relativeTransform


[es(tag=dev, REQUIRE=daeditor__previewEntity, after=entity_prefab_update_relative_transform)]
def entity_prefab_update_child_transforms_for_preview(info : ParallelUpdateFrameDelayed;
                                                      transform aka parent_transform : float3x4;
                                                      entity_prefab__createdEntities : EidList)
  for childEid in entity_prefab__createdEntities
    query(childEid) <| $ [es] (relativeTransform : float3x4; var transform aka child_transform : float3x4)
      child_transform = parent_transform * relativeTransform
