require ecs
require game.utils.team
require game.events_game
require enlisted.events_enlisted
require ecs.safe

def team_penalty(team : int; is_squad_death : bool; squad_penalty_mult : float = 1.)
  find_query() <| $ [es] (team__id : int;
                          team__memberEids : EidList;
                          team__zeroScoreFailTimer : float;
                          team__deathPenalty : float;
                          team__deathPenaltyByMember : float = 0.0;
                          team__minDeathPenalty : float = 0.0;
                          team__minSquadDeathPenalty : float = 0.0;
                          team__deathSquadPenalty : float = 0.0;
                          var team__score : float&)
    if team__id != team
      return false

    let addDeathPenalty = float(length(team__memberEids)) * team__deathPenaltyByMember
    var deathPenalty = (is_squad_death ? max(team__deathSquadPenalty + addDeathPenalty, team__minSquadDeathPenalty) :
                        max(team__deathPenalty + addDeathPenalty, team__minDeathPenalty))
    deathPenalty *= squad_penalty_mult

    if deathPenalty > 0.0
      if deathPenalty >= team__score
        team__score = 0.0
        if team__zeroScoreFailTimer < 0.0
          broadcastEvent(EventTeamLost(team = team__id))
          return true
      else
        team__score -= deathPenalty

    if team__zeroScoreFailTimer > 0.0 && team__score <= 0.0
      let isAliveTeamMemberFound = find_query() <| $ [es(REQUIRE=countAsAlive)] (team : int; isAlive : bool)
        return isAlive && team == team__id
      if !isAliveTeamMemberFound
        broadcastEvent(EventTeamLost(team = team__id))

    return true

[es(tag=server, track=squad__isAlive)]
def team_on_squad_death_es(evt : Event; squad__isAlive : bool; squad__ownerPlayer : EntityId; squad__id : int)
  let team = get_int(squad__ownerPlayer, "team") ?? TEAM_UNASSIGNED
  var squadPenaltyMult = 1.
  query(squad__ownerPlayer) <| $ [es] (squads__customSquadCost : Object)
    squadPenaltyMult = get_float(squads__customSquadCost, string(squad__id)) ?? 1.

  if !squad__isAlive
    team_penalty(team, true, squadPenaltyMult)


[es(tag=server)]
def team_on_death_es(evt : EventAnyEntityDied)
  let victimEid = evt.victim
  let victimTeamId = get_int(victimEid, "team") ?? TEAM_UNASSIGNED
  team_penalty(victimTeamId, false)
