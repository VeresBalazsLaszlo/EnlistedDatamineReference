require ecs
require ecs.common
require app
require DngNet
require game.es.events
require DngHuman
require DngWeapon
require DagorMath
require DagorSystem
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common

def set_lookat_from_sight_node(cur_time : float;
                               human_net_phys : HumanActor;
                               optics_cam_node : int;
                               animchar : AnimcharBaseComponent;
                               human__aimTm : float3x4;
                               human_weap__recoilPunchPos : float;
                               gun_tm : float3x4;
                               bindedCamera : EntityId;
                               cam_shift_min : float;
                               cam_shift_max : float;
                               cam_fov_min : float;
                               cam_fov_max : float;
                               gunmod_eid : EntityId;
                               var camera__look_at : DPoint3&;
                               var gun_aim_offset : float2&)
  if optics_cam_node < 0
    return

  let nodeDir = -DPoint3(gun_tm[2])
  let wposRelScalar = *animchar.nodeTree |> geomtree_getNodeWposRel(optics_cam_node)
  let wtmOfs = *animchar.nodeTree |> geomtree_getWtmOfs()
  var wpos = DPoint3(wposRelScalar) + DPoint3(wtmOfs)

  query(bindedCamera) <| $ [es] (fov : float;
                                 camera__active : bool)
    if !camera__active
      return

    let lookDir = normalize(human__aimTm[0])
    let shift = cvt(fov, cam_fov_min, cam_fov_max, cam_shift_min, cam_shift_max) - human_weap__recoilPunchPos
    let threshold = 0.5
    wpos += nodeDir * threshold - DPoint3(lookDir) * (shift + threshold)

  assume hphys = human_net_phys.phys
  let interpK = get_phys_interpk_clamped(hphys, cur_time)
  let aimPosition = lerp(hphys.previousState.aimPosition, hphys.currentState.aimPosition, interpK)
  let zoomPosition = lerp(hphys.previousState.zoomPosition, hphys.currentState.zoomPosition, interpK)
  let baseValue = has(gunmod_eid, "isCameraAlwaysOnScope") ? 1.0 : 0.0
  let lerpFactor = lerp(0.0, max(zoomPosition, baseValue), aimPosition)
  camera__look_at = lerp(camera__look_at, wpos, lerpFactor)
  gun_aim_offset = lerp(gun_aim_offset, float2(0.0, 0.0), float2(lerpFactor))


[es(tag=render,
     before=before_camera_sync,
     after=(human_fpv_cam_pos, animchar_cam_target_es, animchar_cam_target_with_offset_es, human_gun_lookat_camera_es),
     REQUIRE=hero)]
def human_optics_lookat_camera_es(info : UpdateStageInfoAct;
                                  human__aimTm : float3x4;
                                  human_net_phys : HumanActor;
                                  human_weap__currentGunEid : EntityId;
                                  human_weap__currentGunModEids : ecs::EidList;
                                  human_weap__recoilPunchPos : float;
                                  bindedCamera : EntityId;
                                  var camera__look_at : DPoint3&;
                                  var camera__gunAimOffset : float2&)
  var gunScopeEid = find_scope_eid(human_weap__currentGunModEids)
  let isIntegratedScope = get_bool(human_weap__currentGunEid, "gun__integratedScope") ?? false
  if isIntegratedScope && !gunScopeEid
    gunScopeEid = human_weap__currentGunEid

  var gunTm = human__aimTm
  query(human_weap__currentGunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    animchar |> animchar_get_tm(gunTm)


  query(gunScopeEid) <| $ [es] (gunmod__camNodeId : int;
                                animchar : AnimcharBaseComponent;
                                gunmod__camShiftMin : float;
                                gunmod__camShiftMax : float;
                                gunmod__camFovMin : float;
                                gunmod__camFovMax : float)
    set_lookat_from_sight_node(info.curTime, human_net_phys,
                               gunmod__camNodeId, animchar,
                               human__aimTm, human_weap__recoilPunchPos,
                               gunTm, bindedCamera,
                               gunmod__camShiftMin, gunmod__camShiftMax,
                               gunmod__camFovMin, gunmod__camFovMax,
                               gunScopeEid,
                               camera__look_at,
                               camera__gunAimOffset)