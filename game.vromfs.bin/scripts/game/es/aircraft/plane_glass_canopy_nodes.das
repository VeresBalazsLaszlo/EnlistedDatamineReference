require ecs
require CollRes
require DagorSystem


[es(tag=sound, on_appear)]
def plane_glass_canopy_nodes(evt : Event;
                             eid : EntityId;
                             collres : CollisionResource;
                             plane_glassCanopyNodes : StringList;
                             var plane_glassCanopyNodeIds : IntList&)
  for nodeName in plane_glassCanopyNodes
    let nodeIdx = collres_get_node_index_by_name(collres, string(nodeName))
    if nodeIdx < 0
      logerr("Canopy node {nodeName} was not found in {eid} <{getEntityTemplateName(eid)}>")
    else
      push(plane_glassCanopyNodeIds, nodeIdx)
