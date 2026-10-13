options always_export_initializer = true

require app
require ecs
require BehNodes
require DagorDataBlock
require DagorSystem

require math
require math.ang
require math.base
require math.random
require DagorMath
require DagorMathUtils
require DagorRandom

require Grid
require GridCollision
require CollisionTraces
require Dacoll

require HumanPhys
require DngHuman
require DngWalkerai
require walkerai
require game.es.ai.walker_common
require game.utils.team

require Gun
require DngWeapon
require DaWeapons
require DaWeaponProps

require dm
require DngDm
require BallisticsProps
require BallisticsDm

require AnimV20
require CollRes

require enlisted.game.es.squad_behaviour_command_common
require common_shooter.es.ai.common_shooter_walker_nodes_common
require common_shooter.es.ai.ai_weapons_common
require common_shooter.es.human_attached_gun_common
require common_shooter.es.interactable_common
require game.es.ai.enlisted_combat_ai_common
require game.es.vehicle.vehicle_seats_common
require game.es.dm_ai_common

require common_shooter.events_common_shooter
require game.es.events


[beh_node(name="isAggressiveBehaviour")]
class IsAggressiveBehaviour : BehNodeAdapter
  def override update(dt : float) : EBehResult
    var res = EBehResult.ER_FAILED

    let agentEid = beh_tree_eid(owner)

    query(agentEid) <| $ [es] (squad_member__squad : EntityId)
      query(squad_member__squad) <| $ [es] (squad__squadBehaviour : int)
        if squad__squadBehaviour == int(SquadBehaviour.ESB_AGGRESSIVE)
          res = EBehResult.ER_SUCCESS

    return res

[beh_node(name="startAim")]
class StartAim : BehNodeAdapter

  def override update(dt : float) : EBehResult
    query(beh_tree_eid(owner)) <| $ [es] (var human_net_phys : HumanActor&)
      assume ct = human_net_phys.phys.producedCT
      ct |> human_control_state_set_control_bit(HumanPhysControlType.HCT_AIM, true)
    return EBehResult.ER_SUCCESS

[beh_node(name="stopAim")]
class StopAim : BehNodeAdapter

  def override update(dt : float) : EBehResult
    query(beh_tree_eid(owner)) <| $ [es] (var human_net_phys : HumanActor&)
      assume ct = human_net_phys.phys.producedCT
      ct |> human_control_state_set_control_bit(HumanPhysControlType.HCT_AIM, false)
    return EBehResult.ER_SUCCESS

[beh_node(name="canHoldWeaponInVehicle")]
class CanHoldWeaponInVehicle : BehNodeAdapter

  def override update(dt : float) : EBehResult
    return (get_bool(beh_tree_eid(owner), "human_vehicle__canHoldWeapon") ?? false) ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="assignStationaryGun")]
class AssignStationaryGun : BehNodeAdapter
  gunEidParam : int = -1
  assignForTime : float = 5.0

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    assignForTime = datablock_getReal(data, "assignForTime", assignForTime)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    if agentEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var res = EBehResult.ER_FAILED
    query(gunEid) <| $ [es] (var stationary_gun__botAssignedEid : EntityId&;
                             var stationary_gun__botAssignedTimeout : float&)
      var alreadyAssigned = false
      let curTime = get_sync_time()
      query(stationary_gun__botAssignedEid) <| $ [es] (isAlive : bool; beh_tree__enabled : bool; possessedByPlr : EntityId)
        if isAlive && beh_tree__enabled && possessedByPlr == INVALID_ENTITY_ID && curTime < stationary_gun__botAssignedTimeout
          if stationary_gun__botAssignedEid != agentEid
            alreadyAssigned = true
      if !alreadyAssigned
        stationary_gun__botAssignedEid = agentEid
        stationary_gun__botAssignedTimeout = curTime + assignForTime
        res = EBehResult.ER_SUCCESS
    return res

[beh_node(name="hasStationaryGunAssigned")]
class HasStationaryGunAssigned : BehNodeAdapter
  gunEidParam : int = -1
  allowAliveGuns : bool = true
  allowDeadGuns : bool = false

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    allowAliveGuns = datablock_getBool(data, "allowAliveGuns", allowAliveGuns)
    allowDeadGuns = datablock_getBool(data, "allowDeadGuns", allowDeadGuns)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    if agentEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var res = EBehResult.ER_FAILED
    query(gunEid) <| $ [es] (stationary_gun__botAssignedEid : EntityId;
                             stationary_gun__botAssignedTimeout : float;
                             isAlive : bool)
      if stationary_gun__botAssignedEid == agentEid && get_sync_time() < stationary_gun__botAssignedTimeout
        if (isAlive && allowAliveGuns) || (!isAlive && allowDeadGuns)
          res =  EBehResult.ER_SUCCESS
    return res

[beh_node(name="blacklistStationaryGun")]
class BlacklistStationaryGun : BehNodeAdapter
  gunEidParam : int = -1

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)

  def override update(dt : float) : EBehResult
    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    query(gunEid) <| $ [es] (var stationary_gun__botsBlacklisted : int&)
      stationary_gun__botsBlacklisted += 1

    return EBehResult.ER_SUCCESS


[beh_node(name="attachToStationaryGun")]
class AttachToStationaryGun : BehNodeAdapter
  radius : float = 2.0
  gunEidParam : int = -1

  def override loadFromBlk(data : DataBlock) : void
    if datablock_find_param(data, "gunEidParam") >= 0
      gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    radius = datablock_getReal(data, "radius", radius)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    let gunEid = gunEidParam >= 0 ? EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam))) : find_gun_to_attach(agentEid, radius, true)
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED
    sendEvent(gunEid, CmdUse(requesterEid = agentEid))
    return EBehResult.ER_SUCCESS

[beh_node(name="isAttachedToStationaryGun")]
class IsAttachedToStationaryGun : BehNodeAdapter
  gunEidParam : int = -1

  def override loadFromBlk(data : DataBlock) : void
    if datablock_find_param(data, "gunEidParam") >= 0
      gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    var res = EBehResult.ER_FAILED
    query(agentEid) <| $ [es] (human_attached_gun__attachedGunEid : EntityId)
      if gunEidParam >= 0
        let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
        if !!human_attached_gun__attachedGunEid && gunEid == human_attached_gun__attachedGunEid
          res = EBehResult.ER_SUCCESS
      else
        if !!human_attached_gun__attachedGunEid
          res = EBehResult.ER_SUCCESS
    return res

[beh_node(name="detachFromStationaryGun")]
class DetachFromStationaryGun : BehNodeAdapter

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    var attachedGunEid = INVALID_ENTITY_ID
    query(agentEid) <| $ [es] (human_attached_gun__attachedGunEid : EntityId)
      attachedGunEid = human_attached_gun__attachedGunEid
    if attachedGunEid == INVALID_ENTITY_ID
      return EBehResult.ER_SUCCESS // already detached
    sendEvent(attachedGunEid, CmdUse(requesterEid = agentEid))// request detach
    return EBehResult.ER_SUCCESS


[beh_node(name="findStationaryGun")]
class FindStationaryGun : BehNodeAdapter
  radius : float = 10.0
  posOffset : float3 = float3(0.0, 0.0, 0.0)
  posParam : int = -1

  gunEidOutParam : int = -1
  gunAITypeOutParam : int = -1

  extraChecks : bool = false
  rangeAITypes : int2 = int2(0, -1)
  skipAssignedToSelf : bool = false
  skipAssignedToOthers : bool = true
  skipDeadGuns : bool = true
  skipAliveGuns : bool = false
  maxBlacklisted : int = 2
  targetEidParam : int = -1
  traceTargets : bool = true
  maxTraces : int = 3
  requireEnemySide : bool = false
  requireTargets : int = 0
  hiddenTargets : bool = false
  rangeLimits : float2 =  float2(0, -1)

  def override loadFromBlk(data : DataBlock) : void
    if datablock_find_param(data, "posParam") >= 0
      posParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posParam", ""), float3())
    radius = datablock_getReal(data, "radius", radius)
    posOffset = datablock_getPoint3(data, "posOffset", posOffset)

    if datablock_find_param(data, "gunEidOutParam") >= 0
      gunEidOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidOutParam", ""), 0)
    if datablock_find_param(data, "gunAITypeOutParam") >= 0
      gunAITypeOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunAITypeOutParam", ""), 0)

    extraChecks = datablock_getBool(data, "extraChecks", extraChecks)
    rangeAITypes = datablock_getIPoint2(data, "rangeAITypes", rangeAITypes)
    skipAssignedToSelf = datablock_getBool(data, "skipAssignedToSelf", skipAssignedToSelf)
    skipAssignedToOthers = datablock_getBool(data, "skipAssignedToOthers", skipAssignedToOthers)
    skipDeadGuns = datablock_getBool(data, "skipDeadGuns", skipDeadGuns)
    skipAliveGuns = datablock_getBool(data, "skipAliveGuns", skipAliveGuns)
    maxBlacklisted = datablock_getInt(data, "maxBlacklisted", maxBlacklisted)
    if datablock_find_param(data, "targetEidParam") >= 0
      targetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetEidParam", ""), 0)
    traceTargets = datablock_getBool(data, "traceTargets", traceTargets)
    maxTraces = datablock_getInt(data, "maxTraces", maxTraces)
    requireEnemySide = datablock_getBool(data, "requireEnemySide", requireEnemySide)
    requireTargets = datablock_getInt(data, "requireTargets", requireTargets)
    hiddenTargets = datablock_getBool(data, "hiddenTargets", hiddenTargets)
    rangeLimits = datablock_getPoint2(data, "rangeLimits", rangeLimits)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    if agentEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var playerTeam = -1
    var agentPos = float3()
    if requireEnemySide
      query(agentEid) <| $ [es] (squad_member__playerEid : EntityId; transform : float3x4)
        agentPos = transform[3]
        query(squad_member__playerEid) <| $ [es] (team : int)
          playerTeam = team

    var targetEid = INVALID_ENTITY_ID
    if targetEidParam >= 0
      targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targetEidParam)))
      if targetEid == INVALID_ENTITY_ID
        return EBehResult.ER_FAILED

    let curTime = get_sync_time()

    var gunAIType = 0
    let gunEid = find_interactable(ecs_hash("interactable"), beh_tree_eid(owner), radius, true) <| $(gun_eid : EntityId)
      if !can_shoot_from_attached_gun(gun_eid)
        return false
      if !extraChecks
        return true

      var filtered = false
      query(gun_eid) <| $ [es] (isAlive : bool = false;
                                specialAIStGunType : int = 0;
                                stationary_gun__botAssignedEid : EntityId = INVALID_ENTITY_ID;
                                stationary_gun__botAssignedTimeout : float = 0.0;
                                stationary_gun__botsBlacklisted : int = 0;
                                gun__owner : EntityId = INVALID_ENTITY_ID)
        if !!gun__owner
          filtered = true
          return
        if (!isAlive && skipDeadGuns) || (isAlive && skipAliveGuns)
          filtered = true
          return
        if stationary_gun__botsBlacklisted >= maxBlacklisted
          filtered = true
          return
        gunAIType = specialAIStGunType
        if gunAIType < rangeAITypes.x || (rangeAITypes.y >= 0 && gunAIType > rangeAITypes.y)
          filtered = true
          return
        let assignedEid = stationary_gun__botAssignedEid
        if !!assignedEid && curTime < stationary_gun__botAssignedTimeout
          if (assignedEid == agentEid && skipAssignedToSelf) || (assignedEid != agentEid && skipAssignedToOthers)
            filtered = true
      if filtered
        return false

      var traced = false
      if !!targetEid && !check_attached_gun_target(gun_eid, targetEid, traceTargets, traced)
        return false

      if requireEnemySide && playerTeam >= 1
        var numPos = 0
        let gunDir = get_attached_gun_ai_aim_to_dir(gun_eid)
        query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (active : bool; team : int; transform aka spawn_transform : float3x4; respawnbaseType : string)
          if !active || respawnbaseType != "human" || is_teams_friendly(team, playerTeam)
            return
          let respPos = spawn_transform[3]
          if dot(gunDir, normalize(respPos - agentPos)) > 0.5
            ++numPos
        if numPos <= 0
          return false

      if requireTargets > 0 && !(requireTargets == 1 && !!targetEid)
        var fireRange = MOUNTED_GUN_DEFAULT_FIRE_RANGE
        query(gun_eid) <| $ [es] (mounted_gun__aiFireRange : float2)
          fireRange = mounted_gun__aiFireRange
        let needTargets = requireTargets - (!!targetEid ? 1 : 0)
        var gotTargets = 0
        var leftTraces = maxTraces
        query(agentEid) <| $ [es] (agent_dangers : AgentDangers)
          for danger in agent_dangers.dangers
            if danger.distance < fireRange.x || danger.distance > fireRange.y
              continue
            if !danger.traceable && !(hiddenTargets && is_attached_gun_hidden_target_incoming(gun_eid, danger.eid))
              continue

            let targetOK = check_attached_gun_target(gun_eid, danger.eid, leftTraces > 0, traced)
            if traced
              leftTraces -= 1
            if !targetOK
              continue
            gotTargets += 1
            if gotTargets >= needTargets
              break
        if gotTargets < needTargets
          return false
      return true

    var res = EBehResult.ER_FAILED
    query(gunEid) <| $ [es] (transform : float3x4)
      if posParam >= 0
        owner.blackBoard |> set(posParam, transform * posOffset)
      if gunEidOutParam >= 0
        owner.blackBoard |> set(gunEidOutParam, int(uint(gunEid)))
      if gunAITypeOutParam >= 0
        owner.blackBoard |> set(gunAITypeOutParam, gunAIType)
      res = EBehResult.ER_SUCCESS
    return res


[beh_node(name="findNextTargetForStationaryGun")]
class FindNextTargetForStationaryGun : BehNodeAdapter
  gunEidParam : int = -1
  targetEidOutParam : int = -1
  minTimeInFrustum : float = 2.0
  iterParam : int = -1
  maxTraces : int = 3

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    targetEidOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetEidOutParam", ""), 0)
    minTimeInFrustum = datablock_getReal(data, "minTimeInFrustum", minTimeInFrustum)
    iterParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunIter", "stGunTgtIter"), 0)
    maxTraces = datablock_getInt(data, "maxTraces", maxTraces)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    if agentEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED
    if !can_shoot_from_attached_gun(gunEid)
      return EBehResult.ER_FAILED

    var iterValue = owner.blackBoard |> datablock_getInt(iterParam)
    var targetEid = INVALID_ENTITY_ID

    let curTime = get_sync_time()

    query(agentEid) <| $ [es] (agent_dangers : AgentDangers)
      let numDangers = length(agent_dangers.dangers)
      if iterValue < 0 || iterValue >= numDangers
        iterValue = 0
      if numDangers <= 0
        return
      let startIterValue = iterValue
      var leftTraces = maxTraces
      var leftDangers = numDangers
      while leftDangers > 0 && leftTraces > 0
        leftDangers -= 1
        let dangerIdx = iterValue
        iterValue = (iterValue + 1) % numDangers
        assume danger = agent_dangers.dangers[dangerIdx]
        if danger.traceable && curTime - danger.inFrustumTime >= minTimeInFrustum
          var traced = false
          let targetOK = check_attached_gun_target(gunEid, danger.eid, true, traced)
          if traced
            leftTraces -= 1
          if targetOK
            targetEid = danger.eid
            break
        if iterValue == startIterValue
          break

    owner.blackBoard |> set(iterParam, iterValue)
    owner.blackBoard |> set(targetEidOutParam, int(uint(targetEid)))

    return !!targetEid ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED

[beh_node(name="checkStationaryGunTarget")]
class CheckStationaryGunTarget : BehNodeAdapter
  gunEidParam : int = -1
  targetEidParam : int = -1
  traceHit : bool = false

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    targetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetEidParam", ""), 0)
    traceHit = datablock_getBool(data, "traceHit", traceHit)

  def override update(dt : float) : EBehResult
    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED
    if !can_shoot_from_attached_gun(gunEid)
      return EBehResult.ER_FAILED

    let targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targetEidParam)))
    if targetEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var traced = false
    if !check_attached_gun_target(gunEid, targetEid, traceHit, traced)
      return EBehResult.ER_FAILED
    return EBehResult.ER_SUCCESS

[beh_node(name="getStationaryGunInfo")]
class GetStationaryGunInfo : BehNodeAdapter
  gunEidParam : int = -1
  posOffset : float3  = float3(0.0, 0.0, 0.0)
  posOutParam : int = -1
  gunAITypeOutParam : int = -1
  lookPosOutParam : int = -1
  lookRandYawRange : float2 = float2(-1.0, 1.0)
  lookRandPitchRange : float2 = float2(-1.0, 1.0)
  lookRandDistRange : float2 = float2(0.0, 1.0)

  def override loadFromBlk(data : DataBlock) : void
    gunEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunEidParam", ""), 0)
    posOffset = datablock_getPoint3(data, "posOffset", posOffset)
    if datablock_find_param(data, "posOutParam") >= 0
      posOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posOutParam", ""), float3())
    if datablock_find_param(data, "gunAITypeOutParam") >= 0
      gunAITypeOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "gunAITypeOutParam", ""), 0)
    if datablock_find_param(data, "lookPosOutParam") >= 0
      lookPosOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "lookPosOutParam", ""), float3())
    lookRandYawRange = datablock_getPoint2(data, "lookRandYawRange", lookRandYawRange)
    lookRandPitchRange = datablock_getPoint2(data, "lookRandPitchRange", lookRandPitchRange)
    lookRandDistRange = datablock_getPoint2(data, "lookRandDistRange", lookRandDistRange)

  def override update(dt : float) : EBehResult
    let gunEid = EntityId(uint(owner.blackBoard |> datablock_getInt(gunEidParam)))
    if gunEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var hasData = false
    var gunTransform = IDENT_TM
    var gunAIType = 0
    query(gunEid) <| $ [es] (transform : float3x4; specialAIStGunType : int = 0)
      hasData = true
      gunTransform = transform
      gunAIType = specialAIStGunType
    if !hasData
      return EBehResult.ER_FAILED

    if posOutParam >= 0
      owner.blackBoard |> set(posOutParam, gunTransform * posOffset)

    if gunAITypeOutParam >= 0
      owner.blackBoard |> set(gunAITypeOutParam, gunAIType)

    if lookPosOutParam >= 0
      let kYaw = rnd_float(lookRandYawRange.x, lookRandYawRange.y)
      let kPitch = rnd_float(lookRandPitchRange.x, lookRandPitchRange.y)
      let kDist = rnd_float(lookRandDistRange.x, lookRandDistRange.y)
      var lookPos = float3()
      if !get_attached_gun_ai_aim_point(lookPos, gunEid, kYaw, kPitch, kDist)
        return EBehResult.ER_FAILED
      owner.blackBoard |> set(lookPosOutParam, lookPos)

    return EBehResult.ER_SUCCESS

[beh_node(name="isAllyPlayerNear")]
class IsAllyPlayerNear : BehNodeAdapter
  radius : float = 1.0

  def override loadFromBlk(data : DataBlock) : void
    radius = datablock_getReal(data, "radius", radius)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    var isAllyNear = false
    query(agentEid) <| $ [es] (transform aka agent_transform : float3x4; squad_member__playerEid : EntityId)
      var playerTeam = -1
      query(squad_member__playerEid) <| $ [es] (team : int)
        playerTeam = team
      if playerTeam > 0
        let radiusSq = square(radius)
        for_each_entity_in_grid(ecs_hash("humans"), BSphere3(agent_transform[3], radius), GridEntCheck.BOUNDING) <| $(that_eid : EntityId)
          if agentEid == that_eid
            return
          query(that_eid) <| $ [es] (transform aka that_transform : float3x4; possessedByPlr : EntityId; beh_tree__enabled : bool)
            if !beh_tree__enabled && distance_sq(agent_transform[3], that_transform[3]) < radiusSq
              query(possessedByPlr) <| $ [es(REQUIRE_NOT=playerIsBot)] (team aka that_team : int)
                if is_teams_friendly(playerTeam, that_team)
                  isAllyNear = true
    return isAllyNear ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="passedTimeSinceControlledByPlayer")]
class PassedTimeSinceControlledByPlayer : BehNodeAdapter
  time : float = 5.0

  def override loadFromBlk(var data : DataBlock) : void
    time = data |> datablock_getReal("time", time)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    var timePassed = true
    query(agentEid) <| $ [es] (human_weap__lastTimeInfiniteAmmoEnabled : float = 0.0)
      if human_weap__lastTimeInfiniteAmmoEnabled > 0.0
        timePassed = get_sync_time() > human_weap__lastTimeInfiniteAmmoEnabled + time
    return timePassed ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED

[beh_node(name="checkReloadWeapon")]
class CheckReloadWeapon : BehNodeAdapter
  checkOnly : bool = false
  enoughAmmoRatio : float = 0.0

  skipEnemyNearRadius : float = -1.0
  skipEnemyDeltaHeights : float2 = float2(-2.0, 3.0)
  waitReloadFinish : bool = true

  def override loadFromBlk(var data : DataBlock) : void
    checkOnly = data |> datablock_getBool("checkOnly", checkOnly)
    enoughAmmoRatio = data |> datablock_getReal("enoughAmmoRatio", enoughAmmoRatio)

    skipEnemyNearRadius = data |> datablock_getReal("skipEnemyNearRadius", skipEnemyNearRadius)
    skipEnemyDeltaHeights = data |> datablock_getPoint2("skipEnemyDeltaHeights", skipEnemyDeltaHeights)
    waitReloadFinish = data |> datablock_getBool("waitReloadFinish", waitReloadFinish)

  def override update(dt : float) : EBehResult
    let ownerEid = beh_tree_eid(owner)
    let reload = check_human_reload(ownerEid, enoughAmmoRatio)
    if checkOnly
      return reload != 0 ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED
    if reload > 0
      return waitReloadFinish ? EBehResult.ER_RUNNING : EBehResult.ER_SUCCESS
    if reload < 0
      if skipEnemyNearRadius > 1.0 && check_hostile_humans_nearby(ownerEid, skipEnemyNearRadius, skipEnemyDeltaHeights)
        return EBehResult.ER_SUCCESS
      query(ownerEid) <| $ [es] (human_weap__currentGunEid : EntityId)
        let atTime = get_sync_time()
        sendEventImmediate(ownerEid, CmdRequestReload(atTime = atTime, gunEid = human_weap__currentGunEid, isQuick = false))
      return waitReloadFinish ? EBehResult.ER_RUNNING : EBehResult.ER_SUCCESS
    return EBehResult.ER_SUCCESS

[beh_node(name="decideOnAttackTarget")]
class DecideOnAttackTarget : BehNodeAdapter
  checkOnly : bool = false

  targetEidParam : int = -1
  targetSeeTimeParam : int = -1
  targetAcceptTime : float = 0.3

  lastTargetEidParam : int = -1
  lastTargetSeenParam : int = -1
  lastTargetTimeParam : int = -1
  forgetTargetTime : float = 7.5

  hunchLevelParam : int = -1
  prevHunchTimeParam : int = -1
  hunchTimeForDist1 = float3(2.0, 3.0, 60.)
  hunchTimeForDist2 = float3(1.0, 1.5, 25.)
  hunchTimeForDist3 = float3(0.2, 1.0, 5.)
  hunchDistDiv12 : float = 0.0
  hunchDistDiv23 : float = 0.0

  stillBackTimeRange = float2(0.3, 0.4)
  stillSideTimeRange = float2(0.2, 0.3)
  turnExactBackChance = 0.8
  turnExactSideChance = 0.9

  followTurnAngleRange : float2 = float2(50.0, 70.0)
  sideTurnAngleRange : float2 = float2(70.0, 110.0)
  backTurnAngleRange : float2 = float2(110.0, 150.0)
  deviateExactAngle : float = 10.0
  backAngle : float = 135.0

  focusBackTimeRange = float2(0.3, 0.5)
  focusSideTimeRange = float2(0.2, 0.3)
  focusAheadTimeRange = float2(0.1, 0.2)
  focusProneAddTimeRange = float2(0.1, 0.2)
  refocusTimeRange = float2(0.0, 0.1)

  stillTimeOutParam : int = -1
  turnAngleOutParam : int = -1
  focusTimeOutParam : int = -1

  def override loadFromBlk(data : DataBlock) : void
    checkOnly = datablock_getBool(data, "checkOnly", checkOnly)

    targetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetParam", ""), 0)
    targetSeeTimeParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetSeeTimeParam", ""), -1.0)

    lastTargetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "lastTargetEidParam", "lastTargetEid"), 0)
    lastTargetSeenParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "lastTargetSeenParam", "lastTargetSeen"), false)
    lastTargetTimeParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "lastTargetTimeParam", "lastTargetTime"), 0.0)

    hunchLevelParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "hunchLevelParam", "hunchLevel"), 0.0)
    prevHunchTimeParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "prevHunchTimeParam", "prevHunchTime"), -1.0)
    hunchDistDiv12 = safeinv(hunchTimeForDist1.z - hunchTimeForDist2.z)
    hunchDistDiv23 = safeinv(hunchTimeForDist2.z - hunchTimeForDist3.z)

    followTurnAngleRange *= DEG_TO_RAD
    sideTurnAngleRange *= DEG_TO_RAD
    backTurnAngleRange *= DEG_TO_RAD
    deviateExactAngle *= DEG_TO_RAD
    backAngle *= DEG_TO_RAD

    stillTimeOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "stillTimeOutParam", ""), 0.0)
    turnAngleOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "turnAngleOutParam", ""), 0.0)
    focusTimeOutParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "focusTimeOutParam", ""), 0.0)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)

    let targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targetEidParam)))
    if targetEid == INVALID_ENTITY_ID
      return EBehResult.ER_FAILED

    var lastTargetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(lastTargetEidParam)))
    var lastTargetSeen = owner.blackBoard |> datablock_getBool(lastTargetSeenParam)
    let lastTargetTime = owner.blackBoard |> datablock_getReal(lastTargetTimeParam)

    let curTime = get_sync_time()
    if lastTargetEid != INVALID_ENTITY_ID && curTime - lastTargetTime  > forgetTargetTime
      lastTargetEid = INVALID_ENTITY_ID
      lastTargetSeen = false
      if !checkOnly
        owner.blackBoard |> set(targetSeeTimeParam, curTime)

    let targetSeeTime = owner.blackBoard |> datablock_getReal(targetSeeTimeParam)
    if targetSeeTime >= 0.0 && curTime - targetSeeTime >= targetAcceptTime
      var focusTime = 0.0
      if targetEid != lastTargetEid
        owner.blackBoard |> set(lastTargetEidParam, int(uint(targetEid)))
        focusTime = rnd_float(focusAheadTimeRange.x, focusAheadTimeRange.y)
      elif !lastTargetSeen
        focusTime = rnd_float(refocusTimeRange.x, refocusTimeRange.y)

      query(targetEid) <| $ [es] (human_net_phys : HumanActor)
        if human_net_phys.phys.currentState.isCrawl
          focusTime += rnd_float(focusProneAddTimeRange.x, focusProneAddTimeRange.y)

      if !checkOnly
        owner.blackBoard |> set(lastTargetSeenParam, true)
        owner.blackBoard |> set(lastTargetTimeParam, curTime)

        owner.blackBoard |> set(prevHunchTimeParam, -1.0)
        owner.blackBoard |> set(hunchLevelParam, 0.0)

        owner.blackBoard |> set(stillTimeOutParam, 0.0)
        owner.blackBoard |> set(turnAngleOutParam, 0.0)
        owner.blackBoard |> set(focusTimeOutParam, focusTime)
      return EBehResult.ER_SUCCESS

    if !checkOnly
      owner.blackBoard |> set(lastTargetSeenParam, false)

    var hasTargetPos = false
    var targetPos = float3()
    query(targetEid) <| $ [es] (transform : float3x4)
      hasTargetPos = true
      targetPos = transform[3]

    var targetCrawl = false
    query(targetEid) <| $ [es] (human_net_phys : HumanActor)
      targetCrawl = human_net_phys.phys.currentState.isCrawl

    if targetEid == lastTargetEid
      var turnAngle = 0.0
      if hasTargetPos && lastTargetSeen
        let delta = targetPos - agent.pos
        let angleTo = atan2(delta.z, delta.x)
        let angleDir = atan2(agent.shootDir.z, agent.shootDir.x)
        turnAngle = rnd_float(followTurnAngleRange.x, followTurnAngleRange.y)
        if angle_diff(angleDir, angleTo) < 0.0
          turnAngle = -turnAngle
      else
        turnAngle = rnd_float(-PI, PI)

      var focusTime = rnd_float(refocusTimeRange.x, refocusTimeRange.y)
      if targetCrawl
        focusTime += rnd_float(focusProneAddTimeRange.x, focusProneAddTimeRange.y)

      if !checkOnly
        owner.blackBoard |> set(lastTargetSeenParam, true)
        owner.blackBoard |> set(lastTargetTimeParam, curTime)

        owner.blackBoard |> set(stillTimeOutParam, 0.0)
        owner.blackBoard |> set(turnAngleOutParam, turnAngle)
        owner.blackBoard |> set(focusTimeOutParam, focusTime)
      return EBehResult.ER_SUCCESS

    let dist = hasTargetPos ? distance(targetPos, agent.pos) : 0.0
    var time = 0.0
    if dist > hunchTimeForDist1.z
      time = rnd_float(hunchTimeForDist1.x, hunchTimeForDist1.y)
    elif dist > hunchTimeForDist2.z
      let ratio = (dist - hunchTimeForDist2.z) * hunchDistDiv12
      let time1 = rnd_float(hunchTimeForDist1.x, hunchTimeForDist1.y)
      let time2 = rnd_float(hunchTimeForDist2.x, hunchTimeForDist2.y)
      time = lerp(time2, time1, ratio)
    elif dist > hunchTimeForDist3.z
      let ratio = (dist - hunchTimeForDist3.z) * hunchDistDiv23
      let time2 = rnd_float(hunchTimeForDist2.x, hunchTimeForDist2.y)
      let time3 = rnd_float(hunchTimeForDist3.x, hunchTimeForDist3.y)
      time = lerp(time3, time2, ratio)
    else
      time = rnd_float(hunchTimeForDist3.x, hunchTimeForDist3.y)

    var hunchCoef = 1.0
    if hasTargetPos
      hunchCoef = 1.5 + 0.5 * dot(agent.shootDir, normalize(targetPos - agent.pos))

    let prevHunchTime = owner.blackBoard |> datablock_getReal(prevHunchTimeParam)
    let deltaTime = (prevHunchTime >= 0.0) ? (curTime - prevHunchTime) : 0.0
    let hunchAdd = (time > 0.0 ? (deltaTime / time) : 1.0) * hunchCoef
    let wasHunchLevel = owner.blackBoard |> datablock_getReal(hunchLevelParam)
    var newHunchLevel = min(1.0, wasHunchLevel + hunchAdd)
    if newHunchLevel != wasHunchLevel && !checkOnly
      owner.blackBoard |> set(hunchLevelParam, newHunchLevel)
    if prevHunchTime != curTime && !checkOnly
      owner.blackBoard |> set(prevHunchTimeParam, curTime)

    if newHunchLevel < 1.0
      return EBehResult.ER_FAILED // ignore target until hunchLevel >= 1.0

    var stillTime = 0.0
    var turnAngle = 0.0
    var focusTime = 0.0

    if hasTargetPos
      let delta = targetPos - agent.pos
      let angleTo = atan2(delta.z, delta.x)
      let angleDir = atan2(agent.shootDir.z, agent.shootDir.x)

      let angleDiff = angle_diff(angleDir, angleTo)
      if abs(angleDiff) > backAngle
        stillTime = rnd_float(stillBackTimeRange.x, stillBackTimeRange.y)
        focusTime = rnd_float(focusBackTimeRange.x, focusBackTimeRange.y)
        if rnd_float(0.0, 1.0) < turnExactBackChance
          turnAngle = angleDiff + rnd_float(-deviateExactAngle, deviateExactAngle)
        else
          turnAngle = rnd_float(backTurnAngleRange.x, backTurnAngleRange.y)
          if angleDiff < 0.0
            turnAngle = -turnAngle
          if rnd_float(0.0, 1.0) < 0.5
            turnAngle = -turnAngle
      else
        stillTime = rnd_float(stillSideTimeRange.x, stillSideTimeRange.y)
        focusTime = rnd_float(focusSideTimeRange.x, focusSideTimeRange.y)
        if rnd_float(0.0, 1.0) < turnExactSideChance
          turnAngle = angleDiff + rnd_float(-deviateExactAngle, deviateExactAngle)
        else
          turnAngle = rnd_float(sideTurnAngleRange.x, sideTurnAngleRange.y)
          if angleDiff < 0.0
            turnAngle = -turnAngle
          if rnd_float(0.0, 1.0) < 0.5
            turnAngle = -turnAngle
    else
      // fallback (target with no transform?)
      stillTime = 0.0
      turnAngle = rnd_float(-PI, PI)
      focusTime = rnd_float(focusBackTimeRange.x, focusBackTimeRange.y)

    if focusTime > 0.0 && targetCrawl
      focusTime += rnd_float(focusProneAddTimeRange.x, focusProneAddTimeRange.y)

    if lastTargetEid != INVALID_ENTITY_ID && !checkOnly
      owner.blackBoard |> set(lastTargetEidParam, int(uint(INVALID_ENTITY_ID))) // hunch searching, not target yet

    if !checkOnly
      newHunchLevel = 0.5
      owner.blackBoard |> set(hunchLevelParam, newHunchLevel)

      owner.blackBoard |> set(lastTargetSeenParam, false)
      owner.blackBoard |> set(lastTargetTimeParam, curTime)

      owner.blackBoard |> set(stillTimeOutParam, stillTime)
      owner.blackBoard |> set(turnAngleOutParam, turnAngle)
      owner.blackBoard |> set(focusTimeOutParam, focusTime)
    return EBehResult.ER_SUCCESS

[beh_node(name="fixLookDirPos")]
class FixLookDirPos : BehNodeAdapter
  posParam : int = -1
  goodLookDist : float = 5.0

  def override loadFromBlk(var data : DataBlock) : void
    posParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posParam", ""), float3())
    goodLookDist = data |> datablock_getReal("goodLookDist", goodLookDist)

  def override update(dt : float) : EBehResult
    if posParam < 0
      return EBehResult.ER_SUCCESS

    let agentEid = beh_tree_eid(owner)
    var hasFromPos = false
    var fromPos = float3()
    query(agentEid) <| $ [es] (transform : float3x4; walker_agent : EntityAgent)
      fromPos = transform[3]
      fromPos.y = walker_agent.shootFrom[STANCE_STAND].y
      hasFromPos = true
    if !hasFromPos
      return EBehResult.ER_SUCCESS

    let toPos = owner.blackBoard |> datablock_getPoint3(posParam)

    let dir = normalize((toPos - fromPos) * float3(1, 0, 1))

    var norm : float3
    var dist = goodLookDist
    if !traceray_normalized(fromPos, dir, dist, norm, ETF_ALL)
      return EBehResult.ER_SUCCESS

    let dir2 = float3(dir.z, 0.0, -dir.x)
    let dir2a = normalize(dir + dir2)
    var dist2a = goodLookDist
    if !traceray_normalized(fromPos, dir2a, dist2a, norm, ETF_ALL)
      owner.blackBoard |> set(posParam, fromPos + dir2a * goodLookDist)
      return EBehResult.ER_SUCCESS

    let dir3 = float3(-dir.z, 0.0, dir.x)
    let dir3a = normalize(dir + dir3)
    var dist3a = goodLookDist
    if !traceray_normalized(fromPos, dir3a, dist3a, norm, ETF_ALL)
      owner.blackBoard |> set(posParam, fromPos + dir3a * goodLookDist)
      return EBehResult.ER_SUCCESS

    var dist2 = goodLookDist
    if !traceray_normalized(fromPos, dir2, dist2, norm, ETF_ALL)
      owner.blackBoard |> set(posParam, fromPos + dir2 * goodLookDist)
      return EBehResult.ER_SUCCESS

    var dist3 = goodLookDist
    if !traceray_normalized(fromPos, dir3, dist3, norm, ETF_ALL)
      owner.blackBoard |> set(posParam, fromPos + dir3 * goodLookDist)
      return EBehResult.ER_SUCCESS

    var dirF = dir
    if dist < dist2a
      dist = dist2a
      dirF = dir2a
    if dist < dist3a
      dist = dist3a
      dirF = dir3a
    if dist < dist3
      dist = dist3
      dirF = dir3
    if dist < dist2
      dist = dist2
      dirF = dir2

    owner.blackBoard |> set(posParam, fromPos + dirF * goodLookDist)
    return EBehResult.ER_SUCCESS

[beh_node(name="isPointAhead")]
class IsPointAhead : BehNodeAdapter
  posParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    posParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posParam", ""), float3())

  def override update(dt : float) : EBehResult
    if posParam < 0
      return EBehResult.ER_FAILED

    let pt = owner.blackBoard |> datablock_getPoint3(posParam)

    var result = false
    let agentEid = beh_tree_eid(owner)
    query(agentEid) <| $ [es] (transform : float3x4)
      let dirToPt = normalize(pt - transform[0])
      result = dot(transform[0], dirToPt) > 0.0

    return result ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="isCurrentWeaponRequiresLongAiming")]
class IsCurrentWeaponRequiresLongAiming : BehNodeAdapter
  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    var result = false
    query(agentEid) <| $ [es] (human_weap__currentGunEid : EntityId)
      query(human_weap__currentGunEid) <| $ [es] (specialAIWeaponType : int)
        if specialAIWeaponType == int(SpecialAIWeaponType.ROCKET_LAUNCHERS)
          result = true
        elif specialAIWeaponType == int(SpecialAIWeaponType.ANTI_TANK_RIFLES)
          result = true
    return result ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="findWeaponSlotWithSpecAIType")]
class FindWeaponSlotWithSpecAIType : BehNodeAdapter
  outParam : int = -1
  specWeapAIType : int = 0
  minAmmo : int = 0

  def override loadFromBlk(var data : DataBlock) : void
    outParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "toParam", ""), -1)
    minAmmo = datablock_getInt(data, "minAmmo", minAmmo)

    let weapTypeName = datablock_getStr(data, "specAIWeapTypeName", "")
    for i in range(length(SPECIAL_AI_WEAPON_TYPE_NAMES))
      if weapTypeName == SPECIAL_AI_WEAPON_TYPE_NAMES[i]
        specWeapAIType = i

  def override update(dt : float) : EBehResult
    var found = false
    query(beh_tree_eid(owner)) <| $ [es] (human_weap__gunEids : EidList)
      for slot_index, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
        if minAmmo > 0 && !check_ai_gun_has_min_ammo(gunEid, minAmmo)
          continue
        if !check_ai_gun_has_spec_ai_type(gunEid, specWeapAIType)
          continue
        owner.blackBoard |> set(outParam, slot_index)
        found = true
        break
    return found ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="findWeaponSlotWithTag")]
class FindWeaponSlotWithTag : BehNodeAdapter
  outParam : int = -1
  tag : string = ""
  tagHash : uint
  minAmmo : int = 0

  def override loadFromBlk(var data : DataBlock) : void
    outParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "toParam", "preferedWeapon"), -1)
    tag = datablock_getStr(data, "tag", "")
    tagHash = ecs_hash(tag)
    minAmmo = datablock_getInt(data, "minAmmo", minAmmo)

  def override update(dt : float) : EBehResult
    if tag == ""
      return EBehResult.ER_FAILED
    var found = false
    query(beh_tree_eid(owner)) <| $ [es] (human_weap__gunEids : EidList)
      for slot_index, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
        if !has(gunEid, tag, tagHash)
          continue
        if minAmmo > 0 && !check_ai_gun_has_min_ammo(gunEid, minAmmo)
          continue
        owner.blackBoard |> set(outParam, slot_index)
        found = true
        break
    return found ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="findPiercableEnemyVehicle")]
class FindPiercableEnemyVehicle : BehNodeAdapter
  inTargetEidParam : int  = -1

  outTargetEidParam : int = -1
  outLocalPosParam : int = -1
  outShootStanceParam : int = -1
  outShootLocalPosParam : int = -1

  weaponSlotParam : int = -1
  shootStances : int3 = int3(2, 2, 2)
  chanceTryNotPenetrate : float = 10.0
  chanceToTargetHumanPlayer : float = 0.2

  ignoreMoving : bool = true
  ignoreMovingSpeed : float = 10.0
  ignoreWithNoCrew : bool = false

  distanceErrorCoef : float = 1.1
  randOffset : float2 = float2(0.35, 0.15)
  withSecondaryChance : float = 0.25

  wideTraceRadius : float = 0.25
  wideTraceOffsetUp : float = 0.0
  wideTraceDistance : float = 5.0

  maxTargetsProcessed : int = 5
  maxPointsPerTarget : int = 5

  runTeam : int = 0
  runTeamEid : EntityId = INVALID_ENTITY_ID
  runAgentTransform : float3x4 = float3x4()
  runAgentShootUpPos : float3 = float3()
  runAgentShootForwPos : float3 = float3()
  runAgentShootDownPos : float3 = float3()
  runShootVel : float = 0.0
  runShellId : int = -1
  runDamageId : int = -1
  runBallisticsId : int = -1
  runBallisticCoef : float = 1.0
  runShootRange : float2 = float2()
  runTicketIdx : int = -1

  runStep : int = 0
  runIndex1 : int = 0
  runIndex2 : int = 0
  runTargetNoPierceCheck : bool = false
  runTargetScore : float = 0.0
  runShootPos : float3 = float3()
  runShootStance : int = -1
  runBestEid : EntityId = INVALID_ENTITY_ID
  runBestScore : float = 0.0
  runBestLocalPos : float3 = float3()
  runBestShootPos : float3 = float3()
  runBestStance : int = -1

  SCAN_TICKET_TIMEOUT = 1.0
  BASE_SCORE_VALUE = 100000.0
  TANK_SCORE_MULTIPLIER = 5.0

  STEP_INIT_CHECK = 1
  STEP_TRACE_TARGETS = 2
  STEP_DONE = 3

  def override loadFromBlk(var data : DataBlock) : void
    if datablock_find_param(data, "inTargetEidParam") >= 0
      inTargetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "inTargetEidParam", ""), 0)

    outTargetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outTargetEidParam", ""), 0)
    outLocalPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outLocalPosParam", ""), float3())
    if datablock_find_param(data, "outShootStanceParam") >= 0
      outShootStanceParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outShootStanceParam", ""), 1)
    if datablock_find_param(data, "outShootLocalPosParam") >= 0
      outShootLocalPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outShootLocalPosParam", ""), float3())

    weaponSlotParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "weaponSlotParam", ""), -1)
    shootStances = datablock_getIPoint3(data, "shootStances", shootStances)
    if datablock_find_param(data, "shootStance") >= 0
      let stance = datablock_getInt(data, "shootStance", 1)
      shootStances = int3(stance, stance, stance)

    chanceTryNotPenetrate = datablock_getReal(data, "chanceTryNotPenetrate", chanceTryNotPenetrate)

    let KM_H_IN_M_S = 1000.0 / 3600.0
    ignoreMoving = datablock_getBool(data, "ignoreMoving", ignoreMoving)
    ignoreMovingSpeed = datablock_getReal(data, "ignoreMovingSpeed", ignoreMovingSpeed)
    ignoreMovingSpeed *= KM_H_IN_M_S

    ignoreWithNoCrew = datablock_getBool(data, "ignoreWithNoCrew", ignoreWithNoCrew)

    distanceErrorCoef = datablock_getReal(data, "distanceErrorCoef", distanceErrorCoef)

    wideTraceRadius = datablock_getReal(data, "wideTraceRadius", wideTraceRadius)
    wideTraceOffsetUp = datablock_getReal(data, "wideTraceOffsetUp", wideTraceOffsetUp)
    wideTraceDistance = datablock_getReal(data, "wideTraceDistance", wideTraceDistance)

    maxTargetsProcessed = datablock_getInt(data, "maxTargetsProcessed", maxTargetsProcessed)
    maxPointsPerTarget = datablock_getInt(data, "maxPointsPerTarget", maxPointsPerTarget)

    chanceToTargetHumanPlayer = datablock_getReal(data, "chanceToTargetHumanPlayer", chanceToTargetHumanPlayer)

  def override init() : void
    runStep = STEP_INIT_CHECK
    clear_targets()

  def override exit() : void
    runStep = STEP_INIT_CHECK
    clear_targets()

  def clear_targets()
    query(beh_tree_eid(owner)) <| $ [es] (var beh_tree__runEidList : EidList&; var beh_tree__runPosList : Point3List&)
      beh_tree__runEidList |> clear()
      beh_tree__runPosList |> clear()

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)
    let curTime = get_sync_time()

    if runStep == STEP_INIT_CHECK
      var gunEid = INVALID_ENTITY_ID
      let gunSlot = owner.blackBoard |> datablock_getInt(weaponSlotParam)
      query(agentEid) <| $ [es] (transform : float3x4; human_weap__gunEids : EidList; team : int; walker_agent : EntityAgent)
        if gunSlot >= 0 && gunSlot < length(human_weap__gunEids)
          let checkGunEid = human_weap__gunEids[gunSlot]
          query(checkGunEid) <| $ [es] (combatFiringRange : float2; gun__curShellId : ShellPropIds; combatBallisticCoef : float = 0.0)
            gunEid = checkGunEid
            runShootVel = 50.0
            shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
              runShootVel = shellStartProps.speed
            runShellId = int(gun__curShellId.shellId)
            runDamageId = int(gun__curShellId.damageId)
            runBallisticsId = int(gun__curShellId.ballisticsId)
            runBallisticCoef = combatBallisticCoef
            runShootRange = combatFiringRange
            runAgentTransform = transform
            let invTr = inverse(transform)
            runAgentShootUpPos = invTr * walker_agent.shootFrom[shootStances.x]
            runAgentShootForwPos = invTr * walker_agent.shootFrom[shootStances.y]
            runAgentShootDownPos = invTr * walker_agent.shootFrom[shootStances.z]
            runTeam = team
      if gunEid == INVALID_ENTITY_ID
        return EBehResult.ER_FAILED

      runTeamEid = INVALID_ENTITY_ID
      find_query() <| $ [es] (eid : EntityId; team__id : int)
        if team__id == runTeam
          runTeamEid = eid
          return true
        return false
      if runTeamEid == INVALID_ENTITY_ID
        return EBehResult.ER_FAILED

      runTicketIdx = -1
      query(runTeamEid) <| $ [es] (team_bots__maxFarTracesAtOnce : int;
                                   var team_bots__farTracersEids : EidList&;
                                   var team_bots__farTracersTimeouts : FloatList&)
        for i in iter_range(team_bots__farTracersEids)
          if team_bots__farTracersEids[i] == agentEid || team_bots__farTracersTimeouts[i] < curTime
            team_bots__farTracersEids[i] = agentEid
            team_bots__farTracersTimeouts[i] = curTime + SCAN_TICKET_TIMEOUT
            runTicketIdx = i
            break
        let numAllocated = length(team_bots__farTracersEids)
        if runTicketIdx < 0 && numAllocated < team_bots__maxFarTracesAtOnce
          runTicketIdx = numAllocated
          team_bots__farTracersEids |> push(agentEid)
          team_bots__farTracersTimeouts |> push(curTime + SCAN_TICKET_TIMEOUT)
      if runTicketIdx < 0
        return EBehResult.ER_FAILED

      var numTargets = 0
      query(agentEid) <| $ [es] (var beh_tree__runEidList : EidList&)
        beh_tree__runEidList |> clear()

        let findRadius = runShootRange.y * distanceErrorCoef
        let minDistSq = square(safediv(runShootRange.x, distanceErrorCoef))
        let maxDistSq = square(findRadius)
        let maxVelSq = square(ignoreMovingSpeed)

        if inTargetEidParam >= 0
          let targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(inTargetEidParam)))
          if targetEid != INVALID_ENTITY_ID
            beh_tree__runEidList |> push(targetEid)
            ++numTargets

        if numTargets == 0
          for_each_entity_in_grid(ecs_hash("vehicles"), BSphere3(runAgentTransform[3], findRadius), GridEntCheck.BOUNDING) <| $(that_eid : EntityId)
            query(that_eid) <| $ [es(REQUIRE_NOT=airplane)] (transform : float3x4; team : int; ai_target : Target)
              if that_eid == agentEid
                return
              if !ai_target.isAlive || team <= 0 || is_teams_friendly(team, runTeam)
                return
              if ignoreMoving && length_sq(ai_target.velocity) > maxVelSq
                return
              let distSq = distance_sq(transform[3], runAgentTransform[3])
              if distSq < minDistSq || distSq > maxDistSq
                return
              if ignoreWithNoCrew && !is_vehicle_with_alive_crew(that_eid)
                return
              beh_tree__runEidList |> push(that_eid)
              ++numTargets

          if rnd_float(0.0, 1.0) < chanceToTargetHumanPlayer
            query(agentEid) <| $ [es] (agent_dangers : AgentDangers)
              for danger in agent_dangers.dangers
                if !danger.traceable || danger.distance < runShootRange.x || danger.distance > runShootRange.y
                  continue
                var dangerOK = false
                query(danger.eid) <| $ [es] (transform : float3x4; isAlive : bool = true; isDowned : bool = false; isInVehicleHidden : bool = false; beh_tree__enabled : bool)
                  let LOOKING_TO_AGENT_COS = 0.8
                  if !beh_tree__enabled && isAlive && !isDowned && !isInVehicleHidden && dot(transform[0], normalize(runAgentTransform[3] - transform[3])) > LOOKING_TO_AGENT_COS
                    dangerOK = true
                if dangerOK
                  beh_tree__runEidList |> push(danger.eid)
                  ++numTargets

        if length(beh_tree__runEidList) > 1
          shuffle(beh_tree__runEidList)
        if length(beh_tree__runEidList) > maxTargetsProcessed
          beh_tree__runEidList |> resize(maxTargetsProcessed)

      if numTargets <= 0
        return EBehResult.ER_FAILED
      runStep = STEP_TRACE_TARGETS
      runIndex1 = 0
      runIndex2 = 0
      runBestEid = INVALID_ENTITY_ID
      runBestScore = 0.0
      runBestLocalPos = float3()
      runBestShootPos = float3()
      runBestStance = shootStances.y
      return EBehResult.ER_RUNNING

    if runStep == STEP_TRACE_TARGETS
      query(runTeamEid) <| $ [es] (var team_bots__farTracersEids : EidList&;
                                   var team_bots__farTracersTimeouts : FloatList&)
        if runTicketIdx >= 0 && runTicketIdx < length(team_bots__farTracersEids)
          team_bots__farTracersEids[runTicketIdx] = agentEid
          team_bots__farTracersTimeouts |> push(curTime + SCAN_TICKET_TIMEOUT)

      var done = false
      query(agentEid) <| $ [es] (beh_tree__runEidList : EidList; var beh_tree__runPosList : Point3List&)
        let numTargets = length(beh_tree__runEidList)
        while runIndex1 < numTargets
          let targetEid = beh_tree__runEidList[runIndex1]

          if runIndex2 == 0
            query(targetEid) <| $ [es] (transform : float3x4; isTank : Tag const?; dm_ai__pointsYRange : float2 = float2(0.0, 2.0))
              beh_tree__runPosList |> clear()

              let midPoint = transform * float3(0.0, (dm_ai__pointsYRange.x + dm_ai__pointsYRange.y) * 0.5, 0.0)

              let agentDir = normalize(midPoint.xz - runAgentTransform[3].xz)
              runAgentTransform[0] = float3(agentDir.x, 0.0, agentDir.y)
              runAgentTransform[1] = float3(0.0, 1.0, 0.0)
              runAgentTransform[2] = cross(runAgentTransform[0], runAgentTransform[1])

              let midCheckAgentShootPos = runAgentTransform * runAgentShootDownPos
              let midDelta = midPoint - midCheckAgentShootPos
              let midDir = normalize(midDelta)

              let SHOOT_CLING_SIN = 0.05
              if midDir.y > SHOOT_CLING_SIN
                runShootPos = runAgentTransform * runAgentShootUpPos
                runShootStance = shootStances.x
              elif midDir.y < -SHOOT_CLING_SIN
                runShootPos = runAgentTransform * runAgentShootDownPos
                runShootStance = shootStances.z
              else
                runShootPos = runAgentTransform * runAgentShootForwPos
                runShootStance = shootStances.y

              let targetPoint = transform * float3(0.0, dm_ai__pointsYRange.y, 0.0)
              let targetDelta = targetPoint - runShootPos
              let targetDir = normalize(targetDelta)
              let targetDist = length(targetDelta)

              runTargetScore = safediv(BASE_SCORE_VALUE, targetDist)
              if isTank != null
                runTargetScore *= TANK_SCORE_MULTIPLIER

              if runBestEid != INVALID_ENTITY_ID && runBestScore >= runTargetScore
                return

              let noCrew = ignoreWithNoCrew || !is_vehicle_with_alive_crew(targetEid)
              var targetDMAIPoints : array<TargetDMAIPoint>
              pick_target_dm_ai_points(targetDMAIPoints, maxPointsPerTarget, runShootPos, targetEid, noCrew, randOffset, /*allow_from_front*/ false, withSecondaryChance)
              for point in targetDMAIPoints
                push(beh_tree__runPosList, point.worldPos)

              runTargetNoPierceCheck = false
              if empty(beh_tree__runPosList)
                runTargetNoPierceCheck = has(targetEid, "human")
                if !runTargetNoPierceCheck
                  return
                beh_tree__runPosList |> push(midPoint)

              var dist = targetDist
              var norm : float3
              if traceray_normalized(runShootPos, targetDir, dist, norm, ETF_DEFAULT)
                beh_tree__runPosList |> clear()
                return

              let pt1 = runShootPos + float3(0.0, wideTraceOffsetUp, 0.0) - targetDir * wideTraceRadius
              let pt2 = pt1 + targetDir * (wideTraceDistance + wideTraceRadius)
              var queryOut = ShapeQueryOutput()
              if sphere_cast(pt1, pt2, wideTraceRadius, queryOut)
                beh_tree__runPosList |> clear()
                return

          let numPoints = length(beh_tree__runPosList)
          if runIndex2 >= numPoints
            runIndex2 = 0
            ++runIndex1
            break

          let targetHitPos = beh_tree__runPosList[runIndex2]
          ++runIndex2

          query(targetEid) <| $ [es] (transform : float3x4)
            var aimShootHitPos = targetHitPos
            if runTargetNoPierceCheck || trace_pierce_shot(aimShootHitPos, runShootPos, targetHitPos, runShootVel, runShellId, runDamageId, runBallisticsId, runBallisticCoef, targetEid, chanceTryNotPenetrate)
              runIndex2 = numPoints
              if runBestEid == INVALID_ENTITY_ID || runBestScore < runTargetScore
                runBestEid = targetEid
                runBestScore = runTargetScore
                runBestLocalPos = inverse(transform) * aimShootHitPos
                runBestShootPos = inverse(runAgentTransform) * runShootPos
                runBestStance = runShootStance

          if runIndex2 >= numPoints
            runIndex2 = 0
            ++runIndex1
        done = runIndex1 >= numTargets
      if !done
        return EBehResult.ER_RUNNING
      runStep = STEP_DONE

    clear_targets()

    if outTargetEidParam >= 0
      owner.blackBoard |> set(outTargetEidParam, int(uint(runBestEid)))
    if outLocalPosParam >= 0
      owner.blackBoard |> set(outLocalPosParam, runBestLocalPos)
    if outShootStanceParam >= 0
      owner.blackBoard |> set(outShootStanceParam, runBestStance)
    if outShootLocalPosParam >= 0
      owner.blackBoard |> set(outShootLocalPosParam, runBestShootPos)

    return runBestEid != INVALID_ENTITY_ID ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


def calc_delayed_reaction_score(at_time : float; score : float; score_min_max_vel : float3)
  let curTime = get_sync_time()
  if at_time < 0.0
    return 0.0
  if curTime < at_time
    return score
  return score + clamp(score_min_max_vel.z * (curTime - at_time), score_min_max_vel.x, score_min_max_vel.y)

def try_charge_delayed_reaction(agent_eid : EntityId; reaction_type : string;
                                delay_time : float2; score : float; score_min_max_vel : float3;
                                eid : EntityId; pos : float3; dir : float3)
  query(agent_eid) <| $ [es] (var agent_dangers__delayedReactionAwait : bool&;
                              var agent_dangers__delayedReactionTime : float&;
                              var agent_dangers__delayedReactionScore : float&;
                              var agent_dangers__delayedReactionScoreMinMaxVel : float3&;
                              var agent_dangers__delayedReactionType : das_string&;
                              var agent_dangers__delayedReactionEid : EntityId&;
                              var agent_dangers__delayedReactionPos : float3&;
                              var agent_dangers__delayedReactionDir : float3&)
    var curScore = -1.0
    if agent_dangers__delayedReactionTime >= 0.0
      curScore = calc_delayed_reaction_score(agent_dangers__delayedReactionTime, agent_dangers__delayedReactionScore, agent_dangers__delayedReactionScoreMinMaxVel)
    if score > curScore
      agent_dangers__delayedReactionAwait = true
      agent_dangers__delayedReactionTime = get_sync_time() + rnd_float(delay_time.x, delay_time.y)
      agent_dangers__delayedReactionScore = score
      agent_dangers__delayedReactionScoreMinMaxVel = score_min_max_vel
      agent_dangers__delayedReactionType := reaction_type
      agent_dangers__delayedReactionEid = eid
      agent_dangers__delayedReactionPos = pos
      agent_dangers__delayedReactionDir = dir

[beh_node(name="resetDelayedReaction")]
class ResetDelayedReaction : BehNodeAdapter
  def override update(dt : float) : EBehResult
    query(beh_tree_eid(owner)) <| $ [es] (var agent_dangers__delayedReactionAwait : bool&;
                                          var agent_dangers__delayedReactionTime : float&)
      agent_dangers__delayedReactionAwait = false
      agent_dangers__delayedReactionTime = -1.0
    return EBehResult.ER_SUCCESS

[beh_node(name="checkDelayedReaction")]
class CheckDelayedReaction : BehNodeAdapter
  ofType : string
  minScore : float = 0.0
  isAhead : bool = false

  DELAYED_REACTION_TIMEOUT = 2.5

  def override loadFromBlk(data : DataBlock) : void
    ofType = datablock_getStr(data, "ofType", "")
    minScore = datablock_getReal(data, "minScore", minScore)
    isAhead = datablock_getBool(data, "isAhead", isAhead)

  def override update(dt : float) : EBehResult
    var result = true
    query(beh_tree_eid(owner)) <| $ [es] (agent_dangers__delayedReactionAwait : bool;
                                          agent_dangers__delayedReactionTime : float;
                                          agent_dangers__delayedReactionScore : float;
                                          agent_dangers__delayedReactionScoreMinMaxVel : float3;
                                          agent_dangers__delayedReactionType : string;
                                          agent_dangers__delayedReactionPos : float3;
                                          transform : float3x4)
      if agent_dangers__delayedReactionAwait
        result = false
        return
      let curTime = get_sync_time()
      if agent_dangers__delayedReactionTime < 0.0
        result = false
        return
      if curTime < agent_dangers__delayedReactionTime || curTime > agent_dangers__delayedReactionTime + DELAYED_REACTION_TIMEOUT
        result = false
        return

      if ofType != "" && agent_dangers__delayedReactionType != ofType
        result = false
        return
      if minScore > 0.0
        let curScore = calc_delayed_reaction_score(agent_dangers__delayedReactionTime, agent_dangers__delayedReactionScore, agent_dangers__delayedReactionScoreMinMaxVel)
        if curScore < minScore
          result = false
          return
      if isAhead
        let delta = agent_dangers__delayedReactionPos - transform[3]
        if dot(delta, transform[0]) < 0.0
          result = false
          return

    return result ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED

[beh_node(name="getDelayedReaction")]
class GetDelayedReaction : BehNodeAdapter
  outPosParam : int = -1
  outDirParam : int = -1
  outEidParam : int = -1

  def override loadFromBlk(data : DataBlock) : void
    if datablock_find_param(data, "outPosParam") >= 0
      outPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outPosParam", ""), float3())
    if datablock_find_param(data, "outDirParam") >= 0
      outDirParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outDirParam", ""), float3())
    if datablock_find_param(data, "outEidParam") >= 0
      outEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "outEidParam", ""), 0)

  def override update(dt : float) : EBehResult
    query(beh_tree_eid(owner)) <| $ [es] (agent_dangers__delayedReactionPos : float3;
                                          agent_dangers__delayedReactionDir : float3;
                                          agent_dangers__delayedReactionEid : EntityId)
      if outPosParam >= 0
        owner.blackBoard |> set(outPosParam, agent_dangers__delayedReactionPos)
      if outDirParam >= 0
        owner.blackBoard |> set(outDirParam, agent_dangers__delayedReactionDir)
      if outEidParam >= 0
        owner.blackBoard |> set(outEidParam, int(uint(agent_dangers__delayedReactionEid)))

    return EBehResult.ER_SUCCESS


[beh_node(name="checkedChargeAttackReaction")]
class CheckedChargeAttackReaction : BehNodeAdapter
  targerEidParam : int = -1
  moving : bool = false
  passive : bool = false

  from : int = 0
  FROM_NONE = 0
  FROM_ON_HIT = 1
  FROM_ON_BULLET_NEARBY = 2

  farDistSq : float = square(59.0)

  coverAttackParam : int = -1
  dangerLevelParam : int = -1

  AT_SIDE_COS = 0.57

  HIT_AWARE_RADIUS = 12.0
  HIT_AWARE_RADIUS_SQUAD = 18.0
  BUL_AWARE_RADIUS = 15.0
  BUL_AWARE_RADIUS_SQUAD = 15.0
  NEAR_TARGETS_DISTANCE = 16.0

  HIT_SELF_REACT_CHANCE = 0.9
  HIT_SELF_REACT_DELAYS = float2(1.0, 1.5)

  HIT_ALLY_REACT_DELAYS_FRONT = float2(0.5, 0.7)
  HIT_ALLY_REACT_DELAYS_SIDE = float2(0.7, 0.9)
  HIT_ALLY_REACT_DELAYS_BACK = float2(1.0, 1.5)
  HIT_ALLY_MOVING_CHANCE = 0.5

  BUL_SELF_REACT_CHANCE_FAR_IN_ATTACK = 0.3
  BUL_SELF_REACT_CHANCE_FAR = 0.7

  BUL_ALLY_MOVING_CHANCE = 0.5
  BUL_ALLY_REACT_CHANCE_RESCUE = 0.5
  BUL_ALLY_REACT_CHANCE_HELP = 0.25

  BUL_DELAY_ALREADY = 0.4
  BUL_SELF_REACT_DELAYS_FRONT = float2(0.5, 0.6)
  BUL_SELF_REACT_DELAYS_SIDE = float2(0.75, 0.9)
  BUL_SELF_REACT_DELAYS_BACK = float2(1.0, 1.2)
  BUL_ALLY_REACT_DELAYS_FRONT = float2(1.0, 1.5)
  BUL_ALLY_REACT_DELAYS_SIDE = float2(1.5, 2.0)
  BUL_ALLY_REACT_DELAYS_BACK = float2(2.0, 2.5)

  SCORE_PANIC = 10.0
  SCORE_URGENT = 5.0
  SCORE_RESCUE = 3.0
  SCORE_HELP = 1.0

  SCORE_DYNAMIC_URGENT_DOWN = float3(0.0, 9.5, -1.0)
  SCORE_DYNAMIC_RESCUE_DOWN = float3(1.5, 4.5, -1.0)
  SCORE_DYNAMIC_HELP_DOWN = float3(0.0, 4.5, -1.0)

  def override loadFromBlk(data : DataBlock) : void
    if datablock_find_param(data, "targerEidParam") >= 0
      targerEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targerEidParam", ""), 0)
    moving = datablock_getBool(data, "moving", moving)
    passive = datablock_getBool(data, "passive", passive)

    from = FROM_NONE
    let fromStr = datablock_getStr(data, "from", "")
    if fromStr == "onHit"
      from = FROM_ON_HIT
    elif fromStr == "onBulletNearby"
      from = FROM_ON_BULLET_NEARBY

    coverAttackParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "coverAttackParam", "coverAttack"), 0)
    dangerLevelParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "dangerLevelParam", "dangerLevel"), 0.0)

  def gather_allies_around(agent_eid : EntityId; agent_squad : EntityId; pos : float3; agent_team : int;
                           var allies : array<EntityId>; radius : float; radius_squad : float)
    let radiusSq = square(radius)
    let radiusSquadSq = square(radius_squad)
    for_each_entity_in_grid(ecs_hash("humans"), BSphere3(pos, radius), GridEntCheck.BOUNDING) <| $(that_eid : EntityId)
      if that_eid != agent_eid
        query(that_eid) <| $ [es] (transform : float3x4; team : int; isAlive : bool; isDowned : bool;
                                   squad_member__squad : EntityId = INVALID_ENTITY_ID)
          if isAlive && !isDowned && team == agent_team
            let checkRadiusSq = squad_member__squad == agent_squad ? radiusSquadSq : radiusSq
            if distance_sq(pos, transform[3]) < checkRadiusSq
              push(allies, that_eid)

  def can_see_danger(agent_eid : EntityId; danger_eid : EntityId; from_pos : float3; to_pos : float3)
    var hasResult = false
    var result = false
    query(agent_eid) <| $ [es] (agent_dangers : AgentDangers)
      for danger in agent_dangers.dangers
        if danger.eid == danger_eid
          hasResult = true
          result = danger.traceable
          return
    if hasResult
      return result
    let dir = to_pos - from_pos
    var dist = max(1.0, length(dir) - 1.0)
    var norm : float3
    let HEIGHT_UP = float3(0.0, 1.3, 0.0)
    if traceray_normalized(from_pos + HEIGHT_UP, normalize(dir), dist, norm, ETF_ALL)
      return false
    return true

  def any_near_targets_around(actor_eid : EntityId)
    var result = false
    query(actor_eid) <| $ [es] (agent_dangers : AgentDangers)
      for danger in agent_dangers.dangers
        if danger.traceable && danger.distance < NEAR_TARGETS_DISTANCE
          result = true
          break
    return result

  def check_charge_on_hit(agent_eid : EntityId; agent_squad : EntityId; agent_pos : float3; agent_dir : float3; agent_team : int)
    query(agent_eid) <| $ [es] (agent_dangers__lastHitReactionDir : float3;
                                agent_dangers__lastHitReactionOffenderEid : EntityId)
      let reactEid = agent_dangers__lastHitReactionOffenderEid
      query(reactEid) <| $ [es] (transform : float3x4)
        let reactPos = transform[3]
        let reactDir = agent_dangers__lastHitReactionDir

        if rnd_float(0.0, 1.0) < HIT_SELF_REACT_CHANCE
          try_charge_delayed_reaction(agent_eid, "hide_heal_payback", HIT_SELF_REACT_DELAYS, SCORE_URGENT, SCORE_DYNAMIC_URGENT_DOWN, reactEid, reactPos, reactDir)

        if !passive
          var around : array<EntityId>
          gather_allies_around(agent_eid, agent_squad, agent_pos, agent_team, around, HIT_AWARE_RADIUS, HIT_AWARE_RADIUS_SQUAD)
          let fromBack = dot(agent_dir, reactDir) > 0.0
          if !empty(around)
            for around_eid in around
              if !fromBack && moving && rnd_float(0.0, 1.0) >= HIT_ALLY_MOVING_CHANCE
                continue
              let shouldRescue = fromBack && !any_near_targets_around(around_eid)
              let reactScore = shouldRescue ? SCORE_RESCUE : SCORE_HELP
              let reactScoreDynamic = shouldRescue ? SCORE_DYNAMIC_RESCUE_DOWN : SCORE_DYNAMIC_HELP_DOWN
              query(around_eid) <| $ [es] (transform : float3x4)
                let reactType = fromBack ? "back_assist" : can_see_danger(around_eid, reactEid, transform[3], reactPos) ? "front_assist" : "spot_assist"
                let reactDirAlly = normalize(reactPos - transform[3])
                let dotSideAlly = dot(reactDirAlly, transform[0])
                let fromBackForAlly = dotSideAlly < -AT_SIDE_COS
                let fromSideForAlly = !fromBackForAlly && dotSideAlly < AT_SIDE_COS
                let reactDelays = fromBackForAlly ? HIT_ALLY_REACT_DELAYS_BACK : fromSideForAlly ? HIT_ALLY_REACT_DELAYS_SIDE : HIT_ALLY_REACT_DELAYS_FRONT
                try_charge_delayed_reaction(around_eid, reactType, reactDelays, reactScore, reactScoreDynamic, reactEid, reactPos, reactDirAlly)
    return false

  def check_charge_on_bullet_nearby(agent_eid : EntityId; agent_squad : EntityId; agent_pos : float3; agent_dir : float3; agent_team : int; in_attack : bool)
    var result = !in_attack
    query(agent_eid) <| $ [es] (agent_dangers__lastBulletReactionDir : float3;
                                agent_dangers__lastBulletReactionOffenderEid : EntityId)
      let reactEid = agent_dangers__lastBulletReactionOffenderEid
      query(reactEid) <| $ [es] (transform : float3x4)
        let reactPos = transform[3]
        let reactDir = agent_dangers__lastBulletReactionDir

        let farTarget = distance_sq(reactPos, agent_pos) >= farDistSq

        if farTarget && rnd_float(0.0, 1.0) < (in_attack ? BUL_SELF_REACT_CHANCE_FAR_IN_ATTACK : BUL_SELF_REACT_CHANCE_FAR)
          let dotSide = dot(reactDir, agent_dir)
          let fromBack = dotSide < -AT_SIDE_COS
          let fromSide = !fromBack && dotSide < AT_SIDE_COS
          var reactDelays = fromBack ? BUL_SELF_REACT_DELAYS_BACK : fromSide ? BUL_SELF_REACT_DELAYS_SIDE : BUL_SELF_REACT_DELAYS_FRONT
          reactDelays.x -= BUL_DELAY_ALREADY
          reactDelays.y -= BUL_DELAY_ALREADY

          let isUrgent = fromBack || (coverAttackParam >= 0 ? owner.blackBoard |> datablock_getInt(coverAttackParam) : 0) > 0
          let reactScore = isUrgent ? SCORE_URGENT : SCORE_RESCUE
          let reactScoreDynamic = isUrgent ? SCORE_DYNAMIC_URGENT_DOWN : SCORE_DYNAMIC_RESCUE_DOWN

          let reactType = (in_attack ? (rnd_float(0.0, 1.0) < 0.5 ? "hide_unhide" : "hide_payback") :
                                       (fromBack ? "turn_payback" : can_see_danger(agent_eid, reactEid, agent_pos, reactPos) ? "turn_payback" : "spot_assist"))
          try_charge_delayed_reaction(agent_eid, reactType, reactDelays, reactScore, reactScoreDynamic, reactEid, reactPos, reactDir)
          result = true

          let wasDangerLevel = owner.blackBoard |> datablock_getReal(dangerLevelParam)
          let newDangerLevel = isUrgent ? 2.0 : min(2.0, wasDangerLevel + 1.0)
          owner.blackBoard |> set(dangerLevelParam, newDangerLevel)

        if !passive
          var around : array<EntityId>
          gather_allies_around(agent_eid, agent_squad, agent_pos, agent_team, around, BUL_AWARE_RADIUS, BUL_AWARE_RADIUS_SQUAD)
          let fromBack = dot(agent_dir, reactDir) > 0.0
          if !empty(around)
            for around_eid in around
              if !fromBack && moving && rnd_float(0.0, 1.0) >= BUL_ALLY_MOVING_CHANCE
                continue
              let shouldRescue = fromBack && (in_attack || moving) && !any_near_targets_around(around_eid)
              let reactScore = shouldRescue ? SCORE_RESCUE : SCORE_HELP
              let reactScoreDynamic = shouldRescue ? SCORE_DYNAMIC_RESCUE_DOWN : SCORE_DYNAMIC_HELP_DOWN
              query(around_eid) <| $ [es] (transform : float3x4)
                let reactType = fromBack ? "back_assist" : can_see_danger(around_eid, reactEid, transform[3], reactPos) ? "front_assist" : "spot_assist"
                let reactChance = (shouldRescue || reactType == "spot_assist") ? BUL_ALLY_REACT_CHANCE_RESCUE : BUL_ALLY_REACT_CHANCE_HELP
                if rnd_float(0.0, 1.0) < reactChance
                  let reactDirAlly = normalize(reactPos - transform[3])
                  let dotSideAlly = dot(reactDirAlly, transform[0])
                  let fromBackForAlly = dotSideAlly < -AT_SIDE_COS
                  let fromSideForAlly = !fromBackForAlly && dotSideAlly < AT_SIDE_COS
                  var reactDelays = fromBackForAlly ? BUL_ALLY_REACT_DELAYS_BACK : fromSideForAlly ? BUL_ALLY_REACT_DELAYS_SIDE : BUL_ALLY_REACT_DELAYS_FRONT
                  reactDelays.x -= BUL_DELAY_ALREADY
                  reactDelays.y -= BUL_DELAY_ALREADY
                  try_charge_delayed_reaction(around_eid, reactType, reactDelays, reactScore, reactScoreDynamic, reactEid, reactPos, reactDirAlly)
    return result

    // TODO PANIC ~ 3000ms-5000ms
    //    hit self(30-50), hit ally (10-30), bul self(10-30), bul ally(0-10), die ally(30-50), from side x1.1, from back x1.2 ~ COMPARE TO > 100
    //   "panicMeter" (from too many bullets ~ self, and hit ~ self, and ally hit ~ see TODO file, and dies detect) => panic_run / panic_crawl (PANIC)

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)

    var agentTeam = -1
    var agentPos = float3()
    var agentDir = float3()
    var agentSquad = INVALID_ENTITY_ID
    query(agentEid) <| $ [es] (transform : float3x4; team : int = -1;
                               squad_member__squad : EntityId = INVALID_ENTITY_ID)
      agentTeam = team
      agentPos = transform[3]
      agentDir = transform[0]
      agentSquad = squad_member__squad

    var isPassive = false
    query(agentSquad) <| $ [es] (squad__squadBehaviour : int)
      if squad__squadBehaviour == int(SquadBehaviour.ESB_PASSIVE)
        isPassive = true
    if isPassive
      return EBehResult.ER_FAILED

    var targetEid = INVALID_ENTITY_ID
    if targerEidParam >= 0
      targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targerEidParam)))
    let inAttack = targetEid != INVALID_ENTITY_ID

    var result = false
    if from == FROM_ON_HIT
      result = check_charge_on_hit(agentEid, agentSquad, agentPos, agentDir, agentTeam)
    elif from == FROM_ON_BULLET_NEARBY
      result = check_charge_on_bullet_nearby(agentEid, agentSquad, agentPos, agentDir, agentTeam, inAttack)
    return result ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED


[beh_node(name="checkFriendlyFire")]
class CheckFriendlyFire : BehNodeAdapter
  targetUnitParam : int = -1

  midHeight : float = 1.0
  safeRadius : float = 0.8

  def override loadFromBlk(var data : DataBlock) : void
    targetUnitParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetUnitParam", ""), 0)

  def override update(dt : float) : EBehResult
    var isFriendlyFireEnabled = false
    query() <| $ [es(REQUIRE=gamemodeFriendlyFire)] ()
      isFriendlyFireEnabled = true
    if !isFriendlyFireEnabled
      return EBehResult.ER_SUCCESS

    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult.ER_SUCCESS

    let fromPos = agent.pos + float3(0.0, midHeight, 0.0)
    var toPos = float3()

    var hasTarget = false
    let targetEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targetUnitParam)))
    query(targetEid) <| $ [es] (transform : float3x4)
      toPos = transform[3] + float3(0.0, midHeight, 0.0)
      hasTarget = true

    let delta = toPos - fromPos
    let dir = normalize(delta)
    var dist = length(delta)
    if dist > 0.0
      var allyAtLineOfFire = false
      using() <| $(var intersections : IntersectedEntities)
        trace_entities_in_grid_by_capsule(ecs_hash("humans"), fromPos, dir, dist, safeRadius, agent.eid, intersections, SortIntersections.NO)
        for intersection in intersections
          let eid = intersection.eid
          if eid == targetEid || eid == agent.eid
            continue
          query(eid) <| $ [es] (team : int)
            if is_teams_friendly(agent.teamId, team)
              allyAtLineOfFire = true
          if allyAtLineOfFire
            break
      if allyAtLineOfFire
        return EBehResult.ER_FAILED

    return EBehResult.ER_SUCCESS
