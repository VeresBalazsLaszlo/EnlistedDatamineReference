require ecs
require enlisted.events_enlisted
require net_narrator.modules.net_narrator_events
require game.utils.team
require game.es.stat_bq_common
require DngNet


[es(tag=server, REQUIRE=bomb_site__operator)]
def net_narrator_about_bomb_site_planting(evt : EventBombSitePlanting)
  query(evt.bombSiteOperator) <| $ [es] (team : int)
    broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = "bombPlanting", replace = false))


[es(tag=server, REQUIRE=bomb_site__operator)]
def net_narrator_about_bomb_site_planted(evt : EventBombSitePlanted)
  query(evt.bombSiteOperator) <| $ [es] (team : int)
    broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = "bombPlanted", replace = false))


[es(tag=server, REQUIRE=bomb_site__operator)]
def net_narrator_about_bomb_site_defusing(evt : EventBombSiteDefusing)
  query(evt.bombSiteOperator) <| $ [es] (team : int)
    broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = "bombDefusing", replace = false))


[es(tag=server, REQUIRE=bomb_site__operator)]
def net_narrator_about_bomb_site_defused(evt : EventBombSiteDefused)
  query(evt.bombSiteOperator) <| $ [es] (team : int)
    broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = "bombDefused", replace = false))
