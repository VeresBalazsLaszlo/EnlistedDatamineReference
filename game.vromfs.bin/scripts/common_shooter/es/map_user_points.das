require ecs
require DngNet
require game.es.events
require game.utils.net_utils
require common_shooter.events_common_shooter
require ecs.common
require DagorSystem
require DagorMath
require math.base
require app
require strings
require DngHuman
require DngWeapon
require AnimV20
require game.utils.team
require GeomNodeTree
require DagorMathUtils
require Grid
require GridCollision
require CollisionTraces
require Dacoll
require PhysMat
require CollRes
require SmokeOccluder
require game.events_game
require game.es.awards_common
require game.utils.team
require enlisted.game.es.offender_cache_common

struct PointsStruct
  eid : EntityId = INVALID_ENTITY_ID
  time : float

def delete_player_points(var points : array<PointsStruct>; count : int)
  if count <= 0
    for point in points
      send_net_event(point.eid, CmdDeleteMapUserPoint())
  elif length(points) > count
    let numPoints = length(points) - count
    for _i in range(numPoints)
      var first = 0
      for j in range(1, length(points))
        if points[j].time < points[first].time
          first = j
      if points[first].eid != INVALID_ENTITY_ID
        send_net_event(points[first].eid, CmdDeleteMapUserPoint())
        erase(points, first)

[es(tag=server, on_appear)]
def map_user_point_init_es(evt : Event;
                           eid : EntityId;
                           userPointOwner : EntityId;
                           pointGroup : int;
                           timer__start : float;
                           timer__delta : float;
                           timer__deltaLongMult : float = 1.;
                           var timer__destroy : float&;
                           countPoint : int = 1)
  timer__destroy = timer__start + timer__delta * timer__deltaLongMult

  let renameUserPointOwner = userPointOwner
  let renameEid = eid
  let renamePointGroup = pointGroup
  var points : array<PointsStruct>

  query() <| $ [es] (eid : EntityId;
                     userPointOwner : EntityId;
                     timer__start : float;
                     pointGroup : int)
    if userPointOwner == renameUserPointOwner && eid != renameEid && pointGroup == renamePointGroup
      points |> emplace(PointsStruct(
        eid = eid,
        time = timer__start
      ))

  delete_player_points(points, countPoint - 1)

def get_mark_object(user_points : Object; name : string; templateName : string)
  let objRef = get_ecs_object(user_points, name)
  if objRef == null
    logerr("user mark /*{name}*/ not found in user_points object created from template /*{templateName}*/")
  return objRef

def is_cooldown(var last_time : float&;
                cooldown : float;
                var mark_count : int&;
                mark_limit : int)
  let curTime =  get_sync_time()
  let dt = curTime - last_time
  mark_count = max(0, mark_count - roundi(safediv(dt, cooldown)))
  if mark_count > mark_limit
    return true
  last_time = curTime
  mark_count++
  return false

def private is_human_visible(from : float3;
                             ray_tolerance : float;
                             transform : float3x4;
                             animchar : AnimcharBaseComponent;
                             collres : CollisionResource)
  let nodeCount = collres_get_nodesCount(collres)
  for i in range(nodeCount)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, i, transform, animchar.nodeTree, nodeTm)
    let to = nodeTm * collres_get_node_bbox(collres, i).center
    var dir = to - from
    let t = length(dir)
    dir *= safeinv(t)
    if t > ray_tolerance && rayhit_normalized(from, dir, t - ray_tolerance, ETF_DEFAULT, -1)
      continue
    return true
  return false

def find_enemy_on_ray(trace_pos : float3;
                      trace_dir : float3;
                      var dist : float&;
                      cylinder_rad : float;
                      max_angle_cos : float;
                      local_team : int;
                      skip_dead : bool)
  var bestEid = INVALID_ENTITY_ID
  var bestDot = max_angle_cos

  for_each_entity_in_grid(ecs_hash("humans"), trace_pos, trace_dir, dist, cylinder_rad, GridEntCheck.BOUNDING) <| $(eid : EntityId; pos : float3)
    query(eid) <| $ [es] (team : int;
                          transform : float3x4;
                          animchar : AnimcharBaseComponent;
                          collres : CollisionResource;
                          isAlive : bool = true)
      if skip_dead && !isAlive
        return
      if is_teams_friendly(team, local_team)
        return
      if team == TEAM_UNASSIGNED
        return

      let dirToHuman = pos - trace_pos
      let distToHuman = length(dirToHuman)
      if distToHuman > dist
        return
      let dir = dirToHuman * safeinv(distToHuman)
      let dirDot = dot(dir, trace_dir)
      if dirDot < bestDot
        return
      if is_human_visible(trace_pos, 0.2f, transform, animchar, collres)
        bestEid = eid
        dist = distToHuman
        bestDot = dirDot
  return bestEid

def find_building_on_ray(player_team : int;
                         trace_pos : float3;
                         trace_dir : float3;
                         max_dist : float)
  var buildingEid = INVALID_ENTITY_ID
  var len = max_dist
  var norm : float3
  var pmid : int
  var riDesc = RendInstDesc()
  traceray_normalized(trace_pos, trace_dir, len, pmid, norm, ETF_DEFAULT, riDesc, -1)
  let trace_to = trace_pos + trace_dir * len
  query() <| $ [es(REQUIRE_NOT=(builder_preview, user_point__ignore))] (eid : EntityId;
                                                                        transform : float3x4;
                                                                        buildingRadius : float;
                                                                        building_menu__image : string;
                                                                        isAlive : bool = true;
                                                                        team : int = TEAM_UNASSIGNED;
                                                                        builder_info__team : int = TEAM_UNASSIGNED;
                                                                        build__markForAllTeams : Tag const?)
    let currentTeam = team != TEAM_UNASSIGNED ? team : builder_info__team
    if empty(building_menu__image) || !isAlive || (build__markForAllTeams == null && is_teams_friendly(currentTeam, player_team))
      return
    if test_segment_sphere_intersection(trace_pos, trace_to, transform[3], buildingRadius)
      buildingEid = eid
  return buildingEid

def find_vehicle_on_ray(player_team : int;
                        var pos_mark : float3&;
                        var vehicle_eid : EntityId&;
                        var point_on_vehicle : bool&;
                        selected_vehicle : EntityId;
                        trace_pos : float3;
                        trace_dir : float3;
                        max_dist : float;
                        aim_ray_mat_id : int)
  var found = false
  var t = max_dist
  trace_entities_in_grid(ecs_hash("vehicles"), trace_pos, trace_dir, t, INVALID_ENTITY_ID, SortIntersections.YES) <| $(intersections : array<IntersectedEntity>#)
    for it in intersections
      if selected_vehicle == it.eid
        continue
      query(it.eid) <| $ [es] (isAlive : bool = false; team = TEAM_UNASSIGNED; user_point__attachWithOffset : Tag const?)
        let ray_tolerance = 0.2f
        if it.t <= ray_tolerance || !rayhit_normalized(trace_pos, trace_dir, it.t - ray_tolerance, ETF_DEFAULT, aim_ray_mat_id)
          found = true
          pos_mark = trace_pos + trace_dir * it.t
          point_on_vehicle = user_point__attachWithOffset != null
          if (isAlive && !is_teams_friendly(team, player_team)) || point_on_vehicle
            vehicle_eid = it.eid
      if found
        break

  return !!vehicle_eid

def find_vehicle_around(player_team : int;
                        var pos_mark : float3&;
                        var vehicle_eid : EntityId&;
                        trace_pos : float3;
                        trace_dir : float3;
                        max_dist : float;
                        box_mult : float)
  var minDist = -1.
  let traceStopPos = trace_pos + trace_dir * max_dist
  query() <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=deadEntity, REQUIRE_NOT=airplane)] (eid : EntityId;
                                                                                    transform : float3x4;
                                                                                    team : int;
                                                                                    collres : CollisionResource)
    if team == TEAM_UNASSIGNED || is_teams_friendly(team, player_team)
      return

    var intersection = false
    using() <| $(var box : bbox3f#)
      var bbox = transform * BBox3(collres.vFullBBox.bmin.xyz, collres.vFullBBox.bmax.xyz)
      bbox |> bbox3_inflate(box_mult)
      box.bmax = float4(bbox.boxMax.x, bbox.boxMax.y, bbox.boxMax.z, 1.)
      box.bmin = float4(bbox.boxMin.x, bbox.boxMin.y, bbox.boxMin.z, 1.)
      intersection = v_test_segment_box_intersection(trace_pos, traceStopPos, box) != 0

    if !intersection
      return

    let dist = length_sq(transform[3] - trace_pos)
    if minDist < 0. || dist < minDist
      minDist = dist
      vehicle_eid = eid
      pos_mark = transform[3]
  return !!vehicle_eid

def get_custom_mark_object(enemy_mark : Object; user_points : Object; mark_name : string)
  let fallbackMark = get_string(enemy_mark, "findEnemyNewMark", "")
  let mark = get_string(enemy_mark, mark_name, fallbackMark)
  return get_ecs_object(user_points, mark)

def create_map_user_point(point_type : string;
                          var pos : float3;
                          norm : float3;
                          eid : EntityId;
                          team : int;
                          obj : Object;
                          silent : bool;
                          livetime_mult : float;
                          mark_owner_eid : EntityId;
                          award_name : string;
                          stat_name : string;
                          attr : block<(var compInit : ComponentsInitializer) : void>)
  if length_sq(pos) == 0.f
    return INVALID_ENTITY_ID
  let templateName = get_string(obj, "templateName", "")
  if empty(templateName)
    return INVALID_ENTITY_ID

  let curTime = get_sync_time()
  pos.y += get_float(obj, "yOffset") ?? 0.f

  return createEntity(templateName) <| $(init)
    var tm = IDENT_TM
    if length_sq(norm) > FLT_EPSILON
      make_tm(dir_to_quat(norm), tm)
    tm[3] = pos
    invoke(attr, init)
    init |> set("transform", tm)
    init |> set("team", team)
    init |> set("userPointOwner", eid)
    init |> set("userPointOwnerGuid", get_string(mark_owner_eid, "guid", ""))
    init |> set("userPointType", point_type)
    init |> set("timer__start", curTime)
    init |> set("silentAppearance", silent)
    init |> set("userPointAward", award_name)
    init |> set("userPointStat", stat_name)
    init |> set("timer__deltaLongMult", livetime_mult)

[es(tag=server, REQUIRE=player)]
def map_user_point_create_es(evt : CmdCreateMapUserPoint;
                             team : int;
                             eid : EntityId;
                             possessed : EntityId;
                             user_points : Object;
                             var lastSetMarkTime : float&;
                             setMarkCooldown : float;
                             var lastMarkCount : int&;
                             setMarkLimit : int;
                             markerAroundBoxMult : float = 5f;
                             markerAroundMaxDist : float = 8000f;
                             marker__enemyDetectMaxDistance : float = 250f)
  if is_cooldown(lastSetMarkTime, setMarkCooldown, lastMarkCount, setMarkLimit)
    return
  var pos = evt.pos

  let templateName = getEntityTemplateName(eid)

  var obj = get_mark_object(user_points, evt.item_name, templateName)
  if null == obj
    return

  var buildingEid = INVALID_ENTITY_ID
  var userPointCustomIcon : string
  var userPointVehicleTarget : EntityId = INVALID_ENTITY_ID
  var pointOnVehicle = false
  var awardName = ""
  var statName = ""

  if has(*obj, "findEnemy")
    var isInAirplane = false
    var vehicleSelected = INVALID_ENTITY_ID
    var enemyDetectMaxDistance = marker__enemyDetectMaxDistance
    var humanCurrentGunEid = INVALID_ENTITY_ID
    var aimPos = float3() // fail-closed clamp anchor: if the possessed query below misses, stay server-side rather than trusting evt.traceStart
    var originSpeed = 0.0
    query(possessed) <| $ [es] (human__aimTm : float3x4;
                                human_weap__currentGunEid : EntityId;
                                human_anim__vehicleSelected : EntityId;
                                human_net_phys__velocity : float3 = float3())
      aimPos = human__aimTm[3]
      humanCurrentGunEid = human_weap__currentGunEid
      isInAirplane = has(human_anim__vehicleSelected, "airplane")
      vehicleSelected = human_anim__vehicleSelected
      originSpeed = length(human_net_phys__velocity)
      // in a vehicle also fold in the vehicle's own velocity as a backstop
      query(human_anim__vehicleSelected) <| $ [es] (marker__enemyDetectMaxDistance : float = 300f;
                                                    net_phys__currentStateVelocity : float3 = float3())
        enemyDetectMaxDistance = marker__enemyDetectMaxDistance
        originSpeed = max(originSpeed, length(net_phys__currentStateVelocity))

    // Anti-cheat: clamp the client-supplied traceStart near the aim point (evt.dir is already client-chosen); widen
    // by speed * ORIGIN_LAG so a fast vehicle's client/server position gap isn't clamped as tampering.
    let MAX_ORIGIN_OFFSET = 5.0
    let ORIGIN_LAG = 0.5
    let maxOriginOffset = max(MAX_ORIGIN_OFFSET, originSpeed * ORIGIN_LAG)
    var traceStart = evt.traceStart
    let originOffset = traceStart - aimPos
    let originDist = length(originOffset)
    if !is_finite(originDist)
      traceStart = aimPos // reject a non-finite client origin outright
    elif originDist > maxOriginOffset
      traceStart = aimPos + originOffset * (maxOriginOffset / originDist)

    var aimRayMatId = PHYSMAT_INVALID
    query(humanCurrentGunEid) <| $ [es] (gun__aimRayMatId : int)
      aimRayMatId = gun__aimRayMatId

    let enemyDetectDegree = get_float(obj, "enemyDetectAngle") ?? 0.5f
    let enemyDetectCos = cos(deg_to_rad(enemyDetectDegree))
    let enemyDetectCylinderRad = get_float(obj, "enemyDetectCylinderRad") ?? 0.4f
    let traceDir = evt.dir
    let skipDead = get_bool(obj, "skipDead") ?? false
    let enemyEid = find_enemy_on_ray(traceStart, traceDir, enemyDetectMaxDistance, enemyDetectCylinderRad, enemyDetectCos, team, skipDead)
    if enemyEid != INVALID_ENTITY_ID
      pos = traceStart + traceDir * enemyDetectMaxDistance
      let findEnemyMark = get_string(obj, "findEnemyNewMark", "")
      if !empty(findEnemyMark)
        let newObj = get_ecs_object(user_points, findEnemyMark)
        if newObj != null
          obj = newObj
    buildingEid = find_building_on_ray(team, traceStart, traceDir, enemyDetectMaxDistance)
    var vehicleEid = INVALID_ENTITY_ID
    if buildingEid != INVALID_ENTITY_ID
      query(buildingEid) <| $ [es] (transform : float3x4; building_menu__image : string; spotDestroyStatName : string = "buildingSpot")
        awardName = "building_spots"
        statName = spotDestroyStatName
        pos = transform[3]
        userPointCustomIcon = building_menu__image
        let newObj = get_custom_mark_object(*obj, user_points, "findEnemyBuildingNewMark")
        if newObj != null
          obj = newObj
    elif (isInAirplane
      ? find_vehicle_around(team, pos, vehicleEid, traceStart, traceDir, markerAroundMaxDist, markerAroundBoxMult)
      : find_vehicle_on_ray(team, pos, vehicleEid, pointOnVehicle, vehicleSelected, traceStart, traceDir, enemyDetectMaxDistance, aimRayMatId))
      query(vehicleEid) <| $ [es] (user_point__icon : string; spotDestroyStatName : string = "")
        userPointCustomIcon = user_point__icon
        awardName = "vehicle_spots"
        statName = spotDestroyStatName
      let newTemplateName = pointOnVehicle ? "findEnemyPointOnVehicleNewMark" : "findEnemyVehicleNewMark"
      let newObj = get_custom_mark_object(*obj, user_points, newTemplateName)
      if newObj != null
        userPointVehicleTarget = vehicleEid
        obj = newObj
    if rayhit_smoke_occluders(traceStart, pos)
      return

  if has(possessed, "spy_soldier") && (!!buildingEid || !!userPointVehicleTarget)
    var alreadyMarked = false
    let targetEid = !!buildingEid ? buildingEid : userPointVehicleTarget
    find_query() <| $ [es] (userPointTarget : EntityId = INVALID_ENTITY_ID;
                            userPointVehicleTargetEid : EntityId = INVALID_ENTITY_ID;
                            userPointOwner : EntityId)
      if userPointOwner == eid && (userPointTarget == targetEid || userPointVehicleTargetEid == targetEid)
        alreadyMarked = true
      return alreadyMarked
    if alreadyMarked
      return

  var liveTimeMult = 1.
  query(possessed) <| $ [es] (guid : string; spy_soldier__markLiveTimeMult : float)
    liveTimeMult = spy_soldier__markLiveTimeMult
    if awardName != ""
      add_award(eid, "{awardName}Spy")
    if statName != ""
      send_award_stat(eid, guid, "{statName}Spy")

  if evt.withBinocular
    query(eid) <| $ [es] (itemContainer : EidList)
      for itemEid in itemContainer
        if has(itemEid, "binocular")
          liveTimeMult *= 1.3
          return

  create_map_user_point(evt.item_name, pos, evt.norm, eid, team, *obj, false, liveTimeMult, evt.markOwnerEid, awardName, statName) <| $(var init : ComponentsInitializer)
    if !empty(userPointCustomIcon)
      set(init, "userPointCustomIcon", userPointCustomIcon)
    if !!buildingEid
      set(init, "userPointTarget", buildingEid)
    query(userPointVehicleTarget) <| $ [es] (transform : float3x4)
      set(init, "userPointVehicleTargetEid", userPointVehicleTarget)
      if pointOnVehicle
        set(init, "userPointVehicleOffset", pos - transform[3])

[es(tag=server)]
def marked_vehicle_kill_award(evt : EventAnyEntityDied)
  query(evt.victim) <| $ [es] (eid : EntityId;
                               team : int)
    if is_teams_friendly((get_int(evt.offender, "team") ?? TEAM_UNASSIGNED), team)
      return

    find_query() <| $ [es] (userPointVehicleTargetEid : EntityId const?; userPointTarget : EntityId const?; userPointOwner : EntityId; userPointOwnerGuid : string; userPointAward : string; userPointStat : string)
      if (userPointVehicleTargetEid ?? INVALID_ENTITY_ID) != eid && (userPointTarget ?? INVALID_ENTITY_ID) != eid
        return false

      if userPointOwner == evt.offenderPlayer
        return true

      if userPointAward != ""
        add_award(userPointOwner, userPointAward)
      if userPointStat != ""
        send_award_stat(userPointOwner, userPointOwnerGuid, userPointStat)
      return true