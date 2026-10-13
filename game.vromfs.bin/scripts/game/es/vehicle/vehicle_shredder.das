require vehicle
require ecs
require app
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require enlisted.events_enlisted

[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def vehicle_inactive_update_timer_es(evt : Event;
                                     vehicle_seats__seatEids : EidList;
                                     var inactiveTimer : float&;
                                     inactiveDeleteTimer : float)
  var needDestroy = true
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid != INVALID_ENTITY_ID
      needDestroy = false
      break
  inactiveTimer = needDestroy ? get_sync_time() + inactiveDeleteTimer : 0.0

[es(tag=server, no_order)]
def vehicle_respawn_delete_inactive_es(info : UpdateStageInfoAct;
                                       eid : ecs::EntityId;
                                       inactiveTimer : float;
                                       lastOffender : EntityId = INVALID_ENTITY_ID;
                                       last_offender__gunPropsId : int = -1;
                                       last_offender__shellId : int = -1)
  if inactiveTimer > 0.0 && info.curTime > inactiveTimer
    setOptional(eid, "vehicle__isDestroyedWithoutCrew", true)
    sendEvent(eid, CmdExplosionFatal(offender = lastOffender, gunPropsId = last_offender__gunPropsId, shellId = last_offender__shellId))
    removeSubTemplate(eid, "destroy_inactive_vehicle")

[es(tag=server, no_order)]
def vehicle_shredder_distance_check_es(info : UpdateStageInfoAct;
                                       ownedBySquad : EntityId;
                                       transform : float3x4;
                                       destroyTimerCheckDistance : float;
                                       inactiveDeleteTimer : float;
                                       isExploded : bool;
                                       var inactiveTimer : float&)
  if inactiveTimer <= 0.0 || isExploded
    return
  if vehicle_has_owner_around(transform[3], ownedBySquad, destroyTimerCheckDistance)
    inactiveTimer = get_sync_time() + inactiveDeleteTimer

[es(tag=server, track=disconnected)]
def set_kick_from_vehicle_timer_on_player_disconnect(evt : Event;
                                                     kickDisconnectedSoldiersTimeThreshold : float;
                                                     disconnected : bool;
                                                     var kickDisconnectedSoldiersTime : float&)
  kickDisconnectedSoldiersTime = disconnected ? get_sync_time() + kickDisconnectedSoldiersTimeThreshold : -1.

[es(tag=server)]
def kick_disconnected_timer_es(info : ParallelUpdateFrameDelayed;
                               eid aka player_eid : EntityId;
                               var kickDisconnectedSoldiersTime : float&)
  if kickDisconnectedSoldiersTime > 0. && kickDisconnectedSoldiersTime < get_sync_time()
    kickDisconnectedSoldiersTime = -1.
    query() <| $ [es] (squad_member__playerEid : EntityId; human_anim__vehicleSelected : EntityId; eid aka soldier_eid : EntityId)
      if squad_member__playerEid == player_eid
        sendEvent(human_anim__vehicleSelected, CmdKickFromVehicle(eid = soldier_eid))
