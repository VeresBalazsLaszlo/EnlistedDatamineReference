options no_aot

require ecs
require app
require Dacoll
require PhysMat
require DagorInput
require DagorEditor
require DagorDebug3D
require DagorConsole
require enlisted.events_enlisted
require game.es.input.input_events
require game.es.context_command_common
require enlisted.game.es.squad_personal_order_common
require ecs.ecs_template


[ecs_template]
struct ai_free_camera_control_debug_tmpl
  nonCreatableObj : bool = true
  aiFreeCameraControlDebug : Tag
  ai_free_cam_control__time1 : float = 0.0
  ai_free_cam_control__squad : EntityId = INVALID_ENTITY_ID
  ai_free_cam_control__wasMaxOrderDist : float = -1.0

[console_cmd(name="ai.free_camera_control", hint="Allows to give orders to your squad bots from free camera with RClick and disables orders distance limits")]
def ai_free_camera_control_toggle_command()
  var debugEid = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=aiFreeCameraControlDebug)] (eid : EntityId)
    debugEid = eid
  if debugEid != INVALID_ENTITY_ID
    ai_free_camera_control_unlock()
    destroyEntity(debugEid)
    console_print("AI Free Camera Control: disabled")
    //activate_action_set(get_action_set_handle("StopInput"), false) -- don't to allow first-person controls
  else
    createEntity("ai_free_camera_control_debug_tmpl")
    console_print("AI Free Camera Control: enabled")
    //activate_action_set(get_action_set_handle("StopInput"), true) -- don't to allow first-person controls


def private get_real_time_sec()
  return float(get_time_usec(int64(0))) * 0.000001


def ai_free_camera_control_trace(var pos : float3&; var dist : float&) : bool
  var result = false
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false
    let traceDir = transform[2]
    let traceFrom = transform[3]
    var matId = PHYSMAT_INVALID
    var norm : float3
    var riDesc = RendInstDesc()
    dist = 4000f
    if traceray_normalized(traceFrom, traceDir, dist, matId, norm, ETF_ALL, riDesc, -1)
      pos = traceFrom + traceDir * dist
      result = true
    return true
  return result

def ai_free_camera_control_command(squad_eid : EntityId)
  if is_editor_activated()
    return
  var pos : float3
  var dist : float
  if !ai_free_camera_control_trace(pos, dist)
    return
  query(squad_eid) <| $ [es] (squad__leader : EntityId)
    query(squad__leader) <| $ [es] (eid : EntityId;
                                    squad_member__isPersonalContextCommandMode : bool;
                                    var human_context_command__orderType : int&;
                                    var human_context_command__orderPosition : float3&;
                                    var human_context_command__orderUseEntity : EntityId&)
      human_context_command__orderType = int(ContextCommand.ECC_DEFEND_POINT)
      human_context_command__orderPosition = pos
      human_context_command__orderUseEntity = INVALID_ENTITY_ID
      if squad_member__isPersonalContextCommandMode
        sendEvent(eid, RqPersonalContextCommand())
      else
        sendEvent(eid, RqContextCommand())

def ai_free_camera_control_cancel_command(squad_eid : EntityId)
  if is_editor_activated()
    return
  query(squad_eid) <| $ [es] (squad__leader : EntityId)
    query(squad__leader) <| $ [es] (squad_member__isPersonalContextCommandMode : bool = false)
      if squad_member__isPersonalContextCommandMode
        sendEvent(squad__leader, RqCancelPersonalContextCommand())
      else
        sendEvent(squad__leader, RqCancelContextCommand(include_personal_orders = true))

def ai_free_camera_control_unlock()
  query() <| $ [es(REQUIRE=aiFreeCameraControlDebug)] (var ai_free_cam_control__squad : EntityId&;
                                                       var ai_free_cam_control__wasMaxOrderDist : float&)
    if ai_free_cam_control__wasMaxOrderDist > 0.0
      query(ai_free_cam_control__squad) <| $ [es] (var squad__maxOrderDistance : float&)
        squad__maxOrderDistance = ai_free_cam_control__wasMaxOrderDist
      ai_free_cam_control__wasMaxOrderDist = -1.0
    ai_free_cam_control__squad = INVALID_ENTITY_ID


[es(tag=(input, server), REQUIRE=aiFreeCameraControlDebug)]
def ai_free_camera_control_input_es(evt : EventHidGlobalInputSink;
                                    var ai_free_cam_control__time1 : float&;
                                    ai_free_cam_control__squad : EntityId)
  if is_editor_activated()
    return

  //console_print("!!! key={evt.button_id} pressed={evt.pressed} get_real_time_sec={get_real_time_sec()}")

  if evt.button_id == 0x201 // RMB
    if evt.pressed
      ai_free_cam_control__time1 = get_real_time_sec() + 0.35
    elif ai_free_cam_control__time1 != 0.0
      ai_free_cam_control__time1 = 0.0
      ai_free_camera_control_command(ai_free_cam_control__squad)
    return

  if evt.button_id == 0x202 // MMB
    if evt.pressed
      query(ai_free_cam_control__squad) <| $ [es] (squad__allMembers : EidList)
        for memberEid in squad__allMembers
          query(memberEid) <| $ [es] (var squad_member__isPersonalContextCommandMode : bool&)
            squad_member__isPersonalContextCommandMode = !squad_member__isPersonalContextCommandMode
    return

  if evt.button_id == 0x205 // Wheel Up
    if evt.pressed
      query(ai_free_cam_control__squad) <| $ [es] (squad__leader : EntityId)
        query(squad__leader) <| $ [es] (var personal_bot_order__currentBotEid : EntityId&)
          let wasEid = personal_bot_order__currentBotEid
          var setEid = personal_bot_order__currentBotEid
          var newEid = find_next_bot_for_personal_order(squad__leader, ai_free_cam_control__squad, wasEid)
          while newEid != wasEid
            setEid = newEid
            newEid = find_next_bot_for_personal_order(squad__leader, ai_free_cam_control__squad, newEid)
          personal_bot_order__currentBotEid = setEid
    return

  if evt.button_id == 0x206 // Wheel Down
    if evt.pressed
      query(ai_free_cam_control__squad) <| $ [es] (squad__leader : EntityId)
        query(squad__leader) <| $ [es] (var personal_bot_order__currentBotEid : EntityId&)
          personal_bot_order__currentBotEid = find_next_bot_for_personal_order(squad__leader, ai_free_cam_control__squad, personal_bot_order__currentBotEid)
    return


[es(tag=(input, server), REQUIRE=aiFreeCameraControlDebug)]
def ai_free_camera_control_update_es(info : ParallelUpdateFrameDelayed;
                                     var ai_free_cam_control__time1 : float&;
                                     var ai_free_cam_control__squad : EntityId&;
                                     var ai_free_cam_control__wasMaxOrderDist : float&)
  if ai_free_cam_control__time1 != 0.0
    if get_real_time_sec() >= ai_free_cam_control__time1
      ai_free_cam_control__time1 = 0.0
      // NOTE: holding RMB also used for aiming/zoom, so interfere with first-person here
      ai_free_camera_control_cancel_command(ai_free_cam_control__squad)

  query() <| $ [es(REQUIRE=watchedByPlr)] (squad_member__squad : EntityId)
    if squad_member__squad != ai_free_cam_control__squad
      ai_free_camera_control_unlock()
      ai_free_cam_control__squad = squad_member__squad
      ai_free_cam_control__wasMaxOrderDist = -1.0
      query(squad_member__squad) <| $ [es] (var squad__maxOrderDistance : float&)
        ai_free_cam_control__wasMaxOrderDist = squad__maxOrderDistance
        squad__maxOrderDistance = FLT_MAX


def private draw_cross(pos : float3; dist : float; c1 : E3DCOLOR; c2 : E3DCOLOR)
  let coef = (dist > 10.f) ? (dist / 10.f) : 1.f
  let pd = 0.2 * coef
  let nd = -pd

  let pos1 = pos + float3(0f, 0f, nd)
  let pos2 = pos + float3(0f, 0f, pd)
  let pos3 = pos + float3(nd, 0f, 0f)
  let pos4 = pos + float3(pd, 0f, 0f)

  let ud = -0.01 * coef
  let posu = pos + float3(0f, ud, 0f)
  let pos1u = pos1 + float3(0f, ud, 0f)
  let pos2u = pos2 + float3(0f, ud, 0f)
  let pos3u = pos3 + float3(0f, ud, 0f)
  let pos4u = pos4 + float3(0f, ud, 0f)

  begin_draw_cached_debug_lines(false, false, false)
  draw_cached_debug_line(posu, pos1u, c2)
  draw_cached_debug_line(posu, pos2u, c2)
  draw_cached_debug_line(posu, pos3u, c2)
  draw_cached_debug_line(posu, pos4u, c2)
  draw_cached_debug_line(pos, pos1, c1)
  draw_cached_debug_line(pos, pos2, c1)
  draw_cached_debug_line(pos, pos3, c1)
  draw_cached_debug_line(pos, pos4, c1)
  end_draw_cached_debug_lines()

[es(tag=(render, server), no_order, REQUIRE=aiFreeCameraControlDebug)]
def ai_free_camera_control_render_es(evt : UpdateStageInfoRenderDebug; ai_free_cam_control__squad : EntityId)
  if is_editor_activated()
    return

  var pos : float3
  var dist : float
  if !ai_free_camera_control_trace(pos, dist)
    return

  let c1 = E3DCOLOR(0xFF0000AA)
  let c2 = E3DCOLOR(0xFF000000)

  draw_cross(pos, dist, c1, c2)

  let c3 = E3DCOLOR(0xFF00AA00)
  let c4 = E3DCOLOR(0xFF000000)

  query(ai_free_cam_control__squad) <| $ [es] (squad__regroupPos : float3)
    draw_cross(squad__regroupPos, dist, c3, c4)
