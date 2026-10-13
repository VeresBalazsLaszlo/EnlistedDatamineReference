require ecs
require game.es.respawn_base_common
require DagorSystem
require enlisted.events_enlisted
require enlisted.game.es.fortifications_build_common
require game.events_game
require player
require game.es.events
require game.es.vehicle.vehicle_events
require math.base
require game.es.vehicle.vehicle_seats_common
require game.es.battle_area_common
require game.es.awards_common
require app
require game.utils.team

[es(tag=server, REQUIRE_NOT=paratroopersAircraft)]
def set_kamikaze_status_on_plane_exit(evt : CmdKickFromVehicle;
                                      kamikazePenaltyAvailable : bool;
                                      ownedByPlayer : EntityId)
  if !kamikazePenaltyAvailable
    return
  if (find_query() <| $ [es(REQUIRE=isPractice)] () => true)
    return
  if (find_query() <| $ [es(REQUIRE=isTutorial)] () => true)
    return
  query(evt.eid) <| $ [es] (possessedByPlr : EntityId)
    if ownedByPlayer == possessedByPlr
      query(possessedByPlr) <| $ [es] (var squads__kamikazePenalty : bool&)
        squads__kamikazePenalty = true

[es(tag=server, REQUIRE_NOT=paratroopersAircraft)]
def set_kamikaze_status_on_plane_death(evt : EventEntityDied;
                                       vehicle_seats__seatEids : EidList;
                                       ownedByPlayer : EntityId;
                                       kamikazePenaltyAvailable : bool)
  if !kamikazePenaltyAvailable
    return
  if (find_query() <| $ [es(REQUIRE=isPractice)] () => true)
    return
  if (find_query() <| $ [es(REQUIRE=isTutorial)] () => true)
    return
  for seat in vehicle_seats__seatEids
    query(seat) <| $ [es] (seat__isPlayer : bool; seat__playerEid : EntityId)
      if seat__isPlayer && seat__playerEid == ownedByPlayer
        query(seat__playerEid) <| $ [es] (var squads__kamikazePenalty : bool&)
          squads__kamikazePenalty = true

[es(tag=server)]
def set_kamikaze_status_on_suicide(evt : RequestSuicide; possessedByPlr : EntityId; human_anim__vehicleSelected : EntityId)
  if (find_query() <| $ [es(REQUIRE=isPractice)] () => true)
    return
  if (find_query() <| $ [es(REQUIRE=isTutorial)] () => true)
    return
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE=kamikazePenaltyAvailable, REQUIRE_NOT=paratroopersAircraft)] ()
    query(possessedByPlr) <| $ [es] (var squads__kamikazePenalty : bool&)
      squads__kamikazePenalty = true

[es(tag=server, on_appear)]
def off_kamikaze_status_on_spawn(evt : Event; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var squads__kamikazePenalty : bool&)
    squads__kamikazePenalty = false
