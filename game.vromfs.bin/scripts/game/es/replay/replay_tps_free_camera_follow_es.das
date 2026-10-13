require ecs
require math.base
require game.events_game
require enlisted.events_enlisted
require DagorMath
require DagorSystem
require DagorConsole
require AnimV20
require GeomNodeTree

let FIXED_DT = 1. / 60. // 60hz

[es(tag=playingReplay, track=(camera__target, camera__active), before=replay_tps_free_camera_movement_es)]
def reset_camera_offset_on_camera_target_change(evt : Event;
                                                replay_camera__defaultOffset : float3;
                                                camera__active : bool;
                                                camera__target : EntityId;
                                                var replay_camera__offset : float3&;
                                                var replay_camera__tpsInputAngle : float2&;
                                                var replay_camera__tpsCurAng : float2&)
  if camera__active
    replay_camera__offset = replay_camera__defaultOffset
    query(camera__target) <| $ [es] (transform : float3x4)
      let cameraPos = transform[3] + replay_camera__offset
      let dir = (transform[3] - cameraPos)
      replay_camera__tpsInputAngle = float2(-atan2(dir.x, dir.z), -safe_asin(safediv(replay_camera__offset.y, length(dir))))
      replay_camera__tpsCurAng = replay_camera__tpsInputAngle

[es(tag=playingReplay, after=camera_set_sync, before=before_camera_sync, REQUIRE=replay_camera__tpsFree)]
def replay_tps_free_camera_follow_es(info : UpdateStageInfoAct;
                                     camera__active : bool;
                                     isTpsView : bool;
                                     camera__target : EntityId;
                                     replay_camera__trackingEnabled : bool;
                                     replay_camera__offset : float3;
                                     var transform aka cam_transform : float3x4&;
                                     var camera__accuratePos : DPoint3&)
  if !isTpsView || !camera__active || !replay_camera__trackingEnabled
    return

  query(camera__target) <| $ [es] (transform : float3x4)
    let pos = transform[3] + replay_camera__offset
    cam_transform[3] = pos
    camera__accuratePos = DPoint3(cam_transform[3])


[es(after=camera_set_sync, before=before_camera_sync)]
def replay_tps_free_camera_movement_es(evt : UpdateStageInfoAct;
                                       replay_camera__trackingEnabled : bool;
                                       camera__active : bool;
                                       transform aka cam_transform : float3x4;
                                       camera__target : EntityId;
                                       var camera__accuratePos : DPoint3&;
                                       var replay_camera__offset : float3&)
  if !camera__active || replay_camera__trackingEnabled
    return

  camera__accuratePos = DPoint3(cam_transform[3])
  query(camera__target) <| $ [es] (transform : float3x4)
    replay_camera__offset = cam_transform[3] - transform[3]

[es(track=fovSettings, REQUIRE=replay_camera__tpsFree)]
def set_free_tps_camera_fov_es(evt : Event; fovSettings : float; var fov : float&)
  fov = fovSettings

[es(tag=playingReplay, track=camera__active, before=free_tps_camera_update_es)]
def free_tps_initial_rotation_es(evt : Event;
                                 camera__active : bool;
                                 transform : float3x4;
                                 var replay_camera__tpsInputAngle : float2&;
                                 var replay_camera__tpsCurAng : float2&)
  if !camera__active
    return
  let dir = transform[2]
  replay_camera__tpsInputAngle = float2(-atan2(dir.x, dir.z), safe_asin(dir.y))
  replay_camera__tpsCurAng = replay_camera__tpsInputAngle

[es(tag=playingReplay, before=free_tps_camera_update_es, track=replay_camera__useFixedDirection)]
def on_camera_toggled_es(evt : Event;
                         replay_camera__useFixedDirection : bool;
                         replay_camera__tpsCurAng : float2;
                         var replay_camera__fixedTransform : float3x4&)
  if replay_camera__useFixedDirection
    var tmY, tmX = IDENT_TM
    rotyTM(replay_camera__tpsCurAng.x, tmY)
    rotxTM(replay_camera__tpsCurAng.y, tmX)
    replay_camera__fixedTransform = tmY * tmX

[es(tag=playingReplay, no_order)]
def free_tps_camera_update_es(info : UpdateStageInfoAct;
                              camera__active : bool;
                              replay_camera__tpsInputAngle : float2;
                              replay_camera__tpsLerpFactor : float;
                              free_cam__bank : float&;
                              replay_camera__rollSpeed : float;
                              var replay_camera__currentRoll : float&;
                              var transform : float3x4&;
                              var replay_camera__tpsCurAng : float2&)
  if !camera__active
    return

  let oldPosition = transform[3]
  replay_camera__tpsCurAng = lerp(replay_camera__tpsCurAng, replay_camera__tpsInputAngle, float2(FIXED_DT * replay_camera__tpsLerpFactor))

  var tmY, tmX = IDENT_TM
  rotyTM(replay_camera__tpsCurAng.x, tmY)
  rotxTM(replay_camera__tpsCurAng.y, tmX)
  transform = tmY * tmX

  replay_camera__currentRoll = replay_camera__currentRoll + free_cam__bank * replay_camera__rollSpeed * FIXED_DT
  var q : quat
  euler_to_quat(0.0, deg_to_rad(replay_camera__currentRoll), 0.0, q)
  var rotTm : float3x4
  make_tm(q, float3(0.0f, 0.0f, 0.0f), rotTm)
  transform = transform * rotTm
  transform[3] = oldPosition

[es(tag=playingReplay)]
def replay_track_attach_to_weapon(evt : ReplayTrackAttachToWeapon;
                                  replay_camera__trackingEnabled : bool;
                                  transform aka camera_transform : float3x4;
                                  camera__active : bool;
                                  var replay_camera__trackWeaponEid : EntityId&;
                                  var replay_camera__trackWeaponNodeId : int&;
                                  var replay_camera__trackWeaponRelativeTm : float3x4&)
  if !camera__active
    console_print("attaching camera to weapon's node works only on TPS free camera, that it's not active not")
    return
  query() <| $ [es(REQUIRE=watchedByPlr)] (eid aka soldier_eid : EntityId)
    query(soldier_eid) <| $ [es] (human_weap__currentGunEid : EntityId;
                                  human_anim__vehicleSelected : EntityId)
      if !!human_anim__vehicleSelected
        console_print("cannot attach to a weapon node, cause camera's target is in vehice")
        return
      query(human_weap__currentGunEid) <| $ [es] (animchar : AnimcharBaseComponent)
        let weaponName = getEntityTemplateName(human_weap__currentGunEid)
        var nodeTm : float3x4
        var nodeName = "bullet"
        replay_camera__trackWeaponNodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
        if replay_camera__trackWeaponNodeId < 0
          nodeName = "weaponRoot_2"
          replay_camera__trackWeaponNodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
        if replay_camera__trackWeaponNodeId < 0
          nodeName = "weaponRoot"
          replay_camera__trackWeaponNodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
        if replay_camera__trackWeaponNodeId < 0
          console_print("Cannot attach to a weapon '{weaponName}', node '{nodeName}' not found")
          return
        geomtree_getNodeWtmScalar(*animchar.nodeTree, replay_camera__trackWeaponNodeId, nodeTm)
        replay_camera__trackWeaponRelativeTm = inverse(nodeTm) * camera_transform
        replay_camera__trackWeaponEid = human_weap__currentGunEid
        if !replay_camera__trackingEnabled
          broadcastEvent(ReplayToggleFreeCamera())
        console_print("Camera attached to a weapon '{weaponName}' (node: '{nodeName}')")

[es(tag=playingReplay, on_event=ReplayTrackDetachFromWeapon, track=camera__target, REQUIRE=camera__target)]
def replay_track_detach_from_weapon(evt : Event;
                                    var replay_camera__trackWeaponEid : EntityId&;
                                    var replay_camera__trackWeaponNodeId : int&;
                                    var replay_camera__trackWeaponRelativeTm : float3x4&)
  replay_camera__trackWeaponEid = INVALID_ENTITY_ID
  replay_camera__trackWeaponNodeId = -1
  replay_camera__trackWeaponRelativeTm = IDENT_TM

[es(tag=playingReplay, after=replay_tps_free_camera_follow_es, REQUIRE=replay_camera__tpsFree)]
def replay_track_follow_weapon_node(info : UpdateStageInfoAct;
                                    isTpsView : bool;
                                    camera__active : bool;
                                    replay_camera__trackingEnabled : bool;
                                    replay_camera__trackWeaponEid : EntityId;
                                    replay_camera__trackWeaponNodeId : int;
                                    replay_camera__trackWeaponRelativeTm : float3x4;
                                    var transform : float3x4&;
                                    var camera__accuratePos : DPoint3&)
  if !isTpsView || !camera__active || !replay_camera__trackingEnabled || replay_camera__trackWeaponNodeId < 0
    return

  query(replay_camera__trackWeaponEid) <| $ [es] (animchar : AnimcharBaseComponent)
    var nodeTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, replay_camera__trackWeaponNodeId, nodeTm)
    transform = nodeTm * replay_camera__trackWeaponRelativeTm
    camera__accuratePos = DPoint3(transform[3])
