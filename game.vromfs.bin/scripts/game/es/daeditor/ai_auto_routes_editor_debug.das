options no_aot

require ecs
require app
require Dacoll
require PhysMat
require math.base
require DagorInput
require DagorEditor
require DagorDebug3D
require DagorDebug3DSolid
require DagorConsole
require strings
require daslib/strings_boost
require enlisted.events_enlisted
require game.es.input.input_events

[console_cmd(name="ai.auto_routes_editor", hint="Toggles auto-moving bots routes editor")]
def ai_auto_routes_editor_toggle()
  var debugEid = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=aiAutoRoutesEditor)] (eid : EntityId)
    debugEid = eid
  if debugEid != INVALID_ENTITY_ID
    destroyEntity(debugEid)
    console_print("AI Auto Routes Editor: OFF")
    activate_action_set(get_action_set_handle("StopInput"), false)
  else
    createEntity("ai_auto_routes_editor")
    console_print("-----------------------------------------------------------------------------------------")
    console_print("AI Auto Routes Editor:")
    console_print("  Use Ctrl+LClick to create new route (then 1, 2, 3 for team if team entity exists)")
    console_print("  Use Shift+LClick to add next point or split at mid-point")
    console_print("  Use Backspace to delete last point")
    console_print("  Use LClick+drag to move point")
    console_print("  Use LClick/RClick to switch squadId(for route) or +5s/-5s(for point)")
    console_print("  Use LClick to select another route")
    console_print("  Use RClick to deselect route")
    console_print("  Use Shift+RClick to delete point")
    console_print("  Use Ctrl+Del to delete route")
    console_print("  Use Ctrl+Z/Ctrl+Y to undo/redo")
    console_print("-----------------------------------------------------------------------------------------")
    activate_action_set(get_action_set_handle("StopInput"), true)


enum private EditOp
  CREATE_ROUTE = 1 // op, team, ridx, rcnt + val.xyzw (first point)
  DELETE_ROUTE = 2 // op, team, ridx, rcnt
  ADD_POINT = 3    // op, team, ridx, pidx + val.xyzw
  DEL_POINT = 4    // op, team, ridx, pidx
  EDIT_POINT = 5   // op, team, ridx, pidx + val.xyzw
  READD_POINT = 6  // op, team, ridx, pidx + val.xyzw

def private push_op(var ops : IPoint4List&; var vals : Point4List&; var strs : StringList&; op, team, ridx, arg : int; val : float4; str : string)
  if op == int(EditOp.EDIT_POINT) && !empty(ops) && length(ops) == length(vals)
    let len = length(ops)
    let wop = ops[len - 1]
    if wop.x == int(EditOp.EDIT_POINT) && wop.y == team && wop.z == ridx && wop.w == arg && vals[len - 1].xyz == val.xyz
      return
  ops |> push(int4(op, team, ridx, arg))
  vals |> push(val)
  strs |> push(str)

def private has_op(ops : IPoint4List; vals : Point4List; strs : StringList)
  return !empty(ops) && !empty(vals) && !empty(strs)

def private clear_ops(var ops : IPoint4List&; var vals : Point4List&; var strs : StringList&)
  ops |> clear()
  vals |> clear()
  strs |> clear()

def private get_op(ops : IPoint4List&; var out_team, out_ridx, out_arg : int&)
  let len = length(ops)
  if len <= 0
    return -1
  let op = ops[len - 1]
  out_team = op.y
  out_ridx = op.z
  out_arg = op.w
  return op.x

def private pop_op(var ops : IPoint4List&; var vals : Point4List&; var strs : StringList&)
  if !empty(ops) && !empty(vals) && !empty(strs)
    ops |> pop()
    vals |> pop()
    strs |> pop()

def private get_op_val(vals : Point4List)
  let len = length(vals)
  return (len > 0) ? vals[len - 1] : float4()

def private get_op_str(strs : StringList&)
  let len = length(strs)
  return (len > 0) ? string(strs[len - 1]) : ""


def private log_op(msg)
  console_print(msg)

def private exec_op(op, team, ridx, arg : int; val : float4; str : string; var back_ops : IPoint4List&; var back_vals : Point4List&; var back_strs : StringList&)
  var result = false
  find_query() <| $ [es] (team__id : int; var team__autoRouteBotSquads : Array&)
    if team__id != team
      return false
    let rcnt = length(team__autoRouteBotSquads)

    if op == int(EditOp.CREATE_ROUTE)
      if ridx < 0 || ridx > rcnt || arg != rcnt
        log_op("CREATE_ROUTE error: ridx={ridx} rcnt={rcnt} arg={arg}")
        return false
      push_op(back_ops, back_vals, back_strs, int(EditOp.DELETE_ROUTE), team, ridx, arg + 1, float4(), "")
      using() <| $(var squad : Object)
        squad |> set("squadId", str)
        using() <| $(var points : Array)
          points |> push(val)
          squad |> set("points", points)
        team__autoRouteBotSquads |> push(ridx, squad)
      result = true
      return true

    if op == int(EditOp.DELETE_ROUTE)
      if ridx < 0 || ridx >= rcnt || arg != rcnt
        log_op("DELETE_ROUTE error: ridx={ridx} rcnt={rcnt} arg={arg}")
        return false
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[ridx])
      if routeObj == null
        log_op("DELETE_ROUTE error: no routeObj")
        return false
      var squadId = get_ecs_string(routeObj, "squadId")
      var points = getRW_ecs_array(routeObj, "points")
      if squadId == null || points == null
        log_op("DELETE_ROUTE error: no squadId or points")
        return false
      let len = length(*points)
      if len <= 0
        log_op("DELETE_ROUTE len <= 0")
        return false
      let pt0 = get_Point4((*points)[0]) ?? float4(0.0, 0.0, 0.0, 0.0)
      for i in range(len)
        let pidx = len - 1 - i
        if pidx > 0
          let pt = get_Point4((*points)[pidx]) ?? float4(0.0, 0.0, 0.0, 0.0)
          push_op(back_ops, back_vals, back_strs, int(EditOp.READD_POINT), team, ridx, pidx, pt, "")
      push_op(back_ops, back_vals, back_strs, int(EditOp.CREATE_ROUTE), team, ridx, arg - 1, pt0, string(*squadId))
      team__autoRouteBotSquads |> erase(ridx)
      result = true
      return true

    if op == int(EditOp.ADD_POINT) || op == int(EditOp.READD_POINT)
      let pidx = arg
      if ridx < 0 || ridx >= rcnt || pidx <= 0
        log_op("ADD_POINT/READD_POINT error: ridx={ridx} rcnt={rcnt} pidx={pidx}")
        return false
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[ridx])
      if routeObj == null
        log_op("ADD_POINT/READD_POINT error: no routeObj")
        return false
      var points = getRW_ecs_array(routeObj, "points")
      if points == null || pidx > length(*points)
        log_op("ADD_POINT/READD_POINT error: no points or pidx={pidx} > len(points)={length(*points)}")
        return false
      push_op(back_ops, back_vals, back_strs, int(EditOp.DEL_POINT), team, ridx, pidx, float4(), "")
      *points |> push(pidx, val)
      result = true
      return true

    if op == int(EditOp.DEL_POINT)
      let pidx = arg
      if ridx < 0 || ridx >= rcnt || pidx <= 0
        log_op("DEL_POINT error: ridx={ridx} rcnt={rcnt} pidx={pidx}")
        return false
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[ridx])
      if routeObj == null
        log_op("DEL_POINT error: no routeObj")
        return false
      var points = getRW_ecs_array(routeObj, "points")
      if points == null || pidx >= length(*points)
        log_op("DEL_POINT error: no points or pidx={pidx} >= len(points)={length(*points)}")
        return false
      let pt = get_Point4((*points)[pidx]) ?? float4(0.0, 0.0, 0.0, 0.0)
      push_op(back_ops, back_vals, back_strs, int(EditOp.ADD_POINT), team, ridx, pidx, pt, "")
      *points |> erase(pidx)
      result = true
      return true

    if op == int(EditOp.EDIT_POINT)
      let pidx = arg
      if ridx < 0 || ridx >= rcnt || pidx < 0
        log_op("EDIT_POINT error: ridx={ridx} rcnt={rcnt} pidx={pidx}")
        return false
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[ridx])
      if routeObj == null
        log_op("EDIT_POINT error: no routeObj")
        return false
      var points = getRW_ecs_array(routeObj, "points")
      if points == null || pidx >= length(*points)
        log_op("EDIT_POINT error: no points or pidx={pidx} >= len(points)={length(*points)}")
        return false
      var pt = getRW_Point4((*points)[pidx])
      if pt == null
        log_op("EDIT_POINT error: no pt")
        return false
      push_op(back_ops, back_vals, back_strs, int(EditOp.EDIT_POINT), team, ridx, pidx, *pt, "")
      *pt = val
      result = true
      return true

    return true
  return result


def private get_real_time_sec()
  return float(get_time_usec(int64(0))) * 0.000001


def ai_auto_routes_get_trace(var trace_pos, trace_dir : float3&)
  var result = false
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false
    trace_pos = transform[3]
    trace_dir = normalize(transform[2])
    result = true
    return true
  return result

def ai_auto_routes_trace(trace_pos, trace_dir : float3; var out_pos : float3&; var out_dist : float&) : bool
  var matId = PHYSMAT_INVALID
  var norm : float3
  var riDesc = RendInstDesc()
  var dist = 4000f
  if traceray_normalized(trace_pos, trace_dir, dist, matId, norm, ETF_ALL, riDesc, -1)
    out_pos = trace_pos + trace_dir * dist
    out_dist = dist
    return true
  return false

def ai_auto_routes_trace_sphere(trace_pos, trace_dir : float3; pos : float3; radius : float; var out_dist : float&) : bool
  let dcenter = trace_pos - pos
  let b = 2.0f * dot(dcenter, trace_dir)
  let c = dot(dcenter, dcenter) - radius * radius
  let d = b * b - 4.0 * c
  if (d < 0.0f)
    return false
  let sq = sqrt(d)
  let v0 = (-b - sq) * 0.5
  let v1 = (-b + sq) * 0.5
  if v0 >= 0.0
    if v1 >= 0.0
      out_dist = min(v0, v1)
      return true
    out_dist = v1
  elif v1 >= 0.0
    out_dist = v0
    return true
  return false

def ai_auto_routes_trace_line(trace_pos, trace_dir : float3; pos1, pos2 : float3; line_radius : float; var out_dist : float&) : bool
  let vec = pos2 - pos1
  let dir = normalize(vec)
  let len = sqrt(dot(vec, vec))
  let dht = pos2.y - pos1.y
  let norm = normalize(-dir * dht + float3(0.0, len, 0.0))

  let div = dot(norm, trace_dir)
  if abs(div) < 0.0001
    return false

  let dist = dot(norm, pos1 - trace_pos) / div
  let pt = trace_pos + trace_dir * dist

  let d1 = dot(dir, pt) - dot(dir, pos1)
  if d1 < 0.0
    return false
  let d2 = dot(-dir, pt) - dot(-dir, pos2)
  if d2 < 0.0
    return false

  let off = float3(-dir.z, 0.0, dir.x) * line_radius

  let d3 = dot(-off, pt) - dot(-off, pos1 + off)
  if d3 < 0.0
    return false
  let d4 = dot(off, pt) - dot(off, pos2 - off)
  if d4 < 0.0
    return false

  out_dist = dist
  return true


def private by_mask(value : int; mask : int)
  return (value & mask) != 0

def private set_mask(var value : int&; mask : int; on : bool)
  if on
    value |= mask
  else
    value &= ~mask

let private
  INPUT_LCLICK = 1
  INPUT_RCLICK = 2
  INPUT_LCTRL = 4
  INPUT_RCTRL = 8
  INPUT_CTRL = INPUT_LCTRL | INPUT_RCTRL
  INPUT_LSHIFT = 16
  INPUT_RSHIFT = 32
  INPUT_SHIFT = INPUT_LSHIFT | INPUT_RSHIFT
  INPUT_DELETE = 64
  INPUT_Z = 128
  INPUT_Y = 256
  INPUT_1 = 512
  INPUT_2 = 1024
  INPUT_3 = 2048
  INPUT_BKSPC = 4096

[es(tag=(input, server), REQUIRE=aiAutoRoutesEditor)]
def ai_auto_routes_editor_input_es(evt : EventHidGlobalInputSink;
                                   var free_cam_input__allowZoom : bool&;
                                   var ai_auto_routes_editor__inputs : int&)
  assume inputs = ai_auto_routes_editor__inputs
  if is_editor_activated() && !is_editor_free_camera_enabled()
    inputs = 0; free_cam_input__allowZoom = true
    return

  //console_print("!!! button_id={evt.button_id} pressed={evt.pressed}")

  if evt.button_id == 0x200
    set_mask(inputs, INPUT_LCLICK, evt.pressed)
  elif evt.button_id == 0x201
    set_mask(inputs, INPUT_RCLICK, evt.pressed)
  elif evt.button_id == 0x11D
    set_mask(inputs, INPUT_LCTRL, evt.pressed)
  elif evt.button_id == 0x19D
    set_mask(inputs, INPUT_RCTRL, evt.pressed)
  elif evt.button_id == 0x12A
    set_mask(inputs, INPUT_LSHIFT, evt.pressed)
  elif evt.button_id == 0x136
    set_mask(inputs, INPUT_RSHIFT, evt.pressed)
  elif evt.button_id == 0x1D3
    set_mask(inputs, INPUT_DELETE, evt.pressed)
  elif evt.button_id == 0x12C
    set_mask(inputs, INPUT_Z, evt.pressed)
  elif evt.button_id == 0x115
    set_mask(inputs, INPUT_Y, evt.pressed)
  elif evt.button_id == 0x102
    set_mask(inputs, INPUT_1, evt.pressed)
  elif evt.button_id == 0x103
    set_mask(inputs, INPUT_2, evt.pressed)
  elif evt.button_id == 0x104
    set_mask(inputs, INPUT_3, evt.pressed)
  elif evt.button_id == 0x10E
    set_mask(inputs, INPUT_BKSPC, evt.pressed)

  // NOTE: disable free camera zoom for Ctrl+key combinations (for Ctrl+Z)
  free_cam_input__allowZoom = !by_mask(inputs, INPUT_CTRL)


[es(tag=(input, server), REQUIRE=aiAutoRoutesEditor, on_appear)]
def ai_auto_routes_editor_init_es(evt : Event)
  query() <| $ [es] (team__id : int)
    broadcastEvent(EventAutoRoutesRequestSquads(team = team__id))

[es(tag=(input, server), on_appear)]
def ai_auto_routes_editor_team_appear_es(evt : Event; team__id : int)
  broadcastEvent(EventAutoRoutesRequestSquads(team = team__id))

[es(tag=(input, server))]
def ai_auto_routes_editor_squads_response_es(evt : EventAutoRoutesResponseSquads; team__id : int;
                                             var team__autoRouteBotSquadsList : StringList&)
  if evt.team == team__id
    clear(team__autoRouteBotSquadsList)
    let squadIds <- evt.squadsIds |> split(",")
    team__autoRouteBotSquadsList |> reserve(length(squadIds))
    for squadId in squadIds
      team__autoRouteBotSquadsList |> push(squadId)

def get_team_next_squad_id(team_eid : EntityId; squad_id : string; delta : int) : string
  var result = ""
  query(team_eid) <| $ [es] (team__autoRouteBotSquadsList : StringList)
    let len = length(team__autoRouteBotSquadsList)
    var idx = -1
    for squadIdx in range(len)
      if team__autoRouteBotSquadsList[squadIdx] == squad_id
        idx = squadIdx
        break
    idx += delta
    if idx < -1
      idx = len - 1
    elif idx >= len
      idx = -1
    if idx < 0
      result = "random"
    else
      result := team__autoRouteBotSquadsList[idx]
  return result


[es(tag=(render, server), no_order, REQUIRE=aiAutoRoutesEditor)]
def ai_auto_routes_editor_render_es(evt : UpdateStageInfoRenderDebug;
                                    var free_cam_input__allowZoom : bool&;
                                    var ai_auto_routes_editor__selected : int2&;
                                    var ai_auto_routes_editor__dragIter : int3&;
                                    var ai_auto_routes_editor__dragFrom : float4&;
                                    var ai_auto_routes_editor__dragging : bool&;
                                    var ai_auto_routes_editor__adding : bool&;
                                    ai_auto_routes_editor__dragMinDist : float = 1.0;
                                    var ai_auto_routes_editor__inputs : int&;
                                    var ai_auto_routes_editor__undoOp : IPoint4List&;
                                    var ai_auto_routes_editor__redoOp : IPoint4List&;
                                    var ai_auto_routes_editor__undoVal : Point4List&;
                                    var ai_auto_routes_editor__redoVal : Point4List&;
                                    var ai_auto_routes_editor__undoStr : StringList&;
                                    var ai_auto_routes_editor__redoStr : StringList&;
                                    var ai_auto_routes_editor__create : bool&;
                                    var ai_auto_routes_editor__createTimeout : float&;
                                    var ai_auto_routes_editor__createVal : float4&)
  assume undoOp = ai_auto_routes_editor__undoOp
  assume undoVal = ai_auto_routes_editor__undoVal
  assume undoStr = ai_auto_routes_editor__undoStr
  assume redoOp = ai_auto_routes_editor__redoOp
  assume redoVal = ai_auto_routes_editor__redoVal
  assume redoStr = ai_auto_routes_editor__redoStr

  let clrCursor = E3DCOLOR(0xFF00FF00)
  let clrCursorAt = E3DCOLOR(0xFFFF00FF)

  let clrTeam1 = E3DCOLOR(0xFF0000FF)
  let clrTeam2 = E3DCOLOR(0xFFFF0000)
  let clrTeam3 = E3DCOLOR(0xFFFFFF00)
  let clrTeamOther = E3DCOLOR(0xFFAAAAAA)

  let clrTeam1Gray = E3DCOLOR(0xFF7777AA)
  let clrTeam2Gray = E3DCOLOR(0xFFAA7777)
  let clrTeam3Gray = E3DCOLOR(0xFFAAAA77)
  let clrTeamOtherGray = E3DCOLOR(0xFF777777)

  let clrBlink = E3DCOLOR(0xFFFFFFFF)

  let CURSOR_RADIUS = 0.3
  let CURSOR_RADIUS_AT = 0.3
  let BALOON_RADIUS = 1.0
  let BALOON_HEIGHT = 7.0
  let POINT_RADIUS = 0.5
  let POINT_SELECTED_ADD_RADIUS_BY_DIST_COEF = 0.0035
  let LINE_RADIUS = 0.25
  let SNAP_RADIUS = 0.5

  assume inputs = ai_auto_routes_editor__inputs
  if is_editor_activated() && !is_editor_free_camera_enabled()
    inputs = 0; free_cam_input__allowZoom = true

  if ai_auto_routes_editor__create
    if get_real_time_sec() >= ai_auto_routes_editor__createTimeout
      ai_auto_routes_editor__create = false
      inputs = 0; free_cam_input__allowZoom = true
    else
      begin_draw_cached_debug_lines(false, false, false)
      let pt0 = ai_auto_routes_editor__createVal.xyz
      let baloonPt = pt0 + float3(0.0, BALOON_HEIGHT, 0.0)
      draw_cached_debug_sphere(baloonPt, BALOON_RADIUS, clrBlink, 12)
      draw_cached_debug_line(pt0, baloonPt, clrBlink)
      add_debug_text_mark(baloonPt, "Press 1 or 2 for team", -1, 0.0, E3DCOLOR(0xFFFFFFFF))
      end_draw_cached_debug_lines()

      var forTeam = -1
      if by_mask(inputs, INPUT_1)
        forTeam = 1
      elif by_mask(inputs, INPUT_2)
        forTeam = 2
      elif by_mask(inputs, INPUT_3)
        forTeam = 3
      inputs = 0; free_cam_input__allowZoom = true
      if forTeam >= 1
        find_query() <| $ [es] (eid aka team_eid : EntityId; team__id : int; team__autoRouteBotSquads : Array)
          if team__id != forTeam
            return false
          let rcnt = length(team__autoRouteBotSquads)
          let firstVal = ai_auto_routes_editor__createVal
          if exec_op(int(EditOp.CREATE_ROUTE), forTeam, rcnt, rcnt, firstVal, "random", undoOp, undoVal, undoStr)
            clear_ops(redoOp, redoVal, redoStr)
            entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
          ai_auto_routes_editor__create = false
          return true

  var tracePos : float3
  var traceDir : float3
  let canTrace = ai_auto_routes_get_trace(tracePos, traceDir)

  var cursorPos : float3
  var dist : float
  let hasCursor = canTrace && ai_auto_routes_trace(tracePos, traceDir, cursorPos, dist)
  let wasCursorPos = cursorPos
  var cursorAt = false

  let atDrag = ai_auto_routes_editor__dragIter.x >= 0
  if atDrag
    let team = ai_auto_routes_editor__dragIter.x
    let ridx = ai_auto_routes_editor__dragIter.y
    let pidx = ai_auto_routes_editor__dragIter.z
    var cancel = true
    find_query() <| $ [es] (eid aka team_eid : EntityId; team__id : int; var team__autoRouteBotSquads : Array&)
      if team__id != team
        return false
      let rcnt = length(team__autoRouteBotSquads)
      if ridx < 0 || ridx >= rcnt
        return false
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[ridx])
      if routeObj == null
        return false
      var points = getRW_ecs_array(routeObj, "points")
      if points == null
        return false
      var pt = getRW_Point4((*points)[pidx])
      if pt == null
        return false
      cancel = false
      if !ai_auto_routes_editor__dragging && distance_sq(ai_auto_routes_editor__dragFrom.xyz, cursorPos) > square(ai_auto_routes_editor__dragMinDist)
        ai_auto_routes_editor__dragFrom = *pt
        ai_auto_routes_editor__dragging = true
      if ai_auto_routes_editor__dragging
        (*pt).x = cursorPos.x
        (*pt).y = cursorPos.y
        (*pt).z = cursorPos.z
      if !by_mask(inputs, INPUT_LCLICK)
        cancel = true
        if !ai_auto_routes_editor__dragging
          if !ai_auto_routes_editor__adding
            var newVal = *pt
            newVal.w += 5.0
            if exec_op(int(EditOp.EDIT_POINT), team, ridx, pidx, newVal, "", undoOp, undoVal, undoStr)
              clear_ops(redoOp, redoVal, redoStr)
              entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
        else
          let newVal = *pt
          *pt = ai_auto_routes_editor__dragFrom
          if exec_op(int(EditOp.EDIT_POINT), team, ridx, pidx, newVal, "", undoOp, undoVal, undoStr)
            clear_ops(redoOp, redoVal, redoStr)
            entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
      return true
    if cancel
      ai_auto_routes_editor__dragIter = int3(-1, -1, -1)

  var curTeam = -1
  var curTeamEid = INVALID_ENTITY_ID
  var curRIdx = -1
  var curRCnt = 0
  var curPCnt = 0
  var curPIdx = -1
  var curLIdx = -1

  var toSelectRouteTeam = -1
  var toSelectRouteIdx = -1
  var anySel = false

  let heldCtrl = (inputs & INPUT_CTRL) != 0
  let heldShift = (inputs & INPUT_SHIFT) != 0
  //
  let noMods = !heldCtrl && !heldShift
  let withCtrl = heldCtrl && !heldShift
  let withShift = heldShift && !heldCtrl

  begin_draw_cached_debug_lines(false, false, false)

  query() <| $ [es] (eid aka team_eid : EntityId; team__id : int; var team__autoRouteBotSquads : Array&)
    for routeIdx in iter_range(team__autoRouteBotSquads)
      var routeObj = getRW_ecs_object(team__autoRouteBotSquads[routeIdx])
      if routeObj == null
        continue

      var squadId = get_ecs_string(routeObj, "squadId")
      var points = getRW_ecs_array(routeObj, "points")
      if squadId == null || points == null
        continue

      let len = length(*points)
      if len <= 0
        continue

      var clr = team__id == 1 ? clrTeam1 : team__id == 2 ? clrTeam2 : team__id == 3 ? clrTeam3 : clrTeamOther
      var sel = true
      if ai_auto_routes_editor__selected.x != team__id || ai_auto_routes_editor__selected.y != routeIdx
        clr = team__id == 1 ? clrTeam1Gray : team__id == 2 ? clrTeam2Gray : team__id == 3 ? clrTeam3Gray : clrTeamOtherGray
        sel = false
      let clr2 = E3DCOLOR((uint(clr) & 0x00FFFFFF) | 0x55000000)

      if sel
        curTeam = team__id
        curTeamEid = team_eid
        curRIdx = routeIdx
        curRCnt = length(team__autoRouteBotSquads)
        curPCnt = length(*points)

      var selPtIdx = -1
      var selPtDist = FLT_MAX
      if canTrace
        for ptIdx in range(len)
          let pt = get_Point4((*points)[ptIdx]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let snap = max(SNAP_RADIUS, length_sq(tracePos - pt.xyz) * SNAP_RADIUS * 0.0001)
          if ai_auto_routes_trace_sphere(tracePos, traceDir, pt.xyz, POINT_RADIUS + snap, dist)
            anySel = true
            if selPtIdx < 0 || dist < selPtDist
              selPtIdx = ptIdx
              selPtDist = dist
              if sel
                curPIdx = ptIdx
                cursorPos = tracePos + traceDir * dist
                cursorAt = true

      var selLnIdx = -1
      var selLnDist = FLT_MAX
      if canTrace && selPtIdx < 0
        for ptIdx in range(len - 1)
          let pt1 = get_Point4((*points)[ptIdx]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let pt2 = get_Point4((*points)[ptIdx + 1]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let snap = max(SNAP_RADIUS, length_sq(tracePos - (pt1.xyz + pt2.xyz) * 0.5) * SNAP_RADIUS * 0.0001)
          if ai_auto_routes_trace_line(tracePos, traceDir, pt1.xyz, pt2.xyz, LINE_RADIUS + snap, dist)
            anySel = true
            if selLnIdx < 0 || dist < selLnDist
              selLnIdx = ptIdx
              selLnDist = dist
              if sel
                curLIdx = ptIdx
                cursorPos = tracePos + traceDir * dist
                cursorAt = true

      let pt0 = get_Point4((*points)[0]) ?? float4(0.0, 0.0, 0.0, 0.0)
      let baloonPt = pt0.xyz + float3(0.0, BALOON_HEIGHT, 0.0)

      var selBaloon = false
      if canTrace
        let snap = max(SNAP_RADIUS, length_sq(tracePos - baloonPt) * SNAP_RADIUS * 0.0001)
        if ai_auto_routes_trace_sphere(tracePos, traceDir, baloonPt, BALOON_RADIUS + snap, dist)
          anySel = true
          if selPtIdx < 0 || dist < selPtDist
            selBaloon = true
            selPtIdx = -1
            selLnIdx = -1
            if sel
              cursorPos = tracePos + traceDir * dist
              cursorAt = true

      if noMods && by_mask(inputs, INPUT_LCLICK) && !atDrag
        if !sel
          if noMods && (selBaloon || selPtIdx >= 0 || selLnIdx >= 0)
            toSelectRouteTeam = team__id
            toSelectRouteIdx = routeIdx
        else
          if curPIdx >= 0
            toSelectRouteTeam = -1
            ai_auto_routes_editor__dragIter = int3(curTeam, curRIdx, curPIdx)
            ai_auto_routes_editor__dragFrom = float4(wasCursorPos.x, wasCursorPos.y, wasCursorPos.z, 0.0)
            ai_auto_routes_editor__dragging = false
            ai_auto_routes_editor__adding = false
          elif selBaloon
            let wasId = string(*squadId)
            let newId = get_team_next_squad_id(team_eid, wasId, 1)
            if newId != wasId
              set(*routeObj, "squadId", newId)
              entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
            set_mask(inputs, INPUT_LCLICK, false)

      if noMods && by_mask(inputs, INPUT_RCLICK) && !atDrag
        if sel
          if selPtIdx >= 0 && selPtIdx < len
            var pt = getRW_Point4((*points)[selPtIdx])
            if pt != null
              var newVal =  *pt
              newVal.w = max(0.0, (*pt).w - 5.0)
              if newVal.w != (*pt).w
                if exec_op(int(EditOp.EDIT_POINT), team__id, routeIdx, selPtIdx, newVal, "", undoOp, undoVal, undoStr)
                  clear_ops(redoOp, redoVal, redoStr)
                  entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
            set_mask(inputs, INPUT_RCLICK, false)
          elif selBaloon
            let wasId = string(*squadId)
            let newId = get_team_next_squad_id(team_eid, wasId, -1)
            if newId != wasId
              set(*routeObj, "squadId", newId)
              entity_obj_editor_saveComponent(team_eid, "team__autoRouteBotSquads")
            set_mask(inputs, INPUT_RCLICK, false)

      let cb = sel && selBaloon ? clrBlink : clr
      draw_cached_debug_sphere(baloonPt, BALOON_RADIUS, cb, 12)
      draw_cached_debug_line(pt0.xyz, baloonPt, cb)

      add_debug_text_mark(baloonPt, "{*squadId}", -1, 0.0, E3DCOLOR(0xFFFFFFFF))

      for ptIdx in range(len)
        let pt2 = get_Point4((*points)[ptIdx]) ?? float4(0.0, 0.0, 0.0, 0.0)
        if sel && selPtIdx == ptIdx
          draw_cached_debug_sphere(pt2.xyz, POINT_RADIUS + selPtDist * POINT_SELECTED_ADD_RADIUS_BY_DIST_COEF, clrBlink, 12)
        else
          draw_cached_debug_sphere(pt2.xyz, POINT_RADIUS, clr, 12)
        if sel && pt2.w > 0.0
          add_debug_text_mark(pt2.xyz, "{pt2.w}", -1, -0.5, E3DCOLOR(0xFFFFFFFF))
        if ptIdx == 0
          continue

        let pt1 = get_Point4((*points)[ptIdx - 1]) ?? float4(0.0, 0.0, 0.0, 0.0)

        if sel
          let vec = normalize(pt2.xyz - pt1.xyz)
          let off = float3(-vec.z, 0.0, vec.x) * LINE_RADIUS
          let p1 = pt1.xyz - off
          let p2 = pt1.xyz + off
          let p3 = pt2.xyz + off
          let p4 = pt2.xyz - off
          draw_cached_debug_quad(p1, p2, p3, p4, clr2)

        let c2 = sel && selLnIdx == ptIdx - 1 ? clrBlink : clr
        draw_cached_debug_line(pt1.xyz, pt2.xyz, c2)

  if hasCursor
    if cursorAt
      draw_cached_debug_sphere(cursorPos, CURSOR_RADIUS_AT, clrCursorAt, 12)
    elif anySel
      draw_cached_debug_sphere(cursorPos, CURSOR_RADIUS, clrCursorAt, 12)
    else
      draw_cached_debug_sphere(cursorPos, CURSOR_RADIUS, clrCursor, 12)

  end_draw_cached_debug_lines()

  if atDrag
    return

  if !cursorAt && toSelectRouteTeam >= 1 && toSelectRouteIdx >= 0
    set_mask(inputs, INPUT_LCLICK, false)
    ai_auto_routes_editor__selected.x = toSelectRouteTeam
    ai_auto_routes_editor__selected.y = toSelectRouteIdx
  elif noMods && by_mask(inputs, INPUT_RCLICK) && !anySel
    set_mask(inputs, INPUT_RCLICK, false)
    ai_auto_routes_editor__selected.x = -1
    ai_auto_routes_editor__selected.y = -1

  if !cursorAt && !anySel && withCtrl && by_mask(inputs, INPUT_LCLICK)
    set_mask(inputs, INPUT_LCLICK, false)
    let CREATE_ROUTE_SELECT_TEAM_TIMEOUT = 3.0
    ai_auto_routes_editor__create = true
    ai_auto_routes_editor__createTimeout = get_real_time_sec() + CREATE_ROUTE_SELECT_TEAM_TIMEOUT
    ai_auto_routes_editor__createVal = float4(cursorPos.x, cursorPos.y, cursorPos.z, 0.0)
  elif curRIdx >= 0 && withShift && by_mask(inputs, INPUT_LCLICK)
    set_mask(inputs, INPUT_LCLICK, false)
    let addVal = float4(cursorPos.x, cursorPos.y, cursorPos.z, 0.0)
    let atIdx = (curLIdx >= 0) ? (curLIdx + 1) : curPCnt
    if exec_op(int(EditOp.ADD_POINT), curTeam, curRIdx, atIdx, addVal, "", undoOp, undoVal, undoStr)
      clear_ops(redoOp, redoVal, redoStr)
      entity_obj_editor_saveComponent(curTeamEid, "team__autoRouteBotSquads")
      ai_auto_routes_editor__dragIter = int3(curTeam, curRIdx, atIdx)
      ai_auto_routes_editor__dragFrom = float4(wasCursorPos.x, wasCursorPos.y, wasCursorPos.z, 0.0)
      ai_auto_routes_editor__dragging = false
      ai_auto_routes_editor__adding = true
      set_mask(inputs, INPUT_LCLICK, true)
  elif curRIdx >= 0 && withCtrl && by_mask(inputs, INPUT_DELETE)
    set_mask(inputs, INPUT_DELETE, false)
    if exec_op(int(EditOp.DELETE_ROUTE), curTeam, curRIdx, curRCnt, float4(), "", undoOp, undoVal, undoStr)
      clear_ops(redoOp, redoVal, redoStr)
      entity_obj_editor_saveComponent(curTeamEid, "team__autoRouteBotSquads")
  elif cursorAt && withShift && by_mask(inputs, INPUT_RCLICK)
    set_mask(inputs, INPUT_RCLICK, false)
    if curTeam >= 1 && curRIdx >= 0 && curPIdx >= 0
      if exec_op(int(EditOp.DEL_POINT), curTeam, curRIdx, curPIdx, float4(), "", undoOp, undoVal, undoStr)
        clear_ops(redoOp, redoVal, redoStr)
        entity_obj_editor_saveComponent(curTeamEid, "team__autoRouteBotSquads")
  elif withCtrl && by_mask(inputs, INPUT_Z)
    set_mask(inputs, INPUT_Z, false)
    if has_op(undoOp, undoVal, undoStr)
      var opTeam, opRIdx, opArg : int
      var succ = true
      var cont = true
      while cont
        cont = false
        let op = get_op(undoOp, opTeam, opRIdx, opArg)
        let opVal = get_op_val(undoVal)
        let opStr = get_op_str(undoStr)
        pop_op(undoOp, undoVal, undoStr)
        if !exec_op(op, opTeam, opRIdx, opArg, opVal, opStr, redoOp, redoVal, redoStr)
          succ = false
        if has_op(undoOp, undoVal, undoStr) && get_op(undoOp, opTeam, opRIdx, opArg) == int(EditOp.READD_POINT)
          cont = true
  elif withCtrl && by_mask(inputs, INPUT_Y)
    set_mask(inputs, INPUT_Y, false)
    if has_op(redoOp, redoVal, redoStr)
      var opTeam, opRIdx, opArg : int
      var succ = true
      var cont = true
      while cont
        cont = false
        let op = get_op(redoOp, opTeam, opRIdx, opArg)
        let opVal = get_op_val(redoVal)
        let opStr = get_op_str(redoStr)
        pop_op(redoOp, redoVal, redoStr)
        if !exec_op(op, opTeam, opRIdx, opArg, opVal, opStr, undoOp, undoVal, undoStr)
          succ = false
        if has_op(redoOp, redoVal, redoStr) && get_op(redoOp, opTeam, opRIdx, opArg) == int(EditOp.READD_POINT)
          cont = true
