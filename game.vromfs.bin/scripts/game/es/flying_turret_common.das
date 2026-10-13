module flying_turret_common shared

require ecs
require ecs.common
require ecs.extra_set
require ecs.safe
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require DngPhysObj
require PhysObj
require CollRes
require dm
require strings
require vehicle
require DagorRandom
require math.base
require math.ang
require DngDm
require common_shooter.es.vehicle.vehicle_explosion_common


def gather_bone_subtree(tree : GeomNodeTree const?; boneIdx : int; var out : array<int>&)
  let boneName = string(*tree |> geomtree_getNodeName(boneIdx))
  if !ends_with(boneName, "_dstr")
    out |> push(boneIdx)
    let childCount = int(*tree |> geomtree_getChildCount(boneIdx))
    for i in range(childCount)
      gather_bone_subtree(tree, *tree |> geomtree_getChildNodeIdx(boneIdx, uint(i)), out)


def snapshot_alive_gun_part_bone(part_id : int;
                                 damage_model : DamageModel;
                                 collres : CollisionResource;
                                 animchar : AnimcharBaseComponent;
                                 turret_root_bone_idx : int;
                                 var out : array<string>&)
  if part_id < 0
    return
  let collNodeId = get_collision_node_id(damage_model.dmData, part_id)
  if collNodeId < 0
    return
  let node = collres_get_node(collres, collNodeId)
  if node == null
    return
  var boneIdx = int((*node).geomNodeId)
  while boneIdx >= 0 && boneIdx != turret_root_bone_idx
    let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
    if find_index(out, boneName) < 0
      out |> push(boneName)
    boneIdx = int(*animchar.nodeTree |> geomtree_getParentNodeIdx(boneIdx))


def resolve_dm_part_to_coll_node_id(part_name : string; damage_model : DamageModel) : int
  if empty(part_name)
    return -1
  let partId = find_part_id_by_name(damage_model, part_name)
  if partId < 0
    return -1
  return get_collision_node_id(damage_model.dmData, partId)


def resolve_seat_to_coll_node_id(seat : Object const?; damage_model : DamageModel) : int
  if seat == null
    return -1
  return resolve_dm_part_to_coll_node_id(get_string(*seat, "receiveDamageFromDMPart", ""), damage_model)


def do_detach_turret_server(tankEid : EntityId; bone_name : string; ammoScale : float = 1.0)
  if tankEid == INVALID_ENTITY_ID
    logerr("[detach_turret] invalid tankEid")
    return

  var gatherMatched = false
  query(tankEid) <| $ [es] (collres : CollisionResource;
                            damage_model : DamageModel;
                            animchar__res : string;
                            collres__res : string;
                            dmg_animchar__res : string;
                            transform : float3x4;
                            losable_turret__targetLaunchSpeed : float;
                            losable_turret__rotation : float;
                            losable_turret__deviation : float;
                            losable_turret__speedScale : float2;
                            losable_turret__mass : float;
                            losable_turret__tankMassFloor : float;
                            losable_turret__spawnUpOffset : float;
                            losable_turret__detachCollNode : string;
                            losable_turret__detachCollNodes : StringList const?;
                            fire_damage__openHatchesOnExplosion : bool;
                            fire_damage__hatchAngles : Object;
                            fire_damage__hatchPosOffsets : Object;
                            fire_damage__hatchOpenChance : float;
                            var fire_damage__hatchesOpened : bool&;
                            var losable_turret__lostBone : das_string&;
                            var vehicle_net_phys : VehiclePhysActor&;
                            var animchar : AnimcharBaseComponent;
                            turret_control__gunEids : EidList const?;
                            disableDMParts : StringList const?)
    gatherMatched = true

    if empty(bone_name)
      return
    let rootBoneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(bone_name)
    if rootBoneIdx < 0
      logerr("[detach_turret] bone not found: '{bone_name}'")
      return

    var turretTm : float3x4
    *animchar.nodeTree |> geomtree_getNodeWtmScalar(rootBoneIdx, turretTm)

    var subtree : array<int>
    gather_bone_subtree(animchar.nodeTree, rootBoneIdx, subtree)
    // Auto-discover collres nodes in turret subtree. Prefer `cls_*` (the convex_hull-declared
    // physics nodes from collisionProps): they're artist-tuned shapes that fit the turret silhouette.
    // Only fall back to all subtree nodes (damage-mesh shapes) when no cls_* exists, which is the
    // casemate-vehicle case (sturmpanzer etc.) where the turret has no dedicated physics shape.
    // Mixing both bloats the flying turret with dozens of overlapping convex hulls and can cause
    // it to spawn stuck inside the chassis on tanks with detailed damage parts in the subtree.
    var clsTurretNames : array<string>
    var allTurretNames : array<string>
    var turretCollNodeIds : array<int>
    let numCollNodes = collres_get_nodesCount(collres)
    for i in range(numCollNodes)
      let node = collres_get_node(collres, i)
      if node != null && find_index(subtree, int((*node).geomNodeId)) >= 0
        turretCollNodeIds |> push(i)
        let nodeName = string(collres_get_node_name(collres, i))
        if !empty(nodeName)
          if find_index(allTurretNames, nodeName) < 0
            allTurretNames |> push(nodeName)
          if starts_with(nodeName, "cls_") && find_index(clsTurretNames, nodeName) < 0
            clsTurretNames |> push(nodeName)
    var collNodeNames : array<string>
    if !empty(clsTurretNames)
      for n in clsTurretNames
        collNodeNames |> push(n)
    else
      for n in allTurretNames
        collNodeNames |> push(n)
    if losable_turret__detachCollNodes != null
      for n in *losable_turret__detachCollNodes
        let ns = string(n)
        if !empty(ns) && find_index(collNodeNames, ns) < 0
          collNodeNames |> push(ns)
    if !empty(losable_turret__detachCollNode) && find_index(collNodeNames, losable_turret__detachCollNode) < 0
      collNodeNames |> push(losable_turret__detachCollNode)
    if empty(collNodeNames)
      logerr("[detach_turret] no collres nodes found in subtree of '{bone_name}' and no explicit config for eid={tankEid}")
      return

    var disableDmPartsCopy : array<string>
    if disableDMParts != null
      for partName in *disableDMParts
        disableDmPartsCopy |> push(string(partName))

    var aliveBarrelBones : array<string>
    if turret_control__gunEids != null
      for gunEid in *turret_control__gunEids
        query(gunEid) <| $ [es] (turret_dm_part__barrelDm : int = -1;
                                 turret_dm_part__breechDm : int = -1;
                                 turret__isVisualBroken : bool = false)
          if turret__isVisualBroken
            return
          snapshot_alive_gun_part_bone(turret_dm_part__barrelDm, damage_model, collres, animchar, rootBoneIdx, aliveBarrelBones)
          snapshot_alive_gun_part_bone(turret_dm_part__breechDm, damage_model, collres, animchar, rootBoneIdx, aliveBarrelBones)

    var extraClearedCollNodeIds : array<int>
    query(tankEid) <| $ [es] (@shared_comp vehicle_seats__seats : Array)
      for child in vehicle_seats__seats
        let seat = get_ecs_object(child)
        let collNodeId = resolve_seat_to_coll_node_id(seat, damage_model)
        if collNodeId >= 0 && find_index(extraClearedCollNodeIds, collNodeId) < 0
          extraClearedCollNodeIds |> push(collNodeId)
    if disableDMParts != null
      for partName in *disableDMParts
        let collNodeId = resolve_dm_part_to_coll_node_id(string(partName), damage_model)
        if collNodeId >= 0 && find_index(extraClearedCollNodeIds, collNodeId) < 0
          extraClearedCollNodeIds |> push(collNodeId)

    var spawnTm = transform
    spawnTm[3] = transform[3] + transform[1] * losable_turret__spawnUpOffset

    let comOffset = inverse(spawnTm) * turretTm[3]

    let tankVel = float3(vehicle_net_phys.phys.currentState.velocity)
    let launchScatter = float3(rnd_float(-losable_turret__deviation, losable_turret__deviation), 1.0, rnd_float(-losable_turret__deviation, losable_turret__deviation))
    let speedJitter = rnd_float(losable_turret__speedScale.x, losable_turret__speedScale.y)
    let launchVelLocal = ammoScale * speedJitter * losable_turret__targetLaunchSpeed * launchScatter
    let launchVelWorld = transform[0] * launchVelLocal.x + transform[1] * launchVelLocal.y + transform[2] * launchVelLocal.z

    if fire_damage__openHatchesOnExplosion && !fire_damage__hatchesOpened
      open_hatches_at_seed(tankEid, animchar, fire_damage__hatchAngles, fire_damage__hatchPosOffsets, fire_damage__hatchOpenChance)
      fire_damage__hatchesOpened = true
    using() <| $(var rules : Array)
      push_to_array(rules) <| $(var rule : Object)
        rule |> set("nodeIds", turretCollNodeIds)
        rule |> set("exclude", true)
        rule |> set("behaviorFlags", 0)
      if length(extraClearedCollNodeIds) > 0
        push_to_array(rules) <| $(var rule : Object)
          rule |> set("nodeIds", extraClearedCollNodeIds)
          rule |> set("behaviorFlags", 0)
      using() <| $(var pinnedBoneTms : Object)
        let cosTol = 0.9999
        for boneIdx in subtree
          var restTm : float3x4
          *animchar.originalNodeTree |> geomtree_getNodeTmScalar(boneIdx, restTm)
          var curTm : float3x4
          *animchar.nodeTree |> geomtree_getNodeTmScalar(boneIdx, curTm)
          if dot(restTm[0], curTm[0]) < cosTol || dot(restTm[1], curTm[1]) < cosTol || dot(restTm[2], curTm[2]) < cosTol
            let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
            set(pinnedBoneTms, boneName, curTm)
        using() <| $(var collisionPropsOverride : Object)
          for name in collNodeNames
            set(collisionPropsOverride, name, "convex_hull")
          createEntity("flying_turret_base") <| $(var init : ComponentsInitializer)
            set(init, "transform", spawnTm)
            set(init, "animchar__res", animchar__res)
            set(init, "collres__res", collres__res)
            set(init, "dmg_animchar__res", dmg_animchar__res)
            set(init, "phys_obj__collisionPropsOverride", collisionPropsOverride)
            set(init, "flying_turret__bone", bone_name)
            set(init, "flying_turret__sourceTankEid", tankEid)
            set(init, "flying_turret__comOffset", comOffset)
            set(init, "flying_turret__pinnedBoneTms", pinnedBoneTms)
            if length(disableDmPartsCopy) > 0
              set(init, "disableDMParts", disableDmPartsCopy)
            if length(aliveBarrelBones) > 0
              set(init, "flying_turret__aliveBarrelBones", aliveBarrelBones)
            set(init, "flying_turret__mass", losable_turret__mass)
            let startVelWorld = launchVelWorld + tankVel
            set(init, "start_vel", startVelWorld)
            // start_omega: WT schema is `float3(rnd(-r,r), 0, rnd(-r,r))` -- pitch + roll, no yaw.
            let startOmegaLocal = float3(rnd_float(-losable_turret__rotation, losable_turret__rotation), 0.0, rnd_float(-losable_turret__rotation, losable_turret__rotation))
            let startOmegaWorld = transform[0] * startOmegaLocal.x + transform[1] * startOmegaLocal.y + transform[2] * startOmegaLocal.z
            set(init, "start_omega", startOmegaWorld)
            set(init, "collres__nodeFlagRules", rules)

    losable_turret__lostBone := bone_name

    var tankEffectiveMass = vehicle_net_phys.phys.getMass - losable_turret__mass
    if tankEffectiveMass < losable_turret__tankMassFloor
      tankEffectiveMass = losable_turret__tankMassFloor
    let tankRecoilWorld = launchVelWorld * (-losable_turret__mass / tankEffectiveMass)
    vehicle_net_phys.phys |> wakeUp()
    let newTankVel = tankVel + tankRecoilWorld
    vehicle_net_phys.phys.currentState.velocity = DPoint3(newTankVel)
  if !gatherMatched
    logerr("[detach_turret] gather failed for eid={tankEid} -- entity probably missing one of: animchar, collres, damage_model, animchar__res, collres__res, dmg_animchar__res, transform, vehicle_net_phys; or missing the `_use:t=\"tank_loseable_turret\"` mixin (losable_turret__lostBone field absent). Check with ecs.serialize_entity {tankEid} <file.blk>.")
