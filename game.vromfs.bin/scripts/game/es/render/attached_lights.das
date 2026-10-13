require ecs
require ecs.common
require game.es.node_attach_common
require game.es.events
require AnimV20
require GeomNodeTree
require DagorSystem
require math.base


def attached_lights_cleanup(var attached_lights_eids : EidList)
  for lightEid in attached_lights_eids
    destroyEntity(lightEid)
  clear(attached_lights_eids)

[es(tag=render, on_appear)]
def attached_lights_create(evt : Event;
                           eid : ecs::EntityId;
                           animchar : AnimcharBaseComponent;
                           attached_lights : Array;
                           var attached_lights_eids : EidList)
  resize(attached_lights_eids, length(attached_lights))
  for i in iter_range(attached_lights)
    let lightObj = get_ecs_object(attached_lights[i])
    if lightObj == null
      continue
    attached_lights_eids[i] = createEntity(get_string(lightObj, "template", ""))
    let attachNodeName = get_string(lightObj, "node", "")
    let attachNodeId = geomtree_findNodeIndex(*animchar.nodeTree, attachNodeName)
    if (attachNodeId == -1)
      logerr("Light attach node /*{attachNodeName}*/ was not found.")
      continue
    let attachLocTm = get_TMatrix(lightObj, "tm") ?? IDENT_TM
    attach_to_node(attached_lights_eids[i], eid, attachNodeId, attachLocTm)

[es(tag=render, on_appear, before=attached_lights_enable)]
def attached_light_init(evt : Event;
                        var light__brightness : float&;
                        var light__stored_brightness : float&)
  light__stored_brightness = light__brightness
  light__brightness = 0f

[es(tag=render, track=attached_lights_enabled)]
def attached_lights_input(evt : Event;
                          attached_lights_eids : EidList;
                          attached_lights_enabled : BoolList)
  for lightEid in attached_lights_eids
    query(lightEid) <| $ [es] (light_type : int; var light__brightness : float&; var light__stored_brightness : float&)
      assert(light_type < length(attached_lights_enabled))
      if attached_lights_enabled[light_type]
        light__brightness = light__stored_brightness
      elif light__brightness > FLT_EPSILON
        light__stored_brightness = light__brightness
        light__brightness = 0f

[es(tag=render, on_appear)]
def attached_lights_enable(evt : Event;
                           light_type : int;
                           node_attached__entity : EntityId;
                           var light__brightness : float&;
                           var light__stored_brightness : float&)
  query(node_attached__entity) <| $ [es] (attached_lights_enabled : BoolList)
    if attached_lights_enabled[light_type]
      light__brightness = light__stored_brightness
    elif light__brightness > FLT_EPSILON
      light__stored_brightness = light__brightness
      light__brightness = 0f


[es(tag=render)]
def attached_lights_destroy(evt : EventEntityDestroyed; var attached_lights_eids : EidList)
  attached_lights_cleanup(attached_lights_eids)
