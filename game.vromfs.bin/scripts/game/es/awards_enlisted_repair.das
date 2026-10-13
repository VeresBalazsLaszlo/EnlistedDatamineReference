require ecs
require app
require enlisted.events_enlisted
require game.es.events
require game.es.awards_common
require game.es.vehicle.vehicle_events
require game.utils.team
require game.events_game
require DngNet

def clear_awards_history_and_add_cur_time_value(var awardsTimes : FloatList;
                                                cleanTime : float)
  if empty(awardsTimes)
    return true
  let curTime = get_sync_time()
  for award in awardsTimes
    if award <= 0. || award < (curTime - cleanTime)
      award = curTime
      return true // no reason to clean all list if we already found place to save
  return false

[es(tag=server, on_appear)]
def award_init_repaired_limits(evt : Event;
                               var vehicle_repair__awardsHistory : FloatList;
                               vehicle_repair__awardsLimit : int)
  resize(vehicle_repair__awardsHistory, vehicle_repair__awardsLimit)

[es(tag=server, on_appear)]
def award_init_extinguished_limits(evt : Event;
                                   var vehicle_extinguish__awardsHistory : FloatList;
                                   vehicle_extinguish__awardsLimit : int)
  resize(vehicle_extinguish__awardsHistory, vehicle_extinguish__awardsLimit)

def award_vehicle_maintenance(eid : EntityId; vehicle_owner_player_eid : EntityId; stat : string; repair : bool)
  query(eid) <| $ [es] (squad_member__playerEid : EntityId; guid : string; team : int)
    if (vehicle_owner_player_eid == INVALID_ENTITY_ID
        || team == TEAM_UNASSIGNED
        || squad_member__playerEid == vehicle_owner_player_eid
        || (get_int(vehicle_owner_player_eid, "team") ?? TEAM_UNASSIGNED) != team)
      return

    var skipAward = false

    query(squad_member__playerEid) <| $ [es] (var vehicle_repair__awardsHistory : FloatList&;
                                              vehicle_repair__awardCooldown : float;
                                              var vehicle_extinguish__awardsHistory : FloatList&;
                                              vehicle_extinguish__awardCooldown : float)
      if repair
        if !clear_awards_history_and_add_cur_time_value(vehicle_repair__awardsHistory, vehicle_repair__awardCooldown)
          send_net_event(squad_member__playerEid, CmdHeroLogEvent(event = "vehicle_awards", text = "vehicle_award/repair_cooldown"))
          skipAward = true
      else
        if !clear_awards_history_and_add_cur_time_value(vehicle_extinguish__awardsHistory, vehicle_extinguish__awardCooldown)
          send_net_event(squad_member__playerEid, CmdHeroLogEvent(event = "vehicle_awards", text = "vehicle_award/extinguish_cooldown"))
          skipAward = true

    if skipAward
      return
    using() <| $(var awardList : Array)
      awardList |> push_soldier_stat(squad_member__playerEid, guid, stat)
      broadcast_schemeless_event(typeinfo undecorated_typename(type<EventSquadMembersStats>)) <| $(var init : Object)
        set(init, "list", awardList)

[es(tag=server)]
def award_vehicle_repaired(evt : EventRepairAward; ownedByPlayer : EntityId)
  award_vehicle_maintenance(evt.eid, ownedByPlayer, "vehicleRepairs", true)

[es(tag=server)]
def award_vehicle_extinguished(evt : EventOnVehicleExtinguished; ownedByPlayer : EntityId)
  award_vehicle_maintenance(evt.eid, ownedByPlayer, "vehicleExtinguishes", false)
