require ecs
require soundEvent
require enlisted.events_enlisted
require net_narrator.modules.net_narrator_events
require narrator.modules.narrator_common
require game.events_game
require game.utils.hero
require game.utils.team
require app


[es(tag=sound)]
def narrator_cmd_net_narrator_about_team(evt : CmdNetNarratorAboutTeam; team__id : int)
  if team__id == get_local_player_team()
    ecs::query() <| $ [es] (var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
      start_narrator(evt.phrase, is_teams_friendly(evt.team, team__id), evt.replace, team__id, narrator__event, narrator__queue, narrator__history)


[es(tag=sound)]
def narrator_cmd_narrator_about_team(evt : CmdNarratorAboutTeam; team__id : int)
  if team__id == get_local_player_team()
    ecs::query() <| $ [es] (var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
      start_narrator(evt.phrase, is_teams_friendly(evt.team, team__id), evt.replace, team__id, narrator__event, narrator__queue, narrator__history)


[es(tag=sound)]
def narrator_cmd_narrator_about_local_team(evt : CmdNarratorAboutLocalTeam; var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
  let isOurTeam = true
  start_narrator(evt.phrase, isOurTeam, evt.replace, get_local_player_team(), narrator__event, narrator__queue, narrator__history)


[es(tag=sound)]
def narrator_round_result(evt : EventTeamRoundResult; var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
  let isOurTeam = evt.team == get_local_player_team()
  if isOurTeam
    let replace = true
    start_narrator(evt.isWon ? "win" : "lose", isOurTeam, replace, evt.team, narrator__event, narrator__queue, narrator__history)


[es(tag=sound)]
def narrator_low_score(evt : EventTeamLowScore; var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
  let localPlayerTeam = get_local_player_team()
  let isAllies = is_teams_friendly(localPlayerTeam, evt.teamId)
  let replace = false
  start_narrator("loosingScores", isAllies, replace, evt.teamId, narrator__event, narrator__queue, narrator__history)


[es(tag=sound)]
def narrator_lose_half_score(evt : EventTeamLoseHalfScore; var narrator__event : SoundEvent&; var narrator__queue : Array&; var narrator__history : Object&)
  let localPlayerTeam = get_local_player_team()
  let isAllies = is_teams_friendly(localPlayerTeam, evt.teamId)
  let replace = false
  start_narrator("loseHalfScores", isAllies, replace, evt.teamId, narrator__event, narrator__queue, narrator__history)


[es(tag=sound, on_event=EventOnSoundPresetLoaded)]
def narrator_on_unloaded(evt : Event;
                         var narrator__event : SoundEvent&)
  if !is_narrator_loaded()
    release(narrator__event)
