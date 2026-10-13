require DagorSystem
require ecs.common
require ecs
require GeomNodeTree
require AnimV20
require EcsUtils
require enlisted.events_enlisted
require DngNet

def swap_yz(var tm : float3x4)
  let yTmVec = tm[1]
  tm[1] = tm[2]
  tm[2] = yTmVec

[es(tag=gameClient)]
def node_attached_init_es(evt : SetVehicleDecor;
                          eid : EntityId;
                          animchar : AnimcharBaseComponent;
                          var attach_decorators__entities : EidList&)
  let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, evt.nodeName)
  if nodeId <= -1
    logerr("Invalid node /*{evt.nodeName}*/ on target /*{getEntityTemplateName(eid)}*/")
    return

  let decorEid = createEntity("{evt.templateName}+node_attached_itm") <| $(var init &)
    init |> set("node_attached__nodeId", nodeId)
    init |> set("node_attached__entity", eid)
    init |> set("node_attached__localTm", evt.relativeTm)
    init |> set("decor__id", evt.slotId)
  attach_decorators__entities |> push(decorEid)

[es(on_event=ClearVehicleDecor, REQUIRE=attach_decorators__templates)]
def clear_decors_for_vehicle_es(evt : Event; var attach_decorators__entities : EidList; var replicated_attach_decorators__entities : EidList?)
  var len = length(attach_decorators__entities)
  for ind in range(len)
    let decorEid = attach_decorators__entities[len - 1 - ind]
    if !(get_bool(decorEid, "decor__preinited") ?? true)
      destroyEntity(decorEid)
      erase(attach_decorators__entities, len - 1 - ind)

  if is_server() && replicated_attach_decorators__entities != null
    len = length(*replicated_attach_decorators__entities)
    for ind in range(len)
      let decorEid = (*replicated_attach_decorators__entities)[len - 1 - ind]
      if !(get_bool(decorEid, "decor__preinited") ?? true)
        destroyEntity(decorEid)
        erase(*replicated_attach_decorators__entities, len - 1 - ind)

[es(on_event=(EventEntityDestroyed, EventEntityDied), REQUIRE=attach_decorators__templates)]
def destroy_decors_for_vehicle_es(evt : Event; var attach_decorators__entities : EidList; var replicated_attach_decorators__entities : EidList?)
  for decorEid in attach_decorators__entities
    destroyEntity(decorEid)
  attach_decorators__entities |> clear()
  if is_server() && replicated_attach_decorators__entities != null
    for decorEid in *replicated_attach_decorators__entities
      destroyEntity(decorEid)
    *replicated_attach_decorators__entities |> clear()

def init_decor(eid; var eid_list : EidList; for_replicated)
  clear(eid_list)
  query(eid) <| $ [es] (attach_decorators__templates : Array;
                        animchar : AnimcharBaseComponent)
    for i in iter_range(attach_decorators__templates)
      let obj = get_ecs_object(attach_decorators__templates[i])
      if obj == null
        continue
      let decorTemplate = get_string(*obj, "template", "")
      let nodeName = get_string(*obj, "nodeName", "")
      let preinited = get_bool(*obj, "preinited") ?? false
      let relativeTM = get_TMatrix(obj, "relativeTm")
      if decorTemplate == "" || relativeTM == null
        logerr("can't create all decor for /*{eid}*/ and /*{getEntityTemplateName(eid)}*/, some of them hasn't template or tm")
        continue
      let templ = getTemplateByName(decorTemplate)
      if templ == null
        continue
      if templateHasComponent(*templ, "replicated_node_attached__entity") != for_replicated
        continue
      let attachNodeId = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
      if (attachNodeId == -1)
        logerr("Decor attach node /*{nodeName}*/ was not found.")
        continue
      var testTm = *relativeTM
      let swapYZ = get_bool(*obj, "swapYZ") ?? true
      if swapYZ
        swap_yz(testTm)
      let prefix = for_replicated ? "replicated_" : ""
      let templForCreate = "{decorTemplate}" + (for_replicated ? "" : "+node_attached_itm")
      let decorEid = createEntity(templForCreate) <| $(var init : ComponentsInitializer)
        set(init, "{prefix}node_attached__entity", eid)
        set(init, "{prefix}node_attached__nodeId", attachNodeId)
        set(init, "{prefix}node_attached__localTm", testTm)
        set(init, "decor__preinited", preinited)
        set(init, "decor__id", i)
        set(init, "decor__swapYZ", swapYZ)

      push(eid_list, decorEid)

[es(tag=server, on_appear)]
def init_replicated_decors_for_vehicle_es(evt : Event;
                                          eid : EntityId;
                                          var replicated_attach_decorators__entities : EidList&)
  init_decor(eid, replicated_attach_decorators__entities, true)


[es(tag=gameClient, on_appear)]
def init_decors_for_vehicle_es(evt : Event;
                               eid : EntityId;
                               var attach_decorators__entities : EidList&)
  init_decor(eid, attach_decorators__entities, false)

[es(tag=gameClient, before=node_attached_itm, REQUIRE=daeditor__selected)]
def debug_setup_for_decors(info : ParallelUpdateFrameDelayed;
                           node_attached__entity : EntityId;
                           node_attached__nodeId : int;
                           decor__id : int;
                           transform : float3x4;
                           decor__swapYZ : bool;
                           var node_attached__localTm : float3x4)
  if decor__id < 0
    return
  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent;
                                          var attach_decorators__templates : Array)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    var decorRelativeTm = inverse(tm) * transform
    node_attached__localTm = decorRelativeTm
    if decor__swapYZ
      swap_yz(decorRelativeTm)
    var obj = getRW_ecs_object(attach_decorators__templates[decor__id])
    *obj |> set("relativeTm", decorRelativeTm)


[es(tag=gameClient, track=isExploded, REQUIRE=vehicle)]
def vehicle_burn_decorators_es(evt : Event;
                               attach_decorators__entities : EidList;
                               replicated_attach_decorators__entities : EidList const?;
                               isExploded aka vehicle_isExploded : bool)
  for decorEid in attach_decorators__entities
    query(decorEid) <| $ [es] (var isExploded : bool&)
      isExploded = vehicle_isExploded
  if replicated_attach_decorators__entities != null
    for decorEid in *replicated_attach_decorators__entities
      query(decorEid) <| $ [es] (var isExploded : bool&)
        isExploded = vehicle_isExploded

[es(tag=gameClient, track=animchar_render__enabled)]
def decor_visibility_es(evt : Event;
                        animchar_render__enabled : bool;
                        replicated_attach_decorators__entities : EidList const?;
                        attach_decorators__entities : EidList)
  for decorEid in attach_decorators__entities
    set(decorEid, "animchar_render__enabled", animchar_render__enabled)

  if replicated_attach_decorators__entities != null
    for decorEid in *replicated_attach_decorators__entities
      set(decorEid, "animchar_render__enabled", animchar_render__enabled)
