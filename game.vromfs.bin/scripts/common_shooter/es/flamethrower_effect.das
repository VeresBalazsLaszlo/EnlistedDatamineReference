require ecs
require AnimV20
require GeomNodeTree
require math.base
require DagorSystem

def manage_stream_effect(flamethrower_eid : EntityId;
                         animchar_eid : EntityId;
                         animchar : AnimcharBaseComponent)
  query(flamethrower_eid) <| $ [es] (flamethrower__active : bool;
                                     flamethrower__flameCurrentLength : float;
                                     flamethrower__maxFlameLength : float;
                                     flamethrower__streamEffectTemplate : string;
                                     flamethrower__streamEffectNodeIdx : int;
                                     flamethrower__streamEffectLocalTm : float3x4 const? = null;
                                     flamethrower__stramEffectEps : float = 0.001;
                                     var flamethrower__streamEffectEid : EntityId&)
    if flamethrower__active
      if !flamethrower__streamEffectEid && flamethrower__streamEffectNodeIdx >= 0
        let streamTemplateName = add_sub_template_name(flamethrower__streamEffectTemplate, "node_attached_itm")
        flamethrower__streamEffectEid = createEntity(streamTemplateName) <| $(var init : ComponentsInitializer)
          var localTm = flamethrower__streamEffectLocalTm != null ? *flamethrower__streamEffectLocalTm : IDENT_TM
          localTm[1] *= max(flamethrower__stramEffectEps, flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
          var tm : float3x4
          geomtree_getNodeWtmScalar(*animchar.nodeTree, flamethrower__streamEffectNodeIdx, tm)
          set(init, "transform", tm * localTm)
          set(init, "node_attached__entity", animchar_eid)
          set(init, "node_attached__nodeId", flamethrower__streamEffectNodeIdx)
          set(init, "node_attached__localTm", localTm)
    elif flamethrower__streamEffectEid != INVALID_ENTITY_ID
      destroyEntity(flamethrower__streamEffectEid)
      flamethrower__streamEffectEid = INVALID_ENTITY_ID

[es(on_appear, REQUIRE_NOT=subsidiaryFlamethrower)]
def flamethrower_init_effect(evt : Event;
                             eid : EntityId;
                             animchar : AnimcharBaseComponent;
                             flamethrower__streamEffectNodeName : string;
                             var flamethrower__streamEffectNodeIdx : int&)
  let nodeName = flamethrower__streamEffectNodeName
  flamethrower__streamEffectNodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
  if flamethrower__streamEffectNodeIdx == -1
    logerr("/*{getEntityTemplateName(eid)}*/ does not have /*{nodeName}*/ animchar node. Failed to assign flamethrower.streamEffectNodeIdx")

[es(tag=gameClient, track=flamethrower__active,  REQUIRE=flamethrower__active, REQUIRE_NOT=subsidiaryFlamethrower)]
def flamethrower_manage_stream_effect(evt : Event;
                                      eid : EntityId;
                                      animchar : AnimcharBaseComponent)
  manage_stream_effect(eid, eid, animchar)

[es(tag=gameClient, track=flamethrower__flameCurrentLength)]
def flamethrower_stream_effect_distance(evt : Event;
                                        flamethrower__flameCurrentLength : float;
                                        flamethrower__maxFlameLength : float;
                                        flamethrower__streamEffectEid : EntityId;
                                        flamethrower__streamEffectLocalTm : float3x4 const?;
                                        flamethrower__stramEffectEps = 0.001)
  if !!flamethrower__streamEffectEid
    query(flamethrower__streamEffectEid) <| $ [es] (var node_attached__localTm : float3x4&)
      let lenMul = max(flamethrower__stramEffectEps, flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
      node_attached__localTm[1] = (flamethrower__streamEffectLocalTm ?? IDENT_TM)[1] * lenMul

[es(tag=gameClient, track=flamethrower__active, REQUIRE=flamethrower__active)]
def flamethrower_turret_manage_stream_effect(evt : Event;
                                             eid : EntityId;
                                             turret__flashNodeId : int;
                                             turret__owner : EntityId;
                                             var flamethrower__streamEffectNodeIdx : int&)
  flamethrower__streamEffectNodeIdx = turret__flashNodeId
  query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
    manage_stream_effect(eid, turret__owner, animchar)


[es(on_appear, REQUIRE=subsidiaryFlamethrower)]
def subsidiary_flamethrower_init_effect(evt : Event;
                                        eid : EntityId;
                                        animchar_attach__attachedTo : EntityId;
                                        flamethrower__streamEffectNodeName : string;
                                        var flamethrower__streamEffectNodeIdx : int&)
  query(animchar_attach__attachedTo) <| $ [es] (animchar : AnimcharBaseComponent)
    let nodeName = flamethrower__streamEffectNodeName
    flamethrower__streamEffectNodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
    if flamethrower__streamEffectNodeIdx == -1
      logerr("/*{getEntityTemplateName(eid)}*/ parent does not have /*{nodeName}*/ animchar node for subsidiary flamethrower")

[es(tag=gameClient, track=flamethrower__active, REQUIRE=(flamethrower__active, subsidiaryFlamethrower))]
def subsidiary_flamethrower_manage_stream_effect(evt : Event;
                                                 eid : EntityId;
                                                 animchar_attach__attachedTo : EntityId)
  query(animchar_attach__attachedTo) <| $ [es] (animchar : AnimcharBaseComponent)
    manage_stream_effect(eid, animchar_attach__attachedTo, animchar)

[es(tag=server, track=human_gun_attached)]
def flamethrower_disable_unattached(evt : Event;
                                    human_gun_attached : bool;
                                    var flamethrower__active : bool&)
  if !human_gun_attached
    flamethrower__active = false
