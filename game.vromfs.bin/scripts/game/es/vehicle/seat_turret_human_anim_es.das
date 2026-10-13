require ecs
require ecs.common
require PhysVars
require game.es.turrets_common
require debug.logerr_once
require enlisted.events_enlisted

[es(tag=gameClient, on_appear)]
def human_vehicle_anim_init_turret_vars_es(evt : Event;
                                           var phys_vars : PhysVars;
                                           var human_vehicle_anim__turretYawVarId : int&;
                                           var human_vehicle_anim__turretPitchVarId : int&)
  human_vehicle_anim__turretYawVarId = phys_vars |> registerVar("vehicle_turret_yaw", 0f)
  human_vehicle_anim__turretPitchVarId = phys_vars |> registerVar("vehicle_turret_pitch", 0f)

def find_seat_anim_turret(vehicle_eid : EntityId;
                          seat_no : int;
                          seats : ecs::Array;
                          turret_info : ecs::Array;
                          gun_eids : ecs::EidList) : EntityId
  let seat = get_ecs_object(seats, seat_no)
  if seat == null
    return INVALID_ENTITY_ID
  let turretName = get_string(*seat, "seatAnimTurretName", "")
  if turretName == ""
    return INVALID_ENTITY_ID
  let turretNo = find_turret_index_by_name(turret_info, turretName)
  if turretNo < 0
    logerr_once("seatAnimTurretName '{turretName}' of seat {seat_no} is not a turret of '{getEntityTemplateName(vehicle_eid)}'")
    return INVALID_ENTITY_ID
  return turretNo < length(gun_eids) ? gun_eids[turretNo] : INVALID_ENTITY_ID

[es(tag=gameClient, on_appear)]
def seat_anim_turret_init_es(evt : Event;
                             seat__id : int;
                             seat__vehicleEid : EntityId;
                             var seat_anim__turretEid : EntityId&)
  query(seat__vehicleEid) <| $ [es] (@shared_comp vehicle_seats__seats : Array;
                                     @shared_comp turret_control__turretInfo : Array;
                                     turret_control__gunEids : EidList)
    seat_anim__turretEid = find_seat_anim_turret(seat__vehicleEid, seat__id, vehicle_seats__seats,
                                                 turret_control__turretInfo, turret_control__gunEids)

// The vehicle fills turret_control__gunEids independently of its seats, so a seat can appear before
// the guns exist. Rebinding once the turrets resolve covers that order.
[es(tag=gameClient, on_appear, REQUIRE=resolvedTurret)]
def turret_seat_anim_turret_rebind_es(evt : Event; turret__owner : EntityId)
  query(turret__owner) <| $ [es] (eid aka vehicle_eid : EntityId;
                                  @shared_comp vehicle_seats__seats : Array;
                                  @shared_comp turret_control__turretInfo : Array;
                                  turret_control__gunEids : EidList;
                                  vehicle_seats__seatEids : EidList)
    for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
      query(seatEid) <| $ [es] (var seat_anim__turretEid : EntityId&)
        seat_anim__turretEid = find_seat_anim_turret(vehicle_eid, seatNo, vehicle_seats__seats,
                                                     turret_control__turretInfo, turret_control__gunEids)

[es(tag=gameClient, REQUIRE_NOT=animchar__actOnDemand, no_order)]
def human_vehicle_turret_anim_es(info : ParallelUpdateFrameDelayed;
                                 animchar__updatable : bool;
                                 human_anim__vehicleSelected : EntityId;
                                 human_vehicle__occupiedSeatEid : EntityId;
                                 human_vehicle_anim__turretYawVarId : int;
                                 human_vehicle_anim__turretPitchVarId : int;
                                 var phys_vars aka human_phys_vars : PhysVars;
                                 animchar__visible : bool = true)
  if !animchar__updatable || !animchar__visible
    return

  query(human_vehicle__occupiedSeatEid) <| $ [es] (seat_anim__turretEid : EntityId)
    query(seat_anim__turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__curYawVarId : int;
                                                                   turret__curPitchVarId : int)
      if turret__curYawVarId < 0 || turret__curPitchVarId < 0
        return
      query(human_anim__vehicleSelected) <| $ [es] (phys_vars aka vehicle_phys_vars : PhysVars)
        human_phys_vars |> setVar(human_vehicle_anim__turretYawVarId, vehicle_phys_vars |> getVar(turret__curYawVarId))
        human_phys_vars |> setVar(human_vehicle_anim__turretPitchVarId, vehicle_phys_vars |> getVar(turret__curPitchVarId))
