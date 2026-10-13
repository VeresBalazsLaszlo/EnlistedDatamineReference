require ecs
require ecs.safe
require ecs.common
require DagorSystem
require AnimV20
require enlisted.events_enlisted
require game.es.events
require vehicle

[es(REQUIRE=human, after=(deny_collision_by_ignore_list_es, deny_collision_for_disabled_paircoll_es))]
def human_in_vehicle_collidable(var evt : QueryPhysActorsNotCollidable;
                                human_anim__vehicleSelected aka base_human_anim__vehicleSelected : EntityId)
  if !!base_human_anim__vehicleSelected
    evt.shouldCollide = false
  else
    query(evt.otherEid) <| $ [es] (human_anim__vehicleSelected aka other_human_anim__vehicleSelected : EntityId)
      if !!other_human_anim__vehicleSelected
        evt.shouldCollide = false

[es(REQUIRE=vehicle, after=(deny_collision_by_ignore_list_es, deny_collision_for_disabled_paircoll_es))]
def vehicle_with_crew_collidable(var evt : QueryPhysActorsNotCollidable)
  query(evt.otherEid) <| $ [es] (human_anim__vehicleSelected : EntityId)
    if !!human_anim__vehicleSelected
      evt.shouldCollide = false

[es(on_appear)]
def init_vehicle_seats_enum_var(evt : Event; vehicle_seats__enumVarName : string; var vehicle_seats__enumVarId : int&)
  if vehicle_seats__enumVarName != ""
    vehicle_seats__enumVarId = animV20_add_enum_value(vehicle_seats__enumVarName)

def get_seat_template(seat, seat_templates)
  let seatName = get_string(seat, "name", "default")
  let seatTemplate = get_string(seat_templates, seatName, "")
  if seatTemplate != ""
    return seatTemplate
  return get_string(seat_templates, "default", "")

[es(tag=server, on_appear)]
def create_vehicle_seats(evt : Event;
                         eid : EntityId;
                         @shared_comp vehicle_seats__seats : Array;
                         @shared_comp vehicle_seats__seatTemplates : Object;
                         var vehicle_seats__seatEids : EidList)
  resize(vehicle_seats__seatEids, length(vehicle_seats__seats))
  for seatNo, item in iter_range(vehicle_seats__seats), vehicle_seats__seats
    let seat = get_ecs_object(item)
    if seat == null
      continue

    let seatTemplate = get_seat_template(*seat, vehicle_seats__seatTemplates)
    if seatTemplate == ""
      let seatName = get_string(seat, "name", "default")
      logerr("Seat template not found for seat /*{seatName}*/ in entity /*{eid}*/ /*{getEntityTemplateName(eid)}*/")
      continue

    using() <| $(var init : ComponentsInitializer)
      set(init, "seat__id", seatNo)
      set(init, "seat__vehicleEid", eid)
      set(init, "seats_hatch_effectors__useInSeat", seat.useHatchEffectors ?? false)
      set(init, "seat__hideAttaches", seat.hideAttaches ?? false)

      set(init, "seats_order__canPlaceOnlyOwner", seat?.canPlaceOnlyOwner ?? false)
      set(init, "seat__windAffectMultiplier", seat?.windAffectMultiplier ?? 1.)

      if has(*seat, "aimLimits")
        set(init, "seat__useAimAngleLimits", true)
        set(init, "seat__aimAngleLimits", seat?.aimLimits ?? float4())

      set(init, "seat__bindCamera", seat?.bindCamera ?? false)

      if has(*seat, "canPlaceManually")
        set(init, "seats_order__canPlaceManually", get_bool(seat, "canPlaceManually") ?? false)

      var seatEid = createInstantiatedEntitySync(seatTemplate, init)
      if seatEid == INVALID_ENTITY_ID
        logerr("Seat with template /*{seatTemplate}*/ hasn't been instantiated before entity /*{getEntityTemplateName(eid)}*/")
        seatEid = createEntitySync(seatTemplate, init)

      vehicle_seats__seatEids[seatNo] = seatEid

[es(tag=server, on_appear, after=create_vehicle_seats)]
def vehicle_seat_is_hold_gun_mode_allowed_on_appear(evt : Event;
                                                    vehicle_seats__seatEids : EidList;
                                                    @shared_comp vehicle_seats__seats : Array)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__id : int;
                              var seat__isHoldGunModeAllowed : bool&)
      let seat = vehicle_seats__seats?[seat__id] ?as Object
      seat__isHoldGunModeAllowed = seat?.isHoldGunModeAllowed ?? true


[es(tag=server, on_disappear, REQUIRE=destroyCrewOnDisappear, before=vehicle_seats_kick_from_destroyed)]
def vehicle_seats_destroy_crew_on_vehicle_disappear(evt : Event; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      destroyEntity(seat__ownerEid)

[es(tag=server, REQUIRE=vehicle_forceHandBrake)]
def force_handbrake_movable_cannons(update : CmdPostPhysUpdate;
                                    vehicle_seats__seatEids : EidList;
                                    var vehicle_net_phys : VehiclePhysActor&)
  var hasDriver = false
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__isOwnerAlive : bool; seats__isDriver : bool)
      if seat__isOwnerAlive && seats__isDriver
        hasDriver = true
    if hasDriver
      break
  if !hasDriver
    vehicle_net_phys.phys.producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_HAND_BRAKE, 1.)