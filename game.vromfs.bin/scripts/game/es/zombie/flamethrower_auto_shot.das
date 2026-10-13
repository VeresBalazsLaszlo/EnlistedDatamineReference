require ecs
require Gun
require DaWeapons
require common_shooter.events_common_shooter
require math
require enlisted.events_enlisted
require AnimV20
require GeomNodeTree
require DagorMath
require math.base
require DagorSystem
require DagorMathUtils
require strings

[es(before=after_guns_update_sync, after=flamethrower_auto_shoot_tm_update)]
def flamethrower_auto_shoot_update(info : ParallelUpdateFrameDelayed;
                                   eid : EntityId;
                                   var transform : float3x4;
                                   flamethrower_auto_shoot__gunDir : float3;
                                   flamethrower_auto_shoot__canShoot : bool)
  assume gunDir = flamethrower_auto_shoot__gunDir
  assume gunPos = transform[3]

  transform[0] = normalize(flamethrower_auto_shoot__gunDir)
  transform |> orthonormalize()

  let gctrl = GunControls(shoot = flamethrower_auto_shoot__canShoot, wishShoot = false, boltActionMult = 1.0, timeStep = info.dt)
  using(gunDir, gunDir, gunDir, gunPos) <| $(var gloc : GunLocation#)
    sendEventImmediate(eid, CmdWeapPhysUpdate(
                              owner = eid,
                              atTime = info.curTime,
                              dt = info.dt,
                              isForReal = true,
                              slotId = 0,
                              gctrl := gctrl,
                              gloc := gloc))


[es]
def flamethrower_auto_shoot_tm_update(info : ParallelUpdateFrameDelayed;
                                      flamethrower_auto_shoot__nodeIndex : int;
                                      flamethrower_auto_shoot__offset : float3;
                                      flamethrower_auto_shoot__ownerEid : EntityId;
                                      var transform aka flamethrower_transform  : float3x4&)
  query(flamethrower_auto_shoot__ownerEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                                      transform aka zombie_transform : float3x4)
    if flamethrower_auto_shoot__nodeIndex >= 0
      var tm : float3x4
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(flamethrower_auto_shoot__nodeIndex, tm)
      flamethrower_transform[3] = tm[3]
    else
      flamethrower_transform[3] = zombie_transform[3] + flamethrower_auto_shoot__offset

[es(tag=server, track=zombie_ability__activated, REQUIRE_NOT=deadEntity)]
def zombie_on_flamethrower_shoot_abilitity_targer(evt : Event;
                                                  zombie_ability__activated : bool;
                                                  walker_agent__priorityTarget : EntityId;
                                                  var zombie_giant_boss_flamethrower__targetPos : float3&)
  if zombie_ability__activated
    let targetTm = get_TMatrix(walker_agent__priorityTarget, "human__aimTm")
    if targetTm != null
      zombie_giant_boss_flamethrower__targetPos = (*targetTm)[3]

[es(track=zombie_ability__activated, REQUIRE_NOT=deadEntity)]
def zombie_on_flamethrower_shoot_abilitity_activate(evt : Event;
                                                    zombie_ability__activated : bool;
                                                    zombie_giant_boss_flamethrower__itemEid : EntityId)
  query(zombie_giant_boss_flamethrower__itemEid) <| $ [es] (var flamethrower_auto_shoot__canShoot : bool&)
    flamethrower_auto_shoot__canShoot = zombie_ability__activated

[es(track=zombie_ability__activated, REQUIRE=zombie_giant_boss_flamethrower__itemEid, REQUIRE_NOT=deadEntity)]
def reset_zombie_flame_targets(evt : Event;
                               zombie_ability__activated : bool)
  if zombie_ability__activated
    query() <| $ [es(REQUIRE=zombie_mode_human)] (var zombie_laser__alreadyTargeted : bool&)
      zombie_laser__alreadyTargeted = false


[es(REQUIRE_NOT=deadEntity)]
def zombie_on_flamethrower_abilitity_activate(info : ParallelUpdateFrameDelayed;
                                              zombie_ability__activated : bool;
                                              zombie_giant_boss_flamethrower__itemEid : EntityId;
                                              zombie_ability__endTime : float;
                                              zombie_ability__animTime : float;
                                              zombie_giant_boss_flamethrower__targetPos : float3;
                                              zombie_giant_boss_flamethrower__targetPath : Object;
                                              var zombie_giant_boss_flamethrower__lastApplyedState : int&;
                                              var zombie_giant_boss_flamethrower__lastState : int&;
                                              zombie_giant_boss_flamethrower__staticY : Tag const?)
  if !zombie_ability__activated
    return
  query(zombie_giant_boss_flamethrower__itemEid) <| $ [es] (transform aka gun_transform : float3x4;
                                                            var flamethrower_auto_shoot__gunDir : float3&;
                                                            zombie__lazerGun : Tag const?)
    let curTime = info.curTime
    let curAnimTime = zombie_ability__animTime - (zombie_ability__endTime - curTime)
    let curAnimProgressPercents = safediv(curAnimTime, zombie_ability__animTime) * 100.f
    let curProgressI = int(curAnimProgressPercents)
    if zombie_giant_boss_flamethrower__lastApplyedState > curProgressI
      zombie_giant_boss_flamethrower__lastState = 0
      zombie_giant_boss_flamethrower__lastApplyedState = 0

    var selectedState = 101 //state > 100
    var resAnglesAngles = float2(0., 0.)
    for it in zombie_giant_boss_flamethrower__targetPath
      let intState = to_int(it.key)
      if curProgressI < intState
        if selectedState > intState
          selectedState = intState
          let stateData = get_ecs_object(it.value)
          if stateData == null
            continue
          let start = get_Point2(*stateData, "start")
          let end = get_Point2(*stateData, "end")
          if start != null && end != null
            let relStateVal = cvt(float(curProgressI), float(zombie_giant_boss_flamethrower__lastApplyedState), float(intState), 0., 1.)
            let anglesDir = *end - *start
            let stateRelAngles = *start + anglesDir * relStateVal
            let targetPos = zombie_giant_boss_flamethrower__targetPos
            let dirToTarget = targetPos - gun_transform[3]
            var anglesToTarget = dir_to_angles(dirToTarget)
            if zombie_giant_boss_flamethrower__staticY != null
              anglesToTarget.y = 0.
            resAnglesAngles = anglesToTarget + float2(deg_to_rad(stateRelAngles.x), deg_to_rad(stateRelAngles.y))
          else
            logerr("incorrect strart/end data in /*{zombie_giant_boss_flamethrower__targetPath}*/")

    if zombie__lazerGun != null
      var overrideEid = INVALID_ENTITY_ID
      var overridedX = 0.
      query() <| $ [es(REQUIRE=zombie_mode_human, REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                                            isDowned : bool;
                                                                            transform aka human_transform : float3x4;
                                                                            zombie_laser__alreadyTargeted : bool)
        if zombie_laser__alreadyTargeted || isDowned
          return

        let checkPos = human_transform[3]
        let checkDir = checkPos - gun_transform[3] // check len
        let checkAngles = dir_to_angles(checkDir)
        let lastAngles = dir_to_angles(flamethrower_auto_shoot__gunDir)
        let minX = min(lastAngles.x, resAnglesAngles.x)
        let maxX = max(lastAngles.x, resAnglesAngles.x)
        if checkAngles.x > minX && checkAngles.x < maxX
          let right = resAnglesAngles.x < lastAngles.x
          if (right && checkAngles.x < overridedX) || (!right && checkAngles.x > overridedX) || !overrideEid
            overridedX = checkAngles.x
            overrideEid = eid
        if !!overrideEid
          setOptional(overrideEid, "zombie_laser__alreadyTargeted", true)
          resAnglesAngles.x = overridedX
    flamethrower_auto_shoot__gunDir = angles_to_dir(resAnglesAngles)

    if selectedState != zombie_giant_boss_flamethrower__lastState
      zombie_giant_boss_flamethrower__lastApplyedState = zombie_giant_boss_flamethrower__lastState
      zombie_giant_boss_flamethrower__lastState = selectedState


[es(tag=server, on_appear, REQUIRE_NOT=deadEntity)]
def zombie_on_flamethrower_on_appear(evt : Event;
                                     eid : EntityId;
                                     animchar aka boss_animchar : AnimcharBaseComponent;
                                     zombie_ability__animTime : float;
                                     zombie_giant_boss_flamethrower__nodeName : das_string const?;
                                     zombie_giant_boss_flamethrower__template : string;
                                     var zombie_giant_boss_flamethrower__itemEid : EntityId&;
                                     zombie_giant_boss_flamethrower__offset : float3 = float3())
  var bossFlamethrowerNodeId = -1
  if zombie_giant_boss_flamethrower__nodeName != null
    bossFlamethrowerNodeId = *boss_animchar.nodeTree |> geomtree_findNodeIndex(string(*zombie_giant_boss_flamethrower__nodeName))
    if bossFlamethrowerNodeId < 0
      return

  zombie_giant_boss_flamethrower__itemEid = createEntity(zombie_giant_boss_flamethrower__template) <| $(var init)
    set(init, "flamethrower_auto_shoot__nodeIndex", bossFlamethrowerNodeId)
    set(init, "flamethrower_auto_shoot__offset", zombie_giant_boss_flamethrower__offset)
    set(init, "flamethrower_auto_shoot__ownerEid", eid)
    set(init, "gun__owner", eid)
    set(init, "projectile_beam_tracer__time", zombie_ability__animTime)

[es(tag=server, REQUIRE_NOT=deadEntity, on_disappear)]
def zombie_on_flamethrower_on_disappear(evt : Event;
                                        zombie_giant_boss_flamethrower__itemEid : EntityId)
  if !!zombie_giant_boss_flamethrower__itemEid
    destroyEntity(zombie_giant_boss_flamethrower__itemEid)
