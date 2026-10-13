require ecs
require gameLibs.pufd_events.pufd_events
require math.base
require enlisted.events_enlisted

[es(on_appear, track=respawn_activator__active, tag=server)]
def respawn_base_group_activator(evt : Event;
                                 respawn_activator__active : bool;
                                 respawn_activator__groupId : int;
                                 respawn_activator__groupName : string;
                                 respawn_activator__team : int)
  query() <| $ [es] (respawnBaseGroup : int;
                     var active : bool&;
                     var team : int&;
                     var groupName : das_string)
    if respawnBaseGroup == respawn_activator__groupId
      team = respawn_activator__team
      active = respawn_activator__active
      groupName := respawn_activator__groupName

[es(on_event=EventEntityDestroyed, tag=server)]
def respawn_base_group_activator_destroyed(evt : Event;
                                           respawn_activator__groupId : int;
                                           respawn_activator__team : int)
  query() <| $ [es] (respawnBaseGroup : int;
                     var temporaryInactive : bool?;
                     var active : bool&)
    if respawnBaseGroup == respawn_activator__groupId
      active = false
      if temporaryInactive != null
        *temporaryInactive = false
  query() <| $ [es] (selectedGroup : int; var respawn_icon__temporaryInactive : bool&; var respawn_icon__isEnemyAtRespawn : bool&; team : int)
    if respawn_activator__team == team && selectedGroup == respawn_activator__groupId
      respawn_icon__temporaryInactive = false
      respawn_icon__isEnemyAtRespawn = false
  broadcastEvent(UpdateRespawnIcons())

[es(tag=server, no_order)]
def respawn_base_group_activator_with_enemy_radius_update(info : ParallelUpdateFrameDelayed;
                                                          respawn_activator__active : bool;
                                                          respawn_activator__radius : float;
                                                          respawn_activator__pos : float3;
                                                          var respawn_activator__curStateEnemyInRadius : bool&;
                                                          respawn_activator__groupId : int;
                                                          respawn_activator__team : int)
  var stateChanged = false
  if respawn_activator__active
    var hasEnemy = false
    let distSq = square(respawn_activator__radius)
    find_query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int; transform : float3x4)
      if team != respawn_activator__team && length_sq(transform[3] - respawn_activator__pos) < distSq
        hasEnemy = true
      return hasEnemy
    if hasEnemy != respawn_activator__curStateEnemyInRadius
      respawn_activator__curStateEnemyInRadius = hasEnemy
      stateChanged = true
  elif respawn_activator__curStateEnemyInRadius
    respawn_activator__curStateEnemyInRadius = false
    stateChanged = true

  if stateChanged
    query() <| $ [es] (selectedGroup : int; var respawn_icon__temporaryInactive : bool&; var respawn_icon__isEnemyAtRespawn : bool&; team : int)
      if respawn_activator__team == team && selectedGroup == respawn_activator__groupId
        respawn_icon__temporaryInactive = respawn_activator__active && respawn_activator__curStateEnemyInRadius
        respawn_icon__isEnemyAtRespawn = respawn_activator__curStateEnemyInRadius

    query() <| $ [es] (respawnBaseGroup : int;
                       team : int;
                       var temporaryInactive : bool&;
                       var active : bool&)
      if respawnBaseGroup == respawn_activator__groupId && respawn_activator__team == team
        active = respawn_activator__active && !respawn_activator__curStateEnemyInRadius
        temporaryInactive = respawn_activator__active && respawn_activator__curStateEnemyInRadius
    broadcastEvent(UpdateRespawnIcons())