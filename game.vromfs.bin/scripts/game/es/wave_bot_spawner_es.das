require game.utils.team
require game.es.events
require ecs.common
require ecs
require app
require game.es.respawn_base_common
require enlisted.events_enlisted
require gameLibs.pufd_events.pufd_events
require DngNet
require game.es.player_events

[es(tag=server)]
def init_wave_bot_spawner_first_wave(evt : EventFirstPlayerConnected;
                                     var wave_bot_spawner__nextSpawnTime : float&;
                                     wave_bot_spawner__timeBeforeFirstPlayersCanSpawn : float)
  find_query() <| $ [es] (respawner__missionStartDelay : float)
    wave_bot_spawner__nextSpawnTime = max(evt.time + respawner__missionStartDelay - wave_bot_spawner__timeBeforeFirstPlayersCanSpawn, 0.)
    return true

[es(tag=server, REQUIRE=waveSpawnBot)]
def check_squad_leader(info : ParallelUpdateFrameDelayed; respawner__squad : EntityId; eid : EntityId)
  query(respawner__squad) <| $ [es] (squad__isAlive : bool; squad__allMembers : EidList; var squad__leader : EntityId&)
    if squad__isAlive && has(squad__leader, "deadEntity")
      for member in squad__allMembers
        if get_bool(member, "isAlive") ?? false
          squad__leader = member
          sendEvent(eid, CmdPossessEntity(possessedEid = member))
          return


[es(tag=server, no_order)]
def update_wave_bot_spawner_next_spawn(info : ParallelUpdateFrameDelayed;
                                       var wave_bot_spawner__squadsToSpawn : int&;
                                       wave_bot_spawner__respawnBaseGroupsByName : Object;
                                       var wave_bot_spawner__firstWaveSpawned : bool&;
                                       var wave_bot_spawner__indForNextSpawn : int&;
                                       wave_bot_spawner__waveInterval : float;
                                       wave_bot_spawner__spawnInterval : float;
                                       team aka spawner_team : int;
                                       eid : EntityId;
                                       var wave_bot_spawner__nextSpawnTime : float&)
  if info.curTime < wave_bot_spawner__nextSpawnTime || wave_bot_spawner__nextSpawnTime < 0.
    return

  find_query() <| $ [es] (activator__lastActivatedGroup : string)
    find_query() <| $ [es(REQUIRE=waveSpawnBot)] (team : int;
                                                  eid : EntityId;
                                                  var respawner__shouldSpawn : bool&;
                                                  respawner__enabled : bool;
                                                  respawner__respRequestedSquadId : int)
      if spawner_team == team && respawner__enabled && respawner__shouldSpawn
        let baseGroups = get_ecs_array(wave_bot_spawner__respawnBaseGroupsByName, activator__lastActivatedGroup)
        if baseGroups == null
          return true
        wave_bot_spawner__indForNextSpawn = (wave_bot_spawner__indForNextSpawn + 1) % length(*baseGroups)
        respawner__shouldSpawn = false
        sendEvent(eid, CmdSpawnSquad(
            team = team,
            possessed = INVALID_ENTITY_ID,
            squadId = respawner__respRequestedSquadId,
            squadRoute = 0,
            memberId = 0,
            respawnGroupId = (get_int((*baseGroups)[wave_bot_spawner__indForNextSpawn]) ?? -1),
            existedVehicleEid = INVALID_ENTITY_ID,
            withoutVehicle = true
        ))
        wave_bot_spawner__squadsToSpawn -= 1
        wave_bot_spawner__nextSpawnTime = info.curTime + wave_bot_spawner__spawnInterval
        return true
      return false
    return true

  if wave_bot_spawner__squadsToSpawn == 0
    wave_bot_spawner__firstWaveSpawned = true
    wave_bot_spawner__nextSpawnTime = info.curTime + wave_bot_spawner__waveInterval
    send_net_event(eid, EventWaveBotSpawned())
    return

def update_wave_spawn(bot_player_eid, forced_add_to_waver)
  query(bot_player_eid) <| $ [es(REQUIRE=waveSpawnBot)] (team aka bot_team : int; var respawner__shouldSpawn : bool&)
    query() <| $ [es] (team : int;
                       wave_bot_spawner__firstWaveSpawned : bool;
                       wave_bot_spawner__spawnInterval : float;
                       var wave_bot_spawner__squadsToSpawn : int&;
                       var wave_bot_spawner__nextSpawnTime : float&)
      if team == bot_team
        wave_bot_spawner__squadsToSpawn += 1
        respawner__shouldSpawn = true
        if forced_add_to_waver && wave_bot_spawner__firstWaveSpawned
          wave_bot_spawner__nextSpawnTime = min(wave_bot_spawner__nextSpawnTime, get_sync_time() + wave_bot_spawner__spawnInterval)

[es(tag=server, on_appear, REQUIRE=waveSpawnBot)]
def update_wave_spawn_on_bot_player_appear(evt : Event; eid : EntityId)
  update_wave_spawn(eid, true)

[es(tag=server, track=squad__isAlive)]
def update_wave_spawn_on_squad_death(evt : Event;
                                     squad__isAlive : bool;
                                     squad__ownerPlayer : EntityId)
  if squad__isAlive || !has(squad__ownerPlayer, "waveSpawnBot")
    return
  update_wave_spawn(squad__ownerPlayer, false)

[es(tag=server, on_appear, REQUIRE=waveBotRespawn)]
def update_wave_bot_spawner_on_respawns_change(evt : Event;
                                               groupName : string;
                                               var respawnBaseGroup : int&;
                                               team aka respawn_team : int)
  if respawnBaseGroup == -1
    respawnBaseGroup = get_new_respawn_group(team)
  query() <| $ [es] (team : int; var wave_bot_spawner__respawnBaseGroupsByName : Object&)
    if respawn_team != team
      return
    var groups = getRW_ecs_array(wave_bot_spawner__respawnBaseGroupsByName, groupName)
    if groups != null
      push(*groups, respawnBaseGroup)
    else
      using() <| $(var arr : Array)
        arr |> push(respawnBaseGroup)
        wave_bot_spawner__respawnBaseGroupsByName |> set(groupName, arr)