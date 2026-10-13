require ecs
require ecs.common
require dm
require DngDm
require DngNet
require math.base
require vehicle
require game.es.events
require game.events_game
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require common_shooter.es.repair_common
require game.utils.team
require game.es.awards_common

def set_repairable_state(inProgress; operatorEid; targetEid; partId : int; repairTimeMult : float  = 1.f; recoveryRatioAdd : float = 0.f)
  query(targetEid) <| $ [es] (var maintainable__operator : EntityId&;
                              var repairable__repairTime : float&;
                              var repairable__repairTimeByPart : FloatList&;
                              var repairable__repairPart : int&;
                              var repairable__repairTotalTime : float&;
                              var repairable__inProgress : bool&;
                              var repairable__recoveryRatio : float&;
                              repairable__baseRepairTotalTime : float;
                              repairable__baseRecoveryRatio : float)
    maintainable__operator = operatorEid
    repairable__inProgress = inProgress
    repairable__repairPart = partId
    repairable__recoveryRatio = repairable__baseRecoveryRatio + recoveryRatioAdd
    if partId < 0
      return
    if repairable__repairTimeByPart[partId] <= 0.f && inProgress
      repairable__repairTotalTime = repairable__baseRepairTotalTime * repairTimeMult
      repairable__repairTimeByPart[partId] = repairable__repairTotalTime
      repairable__repairTime = repairable__repairTotalTime

def stop_repair(maintenance__target)
  set_repairable_state(false, INVALID_ENTITY_ID, maintenance__target, -1)
  return false


def use_repair_kit(maintainable__operator)
  query(maintainable__operator) <| $ [es] (var repair__active : bool&;
                                           repair__repairKit : EntityId;
                                           var maintenance__fromInsideActive : bool&)
    repair__active = false
    maintenance__fromInsideActive = false
    query(repair__repairKit) <| $ [es] (var repair_kit__useCounter : int&; var item__repairAmount : int&)
      repair_kit__useCounter += 1
      item__repairAmount -= 1
    sendEvent(maintainable__operator, EventOnLootUse(itemEid = repair__repairKit))

[es(on_appear)]
def item_repair_amount_init(evt : Event; item__ownerEid : EntityId; var item__repairAmount : int&)
  item__repairAmount = get_int(item__ownerEid, "entity_mods__vehicleRepairUsagesPerKit") ?? item__repairAmount

[es(tag=server, track=(extinguisher__usesLeft, repair_kit__useCounter))]
def remove_used_repair_kit(evt : Event;
                           eid : EntityId;
                           item__ownerEid : EntityId;
                           extinguisher__usesLeft : int;
                           repair_kit__useCounter : int)
  query(item__ownerEid) <| $ [es] (var itemContainer : EidList&; entity_mods__vehicleRepairUsagesPerKit : int = -1)
    if extinguisher__usesLeft <= 0 && repair_kit__useCounter > 0 && repair_kit__useCounter >= entity_mods__vehicleRepairUsagesPerKit
      let idx = itemContainer |> find_index(eid)
      if idx >= 0
        erase(itemContainer, idx)

def find_repair_kit(item_container : EidList; uses_per_kit : int)
  for itemEid in item_container
    let repairUses = get_int(itemEid, "repair_kit__useCounter")
    if repairUses != null && (*repairUses == 0 || *repairUses < uses_per_kit)
      return itemEid
  return INVALID_ENTITY_ID

def calculate_total_repair_count(item_container : EidList; uses_per_kit : int) : int
  var totalRepairCount = 0
  for itemEid in item_container
    let repairUses = get_int(itemEid, "repair_kit__useCounter")
    if repairUses != null && (*repairUses == 0 || *repairUses < uses_per_kit)
      totalRepairCount += uses_per_kit - *repairUses
  return totalRepairCount

[es(tag=server, on_appear, track=itemContainer)]
def check_item_container_has_repair_kit(evt : Event;
                                        itemContainer : EidList;
                                        entity_mods__vehicleRepairUsagesPerKit : int = -1;
                                        human_weap__gunEids : EidList;
                                        var repair__hasRepairKit : bool&;
                                        var repair__repairKit : EntityId&)
  repair__repairKit = find_repair_kit(itemContainer, entity_mods__vehicleRepairUsagesPerKit)
  repair__hasRepairKit = !!repair__repairKit
  for gunEid in human_weap__gunEids
    query(gunEid) <| $ [es] (repairKitWeapon : Tag const?;
                             var gun__ammo : int&)
      if repairKitWeapon != null
        gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

[es(tag=server, track=repair_kit__useCounter, on_appear)]
def track_repair_kit_uses(evt : Event; eid : EntityId; item__ownerEid : EntityId; repair_kit__useCounter : int)
  query(item__ownerEid) <| $ [es] (itemContainer : EidList;
                                   entity_mods__vehicleRepairUsagesPerKit : int = -1;
                                   human_weap__gunEids : EidList;
                                   var repair__hasRepairKit : bool&;
                                   var repair__repairKit : EntityId&)
    if repair__repairKit == eid && repair_kit__useCounter > 0 && repair_kit__useCounter >= entity_mods__vehicleRepairUsagesPerKit
      repair__repairKit = find_repair_kit(itemContainer, entity_mods__vehicleRepairUsagesPerKit)
      repair__hasRepairKit = !!repair__repairKit
    for gunEid in human_weap__gunEids
      query(gunEid) <| $ [es] (repairKitWeapon : Tag const?;
                               var gun__ammo : int&)
        if repairKitWeapon != null
          gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

[es(tag=server, on_appear, REQUIRE=repairKitWeapon)]
def total_repair_count_on_weapon_appear(evt : Event;
                                        gun__owner : EntityId;
                                        var gun__ammo : int&)
  query(gun__owner) <| $ [es] (itemContainer : EidList;
                               entity_mods__vehicleRepairUsagesPerKit : int = -1)
    gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

def check_repair_require(damage_model : DamageModel&;
                         dm_parts__canRepair : BoolList;
                         dm_parts__considerAsAliveThreshold : float;
                         dm_parts__canRepairFromInside : BoolList) : tuple<needRepair : bool; availableFromInside : bool>
  var needRepair = false
  var availableFromInside = false
  for i, canRepair in iter_range(dm_parts__canRepair), dm_parts__canRepair
    if !canRepair
      continue
    assume part = get_damage_part_props(damage_model.dmData, i)
    if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
      needRepair = true
      if dm_parts__canRepairFromInside[i]
        availableFromInside = true
        break
  return (needRepair = needRepair, availableFromInside = availableFromInside)

[es(tag=server)]
def need_repair_check_on_part_damaged_es(evt : EventOnPartDamaged;
                                         damage_model : DamageModel&;
                                         dm_parts__canRepair : BoolList;
                                         dm_parts__canRepairFromInside : BoolList;
                                         var repairable__repairRequired : bool&;
                                         var repairable__repairFromInsideAvailable : bool&;
                                         dm_parts__considerAsAliveThreshold : float = 0.9)
  let checkResult = check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold, dm_parts__canRepairFromInside)
  repairable__repairRequired ||= checkResult.needRepair
  repairable__repairFromInsideAvailable = checkResult.availableFromInside

[es(tag=server, after=damage_model_es)]
def need_repair_check_on_volumetric_damaged_es(evt : EventOnVolumetricDamage;
                                               damage_model : DamageModel&;
                                               dm_parts__canRepair : BoolList;
                                               dm_parts__canRepairFromInside : BoolList;
                                               var repairable__repairRequired : bool&;
                                               var repairable__repairFromInsideAvailable : bool&;
                                               dm_parts__considerAsAliveThreshold : float = 0.9)
  let checkResult = check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold, dm_parts__canRepairFromInside)
  repairable__repairRequired ||= checkResult.needRepair
  repairable__repairFromInsideAvailable = checkResult.availableFromInside

[es(tag=server)]
def check_is_part_damaged_by_teammate(evt : EventOnPartDamaged;
                                      team : int;
                                      dm_parts__canRepair : BoolList;
                                      var dm_parts__damagedByTeammate : BoolList&)
  if evt.partId < 0 || evt.partId >= length(dm_parts__canRepair) || !dm_parts__canRepair[evt.partId]
    return
  let offenderTeam = get_int(evt.hitData.offender, "team") ?? TEAM_UNASSIGNED
  dm_parts__damagedByTeammate[evt.partId] = is_teams_friendly(team, offenderTeam)

[es(tag=server)]
def need_repair_check_on_meta_part_damage_es(evt : EventOnMetaPartDamage;
                                             damage_model : DamageModel&;
                                             dm_parts__canRepair : BoolList;
                                             dm_parts__canRepairFromInside : BoolList;
                                             var repairable__repairRequired : bool&;
                                             var repairable__repairFromInsideAvailable : bool&;
                                             dm_parts__considerAsAliveThreshold : float = 0.9)
  let checkResult = check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold, dm_parts__canRepairFromInside)
  repairable__repairFromInsideAvailable = checkResult.availableFromInside
  if evt.damage > 0.f
    repairable__repairRequired = true

[es(tag=server)]
def repair_es(evt : CmdStartRepair;
              eid : EntityId;
              var repair__active : bool&;
              var maintenance__fromInsideActive : bool&;
              human_anim__vehicleSelected : EntityId;
              entity_mods__vehicleRepairTimeMult : float = 1.f;
              maintenance__fromInsideRepairTimeMult : float = 1.f;
              entity_mods__vehicleRepairRecoveryRatioAdd : float = 0.f)
  if evt.partId < 0
    return
  let repairFromInside = human_anim__vehicleSelected == evt.target
  query(evt.target) <| $ [es] (damage_model : DamageModel;
                               dm_parts__repairPartGroupIds : UInt8List;
                               dm_parts__considerAsAliveThreshold : float = 0.9;
                               vehicle__isUnderwater : bool = false)
    if vehicle__isUnderwater
      send_net_event(eid, CmdHeroLogEvent(event = "repair_blocked_underwater", text = "repair_blocked_underwater"))
      return
    let partsCount = length(dm_parts__repairPartGroupIds)
    if evt.partId >= partsCount
      return //try to repair invalid part
    let partGroup = dm_parts__repairPartGroupIds[evt.partId]
    let repairTimeMult = repairFromInside ? entity_mods__vehicleRepairTimeMult * maintenance__fromInsideRepairTimeMult : entity_mods__vehicleRepairTimeMult
    if int(partGroup) > 0
      for i in range(partsCount)
        if dm_parts__repairPartGroupIds[i] == partGroup
          assume part = get_damage_part_props(damage_model.dmData, i)
          if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
            repair__active = true
            maintenance__fromInsideActive = repairFromInside
            //we want to init from first part in group, because timer isn't shared by the group
            set_repairable_state(true, eid, evt.target, i, repairTimeMult, entity_mods__vehicleRepairRecoveryRatioAdd)
            return
    else
      assume part = get_damage_part_props(damage_model.dmData, evt.partId)
      if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
        repair__active = true
        maintenance__fromInsideActive = repairFromInside
        set_repairable_state(true, eid, evt.target, evt.partId, repairTimeMult, entity_mods__vehicleRepairRecoveryRatioAdd)

[es(REQUIRE=maintenance__target)]
def repair_stop_es(evt : CmdStopRepair; var repair__active : bool&; var maintenance__fromInsideActive : bool&)
  repair__active = stop_repair(evt.target)
  maintenance__fromInsideActive = repair__active

[es(tag=server, no_order)]
def check_repairing_conditions(info : UpdateStageInfoAct;
                               maintenance__target : EntityId;
                               var repair__active : bool&;
                               transform aka operator_transform : float3x4;
                               repair__effectiveDistance : float;
                               team aka operator_team : int;
                               var maintenance__fromInsideActive : bool&;
                               maintenance__canMaintainVehicle : bool = true)
  if !repair__active
    return
  var isDistanceValid = maintenance__fromInsideActive
  var isUnderWater = false
  var isTargetHostile = false
  if maintenance__canMaintainVehicle || !maintenance__fromInsideActive
    query(maintenance__target) <| $ [es] (transform aka target_transform : float3x4;
                                          vehicle__isUnderwater : bool = false;
                                          team aka target_team : int = TEAM_UNASSIGNED)
      isUnderWater = vehicle__isUnderwater
      isTargetHostile = !is_maintenance_allowed(operator_team, target_team)
      isDistanceValid = length_sq(target_transform[3] - operator_transform[3]) < square(repair__effectiveDistance)
  if !isDistanceValid || !maintenance__canMaintainVehicle || isUnderWater || isTargetHostile
    repair__active = stop_repair(maintenance__target)
    maintenance__fromInsideActive = repair__active

[es(tag=server)]
def stop_repairing_on_enter_vehicle_es(evt : EventEnterVehicle;
                                       maintenance__target : EntityId;
                                       var maintenance__fromInsideActive : bool&;
                                       var repair__active : bool&)
  if !repair__active
    return
  repair__active = stop_repair(maintenance__target)
  maintenance__fromInsideActive = repair__active

[es(tag=server, no_order)]
def repair_external_es(info : UpdateStageInfoAct;
                       eid : EntityId;
                       var damage_model : DamageModel&;
                       var fire_protection : FireProtection&;
                       repairable__recoveryRatio : float;
                       maintainable__operator : EntityId;
                       repairable__repairPart : int;
                       dm_parts__canRepair : BoolList;
                       dm_parts__canRepairFromInside : BoolList;
                       dm_parts__repairPartGroupIds : UInt8List;
                       var dm_parts__damagedByTeammate : BoolList&;
                       var repairable__repairTime : float&;
                       var repairable__repairTimeByPart : FloatList&;
                       var repairable__inProgress : bool&;
                       var repairable__repairRequired : bool&;
                       var repairable__repairFromInsideAvailable : bool&;
                       dm_parts__considerAsAliveThreshold : float = 0.9)
  if repairable__repairPart < 0 || !maintainable__operator || !repairable__inProgress
    return

  repairable__repairTime = repairable__repairTimeByPart[repairable__repairPart]
  if repairable__repairTime <= 0.f
    return

  repairable__repairTimeByPart[repairable__repairPart] -= info.dt
  if repairable__repairTimeByPart[repairable__repairPart] > 0.f
    return

  repairable__inProgress = false
  if !dm_parts__damagedByTeammate[repairable__repairPart]
    sendEvent(eid, EventRepairAward(eid = maintainable__operator))
  let partGroup = dm_parts__repairPartGroupIds[repairable__repairPart]
  if int(partGroup) > 0
    for i in range(length(dm_parts__repairPartGroupIds))
      if dm_parts__repairPartGroupIds[i] == partGroup
        repair_vehicle_part(repairable__recoveryRatio, i, dm_parts__damagedByTeammate, damage_model, fire_protection)
  else
    repair_vehicle_part(repairable__recoveryRatio, repairable__repairPart, dm_parts__damagedByTeammate, damage_model, fire_protection)

  let checkResult = check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold, dm_parts__canRepairFromInside)
  repairable__repairRequired = checkResult.needRepair
  repairable__repairFromInsideAvailable = checkResult.availableFromInside

  use_repair_kit(maintainable__operator)
  sendEvent(maintainable__operator, CmdStopRepair(target = eid))
  sendEvent(eid, CmdStopBurn())
  sendEvent(eid, EventOnRepaired(eid = maintainable__operator))

[es(on_event=EventOnRepaired)]
def on_repair_phys_wakeup_es(evt : Event; var vehicle_net_phys : VehiclePhysActor)
  vehicle_net_phys.phys |> wakeUp()
