module net_scope_adder_common shared
require DagorConsole
require DagorSystem
require ecs
require matching
require DngNet
require player

def do_add_entity_in_net_scope(var conn : IConnection?;
                               var no : NetObject&;
                               var errlogged : bool&)
  if setObjectInScopeAlways(*conn, no) || errlogged
    return
  let noEid = no.eid
  let noId = int(uint(noEid))
  let templateName = getEntityTemplateName(noEid)
  let connId = connection_getId(*conn)
  let plrEid = find_player_eid_for_connection(conn)
  let plrUserId = get_uint64(plrEid, "userid") ?? INVALID_USER_ID
  let plrName = get_string(plrEid, "name", "")
  logerr("Failed to add entity /*{noId}*/ /*{templateName}*/ into net scope for conn=/*{connId}*/,user\{name,id\}=/*{plrName}*/ /*{plrUserId}*/. MaxReplicas limit reached?\nEntity histogram dumped in log.")
  console_command("ecs.entity_histogram 0") // 0 means whole histogram
  errlogged = true

// TODO: This is a copy of add_entity_in_net_scope function from netScopeAdderES.cpp.inl
//       Remove this comment, when it will cease to be used in the cpp
def add_entity_in_net_scope(eid : EntityId; connid : int)
  query(eid) <| $ [es] (var replication : NetObject&)
    var conn = get_client_connection(connid)
    if conn != null
      var error = false
      do_add_entity_in_net_scope(conn, replication, error)
