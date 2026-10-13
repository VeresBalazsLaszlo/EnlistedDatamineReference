require ecs
require dm
require DngDm
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require danetlibs.native_dasevents.main.native_events
require common_shooter.es.weapon.turret_common
require daslib/strings_boost
require ecs.safe
require strings
require ecs.common

[es(tag=gameClient)]
def human_vehicle_close_repair_menu(evt : CmdCloseRepairMenu; eid : EntityId; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (dm_parts_repair_inside_ids : UInt16List)
    if evt.partId < 0 || evt.partId > length(dm_parts_repair_inside_ids)
      return
    sendEvent(eid, CmdStartMaintenance(target = human_anim__vehicleSelected, partId = int(dm_parts_repair_inside_ids[evt.partId]), isInVehicle = true))

[es(tag=gameClient, track=(maintenance__canMaintainVehicle, isInVehicle, isAlive))]
def close_inside_repair_menu_on_disable_maintance(evt : Event; eid : EntityId; maintenance__canMaintainVehicle : bool; isInVehicle : bool; isAlive : bool)
  if !maintenance__canMaintainVehicle || !isInVehicle || !isAlive
    sendEvent(eid, CmdCloseRepairMenu(partId = -1))

[es(on_appear)]
def init_repair_inside_barrel_parts(evt : Event; turret__triggerGroup : int; turret__owner : EntityId; turret__id : int)
  if turret__triggerGroup != TRIGGER_MG
    return
  query(turret__owner) <| $ [es(REQUIRE_NOT=menuVehicle)] (damage_model : DamageModel&;
                                                           @shared_comp vehicle_seats__seats : Array;
                                                           @shared_comp dm_parts_repair_inside_names_all : StringList;
                                                           @shared_comp turret_control__turretInfo : Array;
                                                           var dm_parts_repair_inside_names : StringList&;
                                                           var dm_parts__canRepairFromInside : BoolList;
                                                           var dm_parts_repair_inside_ids : UInt16List)
    let turret = turret_control__turretInfo[turret__id] as Object
    let turretName = turret?.barrelDm ?as string
    if turretName == null
      return
    let partName = string(*turretName)
    if find_index(dm_parts_repair_inside_names_all, partName) < 0
      return
    for seat in vehicle_seats__seats
      let turretNames = (seat as Object)?.hatchTurretNames ?as Array
      if turretNames != null
        for name in *turretNames
          if name ?? "" == *turretName
            return
    let partId = find_part_id_by_name(damage_model, partName)
    if partId >= 0 && partId < length(dm_parts__canRepairFromInside)
      dm_parts_repair_inside_names |> push(partName)
      dm_parts_repair_inside_ids |> push(uint16(partId))
      dm_parts__canRepairFromInside[partId] = true

[es(on_appear, REQUIRE_NOT=menuVehicle, REQUIRE_NOT=turret_control__turretInfo, before=init_repair_inside_dm_parts_es)]
def init_repair_inside_dm_parts_without_turret__es(evt : Event;
                                                   damage_model : DamageModel&;
                                                   var dm_parts__canRepairFromInside : BoolList)
  resize(dm_parts__canRepairFromInside, get_damage_part_props_count(damage_model.dmData))

[es(on_appear, REQUIRE_NOT=menuVehicle, before=(turret_control_init_guns_es, turret_control_create_guns_es))]
def init_repair_inside_dm_parts_es(evt : Event;
                                   damage_model : DamageModel&;
                                   @shared_comp dm_parts_repair_inside_names_all : StringList;
                                   @shared_comp turret_control__turretInfo : Array;
                                   var dm_parts_repair_inside_names : StringList;
                                   var dm_parts__canRepairFromInside : BoolList;
                                   var dm_parts_repair_inside_ids : UInt16List)
  resize(dm_parts__canRepairFromInside, get_damage_part_props_count(damage_model.dmData))
  clear(dm_parts_repair_inside_names)
  clear(dm_parts_repair_inside_ids)
  let maxPartsCount = length(turret_control__turretInfo) * 4 // barrel, breech, verDrive, horDrive
  reserve(dm_parts_repair_inside_names, maxPartsCount)
  reserve(dm_parts_repair_inside_ids, maxPartsCount)
  for turret in turret_control__turretInfo
    let obj = get_ecs_object(turret)
    for partType in dm_parts_repair_inside_names_all
      let partName = get_string(obj, string(partType), "")
      if partName != ""
        let partId = find_part_id_by_name(damage_model, partName)
        if partId >= 0 && find_index(dm_parts_repair_inside_ids, uint16(partId)) == -1
          dm_parts_repair_inside_names |> push(partName)
          dm_parts_repair_inside_ids |> push(uint16(partId))
          dm_parts__canRepairFromInside[partId] = true