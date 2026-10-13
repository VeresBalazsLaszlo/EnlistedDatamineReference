require ecs
require game.es.events
require game.es.vehicle.vehicle_seats_common
require game.utils.team
require matching
require game.es.vehicle.vehicle_events

[es(tag=gameClient)]
def vehicle_seats_client_enter_exit_request_es(evt : HumanUseObjectRequest;
                                               eid : EntityId)
  vehicle_seats_client_enter_exit_request(eid, evt.objectEid)

[es(tag=gameClient)]
def vehicle_seats_client_enter_exit_request__alt_es(evt : HumanUseObjectRequestAlt;
                                                    eid : EntityId)
  vehicle_seats_client_enter_exit_request(eid, evt.objectEid)

def vehicle_seats_client_enter_exit_request(eid : EntityId; objectEid : EntityId)
  query(eid) <| $ [es] (possessedByPlr : EntityId;
                        squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                        human_vehicle__can_take_seat : bool = true;
                        team : int = TEAM_UNASSIGNED)
    let requester = eid
    query(objectEid) <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                        vehicle_seats__seatEids : EidList;
                                                        vehicle_seats__restrictToGroup : int64 = int64(INVALID_SQUAD_ID);
                                                        vehicle_seats__enterTime : float = 0.f;
                                                        vehicle_seats__exitTime : float = 0.f;
                                                        vehicle__isPlayerCanEnter : bool = true;
                                                        vehicle__isPlayerCanExit : bool = true;
                                                        vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED)
      let playerGroup = get_int64(squad_member__playerEid, "groupId") ?? int64(INVALID_SQUAD_ID)
      if !can_use_vehicle(team, vehicle_seats__restrictToTeam, playerGroup, vehicle_seats__restrictToGroup, eid, requester)
        return

      if find_seat_with_owner(requester, vehicle_seats__seatEids) >= 0
        if !cancel_exit_timer(requester) && vehicle__isPlayerCanExit
          start_exit_vehicle_timer(requester, vehicle_seats__exitTime)
      elif vehicle__isPlayerCanEnter && human_vehicle__can_take_seat && find_highest_free_seat(possessedByPlr, vehicle_seats__seatEids) >= 0
        start_enter_vehicle_timer(requester, eid, vehicle_seats__enterTime)

[es(tag=gameClient)]
def paratroopers_exit_start_client(evt : CmdStartParatroopersExit; eid : EntityId)
  sendEvent(eid, HumanUseObjectRequest(objectEid = evt.aircraftEid))
