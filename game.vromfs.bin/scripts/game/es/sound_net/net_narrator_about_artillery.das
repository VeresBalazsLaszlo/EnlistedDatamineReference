require ecs
require game.utils.team
require net_narrator.modules.net_narrator_events
require DngNet


[es(tag=server, on_appear)]
def net_narrator_about_artillery(evt : Event;
                                 net_narrator_about_artillery__phrase : string;
                                 artillery__offender : EntityId)
  let team = get_int(artillery__offender, "team") ?? TEAM_UNASSIGNED
  broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = net_narrator_about_artillery__phrase, replace = false))
