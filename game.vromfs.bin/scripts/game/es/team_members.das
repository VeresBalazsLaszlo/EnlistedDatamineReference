require ecs
require ecs.common
require game.events_game

[es(tag=server)]
def team_members_add_new_member_to_list(evt : EventTeamMemberJoined;
                                        team__id : int;
                                        team__countAdd : float = 0.0;
                                        team__capacity : int = -1;
                                        var team__locked : bool&;
                                        var team__memberCount : float&;
                                        var team__memberEids : EidList&)
  if evt.team != team__id || has(evt.eid, "waveSpawnBot")
    return
  let isInList = find_index(team__memberEids, evt.eid) >= 0
  if !isInList
    team__memberEids |> push(evt.eid)
    team__memberCount = team__countAdd + float(length(team__memberEids))
    if team__capacity >= 0 && team__memberCount >= float(team__capacity)
      team__locked = true

[es(tag=server)]
def team_members_remove_new_member_to_list(evt : EventTeamMemberLeave;
                                           team__id : int;
                                           team__countAdd : float = 0.0;
                                           var team__memberCount : float&;
                                           var team__memberEids : EidList&)
  if evt.team != team__id || has(evt.eid, "waveSpawnBot")
    return
  let idx = find_index(team__memberEids, evt.eid)
  if idx >= 0
    team__memberEids |> erase(idx)
    team__memberCount = team__countAdd + float(length(team__memberEids))

[es(tag=server, on_appear)]
def override_max_member_count_on_team_create(evt : Event;
                                             var team__maxMembersCount : int&)
  query() <| $ [es] (team__maxMembersCountOverride : int)
    team__maxMembersCount = team__maxMembersCountOverride

[es(tag=server, on_appear)]
def max_member_count_on_override_team_create(evt : Event;
                                             team__maxMembersCountOverride : int)
  query() <| $ [es] (var team__maxMembersCount : int&)
    team__maxMembersCount = team__maxMembersCountOverride
