require ecs
require vehicle
require game.es.vehicle.vehicle_events

[es(tag=server, on_appear, on_event=EventOnSeatOwnersChanged)]
def vehicle_parking_brake_on_seats_changed(evt : Event;
                                           vehicle_seats__seatEids : EidList;
                                           var vehicle_net_phys__allowMoveControl : bool&)
  var seatsSeen = 0
  var hasDriver = false
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__availableControls : VehicleControlsState;
                              seat__ownerEid : EntityId;
                              seat__isOwnerAlive : bool)
      seatsSeen += 1
      if !!seat__ownerEid && seat__isOwnerAlive && seat__availableControls.canControlVehicle
        hasDriver = true

  let allowMove = hasDriver || seatsSeen == 0
  if vehicle_net_phys__allowMoveControl != allowMove
    vehicle_net_phys__allowMoveControl = allowMove

[es(tag=server, on_appear, REQUIRE=seat__isOwnerAlive)]
def vehicle_parking_brake_on_seat_appear(evt : Event; seat__vehicleEid : EntityId)
  sendEvent(seat__vehicleEid, EventOnSeatOwnersChanged())
