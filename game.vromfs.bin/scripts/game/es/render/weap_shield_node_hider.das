require ecs
require AnimV20

[es(tag=gameClient, on_appear)]
def weap_anim_shield_node_hider(evt : Event;
                                weap_anim__gunShieldNodeName : string;
                                var animchar_render : AnimcharRendComponent)
  assume sceneInstance = animchar_render.sceneInstance
  let nodeId = *sceneInstance |> scene_instance_getNodeId(weap_anim__gunShieldNodeName)
  if nodeId >= 0
    sceneInstance |> scene_instance_show_node(nodeId, false)
