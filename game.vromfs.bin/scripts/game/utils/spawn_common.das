module spawn_common shared
require ecs
require pathfinder
require Dacoll
require DagorMath
require math
require math.base


def trace_binary_search(pos : float3; max_ht : float; err_term : float)
  var outNorm = float3()
  var outHitT = max_ht - pos.y
  let dir = float3(0.0, -1.0, 0.0)
  let start = float3(pos.x, (max_ht + pos.y) * 0.5, pos.z)

  if traceray_normalized(start, dir, outHitT, outNorm)
    let resHt = (max_ht + pos.y) * 0.5 - outHitT
    if resHt - pos.y < err_term
      return float3(pos.x, resHt, pos.z)
    return trace_binary_search(pos, resHt, err_term)
  return float3(pos.x, max_ht, pos.z)

def trace_search(pos : float3; top_offs : float)
  var outHitT = top_offs
  let dir = float3(0.0, -1.0, 0.0)

  if !rayhit_normalized(pos, dir, outHitT, ETF_DEFAULT, -1)
    let startDirect = float3(0.0, top_offs, 0.0)
    var outNorm = float3()

    if traceray_normalized(pos + startDirect, dir, outHitT, outNorm)
      let errTerm = 0.4
      if top_offs - outHitT > errTerm
        let maxHt = pos.y + top_offs - outHitT
        return trace_binary_search(pos, maxHt, errTerm)
  return pos

def validate_position(tm : float3x4; orig_pos : float3; horz_extents : float; isVehicle : bool = false) : float3x4
  var wishPos = tm[3]
  var outRayPos = wishPos
  let navExtents = float3(0.25, FLT_MAX, 0.25) //from quirrel bind
  traceray_navmesh(orig_pos, wishPos, navExtents, outRayPos)
  wishPos = trace_search(outRayPos, 1000.0)

  var outNavmeshPos = wishPos
  if isVehicle && pathfinder_is_loaded_ex(NM_EXT_1)
    let projRadius = 10.
    let projExtents = float3(projRadius, FLT_MAX, projRadius)
    let result = project_to_nearest_navmesh_point_no_obstacles_ex(NM_EXT_1, outNavmeshPos, projExtents)
  else
    let projExtents = float3(horz_extents, FLT_MAX, horz_extents)
    project_to_nearest_navmesh_point_no_obstacles(outNavmeshPos, projExtents)
    let pathExtents = float3(0.1, FLT_MAX, 0.1) //from quirrel bind
    outNavmeshPos = check_path(outNavmeshPos, wishPos, pathExtents, 0.5, 1.5, null, int(PolyFlag.POLYFLAG_GROUND) | int(PolyFlag.POLYFLAG_JUMP)) ? outNavmeshPos : wishPos

  var resTm : float3x4 = tm
  orthonormalize(resTm)
  resTm[3] = outNavmeshPos
  return resTm

def validate_tm(tm : float3x4; horz_extents : float = 0.75) : float3x4
  return validate_position(tm, tm[3], horz_extents)

def mk_spawn_params_by_team_impl(team : int; base_eid : EntityId; var params : Object)
  params |> set("baseEid", base_eid)
  params |> set("team", team)

  var tm = IDENT_TM
  var isValidated = false
  query(base_eid) <| $ [es] (transform : float3x4;
                             respbase__start_vel : float3 const?;
                             respbase__noSpawnImmunity : bool = false;
                             respbase__spawnImmunityTime : float const?;
                             respbase__shouldValidateTm : bool = true;
                             respbase__startVelDir : float3 const?;
                             respbase__startRelativeSpeed : float const?;
                             respbase__addTemplatesOnSpawn : StringList const?;
                             respbase__validated : bool = false)
    tm = transform
    isValidated = respbase__validated
    params |> set("transform", transform)
    if respbase__start_vel != null
      params |> set("start_vel", *respbase__start_vel)
    params |> set("noSpawnImmunity", respbase__noSpawnImmunity)
    if respbase__spawnImmunityTime != null
      params |> set("spawnImmunityTime", *respbase__spawnImmunityTime)
    params |> set("shouldValidateTm", respbase__shouldValidateTm)
    if respbase__startVelDir != null
      params |> set("startVelDir", *respbase__startVelDir)
    if respbase__startRelativeSpeed != null
      params |> set("startRelativeSpeed", *respbase__startRelativeSpeed)
    if respbase__addTemplatesOnSpawn != null
      params |> set("addTemplatesOnSpawn", *respbase__addTemplatesOnSpawn)
    params |> set("isValidated", isValidated)

  if !isValidated
    let validatedTm = validate_tm(tm, 0.75) //0.75 from default value
    params |> set("transform", validatedTm)


def update_team_score(team : int;
                      playerSpawnCount : int;
                      squadCostMult : int const?;
                      hasVehicle : bool;
                      playerEid : EntityId;
                      squadId : int)
  var customSquadCostMult = 1.
  if has(playerEid, "waveSpawnBot")
    return
  query(playerEid) <| $ [es] (squads__customSquadCost : Object)
    customSquadCostMult = get_float(squads__customSquadCost, string(squadId)) ?? 1.
  query() <| $ [es] (team__id : int;
                     team__squadSpawnCost : int;
                     team__memberEids : EidList;
                     team__maxMembersCount : int = -1;
                     team__vehicleSquadSpawnCost : int const? = null;
                     team__firstSpawnCostMul : float;
                     var team__score : float&)
    if team == team__id
      var membersCount = length(team__memberEids)
      assume maxMembersCount = team__maxMembersCount
      if maxMembersCount > 0 && membersCount > maxMembersCount
        membersCount = maxMembersCount
      if membersCount <= 0
        return
      let squadSpawnCost = hasVehicle ? (team__vehicleSquadSpawnCost ?? team__squadSpawnCost) : team__squadSpawnCost
      var spawnCost = ((squadCostMult != null ? float(*squadCostMult) : 1.0) * float(squadSpawnCost)) / float(membersCount)
      if playerSpawnCount == 0
        spawnCost *= team__firstSpawnCostMul
      if spawnCost > 0.0
        team__score = max(0.0, team__score - spawnCost * customSquadCostMult)

def can_spawn_player_squads(team : int;
                            playerSpawnCount : int)
  var canSpawn = false
  query() <| $ [es] (team__id : int;
                     team__eachSquadMaxSpawns : int)
    if team == team__id
      canSpawn = team__eachSquadMaxSpawns < 0 || playerSpawnCount < team__eachSquadMaxSpawns
  return canSpawn

def can_spawn_team_squads(team : int;
                          playerSpawnCount : int)
  var canSpawn = false
  query() <| $ [es] (team__id : int;
                     team__eachSquadMaxSpawns : int;
                     team__squadsCanSpawn : bool)
    if team == team__id
      canSpawn = team__squadsCanSpawn && team__eachSquadMaxSpawns < 0 || playerSpawnCount < team__eachSquadMaxSpawns
  return canSpawn
