require ecs
require ecs.safe
require ecs.common
require math.base
require DagorMath
require danetlibs.dm.dm_events
require DagorRandom
require DngPlane
require CollRes
require dm
require DngDm
require fx
require game.es.aircraft.plane_cutting_common


def is_large_part_cut(part_id : int;
                      plane_cutting__cutPartsId : IntList;
                      plane_cutting__largePartsCut : BoolList;
                      plane_cutting__leftWingCutState : int;
                      plane_cutting__rightWingCutState : int) : bool
  let cutPartId = find_index(plane_cutting__cutPartsId, part_id)
  if cutPartId < 0
    return false
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING_L) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING1_L) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING2_L)
    let segCutState = int(FlightModelCutState.FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId.WRECK_PART_PART_WING_L)
    return plane_cutting__leftWingCutState >= segCutState
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING_R) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING1_R) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING2_R)
    let segCutState = int(FlightModelCutState.FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId.WRECK_PART_PART_WING_R)
    return plane_cutting__rightWingCutState >= segCutState
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_TAIL)
    return plane_cutting__largePartsCut?[int(WreckageType.WRECKAGE_TAIL)] ?? false
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_FIN)
    return plane_cutting__largePartsCut?[int(WreckageType.WRECKAGE_FIN)] ?? false
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_1)
    return plane_cutting__largePartsCut?[int(WreckageType.WRECKAGE_STAB_L)] ?? false
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_2)
    return plane_cutting__largePartsCut?[int(WreckageType.WRECKAGE_STAB_R)] ?? false
  return false


def is_part_cut(part_id : int;
                plane_cutting__smallPartsCut : BoolList;
                plane_cutting__cutPartsId : IntList;
                plane_cutting__largePartsCut : BoolList;
                plane_cutting__leftWingCutState : int;
                plane_cutting__rightWingCutState : int) : bool
  if plane_cutting__smallPartsCut?[part_id] ?? false
    return true
  return is_large_part_cut(part_id, plane_cutting__cutPartsId, plane_cutting__largePartsCut, plane_cutting__leftWingCutState, plane_cutting__rightWingCutState)


[es(tag=render, on_appear, after=plane_glass_canopy_nodes, REQUIRE=airplane)]
def plane_hit_effect_on_appear(evt : Event;
                               collres : CollisionResource;
                               damage_model : DamageModel;
                               var plane_hit_effect__collNodeToPartId : IntList&)
  let nodeCount = collres_get_nodesCount(collres)
  resize(plane_hit_effect__collNodeToPartId, nodeCount)
  for nodeId in range(nodeCount)
    let nodeName = collres_get_node_name(collres, nodeId)
    plane_hit_effect__collNodeToPartId[nodeId] = find_part_id_by_name(damage_model, nodeName)


[es(tag=render, on_disappear, REQUIRE=airplane)]
def plane_hit_effect_on_disappear(evt : Event;
                                  var plane_hit_effect__fxEids : EidList)
  for fxEid in plane_hit_effect__fxEids
    destroyEntity(fxEid)


[es(tag=render, track=(plane_cutting__smallPartsCut, plane_cutting__largePartsCut, plane_cutting__largePartsCutPartId), REQUIRE=(airplane, plane_cutting__largePartsCut, plane_cutting__largePartsCutPartId))]
def plane_hit_effect_on_part_cut(evt : Event;
                                 plane_cutting__smallPartsCut : BoolList;
                                 plane_cutting__cutPartsId : IntList;
                                 plane_cutting__largePartsCut : BoolList;
                                 plane_cutting__leftWingCutState : int;
                                 plane_cutting__rightWingCutState : int;
                                 var plane_hit_effect__fxEids : EidList;
                                 var plane_hit_effect__fxPartIds : IntList)
  var i = 0
  while i < length(plane_hit_effect__fxEids)
    let fxEid = plane_hit_effect__fxEids[i]
    let partId = plane_hit_effect__fxPartIds[i]
    let partCut = partId >= 0 && is_part_cut(partId, plane_cutting__smallPartsCut, plane_cutting__cutPartsId, plane_cutting__largePartsCut, plane_cutting__leftWingCutState, plane_cutting__rightWingCutState)
    if !fxEid || partCut
      if partCut
        destroyEntity(fxEid)
      erase(plane_hit_effect__fxEids, i)
      erase(plane_hit_effect__fxPartIds, i)
    else
      ++i


[es(tag=render, REQUIRE=airplane)]
def plane_hit_effect_on_hit(evt : EventOnHitByProjectile;
                            eid : EntityId;
                            transform : float3x4;
                            plane_net_phys : PlaneActor;
                            plane_hit_effect__fxTemplate : string;
                            plane_hit_effect__timeToDestroy : float;
                            plane_hit_effect__probability : float;
                            plane_glassCanopyNodeIds : IntList;
                            plane_hit_effect__collNodeToPartId : IntList;
                            plane_cutting__smallPartsCut : BoolList;
                            plane_cutting__cutPartsId : IntList;
                            plane_cutting__largePartsCut : BoolList;
                            plane_cutting__leftWingCutState : int;
                            plane_cutting__rightWingCutState : int;
                            var plane_hit_effect__fxEids : EidList;
                            var plane_hit_effect__fxPartIds : IntList)
  let hitNodeId = evt.nodeId
  if find_index(plane_glassCanopyNodeIds, hitNodeId) >= 0
    return

  let partId = plane_hit_effect__collNodeToPartId?[hitNodeId] ?? -1
  if partId >= 0 && is_part_cut(partId, plane_cutting__smallPartsCut, plane_cutting__cutPartsId, plane_cutting__largePartsCut, plane_cutting__leftWingCutState, plane_cutting__rightWingCutState)
    return

  if gfrnd() <= plane_hit_effect__probability

    let localHitPos = evt.localHitPos
    let worldHitPos = transform * localHitPos

    var emitterTm = transform
    emitterTm[3] = worldHitPos

    assume vel = plane_net_phys.phys.currentState.velocity

    let fxEid = createEntity(plane_hit_effect__fxTemplate) <| $(var init)
      set(init, "transform", emitterTm)
      set(init, "plane_effect__planeEid", eid)
      set(init, "plane_effect__emitterPos", worldHitPos)
      set(init, "plane_effect__emitterLocalPos", localHitPos)
      set(init, "effect__velocity", float3(vel.x, vel.y, vel.z))
      set(init, "game_effect__timeToDestroy", plane_hit_effect__timeToDestroy)

    push(plane_hit_effect__fxEids, fxEid)
    push(plane_hit_effect__fxPartIds, partId)
