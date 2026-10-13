require ecs
require DngNet
require player
require game.es.player_events
require game.events_game
require enlisted.events_enlisted

[es(tag=server)]
def player_replicate_default_on_connect(evt : CmdSpawnEntityForPlayer;
                                        eid : EntityId;
                                        var clientNetFlags : int&)
  // clientNetFlags is reset on each (re)connect, so a reconnected player gets the default scope again
  if 0 == (clientNetFlags & int(ClientNetFlags.CNF_REPLICATE_PHYS_ACTORS))
    clientNetFlags |= int(ClientNetFlags.CNF_REPLICATE_PHYS_ACTORS)
    sendEventImmediate(eid, CmdAddDefaultEntitiesInNetScopeForPlayer())