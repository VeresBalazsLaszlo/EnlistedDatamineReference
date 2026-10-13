require ecs
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

[es(tag=server, on_appear, track=(animchar_attach__attachedTo, base_vis_item__hideNodesInEntity))]
def hiding_attach_track_es_event_handler(evt : Event;
                                         animchar_attach__attachedTo : EntityId;
                                         base_vis_item__hideFromNode : StringList;
                                         var base_vis_item__hideNodesInEntity : EntityId&)
  if animchar_attach__attachedTo == base_vis_item__hideNodesInEntity
    return

  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, CmdClearHiddenNode(nodeName = string(node)))

  if doesEntityExist(animchar_attach__attachedTo)
    for node in base_vis_item__hideFromNode
      sendEvent(animchar_attach__attachedTo, CmdSetHideNode(nodeName = string(node)))

  base_vis_item__hideNodesInEntity = animchar_attach__attachedTo


[es(tag=server, on_disappear, REQUIRE=animchar_attach__attachedTo)]
def disappear_attach_track_es_event_handler(evt : Event;
                                            base_vis_item__hideFromNode : StringList;
                                            var base_vis_item__hideNodesInEntity : EntityId&)
  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, CmdClearHiddenNode(nodeName = string(node)))

  base_vis_item__hideNodesInEntity = INVALID_ENTITY_ID
