require ecs
require ecs.common
require math
require math.base
require vehicle
require DagorMath
require GeomNodeTree
require AnimV20
require DagorSystem
require app
require game.es.vehicle.vehicle_seats_common
require enlisted.events_enlisted

[es(tag=render, on_appear, track=vehicleCameraType)]
def bomber_cockpit_manage_entity_es(evt : Event;
                                    eid : EntityId;
                                    vehicleCameraType : int;
                                    vehicle_seats__seatEids : EidList;
                                    bomber_cockpit__cameraNodeId : int;
                                    bomber_cockpit__template : string;
                                    bomber_cockpit__attachOffset : float3 = float3(0., 0., 0.);
                                    var bomber_cockpit__cockpitEid : EntityId&)
  let needCockpit = vehicleCameraType == int(VehicleCameraType.VEHICLE_CAMERA_BOMBER_COCKPIT)
  let exists = !!bomber_cockpit__cockpitEid
  if needCockpit == exists
    return
  if needCockpit
    if bomber_cockpit__template == ""
      return
    let heroSeatNo = vehicle_get_watched_seat_idx(vehicle_seats__seatEids)
    if heroSeatNo < 0
      return
    let attachIdx = bomber_cockpit__cameraNodeId >= 0 ? bomber_cockpit__cameraNodeId : 0
    bomber_cockpit__cockpitEid = createEntity(bomber_cockpit__template) <| $(var init : ComponentsInitializer)
      set(init, "cockpit__vehicleEid", eid)
      set(init, "cockpit__seatNo", heroSeatNo)
      set(init, "cockpit__attachNodeIndex", attachIdx)
      set(init, "cockpit__offset", bomber_cockpit__attachOffset)
      set(init, "cockpit__cameraTime", 1.f)
      set(init, "cockpit__forwardOffsetTime", 1.f)
      set(init, "cockpit__isAttached", true)
  else
    destroyEntity(bomber_cockpit__cockpitEid)
    bomber_cockpit__cockpitEid = INVALID_ENTITY_ID

[es(tag=render, on_disappear)]
def bomber_cockpit_cleanup_on_vehicle_destroy_es(evt : Event;
                                                 bomber_cockpit__cockpitEid : EntityId)
  if !!bomber_cockpit__cockpitEid
    destroyEntity(bomber_cockpit__cockpitEid)

[es(tag=render, on_appear)]
def bomber_cockpit_resolve_slit_local_es(evt : Event;
                                         eid : EntityId;
                                         transform : float3x4;
                                         animchar : AnimcharBaseComponent;
                                         bomber_cockpit__slitNodeName : string;
                                         var bomber_cockpit__slitNodeId : int&;
                                         var bomber_cockpit__slitLocalTm : float3x4&)
  if empty(bomber_cockpit__slitNodeName)
    return
  let slitId = geomtree_findNodeIndex(*animchar.nodeTree, bomber_cockpit__slitNodeName)
  if slitId < 0
    logerr("[bomber_cockpit] slit node /*{bomber_cockpit__slitNodeName}*/ not found for /*{eid}*/ /*{getEntityTemplateName(eid)}*/")
    return
  bomber_cockpit__slitNodeId = slitId
  var slitWtm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, slitId, slitWtm)
  bomber_cockpit__slitLocalTm = inverse(transform) * slitWtm

def rodrigues_rotate(v : float3; axis : float3; cosA : float; sinA : float) : float3
  return v * cosA + cross(axis, v) * sinA + axis * (dot(axis, v) * (1.f - cosA))

[es(tag=render, after=vehicle_attach_cockpit_es, before=vehicle_cockpit_update_animchar)]
def bomber_cockpit_orient_cockpit_es(info : ParallelUpdateFrameDelayed;
                                     vehicleCameraType : int;
                                     animchar : AnimcharBaseComponent;
                                     bomber_cockpit__cameraNodeId : int;
                                     bomber_cockpit__lookAtPos : float3;
                                     bomber_cockpit__cockpitEid : EntityId)
  if vehicleCameraType != int(VehicleCameraType.VEHICLE_CAMERA_BOMBER_COCKPIT)
    return
  if bomber_cockpit__cameraNodeId < 0 || !bomber_cockpit__cockpitEid
    return

  var planeNodeTm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, bomber_cockpit__cameraNodeId, planeNodeTm)
  let toImpact = bomber_cockpit__lookAtPos - planeNodeTm[3]
  if length_sq(toImpact) < 1.e-6
    return
  let lookDir = normalize(toImpact)

  query(bomber_cockpit__cockpitEid) <| $ [es] (var transform aka cockpit_transform : float3x4;
                                               bomber_cockpit__slitLocalTm : float3x4)
    let slit_world_pos = cockpit_transform[3] + rotate(cockpit_transform, bomber_cockpit__slitLocalTm[3])
    let slit_world_X_raw = rotate(cockpit_transform, bomber_cockpit__slitLocalTm[0])
    if length_sq(slit_world_X_raw) < 1.e-6
      return
    let slit_world_X = normalize(slit_world_X_raw)

    let cosA = clamp(dot(slit_world_X, lookDir), -1.f, 1.f)
    if cosA > 0.99999
      return

    let axis = cross(slit_world_X, lookDir)
    let axisLen = length(axis)
    if axisLen < 1.e-6
      return
    let axis_n = axis / axisLen
    let sinA = axisLen

    var newTM : float3x4
    newTM[0] = rodrigues_rotate(cockpit_transform[0], axis_n, cosA, sinA)
    newTM[1] = rodrigues_rotate(cockpit_transform[1], axis_n, cosA, sinA)
    newTM[2] = rodrigues_rotate(cockpit_transform[2], axis_n, cosA, sinA)
    let pivot_offset = cockpit_transform[3] - slit_world_pos
    newTM[3] = slit_world_pos + rodrigues_rotate(pivot_offset, axis_n, cosA, sinA)
    cockpit_transform = newTM

[es(tag=render, after=shooter_cam_vehicle_update_tm_es)]
def bomber_cockpit_set_lookdir_es(info : UpdateStageInfoAct;
                                  camera__active : bool;
                                  camera__target : EntityId;
                                  var transform aka camera_transform : float3x4;
                                  var camera__accuratePos : DPoint3&)
  if !camera__active
    return
  query(camera__target) <| $ [es] (vehicleCameraType : int;
                                   transform aka vehicle_transform : float3x4;
                                   bomber_cockpit__lookAtPos : float3;
                                   bomber_cockpit__cockpitEid : EntityId;
                                   bomber_cockpit__camForwardOffset : float = 0.;
                                   var turret_current_visual_shoot_tm : float3x4;
                                   var turret_current_visual_shoot_tm_cached : float3x4;
                                   var turretAimPos : float3&;
                                   var turretAimPosCached : float3&;
                                   var isTurretAimPosValid : bool&;
                                   var isTurretAimPosValidCached : bool&)
    if vehicleCameraType != int(VehicleCameraType.VEHICLE_CAMERA_BOMBER_COCKPIT)
      return
    if !bomber_cockpit__cockpitEid
      return
    query(bomber_cockpit__cockpitEid) <| $ [es] (animchar aka cockpit_animchar : AnimcharBaseComponent;
                                                 bomber_cockpit__slitNodeId : int)
      if bomber_cockpit__slitNodeId < 0
        return
      var slitWtm : float3x4
      geomtree_getNodeWtmScalar(*cockpit_animchar.nodeTree, bomber_cockpit__slitNodeId, slitWtm)

      if length_sq(slitWtm[3] - vehicle_transform[3]) > 100. * 100.
        return

      let fwdRaw = slitWtm[0]
      if length_sq(fwdRaw) < 1.e-6
        return
      let fwd = normalize(fwdRaw)

      let worldUp = float3(0., 1., 0.)
      var rightRaw = cross(worldUp, fwd)
      if length_sq(rightRaw) < 1.e-6
        rightRaw = float3(1., 0., 0.)
      let right = normalize(rightRaw)
      let up = normalize(cross(fwd, right))

      let camPos = slitWtm[3] + fwd * bomber_cockpit__camForwardOffset

      camera_transform[0] = right
      camera_transform[1] = up
      camera_transform[2] = fwd
      camera_transform[3] = camPos
      camera__accuratePos = DPoint3(camPos)

      let aimDir = bomber_cockpit__lookAtPos - camPos
      var shootDir = fwd
      if length_sq(aimDir) > 1.e-6
        shootDir = normalize(aimDir)
      var shootTm : float3x4
      shootTm[0] = shootDir
      shootTm[1] = up
      shootTm[2] = -right
      shootTm[3] = camPos
      turret_current_visual_shoot_tm = shootTm
      turret_current_visual_shoot_tm_cached = shootTm
      turretAimPos = bomber_cockpit__lookAtPos
      turretAimPosCached = bomber_cockpit__lookAtPos
      isTurretAimPosValid = true
      isTurretAimPosValidCached = true
