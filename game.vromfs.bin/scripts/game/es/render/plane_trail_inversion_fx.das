require ecs
require ecs.safe
require math.base
require CollRes
require GamePhys
require Plane
require fx
require DngPlane
require DagorSystem
require DagorMath
require enlisted.events_enlisted


def get_emitter_tm(collres : CollisionResource; node_id : int; plane_tm : float3x4)
  let emitterPos = plane_tm * collres_get_node_tm(collres, node_id)[3]

  var emitterTm = IDENT_TM
  emitterTm[3] = emitterPos

  return emitterTm


[es(tag=render, on_appear)]
def plane_trail_inversion_fx_on_appear(evt : Event;
                                       eid : EntityId;
                                       collres : CollisionResource;
                                       plane_trail_inversion_fx__emitters : Array;
                                       var plane_trail_inversion_fx__nodeIds : IntList;
                                       var plane_trail_inversion_fx__fxEids : EidList)
  for emitterAttr in plane_trail_inversion_fx__emitters
    let emitter = emitterAttr as Object
    let nodeName = emitter?.node ?? ""
    let nodeId = collres_get_node_index_by_name(collres, nodeName)
    if nodeId < 0
      logerr("plane_trail_inversion_fx: node /*{nodeName}*/ not found on /*{getEntityTemplateName(eid)}*/")
      continue

    push(plane_trail_inversion_fx__nodeIds, nodeId)
    push(plane_trail_inversion_fx__fxEids, INVALID_ENTITY_ID)


[es(tag=render, on_disappear)]
def plane_trail_inversion_fx_on_disappear(evt : Event; var plane_trail_inversion_fx__fxEids : EidList)
  for fxEid in plane_trail_inversion_fx__fxEids
    destroyEntity(fxEid)


[es(tag=render, REQUIRE_NOT=deadEntity)]
def plane_trail_inversion_fx_on_update(evt : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       collres : CollisionResource;
                                       transform : float3x4;
                                       plane_trail_inversion_fx__fxTemplate : string;
                                       plane_trail_inversion_fx__aoaRange : float2;
                                       plane_trail_inversion_fx__indSpeedRange : float2;
                                       plane_trail_inversion_fx__minAltitude : float;
                                       plane_trail_inversion_fx__opacityThreshold : float;
                                       plane_trail_inversion_fx__nodeIds : IntList;
                                       var plane_trail_inversion_fx__fxEids : EidList;
                                       plane_net_phys : PlaneActor)
  // wingtip vapor trail intensity: proxied by the shared phys.aoa (per-wing AoA / aoaCrit
  // aren't exposed to das), gated by indicated airspeed and a minimum altitude. opacity is a
  // product of two fade-in windows, so the lower bounds are not hard triggers on their own.
  let altitude = float(plane_net_phys.phys.currentState.location.P.y)
  let aoaOpacity = cvt(abs(plane_net_phys.phys.aoa), plane_trail_inversion_fx__aoaRange.x, plane_trail_inversion_fx__aoaRange.y, 0.0, 1.0)
  let speedOpacity = cvt(plane_net_phys.phys.cache.indSpeed, plane_trail_inversion_fx__indSpeedRange.x, plane_trail_inversion_fx__indSpeedRange.y, 0.0, 1.0)
  let opacity = altitude < plane_trail_inversion_fx__minAltitude ? 0.0 : aoaOpacity * speedOpacity
  let shouldShow = opacity > plane_trail_inversion_fx__opacityThreshold

  for nodeId, fxEid in plane_trail_inversion_fx__nodeIds, plane_trail_inversion_fx__fxEids
    if !shouldShow
      if fxEid != INVALID_ENTITY_ID
        destroyEntity(fxEid)
        fxEid = INVALID_ENTITY_ID
      continue

    if fxEid == INVALID_ENTITY_ID
      fxEid = createEntity(plane_trail_inversion_fx__fxTemplate) <| $(init)
        set(init, "transform", get_emitter_tm(collres, nodeId, transform))
        set(init, "plane_trail_inversion_effect__planeEid", eid)
        set(init, "plane_trail_inversion_effect__nodeId", nodeId)


[es(tag=render, after=plane_trail_inversion_fx_on_update)]
def plane_trail_inversion_effect_on_update(info : ParallelUpdateFrameDelayed;
                                           plane_trail_inversion_effect__planeEid : EntityId;
                                           plane_trail_inversion_effect__nodeId : int;
                                           var transform aka effect_transform : float3x4&;
                                           var effect__velocity : float3&)
  query(plane_trail_inversion_effect__planeEid) <| $ [es] (transform : float3x4;
                                                           collres : CollisionResource;
                                                           plane_net_phys : PlaneActor)
    effect_transform = get_emitter_tm(collres, plane_trail_inversion_effect__nodeId, transform)

    assume planeVel = plane_net_phys.phys.currentState.velocity
    effect__velocity = float3(planeVel.x, planeVel.y, planeVel.z)
