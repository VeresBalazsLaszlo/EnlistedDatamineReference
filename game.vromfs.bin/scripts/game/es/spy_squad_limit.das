require ecs
require ecs.safe

def is_spy_squad(squad__id : int; squad__ownerPlayer : EntityId) : bool
  var result = false
  query(squad__ownerPlayer) <| $ [es] (armies : Object; army : string)
    assume squads = (armies[army] ?as Object)?.squads ?as Array
    if squads == null
      return
    let squadObj = (*squads)[squad__id] as Object
    if squadObj == null
      return
    let squadType = squadObj?.squadType ?? ""
    result = squadType == "saboteur"
  return result

[es(tag=server, track=squad__isAlive)]
def spy_squad_limit_decrease(evt : Event;
                             squad__id : int;
                             squad__isAlive : bool;
                             squad__ownerPlayer : EntityId)
  if squad__isAlive || !is_spy_squad(squad__id, squad__ownerPlayer)
    return
  let squadTeam = get_int(squad__ownerPlayer, "team") ?? -1
  query() <| $ [es] (team__id : int; var team__aliveSpySquads : int&)
    if team__id == squadTeam
      team__aliveSpySquads -= 1
