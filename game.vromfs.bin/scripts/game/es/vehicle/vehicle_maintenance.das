require ecs
require ecs.common
require game.utils.team
require DngNet
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require AnimV20
require GeomNodeTree
require CollRes
require DngHuman
require DagorSystem
require HumanPhys
require game.events_game
require common_shooter.events_common_shooter
require common_shooter.es.repair_common

[es(tag=gameClient, REQUIRE=input__enabled)]
def find_maintainable_object(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             bindedCamera : EntityId;
                             var maintenance__target : EntityId&;
                             var maintenance__hasTarget : bool&;
                             var maintenance__targetNeedsRepair : bool&;
                             var maintenance__targetIsHostile : bool&;
                             var maintenance__targetRepairFromInsideAvailable : bool&;
                             var maintenance__targetNeedsExtinguishing : bool&;
                             human_net_phys__states : int;
                             human_use_object__nodeId : int;
                             human_anim__vehicleSelected : EntityId;
                             human_use_object__useDist : float;
                             animchar : AnimcharBaseComponent;
                             input__enabled : bool;
                             team aka maintainable_team : int = TEAM_UNASSIGNED;
                             isInVehicle : bool = false)
  if !input__enabled
    return
  if isInVehicle
    maintenance__target = human_anim__vehicleSelected
    maintenance__targetIsHostile = false
    query(human_anim__vehicleSelected) <| $ [es] (repairable__repairRequired : bool = false;
                                                  repairable__repairFromInsideAvailable : bool = false;
                                                  repairable__extinguishRequired : bool = false)
      maintenance__targetNeedsRepair = repairable__repairRequired
      maintenance__targetNeedsExtinguishing = repairable__extinguishRequired
      maintenance__targetRepairFromInsideAvailable = repairable__repairFromInsideAvailable
    return
  maintenance__targetRepairFromInsideAvailable = false
  let camTmRef = get_TMatrix(bindedCamera, "transform")
  if camTmRef == null
    return
  let camTm = *camTmRef
  let traceDir : float3 = camTm[2]
  let tracePos : float3 = (human_use_object__nodeId > 0
    ? geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
    : camTm[3])
  var newMaintenanceTarget = INVALID_ENTITY_ID
  var needsRepair = false
  var needsExtinguisher = false
  var targetIsHostile = false
  find_query() <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=maintainable__operator)] (eid : EntityId;
                                                                                  collres : CollisionResource;
                                                                                  transform : float3x4;
                                                                                  animchar : AnimcharBaseComponent;
                                                                                  repairable__repairRequired : bool = false;
                                                                                  repairable__extinguishRequired : bool = false;
                                                                                  team : int = TEAM_UNASSIGNED)
    if collres_rayhit(collres, transform, animchar.nodeTree, tracePos, traceDir, human_use_object__useDist)
      if is_maintenance_allowed(maintainable_team, team)
        newMaintenanceTarget = eid
        needsRepair = repairable__repairRequired
        needsExtinguisher = repairable__extinguishRequired
        return true
      elif has(eid, "attached_ammo_box__eid")
        newMaintenanceTarget = eid
        targetIsHostile = true
        return true
    return false


  let isHumanJumping = ((uint(human_net_phys__states) & uint(StateFlag.ST_JUMP)) != 0u)
  let isMaintenanceInterrupted =  isHumanJumping
  let isNeedStopMaintenance = !!maintenance__target && (newMaintenanceTarget != maintenance__target || isMaintenanceInterrupted)
  if isNeedStopMaintenance
    sendEvent(eid, CmdStopMaintenance(target = maintenance__target))

  maintenance__target = isMaintenanceInterrupted ? INVALID_ENTITY_ID : newMaintenanceTarget
  maintenance__hasTarget = maintenance__target != INVALID_ENTITY_ID
  maintenance__targetNeedsRepair = needsRepair
  maintenance__targetNeedsExtinguishing = needsExtinguisher
  maintenance__targetIsHostile = maintenance__hasTarget && targetIsHostile

[es(tag=server, on_appear, on_event=UpdateOnwerMaintenance, REQUIRE=maintenance__target, track=(isAlive, isDowned, enter_vehicle__timerEnabled, human_anim__vehicleSelected, burning__isBurning, human_vehicle__isInHatch))]
def can_maintain_vehicle(event : Event;
                         isAlive : bool;
                         isDowned : bool;
                         human_vehicle__isInHatch : bool;
                         enter_vehicle__timerEnabled : bool;
                         burning__isBurning : bool;
                         human_anim__vehicleSelected : EntityId;
                         var maintenance__canMaintainVehicle : bool&)
  maintenance__canMaintainVehicle = isAlive && !isDowned && !enter_vehicle__timerEnabled && !burning__isBurning && !human_vehicle__isInHatch && !(get_bool(human_anim__vehicleSelected, "repairable__extinguishRequired") ?? false)

[es(tag=gameClient)]
def set_maintance_on_enter_exit_vehicle(evt : EventEnterVehicle;
                                        var maintenance__target : EntityId&;
                                        var maintenance__hasTarget : bool&)
  if evt.enter
    maintenance__target = evt.vehicle
    maintenance__hasTarget = true
  else
    maintenance__target = INVALID_ENTITY_ID
    maintenance__hasTarget = false

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_start(evt : RequestStartMaintenance; eid : EntityId)
  sendEvent(eid, CmdStartMaintenance(target = evt.target, partId = evt.partId, isInVehicle = evt.isInVehicle))

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_stop(evt : RequestStopMaintenance; eid : EntityId)
  sendEvent(eid, CmdStopMaintenance(target = evt.target))

[es(tag=netClient)]
def request_start_maintenance_client(evt : CmdStartMaintenance; eid : EntityId)
  send_net_event(eid, RequestStartMaintenance(target = evt.target, partId = evt.partId, isInVehicle = evt.isInVehicle))

[es(tag=netClient)]
def request_stop_maintenance_client(evt : CmdStopMaintenance; eid : EntityId)
  send_net_event(eid, RequestStopMaintenance(target = evt.target))

[es(tag=server, on_appear, track=(fire_damage__isBurn, attached_fire__isAnyFireAttached))]
def update_extinguish_required(evt : Event;
                               vehicle_seats__seatEids : EidList;
                               fire_damage__isBurn : bool = false;
                               attached_fire__isAnyFireAttached : bool = false;
                               var repairable__extinguishRequired : bool&)
  repairable__extinguishRequired = fire_damage__isBurn || attached_fire__isAnyFireAttached
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    sendEvent(ownerEid, UpdateOnwerMaintenance())

[es(tag=server)]
def maintenance_dispatcher_start(evt : CmdStartMaintenance;
                                 eid : EntityId;
                                 team aka operator_team : int;
                                 var maintenance__target : EntityId&;
                                 repair__hasRepairKit : bool = true;
                                 extinguisher__hasExtinguisher : bool = true)
  maintenance__target = evt.target
  query(maintenance__target) <| $ [es(REQUIRE_NOT=deadEntity)] (repairable__extinguishRequired : bool = false;
                                                                repairable__repairRequired : bool = false;
                                                                vehicle__isUnderwater : bool = false;
                                                                team aka target_team : int = TEAM_UNASSIGNED)
    if !is_maintenance_allowed(operator_team, target_team)
      send_net_event(eid, CmdHeroLogEvent(event = "maintenance_blocked_enemy_vehicle", text = "maintenance_blocked_enemy_vehicle"))
      return
    if vehicle__isUnderwater
      send_net_event(eid, CmdHeroLogEvent(event = "repair_blocked_underwater", text = "repair_blocked_underwater"))
      return
    let canRepair = repairable__repairRequired && repair__hasRepairKit
    if repairable__extinguishRequired
      if extinguisher__hasExtinguisher
        sendEvent(eid, CmdActivateExtinguisher(eid = maintenance__target))
      elif canRepair
        send_net_event(eid, CmdHeroLogEvent(event = "repair_blocked_by_fire", text = "repair_blocked_by_fire"))
    elif canRepair
      sendEvent(eid, CmdRepairKitWeaponUse(target = maintenance__target, partId = evt.partId))
    elif !repair__hasRepairKit
      send_net_event(eid, CmdHeroLogEvent(event = "repair_blocked_no_parts", text = "repair_blocked_no_parts"))


def find_repair_weapon_in_inventory(itemContainer : EidList)
  for itemEid in itemContainer
    if has(itemEid, "repairKitWeapon")
      return itemEid
  return INVALID_ENTITY_ID


[es(tag=server, on_appear, track=repair__hasRepairKit)]
def create_repair_kit_weapon(evt : Event;
                             eid : EntityId;
                             repair__hasRepairKit : bool;
                             itemContainer : EidList;
                             var repair__repairKitWeapCreated : bool&)
  if !repair__hasRepairKit || repair__repairKitWeapCreated
    return
  if !repair__repairKitWeapCreated && !find_repair_weapon_in_inventory(itemContainer)
    repair__repairKitWeapCreated = true
    createEntity("repair_kit_item_weapon") <| $(var init : ComponentsInitializer)
      set(init, "item__lastOwner", eid)
      set(init, "item__ownerEid", eid)
      set(init, "gun__owner", eid)

[es(on_event=CmdStartMaintenance)]
def maintenance_on_create_repair_weap(evt : Event;
                                      eid : EntityId;
                                      repair__hasRepairKit : bool;
                                      human_net_phys : HumanActor;
                                      itemContainer : EidList;
                                      human_weap__gunEids : EidList;
                                      isInVehicle : bool;
                                      var forcedNextInventoryGunEid : EntityId&)
  if isInVehicle
    return
  assume ct = human_net_phys.phys.producedCT
  assume specialWeapon = human_weap__gunEids[int(HUWeaponSlots.EWS_SPECIAL)]

  if repair__hasRepairKit
    if ct.chosenWeapon != HUWeaponSlots.EWS_SPECIAL
      sendEvent(eid, HumanWeapSetCurrentGun(slot = uint8(HUWeaponSlots.EWS_SPECIAL)))
    if !has(specialWeapon, "repairKitWeapon")
      forcedNextInventoryGunEid = find_repair_weapon_in_inventory(itemContainer)
      send_net_event(eid, CmdNextSpecialGun(byInput = false))

[es(tag=gameClient, on_disappear, REQUIRE=(watchedPlayerItem, repairKitWeapon))]
def maintenance_on_destroy_repair_weap(evt : Event;
                                       gun__owner : EntityId)
  query(gun__owner) <| $ [es] (human_net_phys : HumanActor;
                               human_weap__gunEids : ecs::EidList)
    assume ct = human_net_phys.phys.producedCT
    if ct.chosenWeapon != HUWeaponSlots.EWS_SPECIAL
      return
    for i, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
      if !!gunEid
        sendEvent(gun__owner, HumanWeapSetCurrentGun(slot = uint8(i)))
        return

[es(tag=server)]
def maintenance_create_repair_weap(evt : CmdRepairKitWeaponUse;
                                   eid : EntityId;
                                   isInVehicle : bool;
                                   human_weap__currentGunEid : EntityId)
  if isInVehicle || has(human_weap__currentGunEid, "repairKitWeapon")
    sendEvent(eid, CmdStartRepair(target = evt.target, partId = evt.partId))

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_dispatcher_stop(evt : CmdStopMaintenance;
                                eid : EntityId;
                                extinguisher__active : bool = false;
                                repair__active : bool = false)
  if extinguisher__active
    sendEvent(eid, CmdStopExtinguisher(eid = evt.target))
  elif repair__active
    sendEvent(eid, CmdStopRepair(target = evt.target))


[es(tag=gameClient, track=(repair__hasRepairKit, extinguisher__hasExtinguisher, maintenance__canMaintainVehicle, maintenance__targetNeedsExtinguishing, maintenance__targetNeedsRepair))]
def human_vehicle_maintenance_available(evt : Event;
                                        repair__hasRepairKit : bool;
                                        extinguisher__hasExtinguisher : bool;
                                        maintenance__canMaintainVehicle : bool;
                                        maintenance__targetNeedsExtinguishing : bool;
                                        maintenance__targetNeedsRepair : bool;
                                        var maintenance__isExtinguishAvailable : bool&;
                                        var maintenance__isRepairAvailable : bool&)
  maintenance__isExtinguishAvailable = maintenance__canMaintainVehicle && extinguisher__hasExtinguisher && maintenance__targetNeedsExtinguishing
  maintenance__isRepairAvailable = maintenance__canMaintainVehicle && repair__hasRepairKit && maintenance__targetNeedsRepair
