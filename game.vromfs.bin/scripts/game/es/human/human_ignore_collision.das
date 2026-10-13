require ecs
require PhysMat
require game.utils.team
require enlisted.events_enlisted

[es]
def human_phys_query_one_side_collision_es(var evt : QueryPhysActorsOneSideCollidable&;
                                           team : int;
                                           beh_tree__enabled : bool)
  if beh_tree__enabled
    return
  else
    let otherTeam = get_int(evt.otherEid, "team") ?? TEAM_UNASSIGNED
    if otherTeam == team
      let isBot = get_bool(evt.otherEid, "beh_tree__enabled") ?? false
      if isBot
        evt.oneSideCollidable = true