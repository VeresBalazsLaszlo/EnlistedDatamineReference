module squad_spawn_common shared
require ecs
require ecs.safe
require math
require game.utils.spawn_common
require DagorSystem

let spawnZoneExtents = 3.0 //copy from squad_spawn.nut

def validate_vehicle_position(tm : float3x4)
  var wishPos = tm[3]
  var vehiclesPos : array<float3>
  query() <| $ [es(REQUIRE=vehicle)] (transform : float3x4)
    vehiclesPos |> push(transform[3])
  var isWorking = true
  for _i in range(0, 5)
    if !isWorking
      break
    isWorking = false
    for pos in vehiclesPos
      var dist = wishPos - pos
      dist.y = 0.0
      var len = length(dist)
      if len == 0.0
        len = 1.0
        dist = float3(1.0, 0.0, 0.0)
      if len < 5.0
        dist = dist * (1.0 / len)
        wishPos = wishPos + dist * 5.0
        isWorking = true

  var resTm : float3x4 = tm
  resTm[3] = wishPos
  return validate_position(resTm, tm[3], spawnZoneExtents, true /*isVehicle*/)

def validate_rotation_comps(squadRevivePoints : IntList;
                            soldierRevivePoints : Array const?;
                            squadId, memberId : int)
  if squadId < 0 || squadId >= length(squadRevivePoints)
    logerr("Squad /*{squadId}*/ not found in squads__revivePointsList")
    print("{squadRevivePoints}")
  elif soldierRevivePoints != null
    let lengthPoints = length(*soldierRevivePoints)
    if lengthPoints > 0 && (squadId >= lengthPoints || memberId >= length(*((*soldierRevivePoints)[squadId] as Array)))
      logerr("Member /*{memberId}*/ of squad /*{squadId}*/ not found in soldier_revive_points__points")
      print("{soldierRevivePoints}")
    else
      return true
  else
    return true
  return false

def validate_spawn_rotation(playerEid : EntityId;
                            squadId, memberId : int)
  var result = true
  query(playerEid) <| $ [es] (squads__revivePointsList : IntList;
                              soldier_revive_points__points : Array const?)
    if !validate_rotation_comps(squads__revivePointsList, soldier_revive_points__points, squadId, memberId)
      result = false
      return
    let squadRevivePoints = squads__revivePointsList[squadId]
    var soldierRevivePoints = 100
    if soldier_revive_points__points != null && length(*soldier_revive_points__points) != 0
      assume revivePoints = *((*soldier_revive_points__points)[squadId] as Array)
      soldierRevivePoints = get_int(revivePoints[memberId]) ?? 100
    result = squadRevivePoints == 100 && soldierRevivePoints == 100
  return result
