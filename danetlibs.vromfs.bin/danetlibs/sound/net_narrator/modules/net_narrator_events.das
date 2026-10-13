module net_narrator_events shared
require ecs

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdNetNarratorAboutTeam // server->client
  team : int
  phrase : string
  replace : bool

[event(broadcast)]
struct CmdNarratorAboutLocalTeam // client->client
  phrase : string
  replace : bool

[event(broadcast)]
struct CmdNarratorAboutTeam // client->client
  team : int
  phrase : string
  replace : bool

[event(broadcast)]
struct CmdNarratorTextEvent
  event : string
  text : string
  myTeamScores : bool
