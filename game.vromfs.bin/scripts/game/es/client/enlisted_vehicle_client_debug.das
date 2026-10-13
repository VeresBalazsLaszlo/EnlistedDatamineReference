options no_aot
require ecs
require DagorConsole
require DngCamera
require GridCollision
require CollisionTraces
require DngNet

require game.es.server_debug_common


// Camera-trace variants of the vehicle.* debug commands. These live in the client-only
// folder because DngCamera/GridCollision/CollisionTraces aren't available on the dedicated
// server. Each command resolves the target eid via a 20m forward raytrace from the active
// camera, then dispatches the resolved eid to the server-side `vehicle.*` console command.
//
// Dispatch path depends on whether we're already on the server (offline / single-player /
// host): `console_command` runs the command locally without any networking. Otherwise
// (genuine client→server) we go through `exec_server_cmd`, which routes via /servercmd chat.
// Avoiding the chat path offline skips the harmless "unknown command:
// 'net.set_console_connection_id'" warning that the server-side chat handler emits when the
// net layer isn't active (chat_es.nut:120 always probes that command).
//
// The server-resolvable variants (no camera) live in `vehicle/enlisted_vehicle_debug.das`.

def private trace_vehicle_from_camera() : uint
  var hitEid = INVALID_ENTITY_ID
  query(get_cur_cam_entity()) <| $ [es] (transform aka camera_transform : float3x4)
    var t = 20.0
    using() <| $(var intersections : IntersectedEntities)
      trace_entities_in_grid(ecs_hash("vehicles"), camera_transform[3], camera_transform[2], t,
                              INVALID_ENTITY_ID, intersections, SortIntersections.YES)
      if length(intersections) > 0
        hitEid = intersections[0].eid
  return uint(hitEid)


[console_cmd(name="vehicle.explosion_cam")]
def vehicle_explosion_cam(detach_turret : bool = false)
  let resolvedUeid = trace_vehicle_from_camera()
  if resolvedUeid == uint(INVALID_ENTITY_ID)
    console_print("[vehicle.explosion_cam] no vehicle in camera trace (20m forward)")
    return
  let cmd = "vehicle.explosion {resolvedUeid} {detach_turret}"
  if is_server()
    console_command(cmd)
  else
    exec_server_cmd(cmd)


[console_cmd(name="vehicle.cookoff_cam")]
def vehicle_cookoff_cam(full : bool = true)
  let resolvedUeid = trace_vehicle_from_camera()
  if resolvedUeid == uint(INVALID_ENTITY_ID)
    console_print("[vehicle.cookoff_cam] no vehicle in camera trace (20m forward)")
    return
  let cmd = "vehicle.cookoff {resolvedUeid} {full}"
  if is_server()
    console_command(cmd)
  else
    exec_server_cmd(cmd)


[console_cmd(name="vehicle.explosion_crash_cam")]
def vehicle_explosion_crash_cam()
  let resolvedUeid = trace_vehicle_from_camera()
  if resolvedUeid == uint(INVALID_ENTITY_ID)
    console_print("[vehicle.explosion_crash_cam] no vehicle in camera trace (20m forward)")
    return
  let cmd = "vehicle.explosion_crash {resolvedUeid}"
  if is_server()
    console_command(cmd)
  else
    exec_server_cmd(cmd)
