require app
require ecs
require ecs.common
require ecs.safe
require DagorMath
require math.base
require math.linear
require zones
require enlisted.events_enlisted
require game.events_game
require game.utils.team
require DagorSystem
require game.es.battle_area_common
require DngNet
require DngDm
require game.es.events
require Grid
require common_shooter.events_common_shooter
require AnimV20
require Gun
require GeomNodeTree
require math.ang
require walkerai
require SmokeOccluder
require RendInst
require GridCollision
require Dacoll
require danetlibs.animchar_attach.main.attach_events


[es(tag=gameClient, REQUIRE=(hero, spy_soldier__canChangeClothes), REQUIRE_NOT=deadEntity, after=hero_human_pre_use_object_es, before=hero_human_final_use_object_sync)]
def spy_select_body_for_change_close(info : ParallelUpdateFrameDelayed;
                                     isDowned : bool;
                                     team : int;
                                     human_reviver__maxDistance : float2;
                                     human_reviver__maxAngle : float;
                                     spy_soldier__canChangeClothes : bool;
                                     transform : float3x4;
                                     var human_use_object__selectedObject : EntityId&;
                                     human__aimTm : float3x4)
  if !!human_use_object__selectedObject || isDowned || !spy_soldier__canChangeClothes
    return
  var box = BBox3()
  box |> bbox3_add(human__aimTm[3])
  box |> bbox3_inflate(human_reviver__maxDistance.y)
  let minAngleCos = cos(deg_to_rad(human_reviver__maxAngle))
  find_entity_in_grid(ecs_hash("humans"), box, GridEntCheck.BOUNDING) <| $(targetEid : EntityId)
    if (get_int(targetEid, "team") ?? TEAM_UNASSIGNED) == team || !has(targetEid, "deadEntity") || !(get_bool(targetEid, "canBeTargetForClothesChange") ?? true)
      return false

    var traceTargetPos = float3()
    let lookPos = transform[3] + float3(0., 1.5, 0.)
    query(targetEid) <| $ [es] (animchar : AnimcharBaseComponent; spy_soldier__targetNodeIdx : int)
      if spy_soldier__targetNodeIdx >= 0
        traceTargetPos = geomtree_getNodeWpos(*animchar.nodeTree, spy_soldier__targetNodeIdx)
    if traceTargetPos == float3()
      return false
    let dirToTarget = traceTargetPos - lookPos
    let distToSoldierSq = length_sq(dirToTarget)
    let angleToEntityCos = dot(normalize(dirToTarget.xz), normalize(human__aimTm[0].xz))
    if angleToEntityCos < minAngleCos || distToSoldierSq > square(human_reviver__maxDistance.x)
      return false
    var traceDist = length(dirToTarget)
    var norm : float3
    if traceray_normalized(lookPos, normalize(dirToTarget), traceDist, norm)
      return false
    human_use_object__selectedObject = targetEid
    return true

[es(tag=server)]
def stop_clothes_change(evt : CmdStopClothesChange;
                        var spy_soldier__clothesChangeTarget : EntityId&;
                        var spy_soldier__animationEntity : EntityId&;
                        var spy_soldier__clothesChangeEndTime : float&)
  spy_soldier__clothesChangeTarget = INVALID_ENTITY_ID
  destroyEntity(spy_soldier__animationEntity)
  spy_soldier__animationEntity = INVALID_ENTITY_ID
  spy_soldier__clothesChangeEndTime = -1.

[es(tag=server, REQUIRE=deadEntity)]
def try_spy_start_clothes_change(evt : CmdUse;
                                 eid : EntityId;
                                 team aka target_team : int;
                                 canBeTargetForClothesChange : bool;
                                 spy_soldier__targetNodeIdx : int;
                                 animchar : AnimcharBaseComponent)
  var canChange = true
  if !canBeTargetForClothesChange
    return
  find_query() <| $ [es] (spy_soldier__clothesChangeTarget : EntityId)
    if spy_soldier__clothesChangeTarget == eid
      canChange = false
    return !canChange
  if !canChange
    return
  query(evt.requesterEid) <| $ [es] (var spy_soldier__animationEntity : EntityId&;
                                     spy_soldier__canChangeClothes : bool;
                                     team : int;
                                     var spy_soldier__clothesChangeTarget : EntityId&;
                                     isDowned : bool;
                                     var spy_soldier__clothesChangeEndTime : float&;
                                     spy_soldier__clothesChangeAnimationTemplate : string;
                                     spy_soldier__clothesChangeTotalTime : float;
                                     transform : float3x4)
    if !spy_soldier__canChangeClothes || target_team == team || isDowned
      return
    let shootPos = transform[3] + float3(0., 1.5, 0.)
    var targetPos = float3()
    if spy_soldier__targetNodeIdx >= 0
      targetPos = geomtree_getNodeWpos(*animchar.nodeTree, spy_soldier__targetNodeIdx)
    if targetPos == float3()
      return
    let dirToTarget = targetPos - shootPos
    var traceDist = length(dirToTarget)
    if traceDist > 0.f
      var norm : float3
      if traceray_normalized(shootPos, dirToTarget * safeinv(traceDist), traceDist, norm)
        return
    sendEvent(eid, CmdBodyCleanupUpdateTtl(newTtl = 40.))
    spy_soldier__clothesChangeTarget = eid
    spy_soldier__clothesChangeEndTime = get_sync_time() + spy_soldier__clothesChangeTotalTime
    spy_soldier__animationEntity = createEntity(spy_soldier__clothesChangeAnimationTemplate) <| $(var init : ComponentsInitializer)
      set(init, "game_effect__attachedTo", evt.requesterEid)

[es(tag=gameClient)]
def save_clothes_change_target_lang(evt : ChangeSpeechLang;
                                    var human_speech__locale : das_string&;
                                    human_use_object__selectedObject : EntityId)
  human_speech__locale := get_string(human_use_object__selectedObject, "human_speech__locale", string(human_speech__locale))

def swap_equipment_slots(spy_eid, target_eid : EntityId)
  query(spy_eid) <| $ [es] (var human_equipment__slots aka spy_human_equipment__slots : Object&)
    query(target_eid) <| $ [es] (var human_equipment__slots aka target_human_equipment__slots : Object&)
      for spy_it in spy_human_equipment__slots
        let slotName = spy_it.key
        var spyObj = getRW_ecs_object(spy_human_equipment__slots, slotName)
        var targetObj = getRW_ecs_object(target_human_equipment__slots, slotName)
        if spyObj == null || targetObj == null
          continue
        let spyItem = get_Eid(*spyObj, "item") ?? INVALID_ENTITY_ID
        let targetItem = get_Eid(*targetObj, "item") ?? INVALID_ENTITY_ID
        if has(spyItem, "isAttachableHead") || has(targetItem, "isAttachableHead") || has(spyItem, "attachable_facial_hairs") || has(targetItem, "attachable_facial_hairs")
          continue
        if has(spyItem, "radio_use") || has(targetItem, "radio_use")
          continue
        set(*spyObj, "item", targetItem)
        set(*targetObj, "item", spyItem)
        var spyEntities = getRW_ecs_array(*spyObj, "entities")
        var targetEntities = getRW_ecs_array(*targetObj, "entities")
        if spyEntities != null && targetEntities != null
          using() <| $(var newEntities : Array)
            newEntities |> move(*spyEntities)
            *spyEntities |> move(*targetEntities)
            *targetEntities |> move(*spyEntities)

def reinit_skeleton_attaches(eid)
  query(eid) <| $ [es] (attaches_list : EidList)
    for eid2 in attaches_list
      reinit_skeleton_attaches(eid2)
      sendEventImmediate(eid2, CmdInitSkeletonAttach())

[es(tag=gameClient)]
def spy_change_clothes(evt : CmdSpyChangeClothes;
                       eid : EntityId;
                       var attaches_list aka spy_attaches_list : EidList&)
  query(evt.clothesChangeTarget) <| $ [es] (var attaches_list aka target_attaches_list : EidList&; var canBeTargetForClothesChange : bool&)
    canBeTargetForClothesChange = false
    var spyHeadInd = -1
    var spyHead = INVALID_ENTITY_ID
    var targetHead = INVALID_ENTITY_ID
    for attach, ind in spy_attaches_list, count()
      if has(attach, "isAttachableHead")
        spyHeadInd = ind
      elif has(attach, "radio_use")
        pass
      else
        setOptional(attach, "animchar_attach__attachedTo", evt.clothesChangeTarget)
        setOptional(attach, "slot_attach__inAttachedList", evt.clothesChangeTarget)

    for attach, ind in target_attaches_list, count()
      if has(attach, "isAttachableHead")
        swap(spy_attaches_list[spyHeadInd], target_attaches_list[ind])
        spyHead = spy_attaches_list[spyHeadInd]
        targetHead = target_attaches_list[ind]
        query(spy_attaches_list[spyHeadInd]) <| $ [es] (var attaches_list aka spyHead_attaches_list : EidList&)
          query(target_attaches_list[ind]) <| $ [es] (var attaches_list : EidList&)
            using() <| $(var spyHeadFacialHairs : EidList)
              using() <| $(var targetHeadFacialHairs : EidList)
                for headAttach in spyHead_attaches_list
                  if has(headAttach, "attachable_facial_hairs")
                    spyHeadFacialHairs |> push(headAttach)
                  else
                    setOptional(headAttach, "animchar_attach__attachedTo", target_attaches_list[ind])
                    setOptional(headAttach, "slot_attach__inAttachedList", target_attaches_list[ind])
                for headAttach in attaches_list
                  if has(headAttach, "attachable_facial_hairs")
                    targetHeadFacialHairs |> push(headAttach)
                  else
                    setOptional(headAttach, "animchar_attach__attachedTo", spy_attaches_list[spyHeadInd])
                    setOptional(headAttach, "slot_attach__inAttachedList", spy_attaches_list[spyHeadInd])
                for fh in spyHeadFacialHairs
                  for spyHeadAtt, idx in spyHead_attaches_list, count()
                    if spyHeadAtt == fh
                      erase(spyHead_attaches_list, idx)
                      break
                for fh in targetHeadFacialHairs
                  for targHeadAtt, idx in attaches_list, count()
                    if targHeadAtt == fh
                      erase(attaches_list, idx)
                      break
                swap(attaches_list, spyHead_attaches_list)
                for fh in spyHeadFacialHairs
                  push(spyHead_attaches_list, fh)
                for fh in targetHeadFacialHairs
                  push(attaches_list, fh)
      elif has(attach, "radio_use")
        pass
      else
        setOptional(attach, "animchar_attach__attachedTo", eid)
        setOptional(attach, "slot_attach__inAttachedList", eid)

    var spyRadio = INVALID_ENTITY_ID
    var targetRadio = INVALID_ENTITY_ID
    for attach, ind in spy_attaches_list, count()
      if has(attach, "radio_use")
        spyRadio = attach
        erase(spy_attaches_list, ind)
        break
    for attach, ind in target_attaches_list, count()
      if has(attach, "radio_use")
        targetRadio = attach
        erase(target_attaches_list, ind)
        break

    swap(spy_attaches_list, target_attaches_list)

    if !!spyRadio
      push(spy_attaches_list, spyRadio)
    if !!targetRadio
      push(target_attaches_list, targetRadio)

    reinit_skeleton_attaches(spyHead)
    reinit_skeleton_attaches(targetHead)
    send_net_event(eid, CmdSetAdditionalUpdateFrames(framesCount = 4))
    send_net_event(evt.clothesChangeTarget, CmdSetAdditionalUpdateFrames(framesCount = 4))
    send_net_event(eid, ChangeSpeechLang())


[es(tag=server)]
def update_spy_clothes_change(info : ParallelUpdateFrameDelayed;
                              var spy_soldier__clothesChangeTarget : EntityId&;
                              isAlive : bool;
                              isDowned : bool;
                              eid : EntityId;
                              spy_soldier__canChangeClothes : bool;
                              var spy_soldier__detected : bool&;
                              var spy_soldier__clothesChangeOnce : bool&;
                              var spy_soldier__clothesChangeEndTime : float&;
                              var spy_soldier__animationEntity : EntityId&;
                              transform aka spy_transform : float3x4;
                              human_reviver__maxDistance : float2)
  if !spy_soldier__clothesChangeTarget
    return

  var targetPos = float3()
  query(spy_soldier__clothesChangeTarget) <| $ [es] (transform : float3x4; var canBeTargetForClothesChange : bool&)
    if info.curTime > spy_soldier__clothesChangeEndTime
      spy_soldier__detected = false
      spy_soldier__clothesChangeOnce = true
      canBeTargetForClothesChange = false
      send_net_event(eid, CmdSpyChangeClothes(clothesChangeTarget = spy_soldier__clothesChangeTarget))
      swap_equipment_slots(eid, spy_soldier__clothesChangeTarget)
    targetPos = transform[3]

  if (!isAlive || isDowned || !spy_soldier__canChangeClothes || !spy_soldier__clothesChangeTarget ||
      length_sq(spy_transform[3] - targetPos) > square(human_reviver__maxDistance.x) || info.curTime > spy_soldier__clothesChangeEndTime)
    spy_soldier__clothesChangeTarget = INVALID_ENTITY_ID
    destroyEntity(spy_soldier__animationEntity)
    spy_soldier__animationEntity = INVALID_ENTITY_ID
    spy_soldier__clothesChangeEndTime = -1.
    return

def private can_trace_spy(eid : EntityId; shootPos, shootDir : float3; spy_eid : EntityId; is_zooming : bool)
  if shootPos == float3() || shootDir == float3()
    return false
  var result = false
  query(spy_eid) <| $ [es] (animchar : AnimcharBaseComponent;
                            spy_soldier__targetNodeIdx : int;
                            spy_soldier__detectionAngle : float;
                            spy_soldier__detectionAngleWithScope : float;
                            spy_soldier__detectionConeBackOffset : float;
                            spy_soldier__detectionConeBackOffsetWithScope : float;
                            spy_soldier__detectionVisibleDist : float;
                            spy_soldier__detectionVisibleDistWithScope : float)
    if spy_soldier__targetNodeIdx < 0
      return
    let aimPos = geomtree_getNodeWpos(*animchar.nodeTree, spy_soldier__targetNodeIdx)
    let visibleDist = is_zooming ? spy_soldier__detectionVisibleDistWithScope : spy_soldier__detectionVisibleDist
    let coneBackOffset = is_zooming ? spy_soldier__detectionConeBackOffsetWithScope : spy_soldier__detectionConeBackOffset
    let detAngle = is_zooming ? spy_soldier__detectionAngleWithScope : spy_soldier__detectionAngle
    if length_sq(aimPos - shootPos) > square(visibleDist)
      return
    let shootPosForAngleCheck = shootPos - shootDir * coneBackOffset
    if angle(shootDir, normalize(aimPos - shootPosForAngleCheck)) > deg_to_rad(detAngle) || angle(shootDir, normalize(aimPos - shootPos)) > HALF_PI
      return
    let targetDir = normalize(aimPos - shootPos)
    let dist = length(aimPos - shootPos)
    var t = dist + 0.5
    var norm : float3
    if traceray_normalized(shootPos, targetDir, t, norm)
      return
    if rayhit_entities_in_grid(ecs_hash("vehicles"), shootPos, targetDir, t, eid)
      return
    if traceTransparencyRayRIGenNormalized(shootPos, targetDir, dist, 0.01)
      return
    if rayhit_smoke_occluders(shootPos, aimPos)
      return
    result = true
  return result

def check_spy_visibility(spy_eid)
  var spyDetector = INVALID_ENTITY_ID
  query(spy_eid) <| $ [es] (team aka spy_team : int)
    find_query() <| $ [es(REQUIRE_NOT=deadEntity)] (team : int; turret_control__gunEids : EidList; eid : EntityId; vehicle_seats__seatEids : EidList)
      if spy_team == team || empty(turret_control__gunEids)
        return false
      var Occupant = INVALID_ENTITY_ID
      for seatEid in vehicle_seats__seatEids
        Occupant = (get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID)
        if !!Occupant
          break
      if !Occupant
        return false
      var shootPos = float3()
      var shootDir = float3()
      query(turret_control__gunEids[0]) <| $ [es(REQUIRE_NOT=controlledByTankAiGunner)] (gun : Gun)
        shootPos = gun.gunTm[3]
        shootDir = gun.gunTm[0]
      if can_trace_spy(eid, shootPos, shootDir, spy_eid, false)
        spyDetector = Occupant
      return !!spyDetector
    if !!spyDetector
      return
    find_query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int;
                                                                   eid : EntityId;
                                                                   human_anim__vehicleSelected : EntityId;
                                                                   human_net_phys__isZooming : bool;
                                                                   human_weap__currentGunEid : EntityId)
      if spy_team == team || !!human_anim__vehicleSelected
        return false
      var shootPos = float3()
      var shootDir = float3()
      query(human_weap__currentGunEid) <| $ [es] (gun : Gun)
        shootPos = gun.gunTm[3]
        shootDir = gun.gunTm[0]

      if can_trace_spy(eid, shootPos, shootDir, spy_eid, human_net_phys__isZooming)
        spyDetector = eid
      return !!spyDetector

  return spyDetector

[es(on_appear)]
def init_spy_target_node(evt : Event; animchar : AnimcharBaseComponent; var spy_soldier__targetNodeIdx : int&; spy_soldier__targetNodeName : string)
  spy_soldier__targetNodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, spy_soldier__targetNodeName)

def create_spy_marker(spy_eid, detector_eid)
  let markOwnerEid = get_Eid(detector_eid, "squad_member__playerEid") ?? INVALID_ENTITY_ID
  if !markOwnerEid
    return

  var existingMarkerEid = INVALID_ENTITY_ID
  find_query() <| $ [es] (eid : EntityId; userPointSpyTargetEid : EntityId; userPointOwner : EntityId)
    if userPointSpyTargetEid == spy_eid && userPointOwner == markOwnerEid
      existingMarkerEid = eid
      return true
    return false

  if !!existingMarkerEid
    query(existingMarkerEid) <| $ [es] (timer__delta : float;
                                        timer__deltaLongMult : float;
                                        var timer__destroy : float&)
      timer__destroy = get_sync_time() + timer__delta * timer__deltaLongMult
    return

  query(spy_eid) <| $ [es] (transform : float3x4; team : int)
    createEntity("enlisted_map_user_point_spy") <| $(init)
      init |> set("transform", transform)
      init |> set("team", 3 - team)
      init |> set("userPointOwner", markOwnerEid)
      init |> set("userPointType", "enemy_user_point")
      init |> set("timer__start", get_sync_time())
      init |> set("userPointSpyTargetEid", spy_eid)
      init |> set("userPointCustomIcon", "stealth_icon_man")

[es(tag=server, REQUIRE_NOT=deadEntity)]
def update_spy_visibility_state(info : ParallelUpdateFrameDelayed;
                                spy_soldier__detectionUpdateInterval : float;
                                var spy_soldier__canChangeClothes : bool&;
                                var spy_soldier__detected : bool&;
                                battle_areas_visitor__isInEnemyArea : bool;
                                spy_soldier__canBeDetectedTime : float;
                                var spy_soldier__detectionNextCheckTime : float&;
                                eid : EntityId)
  if info.curTime < spy_soldier__detectionNextCheckTime
    return
  spy_soldier__detectionNextCheckTime = info.curTime + spy_soldier__detectionUpdateInterval
  spy_soldier__canChangeClothes = true

  let spyDetector = check_spy_visibility(eid)
  if !!spyDetector
    spy_soldier__canChangeClothes = false
    if info.curTime < spy_soldier__canBeDetectedTime && !spy_soldier__detected
      spy_soldier__detected = true
      if battle_areas_visitor__isInEnemyArea
        create_spy_marker(eid, spyDetector)

[es(tag=server, REQUIRE_NOT=deadEntity)]
def check_spy_detection_on_deal_damage(evt : EventOnOffenderDealDamage; eid : EntityId)
  if evt.damageType != int(DamageType.DM_PROJECTILE) && evt.damageType != int(DamageType.DM_MELEE)
    return
  query(evt.victimEid) <| $ [es] (var spy_soldier__detected : bool&; battle_areas_visitor__isInEnemyArea : bool)
    spy_soldier__detected = true
    if battle_areas_visitor__isInEnemyArea
      create_spy_marker(evt.victimEid, eid)
  query(eid) <| $ [es] (var spy_soldier__canBeDetectedTime : float&; spy_soldier__canBeDetectedTimeTotal : float)
    spy_soldier__canBeDetectedTime = get_sync_time() + spy_soldier__canBeDetectedTimeTotal

[es(tag=gameClient, no_order)]
def userpoint_update_spy_marker_position(info : ParallelUpdateFrameDelayed;
                                         userPointSpyTargetEid : EntityId;
                                         var transform aka userpoint_transform : float3x4&)
  query(userPointSpyTargetEid) <| $ [es(REQUIRE=human)] (transform : float3x4)
    userpoint_transform[3] = transform[3]
    userpoint_transform[3][1] += 1.
