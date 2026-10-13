options no_aot
require ecs
require ecs.common
require DngNet
require app
require DagorConsole
require DagorDebug3D
require DagorMath
require DngWalkerai
require DngBehTree
require BehNodes
require walkerai
require math
require math.base
require DngHuman
require HumanPhys
require game.es.server_debug_common
require game.es.net_console_macro
require ecs.ecs_template
require strings
require DngActor

[ecs_template(tag=dev)]
struct global_debug_beh_tree
  global_beh_tree__debug : int
  global_beh_tree__showDebugLog : bool
  global_entity_danger__debug : bool


[ecs_template]
struct debug_bot_temp_template
  beh_tree__debug : bool
  beh_tree__debugMode : int
  beh_tree__debugLog : Array
  entity_danger__debug : bool
  beh_tree__showDebugLog : bool


[ecs_template]
struct global_debug_attract_points
  attract_points__debugDraw : bool


def toggle_bots_template(template_name : string; activate : bool)
  ecs::query() <| $ [es(REQUIRE_NOT=hero)] (eid : EntityId; beh_tree__enabled : bool)
    if beh_tree__enabled
      let templateName = getEntityTemplateName(eid)
      var newTemplate = remove_sub_template_name(templateName, template_name)
      if activate
        newTemplate = "{newTemplate}+{template_name}"
      print("ai: {templateName} -> {newTemplate}")
      remote_recreate_entity_from(eid, newTemplate)


[net_console_cmd(name="ai.debug_server_bots")]
def server_debug_behaviour_tree(activate : bool = true)
  toggle_bots_template("squad_member_server_debug_ai", activate)


[es(tag=(server, dev), REQUIRE=beh_tree__server_debug, no_order)]
def sync_server_beh_tree_state(evt : UpdateStageInfoAct; beh_tree : BehaviourTree; var beh_tree__debugState : das_string)
  beh_tree__debugState := beh_tree_current_name(beh_tree, true)


[es(tag=(render, dev), REQUIRE=beh_tree__server_debug, REQUIRE_NOT=deadEntity, no_order)]
def draw_server_beh_tree_state(evt : UpdateStageInfoRenderDebug; transform : float3x4; beh_tree__debugState : string)
  let pos = transform[3]
  add_debug_text_mark(pos, "ai: {beh_tree__debugState}", -1, 0f, E3DCOLOR(0xFFFFFFFF))


[es(tag=(render, dev), REQUIRE_NOT=deadEntity, after=beh_tree_update_es)]
def beh_tree_debug_es(evt : UpdateStageInfoRenderDebug; transform : float3x4;
                      beh_tree : BehaviourTree; team : int = 0;
                      beh_tree__debug : bool;
                      beh_tree__debugMode : int = 1;
                      beh_tree__debugSym1 : int3 = int3(0, 0, 0);
                      beh_tree__debugSym2 : int3 = int3(0, 0, 0);
                      beh_tree__debugSym3 : int3 = int3(0, 0, 0))
  if beh_tree__debug
    var pos = transform[3]
    if beh_tree__debugMode == 1
      beh_tree |> beh_tree_drawDebug()
      add_debug_text_mark(pos, beh_tree |> beh_tree_current_name(true), -1, 0f, E3DCOLOR(0x00000000))
    elif beh_tree__debugMode == 2
      beh_tree |> beh_tree_drawDebug()
      add_debug_text_mark(pos, "{team}", -1, 0f, E3DCOLOR(0x00000000))
    elif beh_tree__debugMode == 3
      add_debug_text_mark(pos, "{team}", -1, 0f, E3DCOLOR(0x00000000))
    elif beh_tree__debugMode == 4
      pos.y += 0.5
      assume sym1 = beh_tree__debugSym1
      assume sym2 = beh_tree__debugSym2
      assume sym3 = beh_tree__debugSym3
      if sym1.x > 0
        let symB = to_char(sym1.x)
        let symA = to_char(sym1.z)
        let symRB = to_char(sym2.z)
        let symRA = to_char(sym3.y)
        if sym2.y != 0
          let symR = sym2.y > 0 ? "r" : "R"
          let idxR = abs(sym2.y)
          add_debug_text_mark(pos, "{team}: {symB}{sym1.y}~{symA}{sym2.x} {symR}{idxR}:{symRA}{sym3.z}{symRB}{sym3.x}", -1, 1.0, E3DCOLOR(0x000000))
        else
          add_debug_text_mark(pos, "{team}: {symB}{sym1.y}~{symA}{sym2.x}", -1, 1.0, E3DCOLOR(0x000000))


[console_cmd(name="ai.beh_tree_enabled")]
def debug_beh_tree(beh_tree_enabled : bool = true)
  ecs::query() <| $ [es(REQUIRE=beh_tree, REQUIRE_NOT=hero)] (var human_net_phys : HumanActor?; var navmesh_phys__wishWalkSpeed : float?;
                                                              var beh_tree__enabled : bool&)
    beh_tree__enabled = beh_tree_enabled

    if !beh_tree_enabled
      if human_net_phys != null
        human_control_state_set_walk_speed(human_net_phys.phys.producedCT, 0.f)
        human_control_state_set_neutral_ctrl(human_net_phys.phys.producedCT)
      if navmesh_phys__wishWalkSpeed != null
        *navmesh_phys__wishWalkSpeed = 0.f


[console_cmd(name="ai.debug_bots", hint="ai.debug_bots (debug_beh_tree, log_ai = false, debug_dangers = false)")]
def debug_behaviour_tree(debug_beh_tree : int; log_ai : bool = false; debug_dangers : bool = false)
  let hasGlobal = find_query() <| $ [es] (var global_beh_tree__debug : int&;
                                          var global_entity_danger__debug, global_beh_tree__showDebugLog : bool&)
    global_beh_tree__debug = debug_beh_tree
    global_beh_tree__showDebugLog = log_ai
    global_entity_danger__debug = debug_dangers
    return true

  if !hasGlobal && (debug_beh_tree > 0 || log_ai || debug_dangers)
    createEntity("global_debug_beh_tree") <| $(init)
      init |> set("global_beh_tree__debug", debug_beh_tree)
      init |> set("global_beh_tree__showDebugLog", log_ai)
      init |> set("global_entity_danger__debug", debug_dangers)


[es(tag=(server, dev), no_order)]
def debug_behaviour_tree_update(evt : UpdateStageInfoAct; eid : EntityId;
                                global_beh_tree__debug : int;
                                global_entity_danger__debug, global_beh_tree__showDebugLog : bool)
  if global_beh_tree__debug <= 0 && !global_entity_danger__debug && !global_beh_tree__showDebugLog
    destroyEntity(eid)
  query() <| $ [es] (eid : EntityId; beh_tree__enabled : bool;
                     var beh_tree__debug : bool?;
                     var beh_tree__debugMode : int?;
                     var entity_danger__debug, beh_tree__showDebugLog : bool?)
    if !beh_tree__enabled
      return
    if beh_tree__debug != null && entity_danger__debug != null && beh_tree__showDebugLog != null
      *beh_tree__debug = global_beh_tree__debug != 0
      if beh_tree__debugMode != null
        *beh_tree__debugMode = global_beh_tree__debug
      *entity_danger__debug = global_entity_danger__debug
      *beh_tree__showDebugLog = global_beh_tree__showDebugLog
    elif global_beh_tree__debug > 0 || global_entity_danger__debug || global_beh_tree__showDebugLog
      addSubTemplate(eid, "debug_bot_temp_template") <| $(var init)
        set(init, "beh_tree__debug", global_beh_tree__debug != 0)
        set(init, "beh_tree__debugMode", global_beh_tree__debug)
        set(init, "entity_danger__debug", global_entity_danger__debug)
        set(init, "beh_tree__showDebugLog", global_beh_tree__showDebugLog)


[console_cmd(name="ai.debug_obstacles")]
def debug_obstacles(draw_obstacles : bool = true)
  let tmpl = "debug_obstacles"
  ecs::query() <| $ [es(REQUIRE=walker_agent)] (eid : EntityId; beh_tree__enabled : bool)
    if beh_tree__enabled
      addSubTemplate(eid, tmpl) <| $(var init)
        set(init, "beh_tree__drawObstacles", draw_obstacles)
  ecs::query() <| $ [es(REQUIRE=agent_obstacles)] (eid : EntityId; beh_tree__enabled : bool)
    if beh_tree__enabled
      addSubTemplate(eid, tmpl) <| $(var init)
        set(init, "beh_tree__drawObstacles", draw_obstacles)

def draw_agent_obstacle(obstacle)
  let offset = float3(0., 0.2, 0.)
  let live = 200
  let convex = length(obstacle.segments) > 2
  if convex
    draw_debug_sphere_buffered(obstacle.center, 1.0, E3DCOLOR(0xFFFF0000), 12, live)
  for seg in obstacle.segments
    let start = seg.start + offset
    let end = seg.end + offset
    if length_sq(seg.dir) > 1e-5
      let dir = normalize(end - start)
      let swap = convex && dot(seg.dir, dir) < 0f
      let st = swap ? end - dir * 0.2 : start + dir * 0.2
      let en = swap ? start + dir * 0.2 : end - dir * 0.2
      draw_debug_sphere_buffered(st, 0.1, E3DCOLOR(0xFFFF0000), 12, live)
      draw_debug_sphere_buffered(en, 0.1, E3DCOLOR(0xFF00FF00), 12, live)
    draw_debug_line_buffered(start, end, E3DCOLOR(0xFFFF0000), live)


[es(tag=dev, tag=render, no_order)]
def debug_obstacles_render_agent(evt : UpdateStageInfoRenderDebug; walker_agent : EntityAgent; beh_tree__drawObstacles : bool)
  if !beh_tree__drawObstacles
    return
  for obstacle in walker_agent.obstacles
    draw_agent_obstacle(obstacle)

[es(tag=dev, tag=render, no_order)]
def debug_obstacles_render_navphys(evt : UpdateStageInfoRenderDebug; agent_obstacles : AgentObstacles; beh_tree__drawObstacles : bool)
  if !beh_tree__drawObstacles
    return
  for obstacle in agent_obstacles.obstacles
    draw_agent_obstacle(obstacle)


[console_cmd(name="ai.debug_stuck_detector")]
def debug_stuck_detector_cmd()
  let hasEntity = find_query() <| $ [es(REQUIRE=stuck_detector_debug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !hasEntity
    createEntity("stuck_detector_debug")

[es(tag=dev, tag=render, no_order, REQUIRE=stuck_detector_debug)]
def debug_stuck_detector(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4;
                     stuck_detector__avgPos : float3;
                     stuck_detector__value : float;
                     stuck_detector__threshold = 0.6)
    draw_debug_sphere_buffered(stuck_detector__avgPos, 0.3, E3DCOLOR(0xffffff00), 12, 1)
    let col = stuck_detector__value > stuck_detector__threshold ? E3DCOLOR(0xffff0000) : E3DCOLOR(0xff00ffff)
    draw_debug_sphere_buffered(transform[3] + float3(0, 1, 0), stuck_detector__value, col, 12, 1)


[es(tag=(render, dev), no_order)]
def entity_dangers_debug(evt : UpdateStageInfoRenderDebug; eid : EntityId; agent_dangers__standShootPos : float3; agent_dangers : AgentDangers; transform : float3x4; entity_danger__debug : bool)
  if !entity_danger__debug || length(agent_dangers.dangers) == 0
    return
  draw_cached_debug_sphere(agent_dangers__standShootPos, 0.1, E3DCOLOR(0xFF0000FF), 12)
  let index = uint(eid)
  let idx1 = index & 7u
  let idx2 = (index >> 3u) & 3u
  let idx3 = (index >> 5u) & 3u
  let offset = float3(0f, float(idx1 + 1u) * 0.2, 0f)
  let color = E3DCOLOR(uint4(idx1 << 5u, idx2 << 6u, idx3 << 6u, 255u))
  let agentPos = transform[3] + offset
  draw_debug_sphere_buffered(agentPos, 0.2, color, 6, 20)
  let atTime = get_sync_time()
  for danger in agent_dangers.dangers
    if !danger.traceable
      continue
    let tm = get_TMatrix(danger.eid, "transform")
    if tm == null
      continue
    let pos = (*tm)[3] + offset
    var dir = agentPos - pos
    let lenSq = length_sq(dir)
    let str = "{danger.traceable?"* ":""}{danger.dangerMeter} noise {danger.noiseMeter} " + (danger.lastTime > 0f ? "{danger.lastTime}" : "{atTime - danger.lastTraceTime}")
    if lenSq > 4f
      let len = sqrt(lenSq)
      dir = dir * safeinv(len)
      let from = agentPos - dir * (len - 1.f)
      let to = pos + dir * (len - 0.7f)
      add_debug_text_mark(from, str, -1, 0f, color)
      add_debug_text_mark(to, str, -1, 0f, color)
    else
      let markPos = (pos + agentPos) * 0.5
      add_debug_text_mark(markPos, str, -1, 0f, color)

    if danger.lastTraceTime > 0f && atTime - danger.lastTraceTime < 0.2f
      draw_cached_debug_line(agentPos, pos, E3DCOLOR(0xFFFF0000))
    else
      draw_cached_debug_line(agentPos, pos, color)


[es(tag=dev, before=walker_agent_es)]
def beh_tree_update_reaction(act : UpdateStageInfoAct; eid : EntityId;
                             beh_tree__showDebugLog : bool; beh_tree : BehaviourTree;
                             var beh_tree__debugLog : Array&; beh_tree__debugLogSize : int = 5)
  if !beh_tree__showDebugLog || beh_tree__debugLogSize <= 0
    return
  if beh_tree.changeNodeReason != null
    let name = (*beh_tree.changeNodeReason) |> beh_node_hierarchy_name(true)
    beh_tree__debugLog |> push("{act.curTime} {eid} {name}")
  if beh_tree.resetReason != null
    let name = (*beh_tree.resetReason) |> beh_node_hierarchy_name(true)
    beh_tree__debugLog |> push("{act.curTime} {eid} {name}")
  while length(beh_tree__debugLog) > beh_tree__debugLogSize
    beh_tree__debugLog |> erase(0)


[es(tag=(dev, render), after=beh_tree_update_es, REQUIRE_NOT=deadEntity)]
def walker_agent_debug_reaction(act : UpdateStageInfoRenderDebug; transform : float3x4;
                                beh_tree__showDebugLog : bool; beh_tree__debugLog : Array&)
  if !beh_tree__showDebugLog
    return
  let pos = transform[3]
  var lineOffset = float(length(beh_tree__debugLog))
  let color = E3DCOLOR(uint4(40, 40, 40, 160))
  for it in beh_tree__debugLog
    add_debug_text_mark(pos, get_string(it, ""), -1, lineOffset, color)
    lineOffset -= 1f


[console_cmd(name="ai.debug_attractive_places")]
def debug_attractive_places(show_attract_point = true)
  let hasGlobal = find_query() <| $ [es] (eid : EntityId; var attract_points__debugDraw : bool&)
    attract_points__debugDraw = show_attract_point
    if !show_attract_point
      destroyEntity(eid)
    return true

  if !hasGlobal && show_attract_point
    createEntity("global_debug_attract_points") <| $(init)
      init |> set("attract_points__debugDraw", show_attract_point)

[es(tag=(dev, render), no_order)]
def debug_draw_attractive_places(act : UpdateStageInfoRenderDebug; attract_points__debugDraw : bool)
  if !attract_points__debugDraw
    return
  let radius = 50f
  let curTime = get_sync_time()
  query() <| $ [es] (transform : float3x4; game_effect__destroyAt : float const?; attract_point__magnitude : float)
    let pos = transform[3]
    if game_effect__destroyAt != null
      let color = E3DCOLOR(uint4(40, 40, 40, 160))
      add_debug_text_mark(pos, "{attract_point__magnitude} : {*game_effect__destroyAt - curTime}", -1, 0f, color)
    draw_debug_sphere_buffered(pos, attract_point__magnitude * radius, E3DCOLOR(0xFF00FFFF), 24, 1)


[console_cmd(name="ai.reload_beh_tree")]
def reload_beh_tree(id : uint = 0u)
  query() <| $ [es(REQUIRE=beh_tree)] (eid : EntityId)
    DngBehTree::unload_beh_tree(eid)
  sceneload_reload_ai()
  if id != 0u
    DngBehTree::load_beh_tree_from_ecs(EntityId(id))
    return
  query() <| $ [es(REQUIRE=beh_tree)] (eid : EntityId)
    DngBehTree::load_beh_tree_from_ecs(eid)


//Can be executed multiple times without issues
[es(on_appear, REQUIRE=behTreeDebugWrapped, after=load_beh_tree_es)]
def insert_wrapper_nodes_es(evt : Event; var beh_tree : BehaviourTree)
  beh_tree |> beh_tree_transformNodes() <| $(node)
    let wrap = node.getType != BN_DEBUG_WRAPPER && !(node.parent != null && node.parent.getType == BN_DEBUG_WRAPPER)
    if wrap
      return newDebugWrapperNode(node, beh_tree)
    return node

require DagorConsole
[net_console_cmd(name="ai.enable_player_ai_mode")]
def enable_player_ai_mode(ai_mode : bool; @net_hero hero_eid : EntityId; @net_player player_eid : EntityId)
  if ai_mode
    remote_add_sub_template(player_eid, "player_ai_controlled")
  else
    remote_remove_sub_template(player_eid, "player_ai_controlled")

  query(hero_eid) <| $ [es] (var beh_tree__enabled : bool&;
                             var replication : NetObject?;
                             var human_net_phys : HumanActor&)
    beh_tree__enabled = ai_mode
    if replication != null
      let role = ai_mode ? NetRole.ROLE_LOCALLY_CONTROLLED_AUTHORITY : NetRole.ROLE_REMOTELY_CONTROLLED_AUTHORITY
      human_net_phys |> base_phys_actor_setRoleAndTickrateType(role, human_net_phys.tickrateType)
      net_object_setControlledBy(*replication, ai_mode ? INVALID_CONNECTION_ID : *get_int(player_eid, "connid"))

[es(tag=gameClient, on_appear, REQUIRE=aiControlledPlayer)]
def human_ai_mode_suspend_player_control(evt : Event; possessed : EntityId)
  query(possessed) <| $ [es] (eid : EntityId;
                              var human_net_phys : HumanActor&)
    human_net_phys |> base_phys_actor_setRoleAndTickrateType(NetRole.ROLE_REMOTELY_CONTROLLED_SHADOW, human_net_phys.tickrateType)
    removeSubTemplate(eid, "human_hero_components_local")

[es(tag=gameClient, on_disappear, REQUIRE=aiControlledPlayer)]
def human_ai_mode_resume_player_control(evt : Event; possessed : EntityId)
  query(possessed) <| $ [es] (eid : EntityId;
                              var human_net_phys : HumanActor&)
    human_net_phys |> base_phys_actor_setRoleAndTickrateType(NetRole.ROLE_LOCALLY_CONTROLLED_SHADOW, human_net_phys.tickrateType)
    addSubTemplate(eid, "human_hero_components_local")

[es(track=possessedByPlr)]
def human_ai_mode_on_hero_possessed(evt : Event;
                                    eid : EntityId;
                                    possessedByPlr : EntityId;
                                    var human_net_phys : HumanActor&;
                                    var beh_tree__enabled : bool&;
                                    var replication : NetObject&)
  if possessedByPlr != INVALID_ENTITY_ID && has(possessedByPlr, "aiControlledPlayer")
    let role = is_true_net_server() ? NetRole.ROLE_LOCALLY_CONTROLLED_AUTHORITY : NetRole.ROLE_REMOTELY_CONTROLLED_SHADOW
    human_net_phys |> base_phys_actor_setRoleAndTickrateType(role, PhysTickRateType.Normal)
    beh_tree__enabled = true
    if is_true_net_server()
      net_object_setControlledBy(replication, -1)
    else
      removeSubTemplate(eid, "human_hero_components_local")
