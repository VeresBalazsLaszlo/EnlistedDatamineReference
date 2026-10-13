require ecs
require game.es.player_events

[es(tag=server, on_event=EventOnPlayerConnected, after=player_on_connect_script_es)]
def init_first_spawn_delay(evt : Event; team aka player_team : int; var squads__firstSpawnDelayByType : Object&; var squads__firstSpawnDelayBySubType : Object&)
  query() <| $ [es] (team : int; respbase__firstSpawnDelay : float; respawnbaseType : string; respawnbaseSubtype : string = "")
    if team == player_team
      squads__firstSpawnDelayByType |> set(respawnbaseType, respbase__firstSpawnDelay)
      if respawnbaseSubtype != ""
        squads__firstSpawnDelayBySubType |> set(respawnbaseSubtype, respbase__firstSpawnDelay)