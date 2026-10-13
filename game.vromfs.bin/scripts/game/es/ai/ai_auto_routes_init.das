require ecs
require app
require DngActor
require DagorConsole
require enlisted.game.es.spawn_soldier_events

[es(tag=server, on_appear)]
def ai_auto_routes_init_es(evt : Event;
                           var squad__autoRouteIdx : int&;
                           var squad__autoRoutePos : int&;
                           var squad__autoRouteEid : EntityId&;
                           var squad__autoRouteTime : float&;
                           squad__ownerPlayer : EntityId)
  if squad__autoRouteIdx < 0
    return
  var playerTeam = -1
  query(squad__ownerPlayer) <| $ [es] (team : int)
    playerTeam = team
  if playerTeam <= 0
    squad__autoRouteIdx = -1
    return
  var inited = false
  find_query() <| $ [es] (eid aka team_eid : EntityId; team__id : int)
    if team__id != playerTeam
      return false
    inited = true
    squad__autoRoutePos = 0
    squad__autoRouteEid = team_eid
    squad__autoRouteTime = -1.0
    return true
  if !inited
    squad__autoRouteIdx = -1

[es(tag=server, on_event=FinalizeSoldierCreation)]
def ai_auto_routes_init_soldier_es(evt : Event;
                                   eid aka soldier_eid : EntityId;
                                   squad_member__squad : EntityId;
                                   transform : float3x4)
  query(squad_member__squad) <| $ [es] (squad__autoRouteIdx : int;
                                        squad__autoRouteEid : EntityId)
    query(squad__autoRouteEid) <| $ [es] (team__autoRouteBotSquads : Array)
      if squad__autoRouteIdx < 0 || squad__autoRouteIdx >= length(team__autoRouteBotSquads)
        return
      let routeObj = get_ecs_object(team__autoRouteBotSquads[squad__autoRouteIdx])
      if routeObj != null
        let points = get_ecs_array(routeObj, "points")
        if points != null
          if length(*points) > 0
            let pt = get_Point4((*points)[0])
            if pt != null
              var tm = transform
              tm[3] = (*pt).xyz
              teleport_phys_actor(soldier_eid, tm)
