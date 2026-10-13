require ecs
require ecs.common
require ecs.safe
require AnimV20
require GeomNodeTree
require DagorMath
require DngPhysObj
require PhysObj
require math.base
require game.es.flying_turret_common
require common_shooter.es.vehicle.vehicle_fx_common


def spawn_trail_fx_for_flying_turret(flying_turret_eid : EntityId;
                                     source_tank_animchar : AnimcharBaseComponent;
                                     flying_turret_tm : float3x4;
                                     bone_idx : int;
                                     fx_template : string)
  if bone_idx < 0
    return
  var boneWtm : float3x4
  *source_tank_animchar.nodeTree |> geomtree_getNodeWtmScalar(bone_idx, boneWtm)
  let bonePos = boneWtm[3]
  let localPos = inverse(flying_turret_tm) * bonePos
  var worldTm = IDENT_TM
  worldTm[3] = bonePos
  var localTm = IDENT_TM
  localTm[3] = localPos
  let combinedTemplate = add_sub_template_name(fx_template, "vehicle_effect_oriented_attached")
  createEntity(combinedTemplate) <| $(var init : ComponentsInitializer)
    set(init, "transform", worldTm)
    set(init, "vehicle_effect__vehicleEid", flying_turret_eid)
    set(init, "vehicle_effect__emitterLocalPos", localPos)
    set(init, "vehicle_effect__emitterPos", bonePos)
    set(init, "vehicle_effect__emitterLocalTm", localTm)


[es(tag=render, on_appear, REQUIRE=flyingTurret)]
def flying_turret_spawn_trail_fx_es(evt : Event;
                                    eid : EntityId;
                                    transform : float3x4;
                                    flying_turret__bone : string;
                                    flying_turret__sourceTankEid : EntityId)
  query(flying_turret__sourceTankEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                                 explosion_fx__nodeName : string;
                                                 losable_turret__turretTrailTemplate : string)
    if !empty(losable_turret__turretTrailTemplate)
      let nodeIdx = *animchar.nodeTree |> geomtree_findNodeIndex(explosion_fx__nodeName)
      spawn_trail_fx_for_flying_turret(eid, animchar, transform, nodeIdx, losable_turret__turretTrailTemplate)
  query(flying_turret__sourceTankEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                                 turret_control__gunEids : EidList;
                                                 losable_turret__barrelTrailTemplate : string)
    if empty(losable_turret__barrelTrailTemplate)
      return
    let turretRootIdx = *animchar.nodeTree |> geomtree_findNodeIndex(flying_turret__bone)
    if turretRootIdx < 0
      return
    var turretSubtree : array<int>
    gather_bone_subtree(animchar.nodeTree, turretRootIdx, turretSubtree)
    for gunEid in turret_control__gunEids
      if !should_spawn_barrel_fx(gunEid)
        continue
      query(gunEid) <| $ [es] (turret__flashNodeId : int)
        if turret__flashNodeId < 0 || find_index(turretSubtree, turret__flashNodeId) < 0
          return
        spawn_trail_fx_for_flying_turret(eid, animchar, transform, turret__flashNodeId, losable_turret__barrelTrailTemplate)


[es(tag=render, no_order, REQUIRE=flyingTurret)]
def flying_turret_update_trail_lifetime_es(info : UpdateStageInfoAct;
                                           phys_obj_net_phys : PhysObjActor;
                                           flying_turret__trailLingerTime : float;
                                           var flying_turret__lastFastTime : float&;
                                           var flying_turret__trailLingerEndTime : float&;
                                           var flying_turret__trailFxCleared : bool&;
                                           var vehicle_fxs__effectsEids : EidList&)
  if flying_turret__trailFxCleared
    return
  let LANDED_VEL_THRESHOLD_SQ = 0.5 * 0.5
  let LANDED_SUSTAINED_TIME = 0.3
  let curTime = info.curTime
  let velMagSq = length_sq(float3(phys_obj_net_phys.phys.currentState.velocity))
  if velMagSq > LANDED_VEL_THRESHOLD_SQ || flying_turret__lastFastTime < 0.0
    flying_turret__lastFastTime = curTime
    flying_turret__trailLingerEndTime = -1.0
    return
  if flying_turret__trailLingerEndTime < 0.0 && curTime - flying_turret__lastFastTime > LANDED_SUSTAINED_TIME
    flying_turret__trailLingerEndTime = curTime + flying_turret__trailLingerTime
  if flying_turret__trailLingerEndTime >= 0.0 && curTime >= flying_turret__trailLingerEndTime
    flying_turret__trailFxCleared = true
    for fxEid in vehicle_fxs__effectsEids
      destroyEntity(fxEid)
    vehicle_fxs__effectsEids |> clear()
