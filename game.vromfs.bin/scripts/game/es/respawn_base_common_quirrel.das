require ecs
require ecs.ecs_quirrel
require game.es.respawn_base_common
require daslib/quirrel_boost
require game.es.respawn_priority_auto_selector_common
require game.utils.spawn_common
require game.utils.squad_spawn_common

def public pushValue(var vm : SQVM?; val : RespawnBaseType)
  sq_newtable(vm)
  if !empty(val.canUseRespawnbaseType)
    _::pushValue(vm, "canUseRespawnbaseType")
    _::pushValue(vm, val.canUseRespawnbaseType)
    sq_rawset(vm, -3l)
    _::pushValue(vm, "canUseRespawnbaseSubtypes")
    _::pushValue(vm, val.canUseRespawnbaseSubtypes)
    sq_rawset(vm, -3l)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team(team : int)
  return respawn_base_common::find_respawn_base_for_team(team)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team_with_type(team : int; resp_type : string; subtypes : array<string>)
  return respawn_base_common::find_respawn_base_for_team_with_type(team, resp_type, subtypes)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team_with_type_of_group(team : int; resp_type : string; subtypes : array<string>; group : int)
  return respawn_base_common::find_respawn_base_for_team_with_type(team, resp_type, subtypes, group)

[quirrel_bind(module_name="das.respawn")]
def find_human_respawn_base(team : int; safest : bool)
  return respawn_base_common::find_human_respawn_base(team, safest)

[quirrel_bind(module_name="das.respawn")]
def count_vehicles_of_type(count_team : int; respawnbase_type : string)
  return respawn_base_common::count_vehicles_of_type(count_team, respawnbase_type)

[quirrel_bind(module_name="das.respawn")]
def is_vehicle_spawn_allowed_by_limit(team : int; resp_type : string; player_eid : EntityId)
  return respawn_base_common::is_vehicle_spawn_allowed_by_limit(team, resp_type, player_eid)

[quirrel_bind(module_name="das.respawn")]
def on_player_awaiting_vehicle_spawn(team : int; player_eid : EntityId; respawnbase_type : string)
  respawn_base_common::on_player_awaiting_vehicle_spawn(team, player_eid, respawnbase_type)

[quirrel_bind(module_name="das.respawn", stub_res_type="\{\}")]
def get_can_use_respawnbase_type(templ_name : string)
  return <- respawn_base_common::get_can_use_respawnbase_type(templ_name)

[quirrel_bind(module_name="das.respawn")]
def is_respawn_at_team_side(spawn_pos : float3; zone_pos : float3; team : int)
  return respawn_base_common::is_respawn_at_team_side(spawn_pos, zone_pos, team)

[quirrel_bind(module_name="das.respawn")]
def check_exists_navmesh_path_from_respawn_to_capzone(respawnPointEid : EntityId; pos : float3; pos_end : float3)
  return respawn_base_common::check_exists_navmesh_path_from_respawn_to_capzone(respawnPointEid, pos, pos_end)

[quirrel_bind(module_name="das.respawn")]
def get_priority_spawn_group(can_use_respawn_base_type : string; team : int; for_bot : bool) : int
  return get_respawn_group(can_use_respawn_base_type, team, for_bot)

[quirrel_bind(raw_return, module_name="das.respawn")]
def validate_position(tm : float3x4; orig_pos : float3; horz_extents : float; var vm : SQVM?)
  pushValue(vm, spawn_common::validate_position(tm, orig_pos, horz_extents)) // return

[quirrel_bind(raw_return, module_name="das.respawn")]
def validate_tm(tm : float3x4; horz_extents : float; var vm : SQVM?)
  pushValue(vm, spawn_common::validate_tm(tm, horz_extents)) // return

[quirrel_bind(raw_return, module_name="das.respawn")]
def mk_spawn_params_by_team(team : int; var vm : SQVM?)
  let baseEid = respawn_base_common::find_human_respawn_base(team, false)
  using() <| $(var params : Object)
    if baseEid != INVALID_ENTITY_ID
      spawn_common::mk_spawn_params_by_team_impl(team, baseEid, params)
    pushValue(vm, params) //return

[quirrel_bind(raw_return, module_name="das.respawn")]
def mk_spawn_params_by_team_ex(team : int; base_eid : EntityId; var vm : SQVM?)
  using() <| $(var params : Object)
    if base_eid != INVALID_ENTITY_ID
      spawn_common::mk_spawn_params_by_team_impl(team, base_eid, params)
    pushValue(vm, params) //return

[quirrel_bind(raw_return, module_name="das.respawn")]
def validate_vehicle_position(tm : float3x4; var vm : SQVM?)
  pushValue(vm, squad_spawn_common::validate_vehicle_position(tm)) // return

[quirrel_bind(module_name="das.respawn")]
def validate_spawn_rotation(playerEid : EntityId; squadId, memberId : int) : bool
  return squad_spawn_common::validate_spawn_rotation(playerEid, squadId, memberId)

[quirrel_bind(module_name="das.respawn")]
def update_team_score(team, playerSpawnCount : int; squadCostMult : int const?; hasVehicle : bool; playerEid : EntityId; squadId : int)
  spawn_common::update_team_score(team, playerSpawnCount, squadCostMult, hasVehicle, playerEid, squadId)

[quirrel_bind(module_name="das.respawn")]
def can_spawn_player_squads(team, playerSpawnCount : int) : bool
  return spawn_common::can_spawn_player_squads(team, playerSpawnCount)

[quirrel_bind(module_name="das.respawn")]
def can_spawn_team_squads(team, playerSpawnCount : int) : bool
  return spawn_common::can_spawn_team_squads(team, playerSpawnCount)
