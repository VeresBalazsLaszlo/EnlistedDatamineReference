options no_aot
require ecs
require ecs.ecs_template
require math.base
require strings
require vehicle
require game.es.ai.timer_common
require game.es.net_console_macro
require game.es.vehicle.vehicle_events
require DagorDebug3D


[console_cmd(name="ai.debug_tank")]
def ai_vehicle_tank_debug_cmd()
  if !is_server()
    exec_server_cmd("ai.debug_tank")
    return
  let exist = find_query() <| $ [es(REQUIRE=aiVehicleTankDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !exist
    createEntity("ai_vehicle_tank_debug_enabler")


[es(tag=server, no_order, REQUIRE=aiVehicleTankDebug)]
def ai_vehicle_tank_server_debug(info : UpdateStageInfoAct)
  query() <| $ [es(REQUIRE_NOT=deadEntity)] (ai_vehicle_tank__plannedPath : Point3List;
                                             ai_vehicle_tank__thinkState : int;
                                             ai_vehicle_tank__motionState : int;
                                             ai_vehicle_tank__checkedObjective : EntityId;
                                             ai_vehicle_tank__curObjective : EntityId;
                                             ai_vehicle_tank__curObjectivePosIdx : int;
                                             ai_vehicle_tank__runOverImpatience : float;
                                             ai_vehicle_tank__timerGeneralBoredom : float;
                                             ai_vehicle_tank__timerObjectiveBoredom : float;
                                             ai_vehicle_tank__timerNextPosition : float;
                                             ai_vehicle_tank__timerInsideObstacle : float;
                                             ai_vehicle_tank__timerOutsideObstacle : float;
                                             ai_vehicle_tank__timerOutsideNavmesh : float;
                                             ai_vehicle_tank__timerThinkState : float;
                                             ai_vehicle_tank__waitTimesOutsideNavmesh : float;
                                             ai_vehicle_tank__waitTimesInsideObstacle : float2;
                                             ai_vehicle_tank__waitTimesOutsideObstacle : float;
                                             ai_vehicle_tank__waitTimesNextPosition : float;
                                             ai_vehicle_tank__waitTimesGeneralBoredom : float;
                                             ai_vehicle_tank__waitTimesObjectiveBoredom : float;
                                             ai_vehicle_tank__waitTimesThinkState : float;
                                             vehicle_net_phys : VehiclePhysActor;
                                             var ai_vehicle_tank__debugPlannedPath : Point3List&;
                                             var ai_vehicle_tank__debugInfo : StringList&)
    let curTime = info.curTime
    let generalBoredomTimerOutput = check_variable_timer(curTime, ai_vehicle_tank__waitTimesGeneralBoredom, ai_vehicle_tank__timerGeneralBoredom, /*paused*/false)
    let objectiveBoredomTimerOutput = check_variable_timer(curTime, ai_vehicle_tank__waitTimesObjectiveBoredom, ai_vehicle_tank__timerObjectiveBoredom, /*paused*/false)
    let nextPositionTimerOutput = check_simple_timer(curTime, ai_vehicle_tank__waitTimesNextPosition, ai_vehicle_tank__timerNextPosition)
    let insideObstacleTimerOutput = check_simple_timer(curTime, ai_vehicle_tank__waitTimesInsideObstacle, ai_vehicle_tank__timerInsideObstacle)
    let outsideObstacleTimerOutput = check_simple_timer(curTime, ai_vehicle_tank__waitTimesOutsideObstacle, ai_vehicle_tank__timerOutsideObstacle)
    let outsideNavmeshTimerOutput = check_simple_timer(curTime, ai_vehicle_tank__waitTimesOutsideNavmesh, ai_vehicle_tank__timerOutsideNavmesh)
    let thinkTimerOutput = check_simple_timer(curTime, ai_vehicle_tank__waitTimesThinkState, ai_vehicle_tank__timerThinkState)
    assume producedCT = vehicle_net_phys.phys.producedCT

    ai_vehicle_tank__debugPlannedPath := ai_vehicle_tank__plannedPath
    clear(ai_vehicle_tank__debugInfo)

    var text = build_string() <| $(var str)
      format(str, "TS: %d  ", ai_vehicle_tank__thinkState)
      format(str, "MS: %d  ", ai_vehicle_tank__motionState)
      format(str, "ChO: %d  ", uint(ai_vehicle_tank__checkedObjective))
      format(str, "CrO: %d  ", uint(ai_vehicle_tank__curObjective))
      format(str, "CrOI: %d  ", ai_vehicle_tank__curObjectivePosIdx)
    push(ai_vehicle_tank__debugInfo, text)

    text = build_string() <| $(var str)
      format(str, "ROI: %.2f  ", ai_vehicle_tank__runOverImpatience)
      format(str, "PL: %d  ", length(ai_vehicle_tank__plannedPath))
      format(str, "T: %.2f  ", curTime)
      format(str, "TTS: %d|", int(thinkTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerThinkState)
    push(ai_vehicle_tank__debugInfo, text)

    text = build_string() <| $(var str)
      format(str, "TGB: %d|", int(generalBoredomTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerGeneralBoredom)
      format(str, "TOB: %d|", int(objectiveBoredomTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerObjectiveBoredom)
      format(str, "TNP: %d|", int(nextPositionTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerNextPosition)
    push(ai_vehicle_tank__debugInfo, text)

    text = build_string() <| $(var str)
      format(str, "TIO: %d|", int(insideObstacleTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerInsideObstacle)
      format(str, "TOO: %d|", int(outsideObstacleTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerOutsideObstacle)
      format(str, "TON: %d|", int(outsideNavmeshTimerOutput))
      format(str, "%.2f  ", ai_vehicle_tank__timerOutsideNavmesh)
    push(ai_vehicle_tank__debugInfo, text)

    text = build_string() <| $(var str)
      format(str, "CTh: %.2f|", producedCT |> ground_control_state_getAxisValue(EGroundControlAxis.GCA_THROTTLE))
      format(str, "CSt: %.2f|", producedCT |> ground_control_state_getAxisValue(EGroundControlAxis.GCA_STEERING))
      format(str, "CBr: %.2f|", producedCT |> ground_control_state_getAxisValue(EGroundControlAxis.GCA_HAND_BRAKE))
    push(ai_vehicle_tank__debugInfo, text)


[es(tag=render, on_appear, REQUIRE=aiVehicleTankDebug)]
def ai_vehicle_tank_render_debug_on_appear(evt : Event)
  console_print("AI tank debug on")


[es(tag=render, on_disappear, REQUIRE=aiVehicleTankDebug)]
def ai_vehicle_tank_render_debug_on_disappear(evt : Event)
  console_print("AI tank debug off")


[es(tag=render, no_order, REQUIRE=aiVehicleTankDebug)]
def ai_vehicle_tank_render_debug(info : UpdateStageInfoRenderDebug)
  begin_draw_cached_debug_lines(false, false, false)
  query() <| $ [es(REQUIRE_NOT=deadEntity)] (transform : float3x4;
                                             ai_vehicle_tank__debugInfo : StringList;
                                             ai_vehicle_tank__debugPlannedPath : Point3List)
    var offset = -0.5
    let offsetStep = 1.5
    for text in ai_vehicle_tank__debugInfo
      add_debug_text_mark(transform[3], string(text), /*max len*/ -1, offset, E3DCOLOR(0xFF68D3C5))
      offset += offsetStep

    for i in iter_range(ai_vehicle_tank__debugPlannedPath)
      let point1 = i == 0 ? transform[3] : ai_vehicle_tank__debugPlannedPath[i - 1]
      let point2 = ai_vehicle_tank__debugPlannedPath[i]
      draw_debug_line_buffered(point1, point2, E3DCOLOR(0xFF0000FF), 1)
      draw_debug_sphere_buffered(point2, 0.5, E3DCOLOR(0xFF00FF00), 12, 1)
  end_draw_cached_debug_lines()


def create(eid : uint; template_name : string; count = 1)
  var tm : float3x4
  var tmIsSet = false

  if eid == 0u
    find_query() <| $ [es] (camera__active : bool; transform : float3x4)
      if camera__active
        tmIsSet = true
        tm = transform
        tm[3] = tm[3] + tm |> rotate <| float3(0f, 0f, 2f)
      return camera__active

  if !tmIsSet
    query(EntityId(eid)) <| $ [es] (transform : float3x4)
      tmIsSet = true
      tm = transform
      tm[3] = tm[3] + tm[0] * 2f + tm[1]

  if !tmIsSet
    tm |> identity()

  var res : EntityId
  for _ in range(count)
    let ceid = createEntity(template_name) <| $(var init : ComponentsInitializer)
      set(init, "transform", tm)
    if !!ceid
      console_print("{ceid}: creating entity <{template_name}>")
      res = ceid
  return res


def vehicle_spawn_crew(team : int;
                       crew_template : string;
                       player_template : string;
                       vehicle_eid : EntityId)
  query(vehicle_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (vehicle_seats__seatEids : EidList)
    var seats : array<int>
    for seat in vehicle_seats__seatEids
      query(seat) <| $ [es] (seat__ownerEid : EntityId; seat__id : int)
        let hasOwner = query(seat__ownerEid) <| $ [es(REQUIRE_NOT=deadEntity)] () {}
        if !hasOwner
          seats |> push(seat__id)
    if !empty(seats)
      let playerEid = createEntity(player_template) <| $(var init)
        set(init, "canBeLocal", false)
        set(init, "team", team)
      for seatId in seats
        let finalize <- @ <| (crewEid : EntityId)
          sendEvent(playerEid, CmdUseVehicleOnSpawn(vehicle = vehicle_eid, seatOrderNo = seatId, squad = INVALID_ENTITY_ID, possessed = crewEid))
        createEntity(crew_template, finalize) <| $(var init)
          set(init, "squad_member__playerEid", playerEid)
          set(init, "team", team)


[console_cmd(name="vehicle.spawn_ai_tank")]
def spawn_ai_tank(tank_team : int; x : float = 0.0; y : float = 0.0; z : float = 0.0)
  var tm = IDENT_TM
  if x == 0.0 && y == 0.0 && z == 0.0
    find_query() <| $ [es] (camera__active : bool; transform : float3x4)
      if camera__active
        tm = transform
        tm[3] = tm[3] + tm |> rotate <| float3(0f, 0f, 2f)
      return camera__active
  else
    tm[3] = float3(x, y, z)

  if !is_server()
    exec_server_cmd("vehicle.spawn_ai_tank {tank_team} {tm[3].x} {tm[3].y} {tm[3].z}")
    return

  let finalizeCreation <- @ <| (tank_eid : EntityId)
    vehicle_spawn_crew(tank_team, "dev_soldier", "bot_player", tank_eid)
    query(tank_eid) <| $ [es] (var team : int&)
      team = tank_team
  createEntity("germ_pzkpfw_IV_ausf_J_zombie+ai_vehicle_tank", finalizeCreation) <| $(var init : ComponentsInitializer&)
    set(init, "transform", tm)


[console_cmd(name="vehicle.spawn_in_crew")]
def spawn_in_crew(crew_team : int; tank_eid : uint)
  query(EntityId(tank_eid)) <| $ [es] (var team aka tank_team : int&)
    tank_team = crew_team
    vehicle_spawn_crew(team, "dev_soldier", "bot_player", EntityId(tank_eid))
