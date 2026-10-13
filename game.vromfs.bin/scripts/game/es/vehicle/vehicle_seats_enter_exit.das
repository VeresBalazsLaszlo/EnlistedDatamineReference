require ecs
require game.es.events
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require game.es.squad_order_common
require game.utils.team
require game.events_game
require matching
require DngNet
require enlisted.game.es.enlisted_squad_common
require common_shooter.events_common_shooter
require enlisted.events_enlisted


[es(REQUIRE_NOT=deadEntity)]
def vehicle_seats_es_enter_exit_es(evt : CmdUse;
                                   eid : EntityId)
  vehicle_seats_es_enter_exit(eid, evt.requesterEid, false)

[es(REQUIRE_NOT=deadEntity)]
def vehicle_seats_es_enter_exit_alternative_es(evt : CmdUseAlt;
                                               eid : EntityId)
  vehicle_seats_es_enter_exit(eid, evt.requesterEid, true)

def vehicle_seats_es_enter_exit(eid : EntityId; requester : EntityId; alternative_exit : bool)
  query(eid) <| $ [es] (vehicle_seats__seatEids : EidList;
                        vehicle_seats__restrictToGroup : int64 = int64(INVALID_SQUAD_ID);
                        vehicle_seats__exitTime : float = 0.f;
                        vehicle_seats__enterTime : float = 0.f;
                        vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED;
                        vehicle__isPlayerCanEnter = true;
                        vehicle__isPlayerCanExit = true;
                        vehicle__lockUsePrompt : string = "")
    query(requester) <| $ [es] (team : int;
                                isInVehicle : bool;
                                squad_member__playerEid : EntityId;
                                human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                                human_vehicle__can_take_seat : bool = true;
                                human_use_object__lockVehicleUse : bool = false;
                                squad_member__squad : EntityId = INVALID_ENTITY_ID)
      if !isInVehicle && !vehicle__isPlayerCanEnter
        if !empty(vehicle__lockUsePrompt)
          send_net_event(requester, CmdHeroLogEvent(event = "can_not_vehicle_use", text = vehicle__lockUsePrompt))
        return

      let playerGroup = get_int64(squad_member__playerEid, "groupId") ?? int64(INVALID_SQUAD_ID)
      if !can_use_vehicle(team, vehicle_seats__restrictToTeam, playerGroup, vehicle_seats__restrictToGroup, eid, requester)
        return

      if vehicle__isPlayerCanExit && find_seat_with_owner(requester, vehicle_seats__seatEids) >= 0
        exit_vehicle(requester, eid, vehicle_seats__exitTime)
        if !alternative_exit && !has(human_anim__vehicleSelected, "paratroopersAircraft")
          query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
            for soldiers in squad__allMembers
              if (get_int(soldiers, "squad_member__orderType") ?? -1) == int(SquadMateOrder.ESMO_USE_VEHICLE)
                reset_squad_mate_behaviour(soldiers)
                reset_squad_mate_order(soldiers)
      elif vehicle__isPlayerCanEnter && human_vehicle__can_take_seat && !human_use_object__lockVehicleUse
        enter_vehicle(requester, eid, vehicle_seats__seatEids, vehicle_seats__enterTime)

[es(REQUIRE=vehicle_seats__seats)]
def vehicle_seats_use_req(evt : CmdUseVehicle; eid : EntityId)
  let requester = evt.requester
  let seatNo = evt.seat_no
  if (seatNo >= 0)
    sendEvent(eid, CmdAcquireVehicleSeat(requester = requester, seat_no = seatNo))

[es(on_event=EventEntityDied)]
def vehicle_seats_client_exit_on_die_es(evt : Event; eid : EntityId; isInVehicle : bool)
  if isInVehicle
    cancel_exit_timer(eid)

[es(tag=server, on_event=EventEntityDied, before=vehicle_seats_client_exit_on_die_es)]
def vehicle_seats_cache_exit_timer_on_death(evt : Event;
                                            possessedByPlr : EntityId;
                                            human_anim__vehicleSelected : EntityId;
                                            exit_vehicle__atTime : float)
  if exit_vehicle__atTime < 0. || !human_anim__vehicleSelected
    return
  query(possessedByPlr) <| $ [es] (var exit_vehicle_cache__vehicle : EntityId&; var exit_vehicle_cache__atTime : float&)
    exit_vehicle_cache__atTime = exit_vehicle__atTime
    exit_vehicle_cache__vehicle = human_anim__vehicleSelected

[es(tag=server, track=possessedByPlr)]
def vehicle_seats_set_exit_timer_to_new_leader(evt : Event;
                                               possessedByPlr : EntityId;
                                               human_anim__vehicleSelected : EntityId;
                                               squad_member__orderType : int;
                                               var server_exit_vehicle__atTime : float&;
                                               var exit_vehicle__atTime : float&)
  query(possessedByPlr) <| $ [es] (var exit_vehicle_cache__vehicle : EntityId&; var exit_vehicle_cache__atTime : float&)
    if (squad_member__orderType != int(SquadMateOrder.ESMO_USE_VEHICLE) &&
        exit_vehicle_cache__atTime >= 0. &&
        human_anim__vehicleSelected == exit_vehicle_cache__vehicle)
      exit_vehicle__atTime = exit_vehicle_cache__atTime
      server_exit_vehicle__atTime = exit_vehicle__atTime
    exit_vehicle_cache__atTime = -1.
    exit_vehicle_cache__vehicle = INVALID_ENTITY_ID

[es(tag=netClient, REQUIRE=hero, track=server_exit_vehicle__atTime)]
def vehicle_seats_apply_server_exit_vehicle_time(evt : Event; server_exit_vehicle__atTime : float; var exit_vehicle__atTime : float&)
  exit_vehicle__atTime = server_exit_vehicle__atTime

