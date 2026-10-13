require game.utils.team
require ecs.ecs_quirrel
require daslib/quirrel_boost


[quirrel_bind(module_name="das.team")]
def assign_team() // returns [teamId, teamEid]
  var resTeamId = int(TEAM_UNASSIGNED)
  var resTeamEid = INVALID_ENTITY_ID
  assign_team(resTeamId, resTeamEid)
  var res : array<int>
  res |> push(resTeamId)
  res |> push(int(uint(resTeamEid)))
  return <- res
