options no_aot
require ecs
require DagorConsole
require net_narrator.modules.net_narrator_events
require game.utils.team
require soundSystem
require DngNet


[console_cmd(name="narrator.local_team")]
def narrator_debug_console_narrator_start()
  find_query() <| $ [es] (eid : EntityId; team__id : int)
    if team__id == get_local_player_team()
      sound_debug("local player team id is {get_local_player_team()} '{getEntityTemplateName(eid)}'")
      return true
    return false


[console_cmd(name="narrator.cmd")]
def narrator_debug_console_narrator_start(phrase : string)
  broadcastEvent(CmdNarratorAboutLocalTeam(phrase = phrase, replace = false))


[console_cmd(name="narrator.net_cmd")]
def narrator_debug_console_narrator_team_start(team : int; phrase : string)
  sound_debug("local player team id is {get_local_player_team()}")
  broadcast_net_event(CmdNetNarratorAboutTeam(team = team, phrase = phrase, replace = false))


[console_cmd(name="narrator.player_team_net_cmd")]
def narrator_debug_console_narrator_player_team_start(phrase : string)
  broadcast_net_event(CmdNetNarratorAboutTeam(team = get_local_player_team(), phrase = phrase, replace = false))


[console_cmd(name="narrator.enemy_team_net_cmd")]
def narrator_debug_console_narrator_enemy_team_start(phrase : string)
  let heroTeamId = get_local_player_team()
  find_query() <| $ [es] (team__id : int)
    if team__id != heroTeamId && team__id != TEAM_UNASSIGNED
      broadcast_net_event(CmdNetNarratorAboutTeam(team = team__id, phrase = phrase, replace = false))
      return true
    return false
