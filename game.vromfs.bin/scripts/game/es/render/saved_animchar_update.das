require ecs
require DagorMath
require AnimV20
require DagorSystem
require DagorMath
require GeomNodeTree

def save_cur_geom_node_tree(animchar : AnimcharBaseComponent&;
                            var saved_animchar : AnimcharBaseComponent)
  assume nodeTree = *(animchar.nodeTree)
  assume savedNodeTree = *(saved_animchar.nodeTree)
  geomtree_setWtmOfs(savedNodeTree, geomtree_getWtmOfs(nodeTree))
  let nodeCount = nodeTree.nodeCount
  if savedNodeTree.nodeCount != nodeCount
    logerr("Incorrect animchar res inited for saved animchar")
    return
  for i in range(0, int(nodeCount))
    geomtree_getNodeTm(savedNodeTree, i) = geomtree_getNodeTm(nodeTree, i)
    geomtree_getNodeWtmRel(savedNodeTree, i) = geomtree_getNodeWtmRel(nodeTree, i)


[es(tag=gameClient, no_order, REQUIRE=vehicleWithWatched)]
def skeleton_attach_save_for_watched_vehicle_es(info : UpdateStageInfoAct;
                                                animchar : AnimcharBaseComponent&;
                                                var saved_animchar : AnimcharBaseComponent)
  save_cur_geom_node_tree(animchar, saved_animchar)