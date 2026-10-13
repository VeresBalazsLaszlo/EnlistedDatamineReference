require ecs
require ecs.safe
require app
require pathfinder
require danetlibs.pathfinder.main.pathfinder_common
require danetlibs.dm.dm_events
require game.events_game
require enlisted.events_enlisted
require enlisted.game.es.ai_poly_areas_common
require DagorRandom
require DagorMath
require DagorMathUtils
require math.base
require math.random
require math
require Dacoll
require BallisticsProps
require DaWeaponProps
require turrets
require common_shooter.es.forestall_common
require common_shooter.events_common_shooter
require common_shooter.es.weapon.turret_common
require game.utils.team
require walkerai
require AnimV20
require GeomNodeTree
require vehicle
require Grid
require SmokeOccluder
require Gun
require game.es.dm_ai_common
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require game.es.ai.enlisted_combat_ai_common
require game.es.ai.timer_common
require game.es.player_events

let TANK_POS_OFFSETS_TO_CHECK_NAVMESH = fixed_array<float3>(float3(0.0, 0.0, 0.0), float3(0.5, 0.0, 0.0), float3(-0.5, 0.0, 0.0), float3(0.0, 0.0, 0.5), float3(0.0, 0.0, -0.5))

let TANK_DIST_MULT_FOR_DANGERS = 1.3


let DEFAULT_TANK_MAX_SPEED = 10.0
let DEFAULT_TANK_TURN_SPEED = 0.5
let DEFAULT_TANK_FORWARD_SPEED = 5.0
let DEFAULT_TANK_BACKWARD_SPEED = 3.5


struct AiTankMotionSpecs
  maxSpeed : float
  turnSpeed : float
  forwardSpeed : float
  backwardSpeed : float


enum AiTankTargetType
  HUMAN
  VEHICLE


enum AiTankMotionState
  STAND_BY
  MOVE_FORWARD_STRAIGHT
  MOVE_BACKWARD_STRAIGHT
  MOVE_FORWARD_TO_POINT
  MOVE_BACKWARD_TO_POINT
  MOVE_FORWARD_FROM_POINT
  MOVE_BACKWARD_FROM_POINT
  TURN_TO_POINT


enum AiTankMotionStateFlags
  MOVE_TO_POINT = (1 << int(AiTankMotionState.MOVE_FORWARD_TO_POINT)) | (1 << int(AiTankMotionState.MOVE_BACKWARD_TO_POINT))
  MOVE_FROM_POINT = (1 << int(AiTankMotionState.MOVE_FORWARD_FROM_POINT)) | (1 << int(AiTankMotionState.MOVE_BACKWARD_FROM_POINT))
  MOVE_FORWARD = (1 << int(AiTankMotionState.MOVE_FORWARD_TO_POINT)) | (1 << int(AiTankMotionState.MOVE_FORWARD_FROM_POINT)) | (1 << int(AiTankMotionState.MOVE_FORWARD_STRAIGHT))
  MOVE_BACKWARD = (1 << int(AiTankMotionState.MOVE_BACKWARD_TO_POINT)) | (1 << int(AiTankMotionState.MOVE_BACKWARD_FROM_POINT)) | (1 << int(AiTankMotionState.MOVE_BACKWARD_STRAIGHT))
  MOVE_RELATIVE_TO_POINT = int(AiTankMotionStateFlags.MOVE_TO_POINT) | int(AiTankMotionStateFlags.MOVE_FROM_POINT)


enum AiTankThinkState
  STAND_BY
  STAND_AND_TARGET

  ADVANCE_AND_UPDATE_DESTINATION
  ADVANCE_AND_UPDATE_PATH
  ADVANCE_AND_PATH_FOUND

  GET_UNSTUCK
  EXIT_OBSTACLE
  AVOID_DANGERS


enum AiTankThinkStateFlags
  STAND = (1 << int(AiTankThinkState.STAND_BY)) | (1 << int(AiTankThinkState.STAND_AND_TARGET))
  ADVANCE = (1 << int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION)) | (1 << int(AiTankThinkState.ADVANCE_AND_UPDATE_PATH)) | (1 << int(AiTankThinkState.ADVANCE_AND_PATH_FOUND))


enum AiTankShootState
  READY                           //the turret is not shooting
  BURST                           //the turret started shooting
  SHORT_PAUSE                     //short pause after a burst
  LONG_PAUSE                      //long pause after a few bursts


enum AiTankTargetState
  IDLE                            //the turret is not targetting anyone
  TARGET                          //the turret is targetting someone
  TARGET_FAILURE                  //the turret is targetting someone, but can't take a good aim right now (e. g. it cannot see weak points on enemy tank)

//Explanation for timers and TimerOutput values
//Note: TIMEOUT_3 and TIMEOUT_4 are not used anywhere, but this might change in the future
//----------------------------------
//ai_vehicle_tank__timerOutsideNavmesh
//TIMEOUT_1: the tank has been outside the navmesh for too long, so it is probably hopelessly stuck => kick out the crew
//---
//ai_vehicle_tank__timerInsideObstacle
//TIMEOUT_1: the tank has been inside an obstacle for too long => try to exit the obstacle
//TIMEOUT_2: the tank has been inside an obstacle for WAY too long, so the tank is hopelessly stuck => kick out the crew
//---
//ai_vehicle_tank__timerOutsideObstacle
//TIMEOUT_1: the tank was inside an obstacle long enough time ago => stop exiting the obstacle and do something else
//           (the tank is free to roam now)
//---
//ai_vehicle_tank__timerNextPosition
//TIMEOUT_1: the tank cannot reach the next position in its path, so it is probably stuck => try to get unstuck
//--
//ai_vehicle_tank__timerObjectiveBoredom
//TIMEOUT_1: the tank has not been killing a lot of enemies recently, so its current location is not good => choose another destination to go to
//--
//ai_vehicle_tank__timerGeneralBoredom
//TIMEOUT_1: the tank has not been killing a lot of enemies recently (for a long time), so it is useless => kick out the crew
//--
//ai_vehicle_tank__timerExit
//TIMEOUT_1: time to kick the crew (we need this timer so that crew doesn't get kicked immediately after the conditions for kicking are met)
//---
//ai_vehicle_tank__timerThinkState
//TIMEOUT_1 for think state ADVANCE_AND_UPDATE_PATH: the tank could not find a new path to its current destination in the given time =>
//          set think state to ADVANCE_AND_UPDATE_DESTINATION (if the current destination is unreachable, let's choose another one)
//TIMEOUT_1 for think state ADVANCE_AND_UPDATE_DESTINATION: the tank could not find the path to any objective in the given time =>
//          kick out the crew
//TIMEOUT_1 for think state GET_UNSTUCK: the tank has been trying to get unstuck for long enough =>
//          set think state to ADVANCE_AND_FOUND_PATH (hopefully the tank got unstuck and can try moving along the path again)
//Other think states do not use this timer


def update_tank_next_position(tank_transform : float3x4;
                              planned_path : Point3List;
                              max_step_size : float;
                              tank_specs : AiTankMotionSpecs;
                              var next_position : float3&;
                              var recorded_min_distance : float&;
                              var motion_state : int&)
  recorded_min_distance = FLT_MAX
  if length(planned_path) == 1
    next_position = planned_path[0]
  elif !empty(planned_path)
    let diff = planned_path[1] - planned_path[0]
    let lenSq = length_sq(diff)
    if lenSq <= square(max_step_size)
      next_position = 0.5 * (planned_path[0] + planned_path[1]) // this averaging helps the tank take smoother turns
    else
      let dir = diff / sqrt(lenSq)
      next_position = planned_path[0] + 0.5 * max_step_size * dir
  var approxPathLength = 0.0
  if length(planned_path) > 0
    approxPathLength += distance(tank_transform[3], planned_path[0])
  if length(planned_path) > 1
    approxPathLength += distance(planned_path[0], planned_path[1]) * float(length(planned_path) - 1)
  choose_forward_or_backward_motion_state(tank_transform, next_position, approxPathLength, tank_specs, motion_state)


def erase_reached_points_in_path(tank_pos : float3; count : int; threshold : float; var path : Point3List&)
  let pointCount = min(count, length(path))
  for a in range(pointCount)
    let i = pointCount - a - 1
    if length_sq(path[i] - tank_pos) <= square(threshold)
      path |> erase(0, i + 1)
      return true
  return false


[es(tag=server, before=ai_vehicle_tank_next_position_reached_es, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_turn_to_target_es(info : ParallelUpdateFrameDelayed;
                                      turret_control__gunEids : EidList;
                                      var ai_vehicle_tank__motionTurnToPoint : float3&;
                                      var ai_vehicle_tank__motionTurnReferenceDirection : float3&)
  if empty(turret_control__gunEids)
    return

  query(turret_control__gunEids[0]) <| $ [es(REQUIRE=controlledByTankAiGunner)] (turret_aim__shootToPos : float3; turret_state : TurretState)
    ai_vehicle_tank__motionTurnToPoint = turret_aim__shootToPos
    ai_vehicle_tank__motionTurnReferenceDirection = turret_state.shoot.dir


[es(tag=server, before=ai_vehicle_tank_driver_es, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_next_position_reached_es(info : ParallelUpdateFrameDelayed;
                                             transform : float3x4;
                                             ai_vehicle_tank__maxStepSize : float;
                                             ai_vehicle_tank__nextPositionReachedThreshold : float;
                                             var ai_vehicle_tank__plannedPath : Point3List&;
                                             var ai_vehicle_tank__nextPosition : float3&;
                                             var ai_vehicle_tank__nextPositionRecordedMinDistance : float&;
                                             var ai_vehicle_tank__motionState : int&;
                                             ai_vehicle_tank__maxSpeed : float = DEFAULT_TANK_MAX_SPEED;
                                             ai_vehicle_tank__turnSpeed : float = DEFAULT_TANK_TURN_SPEED;
                                             ai_vehicle_tank__forwardSpeed : float = DEFAULT_TANK_FORWARD_SPEED;
                                             ai_vehicle_tank__backwardSpeed : float = DEFAULT_TANK_BACKWARD_SPEED)
  if empty(ai_vehicle_tank__plannedPath)
    return

  let diff = ai_vehicle_tank__nextPosition - transform[3]
  if length_sq(diff) <= square(ai_vehicle_tank__nextPositionReachedThreshold)
    ai_vehicle_tank__plannedPath |> erase(0)
    let tankSpecs = AiTankMotionSpecs(maxSpeed = ai_vehicle_tank__maxSpeed, turnSpeed = ai_vehicle_tank__turnSpeed,
      forwardSpeed = ai_vehicle_tank__forwardSpeed, backwardSpeed = ai_vehicle_tank__backwardSpeed)
    update_tank_next_position(transform,
                              ai_vehicle_tank__plannedPath,
                              ai_vehicle_tank__maxStepSize,
                              tankSpecs,
                              ai_vehicle_tank__nextPosition,
                              ai_vehicle_tank__nextPositionRecordedMinDistance,
                              ai_vehicle_tank__motionState)


def choose_forward_or_backward_motion_state(transform : float3x4;
                                            next_position : float3;
                                            path_length : float;
                                            tank_specs : AiTankMotionSpecs;
                                            var motion_state : int&)
  if motion_state != int(AiTankMotionState.MOVE_FORWARD_TO_POINT) && motion_state != int(AiTankMotionState.MOVE_BACKWARD_TO_POINT)
    return

  let diff = next_position - transform[3]
  let distance = length(diff)

  if distance == 0.0
    return

  let wishDir = diff / distance
  let wishAngles = dir_to_angles(wishDir)
  let moveAngles = dir_to_angles(transform[0])
  let angle = abs(norm_s_ang(wishAngles.x - moveAngles.x))
  let timeForward = angle / tank_specs.turnSpeed + path_length / tank_specs.forwardSpeed
  let timeBackward = norm_s_ang(PI - angle) / tank_specs.turnSpeed + path_length / tank_specs.backwardSpeed

  motion_state = timeForward < timeBackward ? int(AiTankMotionState.MOVE_FORWARD_TO_POINT) : int(AiTankMotionState.MOVE_BACKWARD_TO_POINT)


def tank_turning(ang : float; turn_step : float; move_forward : bool; var brake : float&; var throttle : float&; var steering : float&)
  let turnForward = abs(ang) % (2.0 * turn_step) < turn_step == move_forward
  brake = 0.0
  if turnForward
    throttle = 1.0
    steering = -sign(ang)
  else
    throttle = -1.0
    steering = sign(ang)


def is_point_inside_passable_navmesh(point : float3; horz_dist : float = 0.5)
  var triangle : NavMeshTriangle
  if get_triangle_by_pos_ex(NM_EXT_1, point, horz_dist, triangle)
    var flags : uint16
    get_poly_flags_ex(NM_EXT_1, triangle.polyRef, flags)
    if (uint(flags) & uint(EnlPolyFlags.POLYFLAG_TANK_OBSTACLE)) == 0u
      return true
  return false


def slow_down_before_obstacles(should_update : bool;
                               update_interval : float;
                               tank_eid : EntityId;
                               tank_team : int;
                               transform : float3x4;
                               throttle : float;
                               impatience_inc_speed : float;
                               impatience_dec_speed : float;
                               distance_to_obstacle_threshold : float2;
                               shift_to_obstacle_threshold : float;
                               throttle_mult_to_brake_inc : float2;
                               var min_distance_to_obstacle : float&;
                               var impatience : float&;
                               var throttle_mult : float&;
                               var brake_inc : float&)
  if throttle == 0.0
    impatience = 0.0
    min_distance_to_obstacle = FLT_MAX
  elif should_update
    min_distance_to_obstacle = FLT_MAX
    let isMovingForward = throttle > 0.0
    var isVehicleInTheWay = false
    for_each_entity_in_grid(fixed_array(ecs_hash("humans"), ecs_hash("vehicles")), BSphere3(transform[3], distance_to_obstacle_threshold[1]), GridEntCheck.BOUNDING) <| $(target_eid : EntityId)
      query(target_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (team aka other_team : int;
                                                           ai_target : Target;
                                                           ai_target__type : int = int(AiTankTargetType.HUMAN);
                                                           isInVehicle : bool = false)
        if tank_eid == target_eid || isInVehicle || (ai_target__type == int(AiTankTargetType.HUMAN) && !is_teams_friendly(tank_team, other_team))
          return
        let diff = ai_target.targetPos - transform[3]
        let distance = dot(diff, transform[0])
        if (isMovingForward ? distance : -distance) <= 0.0
          return
        let shift = sqrt(length_sq(diff) - distance * distance)
        if shift > shift_to_obstacle_threshold
          return

        let absDistance = abs(distance)
        var navmeshCheck = false
        var isTargetInsidePassableNavmesh = false

        if absDistance < min_distance_to_obstacle
          navmeshCheck = true
          isTargetInsidePassableNavmesh = is_point_inside_passable_navmesh(ai_target.targetPos)
          if isTargetInsidePassableNavmesh
            min_distance_to_obstacle = absDistance

        if (!isVehicleInTheWay && absDistance < distance_to_obstacle_threshold[1] && ai_target__type == int(AiTankTargetType.VEHICLE) &&
            (isTargetInsidePassableNavmesh || (!navmeshCheck && is_point_inside_passable_navmesh(ai_target.targetPos))))
          isVehicleInTheWay = true

    if isVehicleInTheWay
      impatience = 0.0
    elif min_distance_to_obstacle == FLT_MAX
      impatience -= impatience_dec_speed * update_interval
    else
      impatience += impatience_inc_speed * update_interval
    impatience = clamp(impatience, 0.0, 1.0)

  throttle_mult = cvt(min_distance_to_obstacle, distance_to_obstacle_threshold[0], distance_to_obstacle_threshold[1], impatience, 1.0)
  brake_inc = cvt(throttle_mult, throttle_mult_to_brake_inc[0], throttle_mult_to_brake_inc[1], 1.0, 0.0)


[es(tag=server, before=vehicle_input_driver_es, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_driver_es(info : ParallelUpdateFrameDelayed;
                              eid : EntityId;
                              team : int;
                              transform : float3x4;
                              ai_vehicle_tank__nextUpdateAt : float;
                              ai_vehicle_tank__updateInterval : float;
                              ai_vehicle_tank__maxThrottle : float;
                              ai_vehicle_tank__steeringStep : float;
                              ai_vehicle_tank__steeringDeadZone : float;
                              ai_vehicle_tank__steeringSmoothness : float;
                              ai_vehicle_tank__nextPositionReachedThreshold : float;
                              ai_vehicle_tank__plannedPathLengthForSlowingDown : int;
                              ai_vehicle_tank__motionTurnToPoint : float3;
                              ai_vehicle_tank__motionTurnReferenceDirection : float3;
                              ai_vehicle_tank__motionState : int;
                              ai_vehicle_tank__plannedPath : Point3List;
                              ai_vehicle_tank__nextPosition : float3;
                              ai_vehicle_tank__runOverImpatienceIncSpeed : float;
                              ai_vehicle_tank__runOverImpatienceDecSpeed : float;
                              ai_vehicle_tank__distanceToObstacleThreshold : float2;
                              ai_vehicle_tank__shiftToObstacleThreshold : float;
                              ai_vehicle_tank__throttleMultToBrakeInc : float2;
                              var ai_vehicle_tank__runOverImpatience : float&;
                              var ai_vehicle_tank__minDistanceToObstacle : float&;
                              var vehicle_net_phys : VehiclePhysActor&)
  var steering = 0.0
  var throttle = 0.0
  var brake = 1.0
  let motionStateAsFlag = 1 << ai_vehicle_tank__motionState
  let moveForward = (motionStateAsFlag & int(AiTankMotionStateFlags.MOVE_FORWARD)) != 0

  if ai_vehicle_tank__motionState == int(AiTankMotionState.MOVE_FORWARD_STRAIGHT)
    throttle = 1.0
    brake = 0.0
  elif ai_vehicle_tank__motionState == int(AiTankMotionState.MOVE_BACKWARD_STRAIGHT)
    throttle = -1.0
    brake = 0.0
  elif (motionStateAsFlag & int(AiTankMotionStateFlags.MOVE_RELATIVE_TO_POINT)) != 0
    let diff = ai_vehicle_tank__nextPosition - transform[3]
    let distSq = length_sq(diff)

    if !empty(ai_vehicle_tank__plannedPath) || distSq > square(ai_vehicle_tank__nextPositionReachedThreshold)
      var wishDir = diff
      wishDir.y = 0.0
      if ai_vehicle_tank__motionState == int(AiTankMotionState.MOVE_BACKWARD_TO_POINT) || ai_vehicle_tank__motionState == int(AiTankMotionState.MOVE_FORWARD_FROM_POINT)
        wishDir *= -1.0
      wishDir = normalize_default(wishDir, float3(1, 0, 0))

      let wishAngles = dir_to_angles(wishDir)
      let moveAngles = dir_to_angles(transform[0])
      let ang = norm_s_ang(wishAngles.x - moveAngles.x)
      let absAng = abs(ang)

      if absAng > ai_vehicle_tank__steeringDeadZone && vehicle_net_phys.phys.haveSeparateBrakes
        tank_turning(ang, ai_vehicle_tank__steeringStep, moveForward, brake, throttle, steering)
      else
        let moveToPoint = (motionStateAsFlag & int(AiTankMotionStateFlags.MOVE_TO_POINT)) != 0

        throttle = clamp(cvt(absAng, 0.0, ai_vehicle_tank__steeringDeadZone, 1.0, 0.5) * ai_vehicle_tank__maxThrottle, 0.0, 1.0)
        if moveToPoint
          if length(ai_vehicle_tank__plannedPath) <= ai_vehicle_tank__plannedPathLengthForSlowingDown
            throttle = safediv(throttle, float(1 + ai_vehicle_tank__plannedPathLengthForSlowingDown - length(ai_vehicle_tank__plannedPath)))
        steering = clamp(-ang * ai_vehicle_tank__steeringSmoothness, -1.0, 1.0)
        brake = 0.0
        if !moveForward
          throttle *= -1.0
          steering *= -1.0
  elif ai_vehicle_tank__motionState == int(AiTankMotionState.TURN_TO_POINT)
    var wishDir = ai_vehicle_tank__motionTurnToPoint - transform[3]
    wishDir.y = 0.0
    wishDir = normalize(wishDir)
    let wishAngles = dir_to_angles(wishDir)
    let referenceAngles = dir_to_angles(ai_vehicle_tank__motionTurnReferenceDirection)
    let ang = norm_s_ang(wishAngles.x - referenceAngles.x)
    if abs(ang) > ai_vehicle_tank__steeringDeadZone
      tank_turning(ang, ai_vehicle_tank__steeringStep, moveForward, brake, throttle, steering)

  assume producedCT = vehicle_net_phys.phys.producedCT

  let shouldUpdate = ai_vehicle_tank__nextUpdateAt <= info.curTime
  var throttleMult : float
  var brakeInc : float
  slow_down_before_obstacles(shouldUpdate, ai_vehicle_tank__updateInterval, eid, team, transform, throttle, ai_vehicle_tank__runOverImpatienceIncSpeed,
    ai_vehicle_tank__runOverImpatienceDecSpeed, ai_vehicle_tank__distanceToObstacleThreshold, ai_vehicle_tank__shiftToObstacleThreshold,
    ai_vehicle_tank__throttleMultToBrakeInc, ai_vehicle_tank__minDistanceToObstacle, ai_vehicle_tank__runOverImpatience, throttleMult, brakeInc)

  throttle *= throttleMult
  brake += brakeInc

  producedCT |> ground_control_state_setAutomaticTransmission(true)
  producedCT |> ground_control_state_setKeepDrivingDirectionMode(false)

  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_STEERING, steering)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_THROTTLE, throttle)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_HAND_BRAKE, brake)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_BRAKE_LEFT, brake)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_BRAKE_RIGHT, brake)


def remove_close_path_points(pos : float3; threshold : float; var path : Point3List&)
  var removeCount = 0
  let thresholdSq = square(threshold)
  for i in iter_range(path)
    if length_sq(path[i] - pos) <= thresholdSq
      removeCount++
    else
      break
  if removeCount > 0
    erase(path, 0, removeCount)


def try_find_tank_path(team : int;
                       tank_pos : float3;
                       alternative_tank_pos : float3;
                       dest : float3;
                       step_size : float;
                       max_length : float;
                       next_position_threshold : float;
                       ignore_battle_area : bool;
                       var out_path : Point3List&;
                       horz_dist : float = 0.5;
                       path_slop : float = 0.25)
  out_path |> clear()

  var isNavmeshUpdatePending = false
  find_query() <| $ [es] (battle_area_navmesh_manager__areaEids : EidList)
    if !empty(battle_area_navmesh_manager__areaEids)
      isNavmeshUpdatePending = true
    return true
  if isNavmeshUpdatePending
    return false

  let battleAreaFlags = ignore_battle_area ? uint16(PolyFlag.POLYFLAG_GROUND) : team_to_tank_navmesh_poly_flags(team)

  var destTriangle : NavMeshTriangle
  if !get_triangle_by_pos_ex(NM_EXT_1, dest, 0.5, destTriangle)
    return false
  var destFlags : uint16
  get_poly_flags_ex(NM_EXT_1, destTriangle.polyRef, destFlags)
  if (uint(destFlags) & uint(battleAreaFlags)) == 0u || (uint(destFlags) & uint(EnlPolyFlags.POLYFLAG_TANK_OBSTACLE)) != 0u
    return false

  var tankPosUsed = tank_pos
  var tankTriangle : NavMeshTriangle
  if !get_triangle_by_pos_ex(NM_EXT_1, tankPosUsed, 0.5, tankTriangle)
    tankPosUsed = alternative_tank_pos
    if !get_triangle_by_pos_ex(NM_EXT_1, tankPosUsed, 0.5, tankTriangle)
      return false
  var tankFlags : uint16
  get_poly_flags_ex(NM_EXT_1, tankTriangle.polyRef, tankFlags)
  if (uint(tankFlags) & uint(EnlPolyFlags.POLYFLAG_TANK_OBSTACLE)) != 0u
    return false

  if distance_sq(tankPosUsed, dest) < square(next_position_threshold)
    return true

  let OUTSIDE_BATTLE_AREA_COST = 1000.0
  var res = true
  using(tankPosUsed, dest, float3(horz_dist, FLT_MAX, horz_dist)) <| $(var req : FindRequest#)
    req.includeFlags = int(uint16(PolyFlag.POLYFLAG_GROUND))
    req.excludeFlags = int(EnlPolyFlags.POLYFLAG_TANK_OBSTACLE)
    req |> add_area_cost(uint8(POLYAREA_GROUND), OUTSIDE_BATTLE_AREA_COST)
    req |> add_area_cost(uint8(POLYAREA_WALKABLE), OUTSIDE_BATTLE_AREA_COST)
    if team == 1
      req |> add_area_cost(uint8(EnlPolyArea.POLYAREA_TANK_OUT_TEAM_1), OUTSIDE_BATTLE_AREA_COST)
    elif team == 2
      req |> add_area_cost(uint8(EnlPolyArea.POLYAREA_TANK_OUT_TEAM_2), OUTSIDE_BATTLE_AREA_COST)
    let findPathResult = find_path_ex(NM_EXT_1, req, step_size, path_slop) <| $(data)
      out_path |> push(tankPosUsed)
      for point in data
        out_path |> push(point)
    if findPathResult != FindPathResult.FPR_FULL
      out_path |> clear()
      res = false

  if res
    let maxPointCount = int(ceil(max_length / step_size))
    if length(out_path) > maxPointCount
      resize(out_path, maxPointCount)
    remove_close_path_points(tank_pos, next_position_threshold, out_path)

  return res


def can_capzone_be_attacked(team : int; capzone__owningTeam : int; capzone__mustBeCapturedByTeam : int; capzone__onlyTeamCanCapture : int)
  return (capzone__owningTeam != team &&
    (capzone__onlyTeamCanCapture == TEAM_UNASSIGNED && capzone__mustBeCapturedByTeam == TEAM_UNASSIGNED ||
    capzone__onlyTeamCanCapture == team ||
    capzone__mustBeCapturedByTeam == team))


def set_tank_think_state(tank_eid : EntityId; think_state; cur_time : float)
  query(tank_eid) <| $ [es] (ai_vehicle_tank__waitTimesGetUnstuck : float;
                             ai_vehicle_tank__waitTimesUpdatePath : float;
                             ai_vehicle_tank__waitTimesUpdateDestination : float;
                             var ai_vehicle_tank__thinkState : int&;
                             var ai_vehicle_tank__timerThinkState : float&;
                             var ai_vehicle_tank__waitTimesThinkState : float&)
    ai_vehicle_tank__thinkState = int(think_state)
    reset_timer(cur_time, ai_vehicle_tank__timerThinkState)
    if ai_vehicle_tank__thinkState == int(AiTankThinkState.GET_UNSTUCK)
      ai_vehicle_tank__waitTimesThinkState = ai_vehicle_tank__waitTimesGetUnstuck
    elif ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_PATH)
      ai_vehicle_tank__waitTimesThinkState = ai_vehicle_tank__waitTimesUpdatePath
    elif ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION)
      ai_vehicle_tank__waitTimesThinkState = ai_vehicle_tank__waitTimesUpdateDestination
    else
      ai_vehicle_tank__waitTimesThinkState = FLT_MAX


def calc_switch_angle(specs : AiTankMotionSpecs; time : float)
  return (specs.turnSpeed * (specs.forwardSpeed - specs.backwardSpeed) * time + PI * specs.backwardSpeed) / (specs.forwardSpeed + specs.backwardSpeed)


def calc_max_distance(angle : float; tank_turn_speed : float; tank_speed : float; time : float)
  return tank_speed * (time - angle / tank_turn_speed)


def update_danger_escape(tank_transform : float3x4;
                         tank_specs : AiTankMotionSpecs;
                         team : int;
                         path_step_size : float;
                         path_max_step_size : float;
                         ignore_battle_area : bool;
                         min_distance : float;
                         min_score : float;
                         max_score : float;
                         var is_update_needed : bool&;
                         var planned_path : Point3List&;
                         var next_position : float3&;
                         var motion_state : int&;
                         var explosion_time : float&;
                         var danger_eids : EidList&;
                         var next_position_recorded_min_distance : float&)
  update_dangers(tank_transform, tank_specs.maxSpeed, min_score, danger_eids, explosion_time, is_update_needed)

  if !is_update_needed
    return

  is_update_needed = false

  let oldEscapePos = empty(planned_path) ? tank_transform[3] : planned_path[length(planned_path) - 1]
  let timeUntilExplosion = explosion_time - get_sync_time()

  clear(planned_path)
  update_tank_next_position(tank_transform,
                            planned_path,
                            path_max_step_size,
                            tank_specs,
                            next_position,
                            next_position_recorded_min_distance,
                            motion_state)

  var score = calc_danger_score(tank_transform[3], danger_eids, max_score)
  if score <= min_score
    return

  let MAX_FIND_PATH_ATTEMPT_COUNT = 10
  var findPathAttemptCount = 0
  let updatePlannedPath = $ <| (pos : float3)
    var isAcceptable = false
    let thisScore = calc_danger_score(pos, danger_eids, max_score)
    if score < thisScore
      return isAcceptable
    using() <| $(var escape_path : Point3List)
      ++findPathAttemptCount
      if try_find_tank_path(team, tank_transform[3], next_position, pos, path_step_size,
          /*max_length*/ 1000000.0, min_distance, ignore_battle_area, escape_path)
        let timeToReach = approximate_time_to_follow_path(tank_transform, tank_specs, escape_path, min_distance)
        if timeToReach < timeUntilExplosion
          score = thisScore
          planned_path := escape_path
          update_tank_next_position(tank_transform,
                                    planned_path,
                                    path_max_step_size,
                                    tank_specs,
                                    next_position,
                                    next_position_recorded_min_distance,
                                    motion_state)
          if score <= min_score
            isAcceptable = true
    return isAcceptable

  if distance_sq(oldEscapePos, tank_transform[3]) > square(min_distance) && invoke(updatePlannedPath, oldEscapePos)
    return

  var angles : array<float>
  var probs : array<float>
  var maxDistances : array<float>
  let ANGLES_COUNT = 12
  resize(probs, ANGLES_COUNT)
  resize(maxDistances, ANGLES_COUNT)
  let ANGLE_STEP = 2.0 * PI / float(ANGLES_COUNT)
  reserve(angles, ANGLES_COUNT)
  for i in range(ANGLES_COUNT)
    push(angles, -PI + ANGLE_STEP * float(i))

  let switchAngle = calc_switch_angle(tank_specs, timeUntilExplosion)
  var normFactor = 0.0
  for angle, prob, maxDistance in angles, probs, maxDistances
    let speed = abs(angle) < switchAngle ? tank_specs.forwardSpeed : tank_specs.backwardSpeed
    maxDistance = calc_max_distance(angle, tank_specs.turnSpeed, speed, timeUntilExplosion)
    prob = maxDistance - min_distance
    normFactor += prob
  for prob in probs
    prob /= normFactor

  let MAX_CHOOSING_ATTEMPT_COUNT = 100
  for _ in range(MAX_CHOOSING_ATTEMPT_COUNT)
    if findPathAttemptCount >= MAX_FIND_PATH_ATTEMPT_COUNT
      break

    let angleRnd = rnd_float(0.0, 1.0)
    var cumulProb = 0.0
    var chosenAngle = 0.0
    var chosenMaxDistance = 0.0
    for angle, prob, maxDistance in angles, probs, maxDistances
      cumulProb += prob
      if angleRnd < cumulProb
        chosenAngle = angle
        chosenMaxDistance = maxDistance
        break
    let chosenDistance = rnd_float(min_distance, chosenMaxDistance)
    var tankDir2D = tank_transform[0]
    tankDir2D.y = 0.0
    tankDir2D = normalize(tankDir2D)
    var rotTm : float3x4
    rotyTM(chosenAngle, rotTm)
    let chosenPos = tank_transform[3] + rotate(rotTm, tankDir2D * chosenDistance)
    if invoke(updatePlannedPath, chosenPos)
      break


def calc_danger_score(pos : float3;
                      danger_eids : EidList;
                      max_score : float)
  var score = 0.0
  for dangerEid in danger_eids
    query(dangerEid) <| $ [es] (transform aka danger_transform : float3x4; ai_vehicle_tank__dangerPower : float)
      score += safediv(ai_vehicle_tank__dangerPower, distance_sq(pos, danger_transform[3])) //TODO [danger] potential improvement: 2nd, 3rd etc. dangers should give smaller scores than the 1st one to explode
    if score >= max_score
      return max_score
  return score


def approximate_time_to_follow_path(transform : float3x4;
                                    tank_specs : AiTankMotionSpecs;
                                    path : Point3List;
                                    min_distance : float)
  if empty(path)
    return 0.0

  let pos = path[length(path) - 1]
  let diff = pos - transform[3]
  let distance = length(diff)
  if distance < min_distance
    return 0.0

  let wishDir = diff / distance
  let wishAngles = dir_to_angles(wishDir)
  let moveAngles = dir_to_angles(transform[0])
  let angle = abs(norm_s_ang(wishAngles.x - moveAngles.x))
  let timeForward = angle / tank_specs.turnSpeed + distance / tank_specs.forwardSpeed
  let timeBackward = norm_s_ang(PI - angle) / tank_specs.turnSpeed + distance / tank_specs.backwardSpeed
  return min(timeForward, timeBackward)


def is_danger_relevant(danger_transform : float3x4; danger_power : float; explosion_time : float; tank_transform : float3x4; tank_max_speed : float; min_score : float)
  let timeUntilExplosion = explosion_time - get_sync_time()
  let dangerRadius = sqrt(safediv(danger_power, min_score))
  return distance_sq(tank_transform[3], danger_transform[3]) < square(dangerRadius + TANK_DIST_MULT_FOR_DANGERS * timeUntilExplosion * tank_max_speed)


def update_dangers(tank_transform : float3x4; tank_max_speed : float; min_score : float; var danger_eids : EidList&; var explosion_time : float&; var is_update_needed : bool&)
  var i = length(danger_eids) - 1
  explosion_time = FLT_MAX
  while i >= 0
    var isRelevant = false
    query(danger_eids[i]) <| $ [es] (transform aka danger_transform : float3x4; shell__explTime : float; ai_vehicle_tank__dangerPower : float)
      isRelevant = is_danger_relevant(danger_transform, ai_vehicle_tank__dangerPower, shell__explTime, tank_transform, tank_max_speed, min_score)
      if isRelevant && shell__explTime < explosion_time
        explosion_time = shell__explTime
    var ignoredSpy = false
    query(danger_eids[i]) <| $ [es] (spy_soldier__detected : bool; spy_soldier__canBeDetectedTime : float)
      ignoredSpy = !spy_soldier__detected && get_sync_time() > spy_soldier__canBeDetectedTime
    if !isRelevant || ignoredSpy
      erase(danger_eids, i)
      is_update_needed = true
    i--


//TODO [danger] consider also bombs dropped from air (and artillery?)
[es(tag=server, on_appear, REQUIRE=ai_vehicle_tank__danger)]
def add_danger_for_ai_tanks_es(evt : Event;
                               eid aka danger_eid : EntityId;
                               transform aka danger_transform : float3x4;
                               ai_vehicle_tank__dangerPower : float;
                               shell__explTime : float;
                               shell__owner : EntityId)
  if !pathfinder_is_loaded_ex(NM_EXT_1) || shell__explTime == 0.0
    return

  let WORLD_RECORD_TANK_SPEED = 23.0 // m/s; the world record for the fastest tank is 82.23 km/h (FV101 Scorpion)
  let timeUntilExplosion = shell__explTime - get_sync_time()
  let radius = TANK_DIST_MULT_FOR_DANGERS * WORLD_RECORD_TANK_SPEED * timeUntilExplosion
  let dangerTeam = get_int(shell__owner, "team") ?? TEAM_UNASSIGNED
  for_each_entity_in_grid(ecs_hash("vehicles"), BSphere3(transform[3], radius), GridEntCheck.BOUNDING) <| $(tank_eid : EntityId)
    query(tank_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (transform aka tank_transform : float3x4;
                                                       team : int;
                                                       vehicle__isStill : bool;
                                                       vehicle__stillTransform : float3x4;
                                                       vehicle__stillBoxExtents : float;
                                                       ai_vehicle_tank__dangersMinScore : float;
                                                       var ai_vehicle_tank__isDangerEscapeUpdateNeeded : bool&;
                                                       var ai_vehicle_tank__dangerEids : EidList&;
                                                       ai_vehicle_tank__maxSpeed : float = DEFAULT_TANK_MAX_SPEED)
      if is_teams_friendly(dangerTeam, team)
        return
      if !is_danger_relevant(danger_transform, ai_vehicle_tank__dangerPower, shell__explTime, tank_transform, ai_vehicle_tank__maxSpeed, ai_vehicle_tank__dangersMinScore)
        return
      ai_vehicle_tank__isDangerEscapeUpdateNeeded = true
      push(ai_vehicle_tank__dangerEids, danger_eid)
      if vehicle__isStill
        vehicle_not_still(tank_eid, vehicle__stillTransform, vehicle__stillBoxExtents)


[es(tag=server, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_dangers_update_es(info : ParallelUpdateFrameDelayed;
                                      transform : float3x4;
                                      team : int;
                                      ai_vehicle_tank__dangersUpdateInterval : float;
                                      ai_vehicle_tank__dangersMinScore : float;
                                      ai_vehicle_tank__dangersMaxScore : float;
                                      ai_vehicle_tank__stepSize : float;
                                      ai_vehicle_tank__maxStepSize : float;
                                      ai_vehicle_tank__nextPositionReachedThreshold : float;
                                      ai_vehicle_tank__ignoreBattleArea : bool;
                                      var ai_vehicle_tank__dangerNextUpdateAt : float&;
                                      var ai_vehicle_tank__isDangerEscapeUpdateNeeded : bool&;
                                      var ai_vehicle_tank__dangerEids : EidList&;
                                      var ai_vehicle_tank__dangersExplosionTime : float&;
                                      var ai_vehicle_tank__plannedPath : Point3List&;
                                      var ai_vehicle_tank__nextPosition : float3&;
                                      var ai_vehicle_tank__nextPositionRecordedMinDistance : float&;
                                      var ai_vehicle_tank__motionState : int&;
                                      ai_vehicle_tank__maxSpeed : float = DEFAULT_TANK_MAX_SPEED;
                                      ai_vehicle_tank__turnSpeed : float = DEFAULT_TANK_TURN_SPEED;
                                      ai_vehicle_tank__forwardSpeed : float = DEFAULT_TANK_FORWARD_SPEED;
                                      ai_vehicle_tank__backwardSpeed : float = DEFAULT_TANK_BACKWARD_SPEED)
  if !pathfinder_is_loaded_ex(NM_EXT_1) || ai_vehicle_tank__dangerNextUpdateAt > info.curTime
    return
  ai_vehicle_tank__dangerNextUpdateAt = info.curTime + ai_vehicle_tank__dangersUpdateInterval

  //TODO [danger] get the real numbers from the vehicle's specs instead of using the defaults
  let tankSpecs = AiTankMotionSpecs(maxSpeed = ai_vehicle_tank__maxSpeed, turnSpeed = ai_vehicle_tank__turnSpeed,
    forwardSpeed = ai_vehicle_tank__forwardSpeed, backwardSpeed = ai_vehicle_tank__backwardSpeed)
  update_danger_escape(transform,
                       tankSpecs,
                       team,
                       ai_vehicle_tank__stepSize,
                       ai_vehicle_tank__maxStepSize,
                       ai_vehicle_tank__ignoreBattleArea,
                       ai_vehicle_tank__nextPositionReachedThreshold,
                       ai_vehicle_tank__dangersMinScore,
                       ai_vehicle_tank__dangersMaxScore,
                       ai_vehicle_tank__isDangerEscapeUpdateNeeded,
                       ai_vehicle_tank__plannedPath,
                       ai_vehicle_tank__nextPosition,
                       ai_vehicle_tank__motionState,
                       ai_vehicle_tank__dangersExplosionTime,
                       ai_vehicle_tank__dangerEids,
                       ai_vehicle_tank__nextPositionRecordedMinDistance)


[es(tag=server, on_appear, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_init_es(evt : Event;
                            eid : EntityId;
                            ai_vehicle_tank__thinkState : int;
                            var ai_vehicle_tank__timerOutsideNavmesh : float&;
                            var ai_vehicle_tank__timerInsideObstacle : float&;
                            var ai_vehicle_tank__timerOutsideObstacle : float&;
                            var ai_vehicle_tank__timerNextPosition : float&;
                            var ai_vehicle_tank__timerGeneralBoredom : float&;
                            var ai_vehicle_tank__timerObjectiveBoredom : float&;
                            var ai_vehicle_tank__timerExit : float&)
  let curTime = get_sync_time()
  reset_timer(curTime, ai_vehicle_tank__timerOutsideNavmesh)
  reset_timer(curTime, ai_vehicle_tank__timerInsideObstacle)
  reset_timer(curTime, ai_vehicle_tank__timerOutsideObstacle)
  reset_timer(curTime, ai_vehicle_tank__timerNextPosition)
  reset_timer(curTime, ai_vehicle_tank__timerGeneralBoredom)
  reset_timer(curTime, ai_vehicle_tank__timerObjectiveBoredom)
  reset_timer(curTime, ai_vehicle_tank__timerExit)
  set_tank_think_state(eid, ai_vehicle_tank__thinkState, curTime)


[es(tag=server, before=ai_vehicle_tank_update_es, REQUIRE=aiVehicleTankGoToCapzones, REQUIRE_NOT=deadEntity)]
def ai_tank_update_objective_capzone(info : ParallelUpdateFrameDelayed;
                                     team : int;
                                     ai_vehicle_tank__nextUpdateAt : float;
                                     ai_vehicle_tank__curObjective : EntityId;
                                     var ai_vehicle_tank__checkedObjective : EntityId&)
  if !pathfinder_is_loaded_ex(NM_EXT_1) || ai_vehicle_tank__nextUpdateAt > info.curTime
    return
  //ai_vehicle_tank__nextUpdateAt is changed in ai_vehicle_tank_update_es

  var attackableZones : array<EntityId>
  var defendableZones : array<EntityId>
  var isCurZoneAttackable = false
  var isCurZoneDefendable = false

  query(ai_vehicle_tank__curObjective) <| $ [es] (active : bool;
                                                  ai_tank_objective__positions : Point3List;
                                                  capzone__owningTeam : int = -1;
                                                  capzone__mustBeCapturedByTeam : int = -1;
                                                  capzone__onlyTeamCanCapture : int = -1)
    if !active || empty(ai_tank_objective__positions)
      return
    if can_capzone_be_attacked(team, capzone__owningTeam, capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture)
      isCurZoneAttackable = true
    else
      isCurZoneDefendable = true

  if isCurZoneAttackable
    ai_vehicle_tank__checkedObjective = ai_vehicle_tank__curObjective
    return

  query() <| $ [es] (eid : EntityId;
                     active : bool;
                     ai_tank_objective__positions : Point3List;
                     capzone__owningTeam : int = -1;
                     capzone__mustBeCapturedByTeam : int = -1;
                     capzone__onlyTeamCanCapture : int = -1)
    if !active || empty(ai_tank_objective__positions) || eid == ai_vehicle_tank__curObjective
      return
    if can_capzone_be_attacked(team, capzone__owningTeam, capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture)
      attackableZones |> push(eid)
    else
      defendableZones |> push(eid)

  if !empty(attackableZones)
    ai_vehicle_tank__checkedObjective = attackableZones[rnd_int(0, length(attackableZones) - 1)]
  elif isCurZoneDefendable
    ai_vehicle_tank__checkedObjective = ai_vehicle_tank__curObjective
  elif !empty(defendableZones)
    ai_vehicle_tank__checkedObjective = defendableZones[rnd_int(0, length(defendableZones) - 1)]
  else
    ai_vehicle_tank__checkedObjective = INVALID_ENTITY_ID


def can_vehicle_drive(eid : EntityId)
  var res = true
  query(eid) <| $ [es] (dm_state : UInt16List;
                        ai_vehicle_tank__crewExitDestroyedWheelsPercentage : float = 0.3;
                        ai_vehicle_tank__crewExitDestroyedTracksPercentage : float = 0.3;
                        dm_phys_parts__enginePartIds : IntList const?;
                        dm_phys_parts__transmissionPartIds : IntList const?;
                        dm_phys_parts__tracksPartIds : IntList const?;
                        dm_phys_parts__wheelsPartIds : IntList const?)
    if dm_phys_parts__enginePartIds != null
      for partId in *dm_phys_parts__enginePartIds
        if uint(dm_state[partId]) == 0u
          res = false
          return
    if dm_phys_parts__transmissionPartIds != null
      for partId in *dm_phys_parts__transmissionPartIds
        if uint(dm_state[partId]) == 0u
          res = false
          return
    if dm_phys_parts__tracksPartIds != null
      var destroyedPercentage = 0.0
      for partId in *dm_phys_parts__tracksPartIds
        if uint(dm_state[partId]) == 0u
          destroyedPercentage += safeinv(float(length(*dm_phys_parts__tracksPartIds)))
          if destroyedPercentage >= ai_vehicle_tank__crewExitDestroyedTracksPercentage
            res = false
            return
    if dm_phys_parts__wheelsPartIds != null
      var destroyedPercentage = 0.0
      for partId in *dm_phys_parts__wheelsPartIds
        if uint(dm_state[partId]) == 0u
          destroyedPercentage += safeinv(float(length(*dm_phys_parts__wheelsPartIds)))
          if destroyedPercentage >= ai_vehicle_tank__crewExitDestroyedWheelsPercentage
            res = false
            return
  return res

def can_vehicle_kill_enemies(eid : EntityId)
  let MACHINE_GUN_TRIGGER = 2
  var res = true

  query(eid) <| $ [es] (turret_control__gunEids : EidList;
                        dm_state : UInt16List;
                        ai_vehicle_tank__crewExitDisabledTurretsPercentage : float = 0.6)
    var disabledPercentage = 0.0
    var turretsToConsiderCount = 0
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es] (turret_drive_dm_part__horDriveDm : int;
                               turret_drive_dm_part__verDriveDm : int;
                               turret__triggerGroup : int;
                               turret__isBroken : bool;
                               gun__ammo : int;
                               turret__allowShootingFromBroken : bool = false)
        if turret__triggerGroup >= MACHINE_GUN_TRIGGER //ignore machine guns, smoke grenade launchers etc
          return
        turretsToConsiderCount++
        if ((turret__isBroken && !turret__allowShootingFromBroken) || gun__ammo == 0 ||
            (turret_drive_dm_part__horDriveDm >= 0 && uint(dm_state[turret_drive_dm_part__horDriveDm]) == 0u) ||
            (turret_drive_dm_part__verDriveDm >= 0 && uint(dm_state[turret_drive_dm_part__verDriveDm]) == 0u))
          disabledPercentage += 1.0

    if turretsToConsiderCount > 0
      disabledPercentage /= float(turretsToConsiderCount)

    res = disabledPercentage < ai_vehicle_tank__crewExitDisabledTurretsPercentage

  return res


[es(tag=server, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_update_es(info : ParallelUpdateFrameDelayed;
                              eid : EntityId;
                              transform : float3x4;
                              turret_control__gunEids : EidList;
                              fire_damage__isBurn : bool;
                              ownedBySquad : EntityId;
                              ai_vehicle_tank__updateInterval : float;
                              ai_vehicle_tank__destination : float3;
                              ai_vehicle_tank__thinkState : int;
                              ai_vehicle_tank__plannedPathCheckedPointCount : int;
                              ai_vehicle_tank__maxStepSize : float;
                              ai_vehicle_tank__nextPositionTooFarThreshold : float;
                              ai_vehicle_tank__nextPositionReachedThreshold : float;
                              ai_vehicle_tank__nextPositionRecordedMinDistanceStep : float;
                              ai_vehicle_tank__targetScoreThresholdForStanding : float;
                              ai_vehicle_tank__curObjective : EntityId;
                              ai_vehicle_tank__checkedObjective : EntityId;
                              ai_vehicle_tank__allowCrewExiting : bool;
                              ai_vehicle_tank__allowCrewExitingIfCannotKill : bool;
                              ai_vehicle_tank__dangerEids : EidList;
                              ai_vehicle_tank__minNumAliveMembers : int;
                              ai_vehicle_tank__waitTimesOutsideNavmesh : float;
                              ai_vehicle_tank__waitTimesInsideObstacle : float2;
                              ai_vehicle_tank__waitTimesOutsideObstacle : float;
                              ai_vehicle_tank__waitTimesNextPosition : float;
                              ai_vehicle_tank__waitTimesGeneralBoredom : float;
                              ai_vehicle_tank__waitTimesObjectiveBoredom : float;
                              ai_vehicle_tank__waitTimesExit : float;
                              ai_vehicle_tank__waitTimesThinkState : float;
                              var ai_vehicle_tank__nextUpdateAt : float&;
                              var ai_vehicle_tank__motionState : int&;
                              var ai_vehicle_tank__plannedPath : Point3List&;
                              var ai_vehicle_tank__nextPosition : float3&;
                              var ai_vehicle_tank__nextPositionRecordedMinDistance : float&;
                              var ai_vehicle_tank__timerOutsideNavmesh : float&;
                              var ai_vehicle_tank__timerInsideObstacle : float&;
                              var ai_vehicle_tank__timerOutsideObstacle : float&;
                              var ai_vehicle_tank__timerNextPosition : float&;
                              var ai_vehicle_tank__timerGeneralBoredom : float&;
                              var ai_vehicle_tank__timerObjectiveBoredom : float&;
                              var ai_vehicle_tank__timerExit : float&;
                              var ai_vehicle_tank__timerThinkState : float&;
                              ai_vehicle_tank__maxSpeed : float = DEFAULT_TANK_MAX_SPEED;
                              ai_vehicle_tank__turnSpeed : float = DEFAULT_TANK_TURN_SPEED;
                              ai_vehicle_tank__forwardSpeed : float = DEFAULT_TANK_FORWARD_SPEED;
                              ai_vehicle_tank__backwardSpeed : float = DEFAULT_TANK_BACKWARD_SPEED)
  if !pathfinder_is_loaded_ex(NM_EXT_1) || ai_vehicle_tank__nextUpdateAt > info.curTime
    return
  ai_vehicle_tank__nextUpdateAt = info.curTime + ai_vehicle_tank__updateInterval

  if erase_reached_points_in_path(transform[3], ai_vehicle_tank__plannedPathCheckedPointCount, ai_vehicle_tank__nextPositionReachedThreshold, ai_vehicle_tank__plannedPath)
    let tankSpecs = AiTankMotionSpecs(maxSpeed = ai_vehicle_tank__maxSpeed, turnSpeed = ai_vehicle_tank__turnSpeed,
      forwardSpeed = ai_vehicle_tank__forwardSpeed, backwardSpeed = ai_vehicle_tank__backwardSpeed)
    update_tank_next_position(transform,
                              ai_vehicle_tank__plannedPath,
                              ai_vehicle_tank__maxStepSize,
                              tankSpecs,
                              ai_vehicle_tank__nextPosition,
                              ai_vehicle_tank__nextPositionRecordedMinDistance,
                              ai_vehicle_tank__motionState)

  //inputs to state machine

  var isValuableTargetFound = false
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=controlledByTankAiGunner)] (tank_turret_ai__targetScore : float)
      if tank_turret_ai__targetScore < ai_vehicle_tank__targetScoreThresholdForStanding
        isValuableTargetFound = true
    if isValuableTargetFound
      break

  var isInsideNavMesh = false
  var isInsideObstacle = false

  for offset in TANK_POS_OFFSETS_TO_CHECK_NAVMESH
    var nmTriangle : NavMeshTriangle
    var nmFlags = uint16(0)
    let isPointInsideNavMesh = get_triangle_by_pos_ex(NM_EXT_1, transform[3] + offset, 0.5, nmTriangle)
    if isPointInsideNavMesh
      isInsideNavMesh = true
      get_poly_flags_ex(NM_EXT_1, nmTriangle.polyRef, nmFlags)
      isInsideObstacle = (uint(nmFlags) & uint(EnlPolyFlags.POLYFLAG_TANK_OBSTACLE)) != 0u
      if !isInsideObstacle
        break
    // if we don't have a path, we only check navmesh under transform[3]
    // so that the tank goes into EXIT_OBSTACLE think state when pathfinding is impossible
    if empty(ai_vehicle_tank__plannedPath)
      break

  let thinkStateAsFlag = 1 << ai_vehicle_tank__thinkState
  let isAdvancing = (int(AiTankThinkStateFlags.ADVANCE) & thinkStateAsFlag) != 0
  let isStanding = (int(AiTankThinkStateFlags.STAND) & thinkStateAsFlag) != 0
  let reachedThresholdSq = square(ai_vehicle_tank__nextPositionReachedThreshold)
  let distanceToNextPositionSq = distance_sq(ai_vehicle_tank__nextPosition, transform[3])
  let isDestinationReached = (empty(ai_vehicle_tank__plannedPath) &&
    distanceToNextPositionSq < reachedThresholdSq &&
    distance_sq(ai_vehicle_tank__nextPosition, ai_vehicle_tank__destination) < reachedThresholdSq)
  let isIdle = isDestinationReached || isStanding
  var noProgressToNextPosition = true
  if isAdvancing && !isIdle
    if distanceToNextPositionSq <= square(ai_vehicle_tank__nextPositionRecordedMinDistance - ai_vehicle_tank__nextPositionRecordedMinDistanceStep)
      noProgressToNextPosition = false
      ai_vehicle_tank__nextPositionRecordedMinDistance = sqrt(distanceToNextPositionSq)
  else
    noProgressToNextPosition = false
    ai_vehicle_tank__nextPositionRecordedMinDistance = FLT_MAX

  //timers

  let outsideNavmeshTimerOutput = process_simple_timer(info.curTime, /*input*/!isInsideNavMesh,
    /*pause*/isIdle, ai_vehicle_tank__waitTimesOutsideNavmesh, ai_vehicle_tank__timerOutsideNavmesh)
  let insideObstacleTimerOutput = process_simple_timer(info.curTime, /*input*/isInsideObstacle,
    /*pause*/isIdle, ai_vehicle_tank__waitTimesInsideObstacle, ai_vehicle_tank__timerInsideObstacle)
  let outsideObstacleTimerOutput = process_simple_timer(info.curTime, /*input*/!isInsideObstacle,
    /*pause*/false, ai_vehicle_tank__waitTimesOutsideObstacle, ai_vehicle_tank__timerOutsideObstacle)
  let nextPositionTimerOutput = process_simple_timer(info.curTime, /*input*/noProgressToNextPosition,
    /*pause*/false, ai_vehicle_tank__waitTimesNextPosition, ai_vehicle_tank__timerNextPosition)
  let thinkStateTimerOutput = process_simple_timer(info.curTime, /*input*/isAdvancing || ai_vehicle_tank__thinkState == int(AiTankThinkState.GET_UNSTUCK),
    /*pause*/isAdvancing && (!isInsideNavMesh || isInsideObstacle), ai_vehicle_tank__waitTimesThinkState, ai_vehicle_tank__timerThinkState)

  var dummyPaused = false //for variable timers that never get paused

  let generalBoredomTimerOutput = process_variable_timer(info.curTime, /*input*/true, /*pause*/false, ai_vehicle_tank__waitTimesGeneralBoredom,
    ai_vehicle_tank__timerGeneralBoredom, dummyPaused)
  let objectiveBoredomTimerOutput = process_variable_timer(info.curTime, /*input*/true, /*pause*/false, ai_vehicle_tank__waitTimesObjectiveBoredom,
    ai_vehicle_tank__timerObjectiveBoredom, dummyPaused)

  //kick crew out of vehicle

  let numAliveMembers = get_int(ownedBySquad, "squad__numAliveMembers") ?? ai_vehicle_tank__minNumAliveMembers

  let kickCrew = (ai_vehicle_tank__allowCrewExiting && (
      (!empty(ai_vehicle_tank__plannedPath) && !can_vehicle_drive(eid)) ||
      (ai_vehicle_tank__allowCrewExitingIfCannotKill && !can_vehicle_kill_enemies(eid)) ||
      (generalBoredomTimerOutput == int(TimerOutput.TIMEOUT_1) ||
      fire_damage__isBurn ||
      (numAliveMembers != 0 && numAliveMembers < ai_vehicle_tank__minNumAliveMembers) ||
      outsideNavmeshTimerOutput == int(TimerOutput.TIMEOUT_1) ||
      insideObstacleTimerOutput == int(TimerOutput.TIMEOUT_2) ||
      (ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION) && thinkStateTimerOutput == int(TimerOutput.TIMEOUT_1)))))

  let kickTimerOutput = process_simple_timer(info.curTime, /*input*/kickCrew, /*pause*/false, ai_vehicle_tank__waitTimesExit, ai_vehicle_tank__timerExit)

  if kickTimerOutput == int(TimerOutput.TIMEOUT_1)
    kick_crew(eid)
    return

  //transitions of think state

  if !empty(ai_vehicle_tank__dangerEids)
    set_tank_think_state(eid, AiTankThinkState.AVOID_DANGERS, info.curTime)
  elif isValuableTargetFound
    set_tank_think_state(eid, AiTankThinkState.STAND_AND_TARGET, info.curTime)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.AVOID_DANGERS)
    set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_PATH, info.curTime)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.EXIT_OBSTACLE) && outsideObstacleTimerOutput == int(TimerOutput.TIMEOUT_1)
    set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_PATH, info.curTime)
  elif (ai_vehicle_tank__thinkState == int(AiTankThinkState.STAND_AND_TARGET) ||
      (ai_vehicle_tank__thinkState == int(AiTankThinkState.GET_UNSTUCK) && thinkStateTimerOutput == int(TimerOutput.TIMEOUT_1)))
    set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_PATH_FOUND, info.curTime)
  elif isAdvancing
    if !isIdle && insideObstacleTimerOutput >= int(TimerOutput.TIMEOUT_1)
      set_tank_think_state(eid, AiTankThinkState.EXIT_OBSTACLE, info.curTime)
    elif nextPositionTimerOutput == int(TimerOutput.TIMEOUT_1)
      set_tank_think_state(eid, AiTankThinkState.GET_UNSTUCK, info.curTime)
    elif (ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_PATH_FOUND) &&
        (isInsideNavMesh && distanceToNextPositionSq > square(ai_vehicle_tank__nextPositionTooFarThreshold) ||
        (empty(ai_vehicle_tank__plannedPath) && !isIdle)))
      set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_PATH, info.curTime)
    elif (ai_vehicle_tank__thinkState != int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION) &&
        (ai_vehicle_tank__curObjective != ai_vehicle_tank__checkedObjective ||
        objectiveBoredomTimerOutput == int(TimerOutput.TIMEOUT_1) ||
        (ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_PATH) && thinkStateTimerOutput == int(TimerOutput.TIMEOUT_1))))
      set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION, info.curTime)
      reset_timer(info.curTime, ai_vehicle_tank__timerObjectiveBoredom)

  //setting the motion state

  let motionStateAsFlag = 1 << ai_vehicle_tank__motionState

  if ai_vehicle_tank__thinkState == int(AiTankThinkState.STAND_BY)
    ai_vehicle_tank__motionState = int(AiTankMotionState.STAND_BY)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.STAND_AND_TARGET)
    ai_vehicle_tank__motionState = int(AiTankMotionState.TURN_TO_POINT)
  elif isAdvancing
    if (int(AiTankMotionStateFlags.MOVE_TO_POINT) & motionStateAsFlag) == 0
      ai_vehicle_tank__motionState = int(AiTankMotionState.MOVE_FORWARD_TO_POINT)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.GET_UNSTUCK)
    ai_vehicle_tank__motionState = int(AiTankMotionState.MOVE_BACKWARD_FROM_POINT)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.EXIT_OBSTACLE)
    ai_vehicle_tank__motionState = int(AiTankMotionState.MOVE_BACKWARD_STRAIGHT)
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.AVOID_DANGERS)
    if (int(AiTankMotionStateFlags.MOVE_TO_POINT) & motionStateAsFlag) == 0
      ai_vehicle_tank__motionState = int(AiTankMotionState.MOVE_FORWARD_TO_POINT)


[es(tag=server, after=ai_vehicle_tank_update_es, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_path_finding_es(info : ParallelUpdateFrameDelayed;
                                    eid : EntityId;
                                    transform : float3x4;
                                    team : int;
                                    ai_vehicle_tank__updatingPathTriesPerFrame : float;
                                    ai_vehicle_tank__updatingDestinationTriesPerFrame : float;
                                    ai_vehicle_tank__stepSize : float;
                                    ai_vehicle_tank__maxStepSize : float;
                                    ai_vehicle_tank__maxPathLength : float;
                                    ai_vehicle_tank__nextPositionReachedThreshold : float;
                                    ai_vehicle_tank__checkedObjective : EntityId;
                                    ai_vehicle_tank__ignoreBattleArea : bool;
                                    ai_vehicle_tank__thinkState : int;
                                    var ai_vehicle_tank__motionState : int&;
                                    var ai_vehicle_tank__curObjective : EntityId&;
                                    var ai_vehicle_tank__curObjectivePosIdx : int&;
                                    var ai_vehicle_tank__plannedPath : Point3List&;
                                    var ai_vehicle_tank__destination : float3&;
                                    var ai_vehicle_tank__nextPosition : float3&;
                                    var ai_vehicle_tank__nextPositionRecordedMinDistance : float&;
                                    var ai_vehicle_tank__pathFindingTryCountRemainder : float&;
                                    ai_vehicle_tank__maxSpeed : float = DEFAULT_TANK_MAX_SPEED;
                                    ai_vehicle_tank__turnSpeed : float = DEFAULT_TANK_TURN_SPEED;
                                    ai_vehicle_tank__forwardSpeed : float = DEFAULT_TANK_FORWARD_SPEED;
                                    ai_vehicle_tank__backwardSpeed : float = DEFAULT_TANK_BACKWARD_SPEED)
  if !pathfinder_is_loaded_ex(NM_EXT_1)
    return

  if ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION)
    using() <| $(var new_path : Point3List)
      query(ai_vehicle_tank__checkedObjective) <| $ [es] (ai_tank_objective__positions : Point3List;
                                                          ai_tank_objective__positionCountsPerType : IntList;
                                                          ai_tank_objective__probabilityPerPositionType : FloatList)
        //ai_vehicle_tank__updatingDestinationTriesPerFrame can be any positive number.
        //If it is less than 1.0, pathfinding will be skipped on some frames.
        //If greater than 1.0, pathfinding will happen every frame, possibly more than once
        //Note: the end position is chosen randomly from a list of positions each pathfinding attempt
        ai_vehicle_tank__pathFindingTryCountRemainder += ai_vehicle_tank__updatingDestinationTriesPerFrame
        let tryCountThisFrame = floor(ai_vehicle_tank__pathFindingTryCountRemainder)
        ai_vehicle_tank__pathFindingTryCountRemainder -= tryCountThisFrame

        for _ in range(int(tryCountThisFrame))
          var positionType = -1
          let typeRnd = rnd_float(0.0, 1.0)
          var cumulProb = 0.0
          var beginPosIdx = 0
          var endPosIdx = 0

          for i in iter_range(ai_tank_objective__probabilityPerPositionType)
            beginPosIdx = endPosIdx
            endPosIdx = beginPosIdx + ai_tank_objective__positionCountsPerType[i]
            cumulProb += ai_tank_objective__probabilityPerPositionType[i]
            if ai_tank_objective__positionCountsPerType[i] != 0 && typeRnd <= cumulProb
              positionType = i
              break

          if positionType < 0 // should not normally be possible
            continue

          let posIdx = rnd_int(beginPosIdx, endPosIdx - 1)
          let pos = ai_tank_objective__positions[posIdx]
          if try_find_tank_path(team, transform[3], ai_vehicle_tank__nextPosition, pos, ai_vehicle_tank__stepSize,
                                ai_vehicle_tank__maxPathLength, ai_vehicle_tank__nextPositionReachedThreshold,
                                ai_vehicle_tank__ignoreBattleArea, new_path)
            set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_PATH_FOUND, info.curTime)
            ai_vehicle_tank__plannedPath := new_path
            ai_vehicle_tank__curObjective = ai_vehicle_tank__checkedObjective
            ai_vehicle_tank__curObjectivePosIdx = posIdx
            ai_vehicle_tank__destination = pos
            let tankSpecs = AiTankMotionSpecs(maxSpeed = ai_vehicle_tank__maxSpeed, turnSpeed = ai_vehicle_tank__turnSpeed,
              forwardSpeed = ai_vehicle_tank__forwardSpeed, backwardSpeed = ai_vehicle_tank__backwardSpeed)
            update_tank_next_position(transform,
                                      ai_vehicle_tank__plannedPath,
                                      ai_vehicle_tank__maxStepSize,
                                      tankSpecs,
                                      ai_vehicle_tank__nextPosition,
                                      ai_vehicle_tank__nextPositionRecordedMinDistance,
                                      ai_vehicle_tank__motionState)
            break
  elif ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_PATH)
    using() <| $(var new_path : Point3List)
      //ai_vehicle_tank__updatingPathTriesPerFrame can be less or equal to 1.0.
      //If less than 1.0, pathfinding will be skipped on some frames.
      //If equal to 1.0, pathfinding will happen once per every frame
      //There's no point in ai_vehicle_tank__updatingPathTriesPerFrame being greater than 1.0
      //because the pathfinding algorithm would yield the same results in the same frame
      //(the start and end positions are the same)
      ai_vehicle_tank__pathFindingTryCountRemainder += ai_vehicle_tank__updatingPathTriesPerFrame
      if ai_vehicle_tank__pathFindingTryCountRemainder >= 1.0
        if try_find_tank_path(team, transform[3], ai_vehicle_tank__nextPosition, ai_vehicle_tank__destination, ai_vehicle_tank__stepSize,
                              ai_vehicle_tank__maxPathLength, ai_vehicle_tank__nextPositionReachedThreshold,
                              ai_vehicle_tank__ignoreBattleArea, new_path)
          set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_PATH_FOUND, info.curTime)
          ai_vehicle_tank__plannedPath := new_path
          let tankSpecs = AiTankMotionSpecs(maxSpeed = ai_vehicle_tank__maxSpeed, turnSpeed = ai_vehicle_tank__turnSpeed,
            forwardSpeed = ai_vehicle_tank__forwardSpeed, backwardSpeed = ai_vehicle_tank__backwardSpeed)
          update_tank_next_position(transform,
                                    ai_vehicle_tank__plannedPath,
                                    ai_vehicle_tank__maxStepSize,
                                    tankSpecs,
                                    ai_vehicle_tank__nextPosition,
                                    ai_vehicle_tank__nextPositionRecordedMinDistance,
                                    ai_vehicle_tank__motionState)
      ai_vehicle_tank__pathFindingTryCountRemainder -= floor(ai_vehicle_tank__pathFindingTryCountRemainder)


def get_forestall_or(owner_pos, owner_vel, target_pos, target_vel : float3; gun_eid : EntityId; default_val : float3)
  var res = default_val
  query(gun_eid) <| $ [es] (gun__curShellId : ShellPropIds)
    projectile_get_props(int(gun__curShellId.ballisticsId)) <| $(ballisticsProps : ProjectileProps)
      shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
        let muzzleVelocity = shellStartProps.speed
        let forestall = get_forestall_pos(owner_pos, owner_vel, ballisticsProps, muzzleVelocity, target_pos, target_vel)
        if forestall.valid
          res = forestall.pos
  return res


struct AiGunnerTarget
  pos : float3 = float3(0, 0, 0)
  vel : float3 = float3(0, 0, 0)
  active : bool = false
  partType : int = -1


def get_target_pos(shooter_pos, shooter_vel, prev_target_pos : float3; prev_target_active : bool; prev_target_part_type : int; gun_eid, target_eid : EntityId; update_dm_target : bool)
  var target = AiGunnerTarget()
  query(target_eid) <| $ [es] (ai_target : Target; vehicle : Tag const?; ai_target__fixedAimOffset : float3 = float3())
    if !ai_target.isAlive
      return
    if vehicle == null
      target.pos = ai_target.targetPos
      target.active = true
    elif !update_dm_target
      target.pos = prev_target_pos
      target.active = prev_target_active
      target.partType = prev_target_part_type
    else
      let MAX_POINTS_PER_TARGET = 5
      let CHANCE_TRY_NOT_PENETRATE = 0.7
      let ignoreWithNoCrew = false
      let noCrew = ignoreWithNoCrew || !is_vehicle_with_alive_crew(target_eid)
      let withSecondaryChance = 0.25
      var targetDmAiPoints : array<TargetDMAIPoint>
      pick_target_dm_ai_points(targetDmAiPoints, MAX_POINTS_PER_TARGET, shooter_pos, target_eid, noCrew, /*rand_offset*/ float2(), /*allow_from_front*/ true, withSecondaryChance)
      query(gun_eid) <| $ [es] (gun__curShellId : ShellPropIds; combatBallisticCoef : float = 0.0)
        for targetDmAiPoint in targetDmAiPoints
          let pos = targetDmAiPoint.worldPos
          var correctedPos : float3
          var runShootVel = 50.0
          shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
            runShootVel = shellStartProps.speed
          if trace_pierce_shot(correctedPos, shooter_pos, pos, runShootVel, int(gun__curShellId.shellId), int(gun__curShellId.damageId), int(gun__curShellId.ballisticsId), combatBallisticCoef, target_eid, CHANCE_TRY_NOT_PENETRATE)
            target.pos = correctedPos
            target.partType = targetDmAiPoint.partType
            target.active = true
            return
      if !target.active
        target.pos = ai_target.targetPos
        target.partType = int(DMAIPoint.BODY)
        target.active = true
    target.vel = ai_target.velocity

    if length_sq(target.vel) > 1.0
      target.pos = get_forestall_or(shooter_pos, shooter_vel, target.pos, target.vel, gun_eid, target.pos)
    target.pos += ai_target__fixedAimOffset
  return target


def init_targets(turret_pos : float3;
                 owner_eid : EntityId;
                 owner_team : int;
                 prev_target_eid : EntityId;
                 max_dist : float;
                 var out_targets : EidList&;
                 var cur_target_eid : EntityId&)
  cur_target_eid = INVALID_ENTITY_ID
  out_targets |> clear()

  for_each_entity_in_grid(fixed_array(ecs_hash("humans"), ecs_hash("vehicles")), BSphere3(turret_pos, max_dist), GridEntCheck.BOUNDING) <| $(eid : EntityId)
    query(eid) <| $ [es(REQUIRE=targetForTankAiGunner)] (eid : EntityId; team : int; ai_target : Target; isInVehicleHidden : bool = false)
      var ignoredSpy = false
      query(eid) <| $ [es] (spy_soldier__detected : bool; spy_soldier__canBeDetectedTime : float)
        ignoredSpy = !spy_soldier__detected && get_sync_time() > spy_soldier__canBeDetectedTime
      if owner_eid == eid || !ai_target.isAlive || team == TEAM_UNASSIGNED || is_teams_friendly(owner_team, team) || isInVehicleHidden || ignoredSpy
        return
      if prev_target_eid == eid
        cur_target_eid = prev_target_eid
      else
        out_targets |> push(eid)

  shuffle(out_targets)
  if cur_target_eid != INVALID_ENTITY_ID
    out_targets |> push(cur_target_eid, 0)


struct TargetScoreSettings
  angleScoreMult : float = 4.0
  distanceScoreMult : float = 1.0
  targetRetentionScoreMult : float = 0.2


def calc_target_score(target_eid : EntityId;
                      prev_target_eid : EntityId;
                      turret_pos : float3;
                      turret_initial_itm : float3x4;
                      turret_itm : float3x4;
                      ai_target : Target;
                      score_mult : float;
                      max_dist : float;
                      min_dist : float;
                      limit_angles : float4;
                      limit_vision_angles : float4;
                      settings : TargetScoreSettings;
                      var attackers : Object&)
  let initialLocalDirToTarget = turret_initial_itm * ai_target.targetPos
  let distanceToTarget = length(initialLocalDirToTarget)
  if distanceToTarget > max_dist || distanceToTarget < min_dist
    return FLT_MAX

  let angles = dir_to_angles(initialLocalDirToTarget)
  let yaw = angles.x
  let pitch = angles.y

  if yaw < limit_angles[0] || yaw > limit_angles[1] || pitch < limit_angles[2] || pitch > limit_angles[3]
    return FLT_MAX

  let localDirToTarget = turret_itm * ai_target.targetPos
  let visionAngles = dir_to_angles(localDirToTarget)
  let visionYaw = visionAngles.x
  let visionPitch = visionAngles.y

  let attackerTimeout = attackers["{target_eid}"]
  let useVisionLimits = (attackerTimeout ?? 0.0) < get_sync_time()
  if attackerTimeout != null && useVisionLimits
    erase(attackers, "{target_eid}")

  if useVisionLimits && (visionYaw < limit_vision_angles[0] || visionYaw > limit_vision_angles[1] || visionPitch < limit_vision_angles[2] || visionPitch > limit_vision_angles[3])
    return FLT_MAX

  let pos = turret_pos
  let vec = ai_target.targetPos - pos
  let dir = normalize(vec)
  let dist = length(vec)

  if rayhit_smoke_occluders(pos, ai_target.targetPos)
    return FLT_MAX

  if rayhit_normalized(pos, dir, dist, ETF_DEFAULT, -1)
    return FLT_MAX

  let angle = acos(dot(normalize(localDirToTarget), float3(1, 0, 0)))
  let targetRetentionMult = (target_eid == prev_target_eid ? settings.targetRetentionScoreMult : 1.0)
  return score_mult * targetRetentionMult * (settings.angleScoreMult * angle + settings.distanceScoreMult * distanceToTarget)


def find_next_target(owner_eid : EntityId;
                     owner_team : int;
                     targets_per_frame : int;
                     max_target_score : float;
                     turret_pos : float3;
                     turret_initial_itm : float3x4;
                     turret_itm : float3x4;
                     min_dist : float;
                     max_dist : float;
                     limit_angles_deg : float4;
                     limit_vision_angles_deg : float4;
                     var attackers : Object&;
                     var targets : EidList&;
                     var next_target_idx : int&;
                     var cur_target_eid : EntityId&;
                     var prev_target_eid : EntityId&;
                     var cur_target_type : int&;
                     var target_score : float&;
                     target_score_settings : TargetScoreSettings)
  let limitAngles = deg_to_rad(limit_angles_deg)
  let limitVisionAngles = deg_to_rad(limit_vision_angles_deg)

  if next_target_idx == 0
    target_score = FLT_MAX
    prev_target_eid = cur_target_eid
    init_targets(turret_pos, owner_eid, owner_team, prev_target_eid, max_dist, targets, cur_target_eid)
    if empty(targets)
      cur_target_eid = INVALID_ENTITY_ID
      prev_target_eid = INVALID_ENTITY_ID
      return

  let untilIdx = min(length(targets), next_target_idx + targets_per_frame)

  for targetIdx in range(next_target_idx, untilIdx)
    let targetEid = targets[targetIdx]
    query(targetEid) <| $ [es] (ai_target : Target; ai_target__scoreMult : float = 1.0; ai_target__type : int = int(AiTankTargetType.HUMAN))
      let score = calc_target_score(targetEid, prev_target_eid, turret_pos, turret_initial_itm, turret_itm, ai_target, ai_target__scoreMult,
        max_dist, min_dist, limitAngles, limitVisionAngles, target_score_settings, attackers)
      if score < FLT_MAX
        setOptional(targetEid, "spy_soldier__visibleByAiTankLastTime", get_sync_time())
      if score < target_score
        target_score = score
        cur_target_eid = targetEid
        cur_target_type = ai_target__type

  if target_score > max_target_score
    target_score = FLT_MAX
    cur_target_eid = INVALID_ENTITY_ID
    cur_target_type = int(AiTankTargetType.HUMAN)

  if untilIdx == length(targets)
    next_target_idx = 0
  else
    next_target_idx = untilIdx


[es(tag=server, REQUIRE=ai_vehicle_tank, REQUIRE_NOT=deadEntity)]
def tank_ai_gunner_add_attacker(evt : EventOnHitByProjectile;
                                team aka ai_vehicle_tank_team : int;
                                ai_vehicle_tank__attackerMinCaliber : float;
                                ai_vehicle_tank__attackerTimeoutInterval : float;
                                turret_control__gunEids : EidList)
  if !evt.pierced && evt.caliber < ai_vehicle_tank__attackerMinCaliber
    return
  query(evt.projectileEid) <| $ [es] (ownerEid : EntityId)
    query(ownerEid) <| $ [es] (team aka attacker_team : int; isInVehicle : bool; vehicle__lastEid : EntityId)
      if is_teams_friendly(ai_vehicle_tank_team, attacker_team)
        return
      let attackerEid = isInVehicle ? vehicle__lastEid : ownerEid
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=controlledByTankAiGunner)] (var tank_turret_ai__attackers : Object&)
          set(tank_turret_ai__attackers, "{attackerEid}", get_sync_time() + ai_vehicle_tank__attackerTimeoutInterval)


[es(tag=server, before=before_net_phys_sync)]
def tank_ai_gunner_find_target(info : ParallelUpdateFrameDelayed;
                               gun__owner : EntityId;
                               turret__owner : EntityId;
                               turret__aimNodeId : int;
                               tank_turret_ai__targetCheckInterval : float;
                               tank_turret_ai__attackDist : float;
                               tank_turret_ai__maxTargetScore : float;
                               tank_turret_ai__limitAngles : float4 const?;
                               var turret_aim__target : EntityId&;
                               var tank_turret_ai__attackers : Object&;
                               var tank_turret_ai__nextTargetCheckAtTime : float&;
                               var tank_turret_ai__targetList : EidList&;
                               var tank_turret_ai__nextCheckedTargetIdx : int&;
                               var tank_turret_ai__curTargetEid : EntityId&;
                               var tank_turret_ai__prevTargetEid : EntityId&;
                               var tank_turret_ai__targetScore : float&;
                               var tank_turret_ai__curTargetType : int&;
                               controlledByTankAiGunner : Tag const?;
                               controlledByTankAiGunnerWithBot : Tag const?;
                               turret__limit : float4 = float4(-180, 180, -180, 180);
                               tank_turret_ai__atackMinDist : float = 0.f;
                               tank_turret_ai__limitVisionAngles : float4 = float4(-90, 90, -30, 50);
                               tank_turret_ai__checkedTargetsPerFrame : int = 2)
  if turret__aimNodeId < 0
    return
  if controlledByTankAiGunner == null && (controlledByTankAiGunnerWithBot == null || !can_soldier_control_turret(gun__owner))
    return

  let hasAliveOwner = query(gun__owner) <| $ [es(REQUIRE_NOT=deadEntity)] (team : int)
    if tank_turret_ai__nextCheckedTargetIdx == 0
      if info.curTime < tank_turret_ai__nextTargetCheckAtTime
        return
      tank_turret_ai__nextTargetCheckAtTime = info.curTime + tank_turret_ai__targetCheckInterval

    query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
      let parNodeId = geomtree_getParentNodeIdx(*animchar.nodeTree, turret__aimNodeId)
      if parNodeId < 0
        return

      var turretWtm : float3x4
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(turret__aimNodeId, turretWtm)
      let turretItm = inverse(turretWtm)

      var tmOrig : float3x4
      var wtmParent : float3x4
      *animchar.originalNodeTree |> geomtree_getNodeTmScalar(turret__aimNodeId, tmOrig)
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(parNodeId, wtmParent)
      var turretInitialWtm = wtmParent * tmOrig
      orthonormalize(turretInitialWtm)
      let turretInitialItm = inverse(turretInitialWtm)

      let limitAngles = tank_turret_ai__limitAngles ?? turret__limit
      find_next_target(turret__owner, team, tank_turret_ai__checkedTargetsPerFrame, tank_turret_ai__maxTargetScore, turretWtm[3],
        turretInitialItm, turretItm, tank_turret_ai__atackMinDist, tank_turret_ai__attackDist, limitAngles,
        tank_turret_ai__limitVisionAngles, tank_turret_ai__attackers, tank_turret_ai__targetList, tank_turret_ai__nextCheckedTargetIdx, tank_turret_ai__curTargetEid,
        tank_turret_ai__prevTargetEid, tank_turret_ai__curTargetType, tank_turret_ai__targetScore, TargetScoreSettings())
      turret_aim__target = tank_turret_ai__curTargetEid

  if !hasAliveOwner && !empty(tank_turret_ai__targetList)
    clear(tank_turret_ai__targetList)
    clear(tank_turret_ai__attackers)
    turret_aim__target = INVALID_ENTITY_ID
    tank_turret_ai__nextTargetCheckAtTime = 0.0
    tank_turret_ai__nextCheckedTargetIdx = 0
    tank_turret_ai__curTargetEid = INVALID_ENTITY_ID
    tank_turret_ai__prevTargetEid = INVALID_ENTITY_ID
    tank_turret_ai__targetScore = FLT_MAX
    tank_turret_ai__curTargetType = int(AiTankTargetType.HUMAN)


struct AimingErrorSettings
  speedMult = 1.0
  angleMult = 1.0
  maxAngle = 0.5236 // PI / 6
  constantError = 0.5


def calc_aiming_error(time : float; freq : float; time_offset : float; dist : float; wish_dir : float3; shoot_dir : float3; shooter_vel : float3; target_vel : float3; settings : AimingErrorSettings)
  let vel = target_vel - shooter_vel
  let lateralSpeed = length(cross(vel, wish_dir))
  let angleDiff = safe_acos(dot(wish_dir, shoot_dir))
  let errorDueToSpeed = settings.speedMult * lateralSpeed
  let errorDueToAngle = settings.angleMult * min(angleDiff, settings.maxAngle) * dist

  return (errorDueToSpeed + errorDueToAngle + settings.constantError) * perlin_noise1(freq * time + time_offset)


def can_soldier_control_turret(eid : EntityId)
  var res = false
  query(eid) <| $ [es] (beh_tree__enabled : bool = false;
                        human_vehicle__canHoldWeapon : bool = false)
    res = beh_tree__enabled && !human_vehicle__canHoldWeapon
  return res


[es(tag=server, REQUIRE=turret_control__hasTankAiGunners, REQUIRE_NOT=deadEntity, after=vehicle_input_turret_es, before=apply_turret_aim_pos_to_remote_wish_dir_es)]
def turret_tank_ai_gunner_aim(evt : CmdTurretsUpdate;
                              turret_control__gunEids : EidList;
                              net_phys__currentStateVelocity : float3;
                              ai_vehicle_tank__curObjective : EntityId = INVALID_ENTITY_ID;
                              ai_vehicle_tank__curObjectivePosIdx : int = -1)
  let shooterVel = net_phys__currentStateVelocity
  let curTime = get_sync_time()

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (turret_state : TurretState;
                             gun__owner : EntityId;
                             tank_turret_ai__curTargetEid : EntityId;
                             tank_turret_ai__prevTargetEid : EntityId;
                             tank_turret_ai__burstWaitTime : float;
                             tank_turret_ai__shortPauseWaitTime : float;
                             tank_turret_ai__longPauseWaitTime : float;
                             tank_turret_ai__aimingGamma : float;
                             tank_turret_ai__idleSwing : float;
                             tank_turret_ai__maxBurstCount : int;
                             tank_turret_ai__dmTargetUpdateInterval : float;
                             var tank_turret_ai__targetState : int&;
                             var tank_turret_ai__shootState : int&;
                             var tank_turret_ai__prevTargetPos : float3&;
                             var tank_turret_ai__prevTargetActive : bool&;
                             var tank_turret_ai__prevTargetPartType : int&;
                             var tank_turret_ai__burstCount : int&;
                             var turret_aim__shootToPos : float3&;
                             var turret_aim__shootAngles : float2&;
                             var turret_aim__shootFlag : bool&;
                             var tank_turret_ai__shootStateTimeoutAt : float&;
                             var tank_turret_ai__dmTargetUpdateAt : float&;
                             controlledByTankAiGunner : Tag const?;
                             controlledByTankAiGunnerWithBot : Tag const?;
                             tank_turret_ai__shootAngleCos : float = 0.999)
      if controlledByTankAiGunner == null && (controlledByTankAiGunnerWithBot == null || !can_soldier_control_turret(gun__owner))
        return
      let hasAliveOwner = query(gun__owner) <| $ [es(REQUIRE_NOT=deadEntity)] () {}
      if !hasAliveOwner
        tank_turret_ai__targetState = int(AiTankTargetState.IDLE)
        tank_turret_ai__shootState = int(AiTankShootState.READY)
        tank_turret_ai__prevTargetPos = float3(0, 0, 0)
        tank_turret_ai__prevTargetActive = false
        tank_turret_ai__prevTargetPartType = -1
        tank_turret_ai__burstCount = 0
        turret_aim__shootToPos = float3(0, 0, 0)
        turret_aim__shootAngles = float2(0, 0)
        turret_aim__shootFlag = false
        tank_turret_ai__shootStateTimeoutAt = 0.0
        tank_turret_ai__dmTargetUpdateAt = 0.0
        return

      turret_aim__shootFlag = false

      let shooterPos = turret_state.shoot.pos
      var target = AiGunnerTarget()

      //transitions of target state
      if tank_turret_ai__curTargetEid == INVALID_ENTITY_ID
        tank_turret_ai__targetState = int(AiTankTargetState.IDLE)
      elif tank_turret_ai__targetState == int(AiTankTargetState.IDLE) || tank_turret_ai__curTargetEid != tank_turret_ai__prevTargetEid
        tank_turret_ai__targetState = int(AiTankTargetState.TARGET)

      //state machine output
      if tank_turret_ai__targetState == int(AiTankTargetState.IDLE)
        let success = query(ai_vehicle_tank__curObjective) <| $ [es] (ai_tank_objective__aimAtPositions : Point3List)
          if uint(ai_vehicle_tank__curObjectivePosIdx) < uint(length(ai_tank_objective__aimAtPositions))
            turret_aim__shootToPos = ai_tank_objective__aimAtPositions[ai_vehicle_tank__curObjectivePosIdx]
            let diff = turret_aim__shootToPos - turret_state.shoot.pos
            let wishDir = normalize(diff)
            let lateralDir = normalize_default(cross(wishDir, float3(0, 1, 0)), float3(1, 0, 0))
            turret_aim__shootToPos += tank_turret_ai__idleSwing * lateralDir * sin(get_sync_time())
        if !success
          query(gun__owner) <| $ [es] (transform : float3x4)
            turret_aim__shootToPos = turret_state.shoot.pos + transform[0] * 100.0
      else // AiTankTargetState TARGET || AiTankTargetState TARGET_FAILURE
        let ignoreWithNoCrew = false
        let noCrew = ignoreWithNoCrew || !is_vehicle_with_alive_crew(tank_turret_ai__curTargetEid)
        let allowFromFront = true
        var updateDmTarget = false
        query(tank_turret_ai__curTargetEid) <| $ [es(REQUIRE=vehicle)] (transform aka target_transform : float3x4)
          let pointValue = evaluate_dm_ai_point_for_shot(tank_turret_ai__prevTargetPos, target_transform, shooterPos, noCrew, allowFromFront, tank_turret_ai__prevTargetPartType)
          updateDmTarget = curTime > tank_turret_ai__dmTargetUpdateAt || (pointValue == DMAIPointValue.NONE && tank_turret_ai__targetState != int(AiTankTargetState.TARGET_FAILURE))
        if updateDmTarget
          tank_turret_ai__dmTargetUpdateAt = curTime + tank_turret_ai__dmTargetUpdateInterval
        target = get_target_pos(shooterPos, shooterVel, tank_turret_ai__prevTargetPos,
          tank_turret_ai__prevTargetActive, tank_turret_ai__prevTargetPartType, gunEid,
          tank_turret_ai__curTargetEid, updateDmTarget)

        if !target.active
          tank_turret_ai__targetState = int(AiTankTargetState.TARGET_FAILURE)
        else
          tank_turret_ai__targetState = int(AiTankTargetState.TARGET)

          let diff = target.pos - turret_state.shoot.pos
          let wishDir = normalize(diff)
          let dist = length(diff)
          let shootDir = turret_state.shoot.dir

          turret_aim__shootToPos = target.pos
          let dir1 = normalize_default(cross(wishDir, float3(0, 1, 0)), float3(1, 0, 0))
          let dir2 = normalize(cross(dir1, wishDir))
          turret_aim__shootToPos += calc_aiming_error(get_sync_time(), 1.0, 17.21, dist, wishDir, shootDir, shooterVel, target.vel, AimingErrorSettings()) * dir1
          turret_aim__shootToPos += calc_aiming_error(get_sync_time(), 1.0, 13.19, dist, wishDir, shootDir, shooterVel, target.vel, AimingErrorSettings()) * dir2

          let dirDot = dot(wishDir, shootDir)
          let prob = pow((dirDot - tank_turret_ai__shootAngleCos) / (1.0 - tank_turret_ai__shootAngleCos), tank_turret_ai__aimingGamma)

          if ((tank_turret_ai__shootState == int(AiTankShootState.READY) || tank_turret_ai__shootState == int(AiTankShootState.BURST)) &&
              (tank_turret_ai__shootAngleCos <= dirDot &&
              rnd_float(0.0, 1.0) < prob))
            turret_aim__shootFlag = true

      turret_aim__shootAngles = turret_calc_shoot_angles(turret_state.shoot.pos, turret_aim__shootToPos)
      tank_turret_ai__prevTargetPos = target.pos
      tank_turret_ai__prevTargetActive = target.active
      tank_turret_ai__prevTargetPartType = target.partType

      //transitions of shoot state
      if tank_turret_ai__shootState == int(AiTankShootState.READY)
        if turret_aim__shootFlag
          tank_turret_ai__shootState = int(AiTankShootState.BURST)
          tank_turret_ai__shootStateTimeoutAt = curTime + tank_turret_ai__burstWaitTime
      elif tank_turret_ai__shootState == int(AiTankShootState.BURST)
        if curTime > tank_turret_ai__shootStateTimeoutAt
          if tank_turret_ai__burstCount >= tank_turret_ai__maxBurstCount
            tank_turret_ai__burstCount = 0
            tank_turret_ai__shootState = int(AiTankShootState.LONG_PAUSE)
            tank_turret_ai__shootStateTimeoutAt = curTime + tank_turret_ai__longPauseWaitTime
          else
            tank_turret_ai__burstCount += 1
            tank_turret_ai__shootState = int(AiTankShootState.SHORT_PAUSE)
            tank_turret_ai__shootStateTimeoutAt = curTime + tank_turret_ai__shortPauseWaitTime
      elif tank_turret_ai__shootState == int(AiTankShootState.SHORT_PAUSE)
        if curTime > tank_turret_ai__shootStateTimeoutAt
          tank_turret_ai__shootState = int(AiTankShootState.READY)
      elif tank_turret_ai__shootState == int(AiTankShootState.LONG_PAUSE)
        if curTime > tank_turret_ai__shootStateTimeoutAt
          tank_turret_ai__shootState = int(AiTankShootState.READY)


def vehicle_not_still(this_eid : EntityId; still_transform : float3x4; still_box_extents : float)
  update_navmesh_poly_flags_on_still_obstacle(false, still_transform[3], still_box_extents)
  query() <| $ [es] (eid aka other_eid : EntityId;
                     vehicle__isStill aka other_vehicle__isStill : bool;
                     vehicle__stillTransform aka other_vehicle__stillTransform : float3x4;
                     vehicle__stillBoxExtents aka other_vehicle__stillBoxExtents : float)
    if this_eid != other_eid && other_vehicle__isStill && length_sq(other_vehicle__stillTransform[3] - still_transform[3]) < square(still_box_extents + other_vehicle__stillBoxExtents)
      update_navmesh_poly_flags_on_still_obstacle(true, other_vehicle__stillTransform[3], other_vehicle__stillBoxExtents)
  //Let's not broadcast OnTankNavmeshFlagsLocalUpdate here,
  //so that AI tanks continue on the paths they had already chosen when the obstacle was there.
  //Otherwise, they sometimes get stuck, changing their path too often.

[es(tag=server)]
def vehicle_still_es(info : ParallelUpdateFrameDelayed;
                     eid : EntityId;
                     transform : float3x4;
                     vehicle__stillPosThreshold : float;
                     vehicle__stillCheckUpdateInterval : float;
                     vehicle__stillBoxExtents aka this_vehicle__stillBoxExtents : float;
                     var vehicle__stillTransform aka this_vehicle__stillTransform : float3x4&;
                     var vehicle__stillNextCheckAt : float&;
                     var vehicle__isStill : bool&;
                     deadEntity : Tag const?;
                     ai_vehicle_tank__thinkState : int const?;
                     ai_vehicle_tank__plannedPath : Point3List const?)
  if !pathfinder_is_loaded_ex(NM_EXT_1) || info.curTime < vehicle__stillNextCheckAt
    return
  vehicle__stillNextCheckAt = info.curTime + vehicle__stillCheckUpdateInterval

  let isAiTank = ai_vehicle_tank__thinkState != null && ai_vehicle_tank__plannedPath != null
  let isAiTankMoving = ((deadEntity == null) && isAiTank &&
    (*ai_vehicle_tank__thinkState == int(AiTankThinkState.AVOID_DANGERS) ||
    *ai_vehicle_tank__thinkState == int(AiTankThinkState.GET_UNSTUCK) ||
    *ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION) ||
    *ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_PATH) ||
    (*ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_PATH_FOUND) && !empty(*ai_vehicle_tank__plannedPath))))

  let prevIsStill = vehicle__isStill
  vehicle__isStill = !isAiTankMoving && length_sq(transform[3] - vehicle__stillTransform[3]) < square(vehicle__stillPosThreshold)

  if !prevIsStill && vehicle__isStill
    update_navmesh_poly_flags_on_still_obstacle(true, vehicle__stillTransform[3], vehicle__stillBoxExtents)
    broadcastEvent(OnTankNavmeshFlagsLocalUpdate(pos = vehicle__stillTransform[3], extents = vehicle__stillBoxExtents))
  elif prevIsStill && !vehicle__isStill
    vehicle_not_still(eid, vehicle__stillTransform, vehicle__stillBoxExtents)

  if !vehicle__isStill
    vehicle__stillTransform = transform


[es(tag=server, on_disappear)]
def on_still_vehicle_disappear(evt : Event;
                               eid : EntityId;
                               vehicle__isStill : bool;
                               vehicle__stillBoxExtents : float;
                               vehicle__stillTransform : float3x4)
  if pathfinder_is_loaded_ex(NM_EXT_1) && vehicle__isStill
    vehicle_not_still(eid, vehicle__stillTransform, vehicle__stillBoxExtents)


[es(tag=server, on_event=OnTankNavmeshFlagsGlobalUpdate, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_new_path_on_nm_flags_global_update(evt : Event;
                                                       eid : EntityId;
                                                       ai_vehicle_tank__plannedPath : Point3List;
                                                       ai_vehicle_tank__thinkState : int)
  let MIN_PLANNED_PATH_LENGTH = 3
  if length(ai_vehicle_tank__plannedPath) < MIN_PLANNED_PATH_LENGTH || ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION)
    return
  set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_PATH, get_sync_time())


[es(tag=server, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_new_path_on_nm_flags_local_update(evt : OnTankNavmeshFlagsLocalUpdate;
                                                      eid : EntityId;
                                                      transform : float3x4;
                                                      ai_vehicle_tank__plannedPath : Point3List;
                                                      ai_vehicle_tank__maxPathLength : float;
                                                      ai_vehicle_tank__thinkState : int)
  let MIN_PLANNED_PATH_LENGTH = 3
  if (length(ai_vehicle_tank__plannedPath) < MIN_PLANNED_PATH_LENGTH || ai_vehicle_tank__thinkState == int(AiTankThinkState.ADVANCE_AND_UPDATE_DESTINATION) ||
      length_sq(evt.pos - transform[3]) > square(ai_vehicle_tank__maxPathLength + evt.extents))
    return
  set_tank_think_state(eid, AiTankThinkState.ADVANCE_AND_UPDATE_PATH, get_sync_time())


[es(tag=server, REQUIRE=turret_control__hasTankAiGunners, REQUIRE_NOT=deadEntity, after=turret_tank_ai_gunner_aim, before=apply_turret_aim_pos_to_remote_wish_dir_es)]
def turret_tank_ai_trigger_group(evt : CmdTurretsUpdate;
                                 turret_control__gunEids : EidList)
  for aiGunEid in turret_control__gunEids
    query(aiGunEid) <| $ [es(REQUIRE=(resolvedTurret, controlledByTankAiGunner), REQUIRE_NOT=turret__ignoreGroupTrigger)] (turret__groupHash aka ai_turret__groupHash : int;
                                                                                                                           turret_aim__shootToPos aka ai_turret_aim__shootToPos : float3;
                                                                                                                           turret_aim__shootFlag aka ai_turret_aim__shootFlag : bool;
                                                                                                                           turret_aim__target aka ai_turret_aim__target : EntityId)
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=controlledByTankAiGunner)] (turret__groupHash : int;
                                                                                               var turret_aim__shootToPos : float3&;
                                                                                               var turret_aim__shootFlag : bool&;
                                                                                               var turret_aim__target : EntityId&)
          if turret__groupHash == ai_turret__groupHash
            turret_aim__shootToPos = ai_turret_aim__shootToPos
            turret_aim__shootFlag = ai_turret_aim__shootFlag
            turret_aim__target = ai_turret_aim__target


[es(tag=server, on_event=EventOnGunCreated, REQUIRE=ai_vehicle_tank, REQUIRE_NOT=deadEntity)]
def turret_tank_ai_gun_init(evt : Event;
                            turret_control__gunEids : EidList)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE_NOT=gun__isLauncher)] (var turret__isControlledByTankAi : bool&)
      turret__isControlledByTankAi = true


[es(tag=server, on_appear, REQUIRE=vehicle, REQUIRE_NOT=deadEntity)]
def add_ai_to_tank_on_appear(evt : Event;
                             eid : EntityId;
                             ownedByPlayer : EntityId)
  query(ownedByPlayer) <| $ [es(REQUIRE=botAiEnabler)] ()
    addSubTemplate(eid, "ai_vehicle_tank")


def find_bullet_id(target_type : int; ammo : IntList; ammo_set_length : int; ammo_set_info : Array; bullet_type_efficiency : Array)
  let rangeEnd = min(length(ammo), ammo_set_length)
  var res = -1
  var score = 0.0

  let list = bullet_type_efficiency[target_type] as Object
  if list == null
    return res
  for i in range(rangeEnd)
    if ammo[i] > 0
      let ammoBt = ((ammo_set_info[i] as Array)?[0] ?as Object)?["type"] ?? ""
      if empty(ammoBt)
        continue
      for elem in *list
        if ammoBt == elem.key
          if score < elem.value ?? 0.0
            res = i
            score = elem.value ?? 0.0
          break
  return res


[es(tag=server, no_order, REQUIRE=ai_vehicle_tank, REQUIRE_NOT=deadEntity)]
def ai_vehicle_tank_choose_shell(info : ParallelUpdateFrameDelayed;
                                 eid aka vehicle_eid : EntityId;
                                 @shared_comp ai_vehicle_tank__bullet_type_efficiency : Array)
  query() <| $ [es] (gun : Gun;
                     eid : EntityId;
                     tank_turret_ai__curTargetType : int;
                     var nextBulletId : int&;
                     var currentBulletId : int&;
                     turret__owner : EntityId;
                     gun__ammoSets : Array;
                     @shared_comp gun__ammoSetsInfo : Array;
                     gun__ammo_by_shell : IntList;
                     gun__reloadFinishTime : float const?)
    if turret__owner == vehicle_eid
      let maybeNextBulletId = find_bullet_id(tank_turret_ai__curTargetType, gun__ammo_by_shell, length(gun__ammoSets), gun__ammoSetsInfo, ai_vehicle_tank__bullet_type_efficiency)
      if maybeNextBulletId < 0
        return
      if maybeNextBulletId != nextBulletId
        nextBulletId = maybeNextBulletId
        sendEvent(vehicle_eid, EventOnSelectNextBulletId(gunEid = eid, nextBulletId = nextBulletId))
      let isReloadChange = gun__reloadFinishTime ?? gun.nextShotAtTime > info.curTime
      let isCurrentShellTypeDepleted = currentBulletId < length(gun__ammo_by_shell) && gun__ammo_by_shell[currentBulletId] <= 0
      if isCurrentShellTypeDepleted || isReloadChange
        currentBulletId = nextBulletId


def kick_crew(vehicle_eid : EntityId)
  query(vehicle_eid) <| $ [es] (ownedBySquad : EntityId)
    query(ownedBySquad) <| $ [es] (squad__leader : EntityId)
      sendEvent(vehicle_eid, CmdKickFromVehicle(eid = squad__leader))
      removeSubTemplate(vehicle_eid, "ai_vehicle_tank")


[es(tag=server, REQUIRE=eid)]
def ai_vehicle_tank_on_enemy_killed(evt : EventEntityDied)
  query(evt.offender) <| $ [es(REQUIRE_NOT=deadEntity)] (isInVehicle : bool;
                                                         vehicle__lastEid : EntityId)
    if !isInVehicle
      return
    query(vehicle__lastEid) <| $ [es(REQUIRE_NOT=deadEntity)] (ai_vehicle_tank__generalBoredomDecreasePerKill : float;
                                                               ai_vehicle_tank__objectiveBoredomDecreasePerKill : float;
                                                               var ai_vehicle_tank__timerGeneralBoredom : float&;
                                                               var ai_vehicle_tank__timerObjectiveBoredom : float&)
      add_elapsed_time_to_variable_timer(-ai_vehicle_tank__generalBoredomDecreasePerKill, /*paused*/false, get_sync_time(), ai_vehicle_tank__timerGeneralBoredom)
      add_elapsed_time_to_variable_timer(-ai_vehicle_tank__objectiveBoredomDecreasePerKill, /*paused*/false, get_sync_time(), ai_vehicle_tank__timerObjectiveBoredom)


[es(on_event=EventOnSeatOwnersChanged, REQUIRE=ai_vehicle_tank)]
def ai_vehicle_tank_on_seat_owner_changed(evt : Event; eid : EntityId; ownedBySquad : EntityId; ownedByPlayer : EntityId)
  let bestLeaderEid = find_best_leader_in_vehicle(ownedBySquad, eid)
  if bestLeaderEid != INVALID_ENTITY_ID
    sendEvent(ownedByPlayer, CmdPossessEntity(possessedEid = bestLeaderEid))
