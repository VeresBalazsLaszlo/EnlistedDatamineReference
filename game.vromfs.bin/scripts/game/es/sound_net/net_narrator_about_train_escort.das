require ecs
require game.utils.team
require net_narrator.modules.net_narrator_events
require DngNet

[es(tag=server, on_event=ParallelUpdateFrameDelayed)]
def net_narrator_about_train_escort(evt : Event;
                                    train__teamOffense : int;
                                    train__teamDefense : int;
                                    var net_narrator_about_train_escort__teamOffensePresence : int&;
                                    var net_narrator_about_train_escort__teamDefensePresence : int&)
  net_narrator_about_train_escort__teamOffensePresence = -1
  net_narrator_about_train_escort__teamDefensePresence = -1
  query() <| $ [es] (teamPresence : Object)
    let offense = get_ecs_array(teamPresence, "{train__teamOffense}")
    let defense = get_ecs_array(teamPresence, "{train__teamDefense}")
    net_narrator_about_train_escort__teamOffensePresence = offense != null && length(*offense) > 0 ? train__teamOffense : -1
    net_narrator_about_train_escort__teamDefensePresence = defense != null && length(*defense) > 0 ? train__teamDefense : -1
    if net_narrator_about_train_escort__teamOffensePresence == TEAM_UNASSIGNED
      net_narrator_about_train_escort__teamOffensePresence = -1
    if net_narrator_about_train_escort__teamDefensePresence == TEAM_UNASSIGNED
      net_narrator_about_train_escort__teamDefensePresence = -1


[es(tag=server, track=(net_narrator_about_train_escort__teamOffensePresence, net_narrator_about_train_escort__teamDefensePresence))]
def net_narrator_about_train_escort_on_team_presence(evt : Event;
                                                     net_narrator_about_train_escort__teamOffensePresence : int;
                                                     net_narrator_about_train_escort__teamDefensePresence : int;
                                                     var net_narrator_about_train_escort__prevTeamOffensePresence : int&;
                                                     var net_narrator_about_train_escort__prevTeamDefensePresence : int&)

  let offense = net_narrator_about_train_escort__teamOffensePresence
  let defense = net_narrator_about_train_escort__teamDefensePresence
  let prevOffense = net_narrator_about_train_escort__prevTeamOffensePresence
  let prevDefense = net_narrator_about_train_escort__prevTeamDefensePresence

  let wasOffence = prevOffense != -1
  let wasDefense = prevDefense != -1
  let hasOffence = offense != -1
  let hasDefense = defense != -1

  if hasOffence && wasDefense && !hasDefense
    broadcast_net_event(CmdNetNarratorAboutTeam(team = offense, phrase = "trainCaptured", replace = false))
  elif hasDefense && wasOffence && !hasOffence
    broadcast_net_event(CmdNetNarratorAboutTeam(team = defense, phrase = "trainCaptured", replace = false))
  elif hasOffence && !wasOffence
    broadcast_net_event(CmdNetNarratorAboutTeam(team = offense, phrase = "trainCapturing", replace = false))
  elif hasDefense && !wasDefense
    broadcast_net_event(CmdNetNarratorAboutTeam(team = defense, phrase = "trainCapturing", replace = false))

  net_narrator_about_train_escort__prevTeamOffensePresence = offense
  net_narrator_about_train_escort__prevTeamDefensePresence = defense
