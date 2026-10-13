require ecs
require game.es.respawn_base_common
require DagorSystem
require DngNet
require enlisted.events_enlisted
require enlisted.game.es.fortifications_build_common
require game.events_game
require player
require game.es.vehicle.vehicle_events
require math.base
require game.es.vehicle.vehicle_seats_common
require game.es.battle_area_common
require game.es.awards_common
require app
require game.utils.team
require zones
require DagorMath
require math.base
require math.linear
require DagorMathUtils
require game.utils.net_utils
require ecs.common

def mobile_respawn_position_check(mob_spawn_eid, soldier)
  var isCloseToCapzone = false
  query(mob_spawn_eid) <| $ [es] (mobile_respawn__minDistanceToCapturePoint : float;
                                  var mobile_respawn__lastCheckPos : float3&;
                                  var mobile_respawn__lastCheckPosActive : bool&;
                                  transform aka mob_spawn_transform : float3x4;
                                  var active : bool&)
    mobile_respawn__lastCheckPos = transform[3]
    mobile_respawn__lastCheckPosActive = true
    query() <| $ [es(REQUIRE=capzone)] (transform aka zone_transform : float3x4;
                                        active : bool;
                                        eid : EntityId;
                                        capzone__approximateRadius : float const?;
                                        capzone__mobileRespawnBlockDist : float const?;
                                        sphere_zone__mediumRadius : float const?;
                                        box_zone__areaPoints : Point2List const?;
                                        capzone__areaPoints : Point2List const?)
      if !active
        return
      var distToZoneBorder = -1.
      let blockDist = capzone__mobileRespawnBlockDist ?? mobile_respawn__minDistanceToCapturePoint
      let mobSpawnPos = mob_spawn_transform[3].xz
      let distToZone = length(zone_transform[3].xz - mobSpawnPos)
      if capzone__approximateRadius != null && (*capzone__approximateRadius + blockDist + SPAWN_POINT_BLOCK_DIST_SHOW < distToZone)
        pass
      else
        if sphere_zone__mediumRadius != null
          distToZoneBorder = distToZone - *sphere_zone__mediumRadius
        elif box_zone__areaPoints != null
          if is_point_in_poly(mobSpawnPos, *box_zone__areaPoints)
            distToZoneBorder = 0.
          else
            distToZoneBorder = closest_dist_to_poly_border(mobSpawnPos, *box_zone__areaPoints)
        elif capzone__areaPoints != null
          if is_point_in_poly(mobSpawnPos, *capzone__areaPoints)
            distToZoneBorder = 0.
          else
            distToZoneBorder = closest_dist_to_poly_border(mobSpawnPos, *capzone__areaPoints)

        if distToZoneBorder > SPAWN_POINT_BLOCK_DIST_SHOW + blockDist
          distToZoneBorder = -1.

      if !!soldier
        send_net_event(eid, MobileSpawnDistToCapzoneEvent(distance = int(distToZoneBorder - blockDist)), target_entity_conn(soldier))

      if distToZoneBorder < blockDist && distToZoneBorder != -1.
        mobile_respawn__lastCheckPosActive = false
        isCloseToCapzone = true

    active &&= mobile_respawn__lastCheckPosActive
  setOptional(soldier, "human_vehicle__heroMobRespCloseToCapzone", isCloseToCapzone)


[es(tag=gameClient)]
def get_block_distance_for_local_player_mobile_respawn(evt : MobileSpawnDistToCapzoneEvent;
                                                       var capzone__localHeroDist : int&)
  capzone__localHeroDist = evt.distance

[es(tag=server, REQUIRE_NOT=deadEntity)]
def mobile_respawn_update_active_state(info : ParallelUpdateFrameDelayed;
                                       transform aka mob_spawn_transform : float3x4;
                                       eid : EntityId;
                                       isAlive : bool;
                                       vehicle__isUnderwater : bool;
                                       repairable__extinguishRequired : bool;
                                       mobile_respawn__nextSpawnTimer : float;
                                       team : int;
                                       var mobile_respawn__capturePointsCheckTime : float&;
                                       mobile_respawn__occupiedSeats : int;
                                       mobile_respawn__lastCheckPos : float3;
                                       mobile_respawn__lastCheckPosDistThreshold : float;
                                       ownedBySquad : EntityId;
                                       mobile_respawn__lastCheckPosActive : bool;
                                       mobile_respawn__capturePointsCheckInterval : float;
                                       var active : bool&;
                                       ownedByPlayer : EntityId;
                                       respawnBaseGroup : int;
                                       lastOffender : EntityId = INVALID_ENTITY_ID;
                                       last_offender__gunPropsId : int = -1;
                                       last_offender__shellId : int = -1)
  if mobile_respawn__capturePointsCheckTime > info.curTime || respawnBaseGroup == 0
    return
  mobile_respawn__capturePointsCheckTime = info.curTime + mobile_respawn__capturePointsCheckInterval
  active = true
  let isOutsideBattleArea = is_tm_outside_battle_area(transform, team)
  if isOutsideBattleArea
    if !is_vehicle_with_crew(eid) && !!ownedByPlayer
      sendEvent(eid, CmdExplosionFatal(offender = lastOffender, gunPropsId = last_offender__gunPropsId, shellId = last_offender__shellId))
      return
  active = (!isOutsideBattleArea && mobile_respawn__occupiedSeats == 0 && !repairable__extinguishRequired &&
    info.curTime > mobile_respawn__nextSpawnTimer && isAlive && !vehicle__isUnderwater)

  if length_sq(mobile_respawn__lastCheckPos - transform[3]) < square(mobile_respawn__lastCheckPosDistThreshold)
    active &&= mobile_respawn__lastCheckPosActive
    return

  let havePlayersInSpawnState = find_query() <| $ [es(REQUIRE_NOT=playerIsBot)] (respawner__enabled : bool)
    return respawner__enabled

  let driverSoldier = get_Eid(ownedBySquad, "squad__leader") ?? INVALID_ENTITY_ID
  let driverPlayerIsIn = (get_Eid(driverSoldier, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID) == eid

  if havePlayersInSpawnState || driverPlayerIsIn
    mobile_respawn_position_check(eid, driverPlayerIsIn ? driverSoldier : INVALID_ENTITY_ID)

[es(track=active, REQUIRE=(active, capzone))]
def update_mobile_respawn_last_check_pos_on_capzones_change(evt : Event)
  query() <| $ [es] (var mobile_respawn__lastCheckPos : float3&; mobile_respawn__lastCheckPosDistThreshold : float)
    mobile_respawn__lastCheckPos.y += mobile_respawn__lastCheckPosDistThreshold * 10.

[es(REQUIRE_NOT=deadEntity)]
def mobile_respawn_check_seats(evt : EventOnSeatOwnersChanged;
                               vehicle_seats__seatEids : EidList;
                               ownedBySquad : EntityId;
                               var mobile_respawn__occupiedSeats : int&)
  mobile_respawn__occupiedSeats = 0
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__squadEid : EntityId; seat__isOwnerAlive : bool)
      if seat__isOwnerAlive && !!seat__squadEid && seat__squadEid != ownedBySquad
        mobile_respawn__occupiedSeats += 1

[es(tag=server, on_appear, REQUIRE=mobileRespawnTag)]
def set_respawn_group_to_mobile_respawn(evt : Event;
                                        team : int;
                                        var active : bool&;
                                        var respawnBaseGroup : int&)
  respawnBaseGroup = get_new_respawn_group(team)
  if respawnBaseGroup == -1 //disable spawn for mobile respawn with unuassigned group
    active = false
    respawnBaseGroup = 0

[es(tag=server, on_appear)]
def attach_mobile_respawn_icon(evt : Event;
                               selectedGroup : int;
                               eid aka icon_eid : EntityId&;
                               team aka icon_team : int;
                               var mobile_respawn_point_selector__mobileRespawnEid : EntityId&)
  find_query() <| $ [es] (var mobile_respawn__respawnIconEid : EntityId&; respawnBaseGroup : int; eid aka respawn_eid : EntityId; team aka apc_team : int)
    if selectedGroup == respawnBaseGroup && icon_team == apc_team
      mobile_respawn__respawnIconEid = icon_eid
      mobile_respawn_point_selector__mobileRespawnEid = respawn_eid
      return true
    return false

[es(tag=gameClient, track=repairable__extinguishRequired)]
def mobile_respawn_is_on_fire_track(evt : Event; repairable__extinguishRequired : bool; mobile_respawn__respawnIconEid : EntityId)
  query(mobile_respawn__respawnIconEid) <| $ [es] (var respawn_icon__additionalInfo : das_string&)
    respawn_icon__additionalInfo := repairable__extinguishRequired ? "respawn/is_onfire" : ""

[es(tag=gameClient, REQUIRE_NOT=deadEntity)]
def update_mobile_respawn_icon(info : ParallelUpdateFrameDelayed;
                               team aka icon_team : int;
                               var transform aka icon_transform : float3x4&;
                               var respawn_icon__active : bool&;
                               var respawn_icon__position : float3&;
                               var respawn_icon__isOccupied : bool&;
                               mobile_respawn_point_selector__mobileRespawnEid : EntityId)
  var exit = false
  query(get_local_player_eid()) <| $ [es] (respawner__enabled : bool; team aka player_team : int)
    exit = !respawner__enabled || player_team != icon_team
  if exit
    return
  query(mobile_respawn_point_selector__mobileRespawnEid) <| $ [es] (transform aka vehicle_transform : float3x4;
                                                                    mobile_respawn__reservedPlayerEid : EntityId;
                                                                    mobile_respawn__occupiedSeats : int;
                                                                    active : bool)
    icon_transform[3] = vehicle_transform[3]
    respawn_icon__position = icon_transform[3]
    if (!!mobile_respawn__reservedPlayerEid && get_local_player_eid() != mobile_respawn__reservedPlayerEid) || mobile_respawn__occupiedSeats != 0
      respawn_icon__active = false
      respawn_icon__isOccupied = true
    else
      respawn_icon__active = active
      respawn_icon__isOccupied = false

[es(tag=server, track=disconnected)]
def free_mobile_respawn_on_player_disconnect(evt : Event; disconnected : bool; eid : EntityId; var respawner__mobileRespawnEid : EntityId&)
  if !!respawner__mobileRespawnEid && disconnected
    query(respawner__mobileRespawnEid) <| $ [es] (var mobile_respawn__reservedPlayerEid : EntityId&)
      if eid == mobile_respawn__reservedPlayerEid
        mobile_respawn__reservedPlayerEid = INVALID_ENTITY_ID
    respawner__mobileRespawnEid = INVALID_ENTITY_ID

[es(tag=gameClient, track=mobile_respawn__reservedPlayerEid)]
def control_local_player_mobile_respawn_reservation(evt : Event; mobile_respawn__reservedPlayerEid : EntityId; respawnBaseGroup : int)
  if !mobile_respawn__reservedPlayerEid
    return
  let locPlayer = get_local_player_eid()
  query(locPlayer) <| $ [es] (var respawner__respawnGroupId : int&)
    if respawnBaseGroup == respawner__respawnGroupId && locPlayer != mobile_respawn__reservedPlayerEid
      respawner__respawnGroupId = -1

[es(tag=gameClient, on_appear)]
def make_seat_non_placeable_for_non_onwer_on_local(evt : Event;
                                                   seat__vehicleEid : EntityId;
                                                   seats_order__canPlaceOnlyOwner : bool;
                                                   var seats_order__canPlaceManually : bool&)
  if seats_order__canPlaceOnlyOwner
    query(seat__vehicleEid) <| $ [es] (ownedBySquad : EntityId)
      let localPlayerSquad = get_Eid(get_local_player_eid(), "respawner__squad") ?? INVALID_ENTITY_ID
      seats_order__canPlaceManually = (localPlayerSquad == ownedBySquad)
      sendEvent(seat__vehicleEid, EventOnSeatOwnersChanged())

[es(tag=server, on_appear, REQUIRE=deadEntity)]
def destroy_mobile_spawn_icon_on_spawn_death(evt : Event;
                                             eid : EntityId;
                                             vehicle_seats__seatEids : EidList;
                                             var active : bool&;
                                             mobile_respawn__respawnIconEid : EntityId)
  active = false
  destroyEntity(mobile_respawn__respawnIconEid)
  kick_all_from_vehicle(eid, vehicle_seats__seatEids)

[es(tag=server, on_appear)]
def kick_soldiers_if_spawn_in_dead_vehicle(evt : Event;
                                           eid : EntityId;
                                           human_anim__vehicleSelected : EntityId)
  if !(get_bool(human_anim__vehicleSelected, "isAlive") ?? true)
    sendEventImmediate(human_anim__vehicleSelected, CmdKickFromVehicle(eid = eid))

[es(tag=ui)]
def mobile_spawn_icon_cooldawn_counter(info : ParallelUpdateFrameDelayed;
                                       team : int;
                                       mobile_respawn__nextSpawnTimer : float;
                                       mobile_respawn__respawnIconEid : EntityId)
  if get_int(get_local_player_eid(), "team") ?? TEAM_UNASSIGNED != team || mobile_respawn__nextSpawnTimer < info.curTime
    return
  query(mobile_respawn__respawnIconEid) <| $ [es] (var respawn_icon__playersCount : int&)
    respawn_icon__playersCount = int(mobile_respawn__nextSpawnTimer - info.curTime)


[es(tag=server, on_appear, REQUIRE=mobileRespawnTag)]
def destroy_previous_player_mobile_respawn_on_new_appear(evt : Event;
                                                         eid aka new_spawn_eid : EntityId;
                                                         ownedByPlayer aka new_spawn_ownedByPlayer : EntityId;
                                                         mobile_respawn__capturePointsCheckInterval : float;
                                                         var mobile_respawn__capturePointsCheckTime : float&)
  mobile_respawn__capturePointsCheckTime = get_sync_time() + mobile_respawn__capturePointsCheckInterval
  find_query() <| $ [es(REQUIRE=mobileRespawnTag, REQUIRE_NOT=deadEntity)] (eid aka old_spawn_eid : EntityId;
                                                                            ownedByPlayer aka old_spawn_ownedByPlayer : EntityId;
                                                                            vehicle_seats__seatEids : EidList;
                                                                            lastOffender : EntityId = INVALID_ENTITY_ID;
                                                                            last_offender__gunPropsId : int = -1;
                                                                            last_offender__shellId : int = -1)
    if old_spawn_eid != new_spawn_eid && new_spawn_ownedByPlayer == old_spawn_ownedByPlayer && !!new_spawn_ownedByPlayer
      kick_all_from_vehicle(old_spawn_eid, vehicle_seats__seatEids)
      sendEvent(old_spawn_eid, CmdExplosionFatal(offender = lastOffender, gunPropsId = last_offender__gunPropsId, shellId = last_offender__shellId))
      return true
    return false

[es(tag=server, track=active, on_appear)]
def create_respawn_extra_respawn_on_appear(evt : Event;
                                           team : int;
                                           eid : EntityId;
                                           active : bool;
                                           groupName : string;
                                           respawnBaseGroup : int;
                                           transform : float3x4;
                                           resp__autoCreateExtraRespawnOnAppear : string;
                                           var resp__autoRespawnCreated : bool&)
  if resp__autoCreateExtraRespawnOnAppear != "" && !resp__autoRespawnCreated && active
    resp__autoRespawnCreated = true
    createEntity(resp__autoCreateExtraRespawnOnAppear) <| $(var init : ComponentsInitializer)
      set(init, "transform", transform)
      set(init, "team", team)
      set(init, "active", active)
      set(init, "groupName", groupName)
      set(init, "respawnBaseGroup", respawnBaseGroup)
      set(init, "copyTeamAndGroupOnCreateFromEid", eid)

[es(on_appear, tag=server, before=respawn_bases_selector_group_es)]
def copy_respawn_team_and_group_on_appear(evt : Event;
                                          copyTeamAndGroupOnCreateFromEid : EntityId;
                                          var team aka child_team : int&;
                                          var active aka child_active : bool&;
                                          var groupName aka child_groupName : das_string&)
  query(copyTeamAndGroupOnCreateFromEid) <| $ [es] (team aka parent_team : int&;
                                                    active aka parent_active : bool;
                                                    groupName aka parent_groupName : das_string)
    child_team = parent_team // Set team and groupName from parent respawn because they could have already
    child_groupName := parent_groupName // been changed during creation of child respawn by respawn_base_group_activator
    child_active = parent_active

[es(tag=server, on_appear)]
def mobile_spawn_uses_award(evt : Event;
                            squad__respawnBaseEid : EntityId;
                            squad__ownerPlayer : EntityId)
  query(squad__respawnBaseEid) <| $ [es] (ownedByPlayer : EntityId; mobile_respawn__lastDriverGuid : string)
    if squad__ownerPlayer != ownedByPlayer
      add_award(ownedByPlayer, "owned_mobile_spawn_usage")
      send_award_stat(ownedByPlayer, mobile_respawn__lastDriverGuid, "ownedMobileSpawnUses")

[es(tag=server, track=seat__ownerEid, on_appear)]
def set_seat_last_driver_guid(evt : Event;
                              seat__ownerEid : EntityId;
                              seat__vehicleEid : EntityId;
                              seats_order__canPlaceOnlyOwner : bool)
  if !seats_order__canPlaceOnlyOwner
    return
  query(seat__vehicleEid) <| $ [es] (ownedBySquad : EntityId; var mobile_respawn__lastDriverGuid : das_string&)
    query(seat__ownerEid) <| $ [es] (squad_member__squad : EntityId; guid : string)
      if squad_member__squad == ownedBySquad
        mobile_respawn__lastDriverGuid := guid

[es(tag=gameClient, REQUIRE=mobileRespawnTag)]
def send_message_on_mobile_respawn_die(evt : EventEntityDied;
                                       lastOffender : EntityId;
                                       team : int;
                                       ownedByPlayer : EntityId)
  if get_local_player_eid() == ownedByPlayer && !is_teams_friendly(team, get_int(lastOffender, "team") ?? TEAM_UNASSIGNED)
    send_net_event(ownedByPlayer, CmdHeroLogEvent(event = "your_mobile_rally_point_destroyed", text = "your_mobile_rally_point_destroyed"))
