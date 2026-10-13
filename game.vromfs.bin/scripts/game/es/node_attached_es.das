require ecs
require game.es.events
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted
require dm
require DngDm
require game.es.vehicle.vehicle_events
require app
require PhysDecl
require Dacoll
require DngNet
require danetlibs.navmesh_phys.main.nphys_events
require math.random
require DagorMathUtils
require math.base
require common_shooter.events_common_shooter

[es(REQUIRE_NOT=deadEntity, after=after_animchar_update_sync)]
def replicated_node_attached_itm(info : ParallelUpdateFrameDelayed;
                                 replicated_node_attached__entity : EntityId;
                                 replicated_node_attached__nodeId : int;
                                 replicated_node_attached__localTm : float3x4;
                                 var transform : float3x4&)
  if replicated_node_attached__nodeId < 0
    return

  query(replicated_node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, replicated_node_attached__nodeId, tm)
    transform = tm * replicated_node_attached__localTm

[es(tag=gameClient, after=replicated_node_attached_itm)]
def replicated_node_attached_update_animchar_es(info : ParallelUpdateFrameDelayed;
                                                transform : float3x4;
                                                replicated_node_attached__nodeId : int;
                                                var animchar : AnimcharBaseComponent;
                                                var animchar_node_wtm : AnimcharNodesMat44&;
                                                var animchar_render__root_pos : vec4f&)
  if replicated_node_attached__nodeId < 0
    return
  animchar_set_tm(animchar, transform, true)
  animchar_recalc_wtm(animchar)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

[es(tag=server)]
def volumetric_damage_on_decor_with_dm(evt : EventOnVolumetricDamage;
                                       var isAlive : bool&;
                                       decor__considerAsAliveThreshold : float;
                                       var decor_with_dm__deathHpDelta : float&;
                                       bodyCleanupTime : float;
                                       eid : EntityId;
                                       damage_model : DamageModel&)
  decor_with_dm__deathHpDelta = float(uint(get_damage_part_props(damage_model.dmData, 0).relHpFixed))
  if uint(get_damage_part_props(damage_model.dmData, 0).relHpFixed) < uint(decor__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
    isAlive = false
    decor_with_dm__deathHpDelta = float(decor_with_dm__deathHpDelta - float(uint(get_damage_part_props(damage_model.dmData, 0).relHpFixed))) / float(MAX_REL_HP_FIXED)
    sendEvent(eid, CmdBodyCleanup(time = bodyCleanupTime))

[es(tag=server)]
def part_damage_on_decor_with_dm(evt : EventOnPartDamaged;
                                 var isAlive : bool&;
                                 decor__considerAsAliveThreshold : float;
                                 bodyCleanupTime : float;
                                 transform : float3x4;
                                 var decor_with_dm__ragdollVel : float3&;
                                 var decor_with_dm__deathHpDelta : float&;
                                 eid : EntityId;
                                 damage_model : DamageModel&)
  if uint(get_damage_part_props(damage_model.dmData, 0).relHpFixed) < uint(decor__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
    isAlive = false
    decor_with_dm__ragdollVel = reflect(rotate(transform, float3(0., 1., 0)), evt.hitData.dir)
    decor_with_dm__deathHpDelta = (float(evt.prevHpFixed) - float(evt.hpFixed)) / float(MAX_REL_HP_FIXED) * 10.
    sendEvent(eid, CmdBodyCleanup(time = bodyCleanupTime))

[es(tag=gameClient, on_appear, tag=gameClient)]
def start_decor_with_dm_ragdoll_on_death(evt : Event;
                                         eid : EntityId;
                                         transform : float3x4;
                                         decor_with_dm__ragdollVel : float3;
                                         decor_with_dm__ragdollVelAngleVariation : float;
                                         decor_with_dm__ragdollVelMin : float;
                                         decor_with_dm__ragdollVelDeathHpScale : float;
                                         decor_with_dm__ragdollVelVariation : float;
                                         decor_with_dm__ragdollOmega : float;
                                         decor_with_dm__deathHpDelta : float;
                                         var ragdoll : PhysRagdoll?;
                                         var animchar__updatable : bool&;
                                         var ragdoll__applyParams : bool&;
                                         var animchar : AnimcharBaseComponent;
                                         var ragdoll__active : bool&)
  ragdoll__active = true

  if ragdoll == null || distance_sq(transform[3], get_hidden_pos()) < 1.0
    return

  animchar__updatable = true

  var vel = decor_with_dm__ragdollVel
  if decor_with_dm__ragdollVel == float3()
    vel = rotate(transform, float3(0., 1., 0.))
    var angle = dir_to_angles(normalize(vel))
    angle.x += deg_to_rad(rnd_float(-decor_with_dm__ragdollVelAngleVariation, decor_with_dm__ragdollVelAngleVariation))
    angle.y += deg_to_rad(rnd_float(-decor_with_dm__ragdollVelAngleVariation, decor_with_dm__ragdollVelAngleVariation))
    vel = angles_to_dir(angle)

  vel *= decor_with_dm__ragdollVelMin + decor_with_dm__ragdollVelDeathHpScale * decor_with_dm__deathHpDelta + rnd_float(-decor_with_dm__ragdollVelVariation, decor_with_dm__ragdollVelVariation)

  *ragdoll |> ragdoll_setOverrideVel(vel)
  let omega = rnd_dir3() * decor_with_dm__ragdollOmega
  *ragdoll |> ragdoll_setOverrideOmega(omega)
  *ragdoll |> ragdoll_startRagdoll(int(PhysLayer.EPL_CHARACTER), int(PhysLayer.EPL_ALL), animchar.nodeTree)
  ragdoll__applyParams = true
  sendEvent(eid, CmdApplyRagdollParameters(cur_time = get_sync_time()))
  animchar |> animchar_setPostController(*ragdoll)


[es]
def node_attached_itm(info : ParallelUpdateFrameDelayed;
                      node_attached__entity : EntityId;
                      node_attached__nodeId : int;
                      node_attached__localTm : float3x4;
                      var transform : float3x4&)
  if node_attached__nodeId < 0
    return

  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    transform = tm * node_attached__localTm

[es]
def node_attached_pos(info : ParallelUpdateFrameDelayed;
                      node_attached__entity : EntityId;
                      node_attached__nodeId : int;
                      node_attached__localPos : float3;
                      var transform : float3x4&)
  if node_attached__nodeId < 0
    return

  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    transform[3] = tm * node_attached__localPos

[es(tag=server, tag=net, no_order, REQUIRE=node_attached__destroyWithParent)]
def node_attached_destroy_with_parent_server(info : ParallelUpdateFrameDelayed; eid : EntityId; node_attached__entity : EntityId)
  if !doesEntityExist(node_attached__entity)
    destroyEntity(eid)

[es(no_order, REQUIRE=node_attached__destroyWithParent, REQUIRE_NOT=replication)]  // same as above ES but for local (not networking) entities
def node_attached_destroy_with_parent_local(info : ParallelUpdateFrameDelayed; eid : EntityId; node_attached__entity : EntityId)
  if !doesEntityExist(node_attached__entity)
    destroyEntity(eid)

[es(tag=gameClient, after=node_attached_itm, REQUIRE=node_attached__updateWtm)]
def node_attached_update_animchar_es(info : ParallelUpdateFrameDelayed;
                                     transform : float3x4;
                                     node_attached__nodeId : int;
                                     var animchar : AnimcharBaseComponent;
                                     var animchar_node_wtm : AnimcharNodesMat44&;
                                     var animchar_render__root_pos : vec4f&)
  if node_attached__nodeId < 0
    return
  animchar_set_tm(animchar, transform, true)
  animchar_recalc_wtm(animchar)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
