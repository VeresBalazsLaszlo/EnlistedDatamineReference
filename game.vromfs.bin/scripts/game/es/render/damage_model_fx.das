require ecs
require ecs.safe
require ecs.common
require ecs.extra_set
require math.base
require DagorMathUtils
require AnimV20
require GeomNodeTree
require dm
require DngDm
require fx
require DagorSystem
require DagorRandom
require Gun
require BallisticsProps
require DaWeaponProps
require game.es.vehicle.vehicle_events
require strings
require common_shooter.es.vehicle.vehicle_explosion_common
require common_shooter.es.vehicle.vehicle_fx_common


enum VehicleEffectType
  FatalFire = 0
  EngineFire
  FatalExplosion
  Destroyed


def vehicle_fx_on_appear(vehicle_eid : EntityId;
                         effect_type : VehicleEffectType;
                         damage_model : DamageModel;
                         animchar : AnimcharBaseComponent;
                         fx_desc_array : Array;
                         var vehicle_fx_eids : EidList;
                         skip_subtree_bone : string = "";
                         exempt_templates : StringList const? = null)
  var skipRootIdx = -1
  if !empty(skip_subtree_bone)
    skipRootIdx = geomtree_findNodeIndex(*animchar.nodeTree, skip_subtree_bone)
  for i, fxDescArrayItem in iter_range(fx_desc_array), fx_desc_array
    let fxDescItem = fxDescArrayItem as Object

    let vehicleFxEid = createEntity("vehicle_fx") <| $(var init)
      set(init, "vehicle_fx__ownerVehicleEid", vehicle_eid)
      set(init, "vehicle_fx__effectType", int(effect_type))
      set(init, "vehicle_fx__id", i)

      var dmPartIds : array<int>
      let dmParts = fxDescItem?.dmParts ?as Array
      if dmParts != null
        for dmPartItem in *dmParts
          let name = dmPartItem ?? ""
          let id = find_part_id_by_name(damage_model, name)
          if id >= 0
            push(dmPartIds, id)
      set(init, "vehicle_fx__dmPartId", dmPartIds)

      var fxTemplateNames : array<string>
      var nodeIds : array<int>
      let fxArray = fxDescItem?.fx ?as Array
      if fxArray != null
        for fxItem in *fxArray
          let fx = fxItem as Object
          let fxTemplateName = fx?.name ?? ""
          let fxEmitterName = fx?.emitter ?? ""
          let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, fxEmitterName)
          if nodeId >= 0
            var inTurretSubtree = false
            if skipRootIdx >= 0
              var cur = nodeId
              while cur >= 0 && cur != skipRootIdx
                cur = int(*animchar.nodeTree |> geomtree_getParentNodeIdx(cur))
              inTurretSubtree = cur == skipRootIdx
            var isExempt = false
            if exempt_templates != null
              for t in *exempt_templates
                if string(t) == fxTemplateName
                  isExempt = true
                  break
            if isExempt || !inTurretSubtree
              push(fxTemplateNames, fxTemplateName)
              push(nodeIds, nodeId)

      set(init, "vehicle_fx_node__fxTemplateName", fxTemplateNames)
      set(init, "vehicle_fx_node__nodeId", nodeIds)

    push(vehicle_fx_eids, vehicleFxEid)


def vehicle_fx_on_disappear(vehicle_fx_eids : EidList)
  for vehicleFxEid in vehicle_fx_eids
    destroyEntity(vehicleFxEid)


[es(tag=render, on_appear)]
def fatal_fire_fx_on_appear(evt : Event;
                            eid : EntityId;
                            damage_model : DamageModel;
                            animchar : AnimcharBaseComponent;
                            fatal_fire_fx__fx : Array;
                            var fatal_fire_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType.FatalFire, damage_model, animchar, fatal_fire_fx__fx, fatal_fire_fx__eids)

[es(tag=render, on_appear)]
def engine_fire_fx_on_appear(evt : Event;
                             eid : EntityId;
                             damage_model : DamageModel;
                             animchar : AnimcharBaseComponent;
                             engine_fire_fx__fx : Array;
                             var engine_fire_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType.EngineFire, damage_model, animchar, engine_fire_fx__fx, engine_fire_fx__eids)

[es(tag=render, on_appear)]
def fatal_explosion_fx_on_appear(evt : Event;
                                 eid : EntityId;
                                 damage_model : DamageModel;
                                 animchar : AnimcharBaseComponent;
                                 fatal_explosion_fx__fx : Array;
                                 var fatal_explosion_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType.FatalExplosion, damage_model, animchar, fatal_explosion_fx__fx, fatal_explosion_fx__eids)

[es(tag=render, on_appear)]
def destroyed_fx_on_appear(evt : Event;
                           eid : EntityId;
                           damage_model : DamageModel;
                           animchar : AnimcharBaseComponent;
                           destroyed_fx__fx : Array;
                           var destroyed_fx__eids : EidList;
                           losable_turret__detachBone : string = "";
                           destroyed_fx__hullOnlyExemptTemplates : StringList const? = null)
  vehicle_fx_on_appear(eid, VehicleEffectType.Destroyed, damage_model, animchar, destroyed_fx__fx, destroyed_fx__eids, losable_turret__detachBone, destroyed_fx__hullOnlyExemptTemplates)

[es(tag=render, on_appear)]
def explosion_fx_on_appear(evt : Event;
                           animchar : AnimcharBaseComponent;
                           explosion_fx__nodeName : string;
                           var explosion_fx__nodeId : int&)
  explosion_fx__nodeId = geomtree_findNodeIndex(*animchar.nodeTree, explosion_fx__nodeName)

[es(tag=render, on_disappear)]
def fatal_fire_fx_on_disappear(evt : Event; fatal_fire_fx__eids : EidList)
  vehicle_fx_on_disappear(fatal_fire_fx__eids)

[es(tag=render, on_disappear)]
def engine_fire_fx_on_disappear(evt : Event; engine_fire_fx__eids : EidList)
  vehicle_fx_on_disappear(engine_fire_fx__eids)

[es(tag=render, on_disappear)]
def fatal_explosion_fx_on_disappear(evt : Event; fatal_explosion_fx__eids : EidList)
  vehicle_fx_on_disappear(fatal_explosion_fx__eids)

[es(tag=render, on_disappear)]
def destroyed_fx_on_disappear(evt : Event; destroyed_fx__eids : EidList)
  vehicle_fx_on_disappear(destroyed_fx__eids)


[es(tag=render, on_disappear)]
def vehicle_fx_destroy_effects_on_disappear(evt : Event;
                                            vehicle_fx__ownerVehicleEid : EntityId;
                                            vehicle_fx__effectType : int;
                                            vehicle_fx__id : int)
  query(vehicle_fx__ownerVehicleEid) <| $ [es] (vehicle_fxs__effectsEids : EidList)
    stop_fx(vehicle_fxs__effectsEids, vehicle_fx__effectType, vehicle_fx__id)


def stop_fx(vehicle_fxs__effectsEids : EidList; effect_type : int; vehicle_fx_id : int)
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int; vehicle_effect__vehicleFxId : int)
      if vehicle_effect__type == effect_type && vehicle_effect__vehicleFxId == vehicle_fx_id
        destroyEntity(effectEid)


def stop_all_fxs(vehicle_fxs__effectsEids : EidList; effect_type : VehicleEffectType)
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int)
      if vehicle_effect__type == int(effect_type)
        destroyEntity(effectEid)


def spawn_single_vehicle_fx(vehicle_eid : EntityId;
                            inv_transform : float3x4;
                            animchar : AnimcharBaseComponent;
                            effect_type : VehicleEffectType;
                            vehicle_fx_id : int;
                            fx_template_name : string;
                            node_id : int)
  var nodeTm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, node_id, nodeTm)
  var emitterTm = IDENT_TM
  emitterTm[3] = nodeTm[3]
  createEntity(fx_template_name) <| $(var init)
    set(init, "transform", emitterTm)
    set(init, "vehicle_effect__type", int(effect_type))
    set(init, "vehicle_effect__vehicleFxId", vehicle_fx_id)
    set(init, "vehicle_effect__emitterLocalPos", inv_transform * emitterTm[3])
    set(init, "vehicle_effect__nodeId", node_id)
    set(init, "vehicle_effect__vehicleEid", vehicle_eid)
    set(init, "vehicle_effect__emitterPos", emitterTm[3])


def start_fx(vehicle_eid : EntityId;
             vehicle_fxs__effectsEids : EidList;
             transform : float3x4;
             animchar : AnimcharBaseComponent;
             vehicle_fx_eid : EntityId;
             vehicle_fx_id : int;
             effect_type : VehicleEffectType;
             probability : float = 1.0) : int
  let itm = inverse(transform)

  var isStateActive = false
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int; vehicle_effect__vehicleFxId : int)
      isStateActive = vehicle_effect__type == int(effect_type) && vehicle_effect__vehicleFxId == vehicle_fx_id
    if isStateActive
      return 0

  stop_fx(vehicle_fxs__effectsEids, int(effect_type), vehicle_fx_id)

  var spawnedCount = 0
  let seed = hash_combine_u32(uint(vehicle_eid), uint(effect_type))
  query(vehicle_fx_eid) <| $ [es] (vehicle_fx_node__fxTemplateName : StringList;
                                   vehicle_fx_node__nodeId : IntList)
    for i, fxTemplateName, nodeId in iter_range(vehicle_fx_node__nodeId), vehicle_fx_node__fxTemplateName, vehicle_fx_node__nodeId
      if nodeId < 0
        continue
      if probability < 1.0
        let roll = hash_to_unit_float(hash_combine_u32(seed, uint(i)))
        if roll >= probability
          continue
      spawn_single_vehicle_fx(vehicle_eid, itm, animchar, effect_type, vehicle_fx_id, string(fxTemplateName), nodeId)
      spawnedCount += 1
  return spawnedCount


def start_all_fxs(vehicle_eid : EntityId;
                  vehicle_fxs__effectsEids : EidList;
                  transform : float3x4;
                  animchar : AnimcharBaseComponent;
                  vehicle_fx_eids : EidList;
                  effect_type : VehicleEffectType;
                  probability : float = 1.0) : bool
  var anySpawned = false
  for i, vehicleFxEid in iter_range(vehicle_fx_eids), vehicle_fx_eids
    if start_fx(vehicle_eid, vehicle_fxs__effectsEids, transform, animchar, vehicleFxEid, i, effect_type, probability) > 0
      anySpawned = true
  return anySpawned


def is_effect_should_be_active(vehicle_fx_eid : EntityId;
                               fire_damage_state : FireDamageState)
  var result = false
  query(vehicle_fx_eid) <| $ [es] (vehicle_fx__dmPartId : IntList)
    for state in fire_damage_state.states
      if state.startTime <= 0.0
        continue
      if find_index(vehicle_fx__dmPartId, int(state.partId.id)) > -1
        result = true
        break
  return result


[es(tag=render, REQUIRE=damage_model, track=(fire_damage_state, isExploded))]
def fire_fx_check_state_es_event_handler(evt : Event;
                                         eid : EntityId;
                                         transform : float3x4;
                                         vehicle__isUnderwater : bool;
                                         fire_damage_state : FireDamageState;
                                         animchar : AnimcharBaseComponent;
                                         engine_fire_fx__eids : EidList;
                                         vehicle_fxs__effectsEids : EidList;
                                         isExploded : bool = false)
  for i, vehicleFxEid in iter_range(engine_fire_fx__eids), engine_fire_fx__eids
    if !isExploded && is_effect_should_be_active(vehicleFxEid, fire_damage_state) && !vehicle__isUnderwater
      start_fx(eid, vehicle_fxs__effectsEids, transform, animchar, vehicleFxEid, i, VehicleEffectType.EngineFire)
    else
      stop_fx(vehicle_fxs__effectsEids, int(VehicleEffectType.EngineFire), i)


[es(tag=render, REQUIRE=damage_model)]
def explosion_fx_es(evt : EventExplosionFatal;
                    eid : EntityId;
                    transform : float3x4;
                    vehicle__isUnderwater : bool;
                    animchar : AnimcharBaseComponent;
                    fatal_explosion_fx__eids : EidList;
                    vehicle_fxs__effectsEids : EidList;
                    var isFatalExplosionFxStarted : bool&)
  if isFatalExplosionFxStarted
    return
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalFire)
  if !vehicle__isUnderwater
    isFatalExplosionFxStarted = true
    start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, fatal_explosion_fx__eids, VehicleEffectType.FatalExplosion)


def pick_caliber_tier(caliber : float; thresholds : FloatList) : int
  var tier = 0
  for t in thresholds
    if caliber >= t
      tier += 1
    else
      break
  return tier


def template_for_tier(templates : StringList; tier : int) : string
  let n = length(templates)
  if n == 0
    return ""
  let idx = clamp(tier, 0, n - 1)
  return string(templates[idx])


[es(tag=render, REQUIRE=damage_model)]
def fatal_fire_fx_es(evt : EventFireFatal;
                     eid : EntityId;
                     transform : float3x4;
                     vehicle__isUnderwater : bool;
                     animchar : AnimcharBaseComponent;
                     fatal_fire_fx__eids : EidList;
                     vehicle_fxs__effectsEids : EidList;
                     isExploded : bool;
                     fatal_fire_fx__probability : float = 1.0;
                     fatal_fire_fx__ringProbability : float = 1.0;
                     fatal_fire_fx__barrelProbability : float = 1.0;
                     fatal_fire_fx__caliberThresholds : FloatList;
                     fatal_fire_fx__ringTemplates : StringList;
                     fatal_fire_fx__barrelTemplates : StringList;
                     fatal_fire_fx__smokeTemplate : string;
                     explosion_fx__nodeName : string = "";
                     losable_turret__detachBone : string = "";
                     turret_control__gunEids : EidList const? = null)
  if isExploded || vehicle__isUnderwater
    return

  let seed = uint(eid)
  let maxCaliber = turret_control__gunEids != null ? get_max_gun_caliber(*turret_control__gunEids) : 0.0
  let caliberTier = pick_caliber_tier(maxCaliber, fatal_fire_fx__caliberThresholds)
  let ringFxTemplate = template_for_tier(fatal_fire_fx__ringTemplates, caliberTier)
  let barrelFxTemplate = template_for_tier(fatal_fire_fx__barrelTemplates, caliberTier)
  let itm = inverse(transform)

  // 1) Hatches: per-emitter dice inside start_all_fxs -> start_fx (existing engine path).
  let hatchAnySpawned = start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar,
                                       fatal_fire_fx__eids, VehicleEffectType.FatalFire,
                                       fatal_fire_fx__probability)

  // 2) Ring (turret race burst): single dice, deterministic via eid + index 100.
  //    Spawned at `losable_turret__detachBone` (the hull-to-turret attachment point, e.g.
  //    `bone_turret` or `bone_turret_01`) so the ring seats at the turret ring gap.
  var ringSpawned = false
  if !empty(losable_turret__detachBone) && !empty(ringFxTemplate)
    let rollRing = hash_to_unit_float(hash_combine_u32(seed, 100u))
    if rollRing < fatal_fire_fx__ringProbability
      spawn_fatal_fire_fx_at_bone(eid, transform, itm, animchar, losable_turret__detachBone, ringFxTemplate)
      ringSpawned = true

  // 3) Barrels: per-gun dice, deterministic via eid + 200 + gun's turret__id. MGs and smoke
  //    launchers filtered via should_spawn_barrel_fx.
  var barrelAnySpawned = false
  if turret_control__gunEids != null && !empty(barrelFxTemplate)
    let barrelSeed = hash_combine_u32(seed, 200u)
    for gunEid in *turret_control__gunEids
      if !should_spawn_barrel_fx(gunEid)
        continue
      query(gunEid) <| $ [es] (turret__flashNodeId : int;
                               turret__id : int)
        if turret__flashNodeId < 0
          return
        let roll = hash_to_unit_float(hash_combine_u32(barrelSeed, uint(turret__id)))
        if roll >= fatal_fire_fx__barrelProbability
          return
        spawn_fatal_fire_fx_at_barrel(eid, animchar, turret__flashNodeId, barrelFxTemplate)
        barrelAnySpawned = true

  // 4) At-least-one fallback: if nothing rolled true across 1-3, force the first hatch.
  if !hatchAnySpawned && !ringSpawned && !barrelAnySpawned
    force_spawn_first_hatch_fx(eid, transform, animchar, fatal_fire_fx__eids)

  // 5) Smoke at explosion_fx__nodeName when set, otherwise at the entity origin
  //    (so cannons / light AA / civ cars without the center bone still get the
  //    fx + its explode_ammo sound). Position-only attachment - smoke is
  //    rotationally symmetric, so it skips the oriented sub-template.
  if !empty(fatal_fire_fx__smokeTemplate)
    spawn_fatal_fire_smoke_fx(eid, transform, itm, animchar, explosion_fx__nodeName, fatal_fire_fx__smokeTemplate)


def get_max_gun_caliber(gun_eids : EidList) : float
  var maxCaliber = 0.0
  for gunEid in gun_eids
    query(gunEid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds)
      if length(gun__shell_prop_ids) > 0
        assume shellId = gun__shell_prop_ids[0]
        projectile_get_props(int(shellId.shellId)) <| $(props : ProjectileProps)
          if props.caliber > maxCaliber
            maxCaliber = props.caliber
  return maxCaliber


def spawn_fatal_fire_fx_at_bone(vehicle_eid : EntityId;
                                vehicle_tm : float3x4;
                                inv_vehicle_tm : float3x4;
                                animchar : AnimcharBaseComponent;
                                bone_name : string;
                                fx_template : string)
  let boneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(bone_name)
  if boneIdx < 0
    return
  var boneWtm : float3x4
  *animchar.nodeTree |> geomtree_getNodeWtmScalar(boneIdx, boneWtm)
  var fxTm = vehicle_tm
  fxTm[3] = boneWtm[3]
  spawn_fatal_fire_fx_at_world_tm(vehicle_eid, inv_vehicle_tm, fxTm, fx_template)


def spawn_fatal_fire_fx_at_barrel(vehicle_eid : EntityId;
                                  animchar : AnimcharBaseComponent;
                                  bone_idx : int;
                                  fx_template : string)
  if bone_idx < 0
    return
  var boneWtm : float3x4
  *animchar.nodeTree |> geomtree_getNodeWtmScalar(bone_idx, boneWtm)
  var remapTm = IDENT_TM
  remapTm[0] = float3(0.0, 1.0, 0.0)
  remapTm[1] = float3(1.0, 0.0, 0.0)
  remapTm[2] = float3(0.0, 0.0, -1.0)
  spawn_fatal_fire_fx_at_world_tm(vehicle_eid, inverse(boneWtm), boneWtm * remapTm, fx_template, bone_idx)


def spawn_fatal_fire_fx_at_world_tm(vehicle_eid : EntityId;
                                    inv_parent_tm : float3x4;
                                    world_tm : float3x4;
                                    fx_template : string;
                                    parent_node_id : int = -1)
  let localTm = inv_parent_tm * world_tm
  let combinedTemplate = add_sub_template_name(fx_template, "vehicle_effect_oriented_attached")
  createEntity(combinedTemplate) <| $(var init : ComponentsInitializer)
    set(init, "transform", world_tm)
    set(init, "vehicle_effect__type", int(VehicleEffectType.FatalFire))
    set(init, "vehicle_effect__vehicleEid", vehicle_eid)
    set(init, "vehicle_effect__nodeId", parent_node_id)
    set(init, "vehicle_effect__emitterLocalPos", localTm[3])
    set(init, "vehicle_effect__emitterPos", world_tm[3])
    set(init, "vehicle_effect__emitterLocalTm", localTm)


def spawn_fatal_fire_smoke_fx(vehicle_eid : EntityId;
                              vehicle_tm : float3x4;
                              inv_vehicle_tm : float3x4;
                              animchar : AnimcharBaseComponent;
                              bone_name : string;
                              fx_template : string)
  var worldPos = vehicle_tm[3]
  if !empty(bone_name)
    let nodeIdx = *animchar.nodeTree |> geomtree_findNodeIndex(bone_name)
    if nodeIdx >= 0
      var nodeWtm : float3x4
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(nodeIdx, nodeWtm)
      worldPos = nodeWtm[3]
  var emitterTm = IDENT_TM
  emitterTm[3] = worldPos
  createEntity(fx_template) <| $(var init)
    set(init, "transform", emitterTm)
    set(init, "vehicle_effect__type", int(VehicleEffectType.FatalFire))
    set(init, "vehicle_effect__vehicleEid", vehicle_eid)
    set(init, "vehicle_effect__emitterLocalPos", inv_vehicle_tm * worldPos)
    set(init, "vehicle_effect__emitterPos", worldPos)


def force_spawn_first_hatch_fx(vehicle_eid : EntityId;
                               transform : float3x4;
                               animchar : AnimcharBaseComponent;
                               vehicle_fx_eids : EidList)
  if length(vehicle_fx_eids) == 0
    return
  let firstDescEid = vehicle_fx_eids[0]
  query(firstDescEid) <| $ [es] (vehicle_fx_node__fxTemplateName : StringList;
                                 vehicle_fx_node__nodeId : IntList)
    if length(vehicle_fx_node__nodeId) == 0
      return
    let nodeId = vehicle_fx_node__nodeId[0]
    if nodeId < 0
      return
    spawn_single_vehicle_fx(vehicle_eid, inverse(transform), animchar, VehicleEffectType.FatalFire, 0, string(vehicle_fx_node__fxTemplateName[0]), nodeId)


[es(tag=render, REQUIRE=fatal_fire_fx__eids)]
def dm_restore_fx_es(evt : CmdRestore; vehicle_fxs__effectsEids : EidList)
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalFire)
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalExplosion)


[es(tag=render, track=isExploded)]
def fatal_explosion_fx_check_es(evt : Event;
                                eid : EntityId;
                                transform : float3x4;
                                vehicle__isUnderwater : bool;
                                animchar : AnimcharBaseComponent;
                                fatal_explosion_fx__eids : EidList;
                                vehicle_fxs__effectsEids : EidList;
                                isExploded : bool;
                                var isFatalExplosionFxStarted : bool&)
  if isExploded && !isFatalExplosionFxStarted
    isFatalExplosionFxStarted = true
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalFire)
    if !vehicle__isUnderwater
      start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, fatal_explosion_fx__eids, VehicleEffectType.FatalExplosion)


// Phase 2 of destruction: at each emitter that carried `replace_template` (the destroyed
// smoke), spawn `phase2_template` (the lighter late smoke). Same descriptor-indexed fx id
// as the phase-1 fx so both share the Destroyed vehicle_fx_id space.
def start_destroyed_phase2_fxs(vehicle_eid : EntityId;
                               transform : float3x4;
                               animchar : AnimcharBaseComponent;
                               vehicle_fx_eids : EidList;
                               replace_template : string;
                               phase2_template : string)
  let itm = inverse(transform)
  for fxId, vehicleFxEid in iter_range(vehicle_fx_eids), vehicle_fx_eids
    query(vehicleFxEid) <| $ [es] (vehicle_fx_node__fxTemplateName : StringList;
                                   vehicle_fx_node__nodeId : IntList)
      for fxTemplateName, nodeId in vehicle_fx_node__fxTemplateName, vehicle_fx_node__nodeId
        if nodeId < 0 || string(fxTemplateName) != replace_template
          continue
        spawn_single_vehicle_fx(vehicle_eid, itm, animchar, VehicleEffectType.Destroyed, fxId, phase2_template, nodeId)


[es(tag=render)]
def destroyed_fx_start_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                          transform : float3x4;
                          vehicle__isUnderwater : bool;
                          animchar : AnimcharBaseComponent;
                          destroyed_fx__eids : EidList;
                          vehicle_fxs__effectsEids : EidList;
                          fatal_explosion_fire__endTime : float;
                          isExploded : bool;
                          var isFatalExplosionFxStarted : bool&;
                          var isDestroyedFxStarted : bool&;
                          var isDestroyedSmokeSmallStarted : bool&;
                          destroyed_fx__phase2Template : string = "";
                          destroyed_fx__phase2ReplaceTemplate : string = "";
                          destroyed_fx__phase2Delay : float = 0.0)
  if isFatalExplosionFxStarted && fatal_explosion_fire__endTime > 0.f && info.curTime >= fatal_explosion_fire__endTime
    isFatalExplosionFxStarted = false
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalExplosion)
    if !isDestroyedFxStarted && isExploded
      isDestroyedFxStarted = true
      if !vehicle__isUnderwater
        start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, destroyed_fx__eids, VehicleEffectType.Destroyed)
  if isDestroyedFxStarted && !isDestroyedSmokeSmallStarted && !empty(destroyed_fx__phase2Template) && !empty(destroyed_fx__phase2ReplaceTemplate) && fatal_explosion_fire__endTime > 0.f && info.curTime >= fatal_explosion_fire__endTime + destroyed_fx__phase2Delay
    isDestroyedSmokeSmallStarted = true
    if !vehicle__isUnderwater
      start_destroyed_phase2_fxs(eid, transform, animchar, destroyed_fx__eids, destroyed_fx__phase2ReplaceTemplate, destroyed_fx__phase2Template)


[es(tag=render, track=vehicle__isUnderwater)]
def vehicle_fx_stop_all_on_flooding(evt : Event;
                                    vehicle_fxs__effectsEids : EidList;
                                    vehicle__isUnderwater : bool)
  if vehicle__isUnderwater
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalFire)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.EngineFire)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.FatalExplosion)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType.Destroyed)


[es(tag=render, track=isExploded, REQUIRE=damage_model)]
def damage_model_fx_es(evt : Event;
                       eid : EntityId;
                       transform : float3x4;
                       vehicle__isUnderwater : bool;
                       animchar : AnimcharBaseComponent;
                       explosion_fx__effectName : string;
                       explosion_fx__nodeId : int;
                       isExploded : bool)
  if !isExploded || vehicle__isUnderwater || empty(explosion_fx__effectName)
    return

  var fxTm = IDENT_TM
  fxTm[3] = (explosion_fx__nodeId >= 0
          ? geomtree_getNodeWpos(*animchar.nodeTree, explosion_fx__nodeId)
          : transform[3])
  createEntity(explosion_fx__effectName) <| $(var init)
    set(init, "transform", fxTm)
    set(init, "vehicle_effect__vehicleEid", eid)


[es(tag=render, on_appear, REQUIRE=vehicleEffect)]
def vehicle_effect_on_appear(evt : Event;
                             eid : EntityId;
                             vehicle_effect__vehicleEid : EntityId;
                             vehicle_effect__type : int = -1)
  var registered = false
  query(vehicle_effect__vehicleEid) <| $ [es] (var vehicle_fxs__effectsEids : EidList;
                                               isExploded : bool = false)
    if !(isExploded && vehicle_effect__type == int(VehicleEffectType.FatalFire))
      push(vehicle_fxs__effectsEids, eid)
      registered = true
  // An unregistered FatalFire fx (created in flight when the vehicle exploded, or owner
  // query miss) is unreachable for stop_all_fxs and would burn forever - destroy it now.
  if !registered && vehicle_effect__type == int(VehicleEffectType.FatalFire)
    destroyEntity(eid)


[es(tag=render, on_disappear, REQUIRE=vehicleEffect)]
def vehicle_effect_on_disappear(evt : Event; eid : EntityId; vehicle_effect__vehicleEid : EntityId)
  query(vehicle_effect__vehicleEid) <| $ [es] (var vehicle_fxs__effectsEids : EidList)
    let effectIdx = find_index(vehicle_fxs__effectsEids, eid)
    if effectIdx > -1
      erase(vehicle_fxs__effectsEids, effectIdx)


[es(tag=render, on_disappear)]
def vehicle_effect_destroy_on_vehicle_disappear(evt : Event;
                                                var vehicle_fxs__effectsEids : EidList&)
  for vehicleEffectEid in vehicle_fxs__effectsEids
    destroyEntity(vehicleEffectEid)
  vehicle_fxs__effectsEids |> clear()


def update_vehicle_effect_emitter_tm(parent_tm : float3x4;
                                     local_pos : float3;
                                     local_tm : float3x4 const?;
                                     min_dist_sq : float;
                                     var cached_pos : float3&;
                                     var effect : TheEffect&)
  if local_tm != null
    effect_set_emitter_tm(effect, parent_tm * *local_tm)
  else
    let pos = parent_tm * local_pos
    if length_sq(pos - cached_pos) > min_dist_sq
      cached_pos = pos
      var emitterTm = IDENT_TM
      emitterTm[3] = pos
      effect_set_emitter_tm(effect, emitterTm)


def resolve_emitter_parent_tm(vehicle_tm : float3x4;
                              animchar : AnimcharBaseComponent;
                              local_tm : float3x4 const?;
                              node_id : int) : float3x4
  if local_tm == null || node_id < 0
    return vehicle_tm
  var boneWtm : float3x4
  *animchar.nodeTree |> geomtree_getNodeWtmScalar(node_id, boneWtm)
  return boneWtm


[es(tag=render, on_appear)]
def vehicle_effect_init_emitter_tm_es(evt : Event;
                                      vehicle_effect__vehicleEid : EntityId;
                                      vehicle_effect__emitterLocalPos : float3;
                                      vehicle_effect__emitterLocalTm : float3x4 const?;
                                      vehicle_effect__nodeId : int = -1;
                                      var vehicle_effect__emitterPos : float3&;
                                      var effect : TheEffect)
  query(vehicle_effect__vehicleEid) <| $ [es] (transform : float3x4; animchar : AnimcharBaseComponent)
    let parentTm = resolve_emitter_parent_tm(transform, animchar, vehicle_effect__emitterLocalTm, vehicle_effect__nodeId)
    update_vehicle_effect_emitter_tm(parentTm, vehicle_effect__emitterLocalPos,
                                     vehicle_effect__emitterLocalTm, -1.0,
                                     vehicle_effect__emitterPos, effect)


[es(tag=render, no_order)]
def vehicle_effect_update_emitter_es(info : UpdateStageInfoAct;
                                     vehicle_effect__vehicleEid : EntityId;
                                     vehicle_effect__emitterLocalPos : float3;
                                     vehicle_effect__minDistSqToUpdateEmitterTm : float;
                                     vehicle_effect__emitterLocalTm : float3x4 const?;
                                     vehicle_effect__nodeId : int = -1;
                                     var vehicle_effect__emitterPos : float3&;
                                     var effect : TheEffect)
  query(vehicle_effect__vehicleEid) <| $ [es] (transform : float3x4; animchar : AnimcharBaseComponent; animchar__updatable : bool = true)
    if vehicle_effect__emitterLocalTm != null || animchar__updatable
      let parentTm = resolve_emitter_parent_tm(transform, animchar, vehicle_effect__emitterLocalTm, vehicle_effect__nodeId)
      update_vehicle_effect_emitter_tm(parentTm, vehicle_effect__emitterLocalPos,
                                       vehicle_effect__emitterLocalTm,
                                       vehicle_effect__minDistSqToUpdateEmitterTm,
                                       vehicle_effect__emitterPos, effect)
