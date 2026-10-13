require app
require ecs
require ecs.common
require ecs.safe
require DagorSystem
require enlisted.events_enlisted
require DagorRandom
require math.base
require DagorMath
require strings
require GeomNodeTree
require common_shooter.events_common_shooter
require game.es.battle_area_common
require game.es.inventory_common
require game.es.inventory_drop_common
require game.utils.sound_utils
require game.es.mine_common
require inventory
require pathfinder
require DngPhysObj
require DngNet
require game.es.capzones_common
require math
require DagorMath
require game.events_game
require HumanPhys
require DagorMathUtils
require DngHuman
require GamePhys
require DagorRandom
require game.es.events
require RendInst
require PhysVars
require AnimV20
require AnimatedPhys
require vehicle
require DngShip
require Dacoll
require game.es.action_common
require DngDm
require game.es.awards_common


[event(unicast)]
struct CmdReInitWaveZombies {}

[event(unicast)]
struct EventObjectiveActivated {}

def broadcast_hero_log_event(evt : string; message : string)
  find_query() <| $ [es] (entity_spawner__aliveHumans : EidList)
    for humanEid in entity_spawner__aliveHumans
      send_net_event(humanEid, CmdHeroLogEvent(event = evt, text = message))
    return true

[es(tag=server)]
def calculate_spawns_count_mode(info : ParallelUpdateFrameDelayed;
                                transform aka human_transform : float3x4;
                                zombie__navmeshMaxSpawnEnemyNearMinMaxCount : float2;
                                zombie__navmeshMaxSpawnEnemyNearZoneMaxDist : float;
                                var zombie__navmeshCapzoneNextCheckAtTime : float&;
                                var zombie__navmeshMaxSpawnEnemyNear : int&;
                                zombie__navmeshCapzoneNextCheckPriod : float = 5.f)
  if info.curTime < zombie__navmeshCapzoneNextCheckAtTime
    return
  zombie__navmeshCapzoneNextCheckAtTime = info.curTime + zombie__navmeshCapzoneNextCheckPriod
  zombie__navmeshMaxSpawnEnemyNear = 0
  var distance = zombie__navmeshMaxSpawnEnemyNearZoneMaxDist
  query() <| $ [es(REQUIRE=capzone)] (transform aka zone_transform : float3x4;
                                      active : bool)
    if !active
      return
    distance = min(distance, length(zone_transform[3] - human_transform[3]))
    let relVal = min(distance / zombie__navmeshMaxSpawnEnemyNearZoneMaxDist, 1.)
    zombie__navmeshMaxSpawnEnemyNear = max(zombie__navmeshMaxSpawnEnemyNear,
      int(cvt(1. - relVal, 0., 1., zombie__navmeshMaxSpawnEnemyNearMinMaxCount.x, zombie__navmeshMaxSpawnEnemyNearMinMaxCount.y)))


[es(tag=server, on_appear, REQUIRE=building_menu__image, REQUIRE_NOT=build__markForAllTeams)]
def ammo_box_mark_init(evt : Event;
                       eid : EntityId)
  query() <| $ [es(REQUIRE=zombie_travel_mode)] ()
    remote_add_sub_template(eid, "build__mark_all_teams")


[es(tag=server, on_appear, REQUIRE=zombie_travel_mode)]
def ammo_box_mark_init_modoe(evt : Event)
  query() <| $ [es(REQUIRE_NOT=build__markForAllTeams, REQUIRE=building_menu__image)] (eid : EntityId)
    remote_add_sub_template(eid, "build__mark_all_teams")

[es(tag=server, on_appear, REQUIRE=gun, REQUIRE=itemInWorld, REQUIRE_NOT=build__markForAllTeams)]
def gun_mark_init_es(evt : Event;
                     eid : EntityId)
  query() <| $ [es(REQUIRE=zombie_travel_mode)] ()
    remote_add_sub_template(eid, "marker_for_guns")
    remote_add_sub_template(eid, "build__mark_all_teams")

[es(tag=server, on_appear, REQUIRE=zombie_travel_mode)]
def gun_mark_init_mode_es(evt : Event)
  query() <| $ [es(REQUIRE=gun, REQUIRE=itemInWorld, REQUIRE_NOT=build__markForAllTeams)] (eid : EntityId)
    remote_add_sub_template(eid, "marker_for_guns")
    remote_add_sub_template(eid, "build__mark_all_teams")

[es(tag=server, on_appear)]
def gun_marker_on_appear_es(evt : Event;
                            userPointTarget : EntityId;
                            userPointOwner : EntityId;
                            var transform : float3x4)
  query(userPointTarget) <| $ [es(REQUIRE=marker_for_gunsTag)] (var outline__enabled : bool&;
                                                                marker_for_guns__yOffset : float = 0.2)
    outline__enabled = true
    transform[3].y += marker_for_guns__yOffset
    send_net_event(userPointOwner, EventGunFound(gunEid = userPointTarget))

[es(tag=server, on_disappear, REQUIRE=userPointTarget)]
def gun_marker_on_disappear_es(evt : Event;
                               userPointTarget : EntityId)
  query(userPointTarget) <| $ [es(REQUIRE=marker_for_gunsTag)] (var outline__enabled : bool&)
    outline__enabled = false

[es(tag=server, on_disappear, REQUIRE=marker_for_gunsTag)]
def remove_gun_marker(evt : Event;
                      eid aka gun_eid : EntityId)
  query() <| $ [es] (eid aka marker_eid : EntityId;
                     userPointTarget : EntityId)
    if userPointTarget == gun_eid
      destroyEntity(marker_eid)

[es(tag=server, on_appear, before=init_force_anim)]
def travel_zombie_zombie_init(evt : Event;
                              eid : EntityId;
                              var game_effect__attachedTo : EntityId&;
                              travelzombie__zombieEnableTime : float;
                              var travelzombie__zombieEnableAt : float&)
  game_effect__attachedTo = eid
  travelzombie__zombieEnableAt = get_sync_time() + travelzombie__zombieEnableTime

[es(on_appear, tag=server, REQUIRE=simple_spawner__useHumansAsSpawn)]
def simple_zombie_travel_spawner_init(evt : Event;
                                      var simple_spawner__zonesPos : Point3List)
  query() <| $ [es(REQUIRE=zombie__nearestNavmeshSearchRadius)] (transform : float3x4)
    push(simple_spawner__zonesPos, transform[3])

[es(on_appear, tag=server, REQUIRE=simple_spawner__useArenaAsSpawn)]
def simple_zombie_arena_spawner_init(evt : Event;
                                     var simple_spawner__zonesPos : Point3List)
  query() <| $ [es(REQUIRE=zombie_arena)] (transform : float3x4;
                                           active : bool)
    if active
      push(simple_spawner__zonesPos, transform[3])

[es(on_appear, tag=server, REQUIRE=simple_spawner__useOwnPos)]
def simple_zombie_positionate_spawner_init(evt : Event;
                                           transform : float3x4;
                                           var simple_spawner__zonesPos : Point3List)
  push(simple_spawner__zonesPos, transform[3])

[es(tag=server, REQUIRE_NOT=deadEntity, before=sleep_zombie_sub_template, on_event=ParallelUpdateFrameDelayed, on_appear)]
def sleep_zombie_without_target(evt : Event;
                                walker_agent__targetEid : EntityId;
                                walker_agent__priorityTarget : EntityId;
                                var beh_tree__enabled : bool&;
                                var sleep_mode__isSleeping : bool&;
                                zombie_ability__activated : bool = false;
                                zombie_arise : Tag const?)
  let hasTarget = !!walker_agent__targetEid || !!walker_agent__priorityTarget
  beh_tree__enabled = hasTarget && !zombie_ability__activated && zombie_arise == null
  sleep_mode__isSleeping = !hasTarget

[es(REQUIRE_NOT=deadEntity, on_appear, on_event=ParallelUpdateFrameDelayed)]
def sleep_zombie_sub_template(evt : Event;
                              sleep_mode__isSleeping : bool;
                              eid : EntityId;
                              loc_snaphots__disabled : Tag const?)
  let sleepingNow = loc_snaphots__disabled != null
  if sleep_mode__isSleeping && !sleepingNow
    addSubTemplate(eid, "sleeping_zombie")
  if !sleep_mode__isSleeping && sleepingNow
    removeSubTemplate(eid, "sleeping_zombie")

[es(tag=gameClient, REQUIRE=deadEntity, on_appear)]
def dead_entity_init_emissive(info : Event;
                              zombie__minEmissiveDeadTime : float;
                              dynamic_material_channels_arr : Array;
                              var zombie__minEmissiveDeadAtTime : float&;
                              var zombie__initEmissiveColor : float4&)
  zombie__minEmissiveDeadAtTime = get_sync_time() + zombie__minEmissiveDeadTime

  if length(dynamic_material_channels_arr) == 0
    return

  let matParams = get_ecs_object(dynamic_material_channels_arr[0])
  if matParams != null
    zombie__initEmissiveColor = get_Point4(*matParams, "dynmat_param__emissive_color") ?? float4(0.0, 0.0, 0.0, 0.0)

[es(tag=gameClient, no_order, REQUIRE=deadEntity)]
def change_color_for_dead_zombie(info : UpdateStageInfoAct;
                                 zombie__minEmissiveDeadTime : float;
                                 zombie__initEmissiveColor : float4;
                                 zombie__minEmissiveMul : float;
                                 var zombie__minEmissiveDeadAtTime : float&;
                                 var dynamic_material_channels_arr : Array)
  if zombie__minEmissiveDeadAtTime < 0.
    return
  if zombie__minEmissiveDeadAtTime < info.curTime
    zombie__minEmissiveDeadAtTime = -1.
    return
  if length(dynamic_material_channels_arr) == 0
    return
  var matParams = getRW_ecs_object(dynamic_material_channels_arr[0])
  if matParams != null
    var color = zombie__initEmissiveColor
    let spendTime = zombie__minEmissiveDeadAtTime - info.curTime
    color.w *= cvt(spendTime, 0., zombie__minEmissiveDeadTime, zombie__minEmissiveMul, 1.f)
    set(*matParams, "dynmat_param__emissive_color", color)

[es(tag=server, no_order, REQUIRE=zombie_objective)]
def save_zombie_hp_for_gui(info : ParallelUpdateFrameDelayed;
                           hitpoints__hp : float;
                           walker_agent__targetEid : EntityId;
                           walker_agent__priorityTarget : EntityId;
                           var zombie_zone__agressive : bool&;
                           var zombie_zone__hp : int&)
  zombie_zone__hp = int(hitpoints__hp)
  zombie_zone__agressive ||= !!walker_agent__targetEid || !!walker_agent__priorityTarget

[es(tag=server, no_order, REQUIRE=arena_zombie_boss)]
def arena_zombie_hp_for_gui(info : ParallelUpdateFrameDelayed;
                            hitpoints__hp : float;
                            hitpoints__maxHp : float;
                            objective_spawner__owner : EntityId;
                            killLogName : string)
  query(objective_spawner__owner) <| $ [es] (var zombie_arena__bossRelHp : float&;
                                             var zombie_arena__bossName : das_string&)
    if hitpoints__hp <= 0.
      zombie_arena__bossRelHp = -1.
      zombie_arena__bossName := ""
    else
      zombie_arena__bossRelHp = safediv(hitpoints__hp, hitpoints__maxHp)
      zombie_arena__bossName := killLogName

[es(tag=server, on_appear, REQUIRE=arena_zombie_boss)]
def arena_zombie_boss_next_activation_block(evt : Event;
                                            objective_spawner__owner : EntityId)
  query(objective_spawner__owner) <| $ [es] (var zombie_arena__zombieNextWaveActivationAfter : float&;
                                             arena__blockActivationTime : float = 99999.)
    zombie_arena__zombieNextWaveActivationAfter = get_sync_time() + arena__blockActivationTime


[es(tag=server, no_order)]
def travel_zombie_activate_after_rising(info : ParallelUpdateFrameDelayed;
                                        eid : EntityId;
                                        travelzombie__zombieEnableAt : float;
                                        var game_effect__attachedTo : EntityId&;
                                        var beh_tree__enabled : bool&)
  if get_sync_time() >= travelzombie__zombieEnableAt
    game_effect__attachedTo = INVALID_ENTITY_ID
    beh_tree__enabled = true
    remote_remove_sub_template(eid, "zombie_arise")

[es(no_order)]
def zombie_ability_anim_disabled(info : ParallelUpdateFrameDelayed;
                                 eid : EntityId;
                                 zombie_ability__endTime : float;
                                 zombie_avility__subTemplate : string;
                                 var zombie_ability__activated : bool&;
                                 var game_effect__attachedTo : EntityId&;
                                 var beh_tree__enabled : bool&)
  if get_sync_time() >= zombie_ability__endTime
    game_effect__attachedTo = INVALID_ENTITY_ID
    zombie_ability__activated = false
    beh_tree__enabled = true
    removeSubTemplate(eid, zombie_avility__subTemplate)

[es(tag=server, no_order)]
def zombie_ability_activator(info : ParallelUpdateFrameDelayed;
                             transform aka boss_transform : float3x4;
                             zombie_boss__abilityActivatePeriodRange : float2;
                             zombie_boss__abilityActivateDist : float;
                             zombie_boss__ability_random_target : bool = false;
                             zombie_boss__ability_random_target_trace : bool = false;
                             var zombie_boss__abilityActivatePeriod : float&;
                             var walker_agent__priorityTarget : EntityId&;
                             var zombie_boss__abilityActivatedLastTime : float&;
                             var zombie_ability__activated : bool&;
                             var navmesh_phys__wishLookDir : float3?;
                             var navmesh_phys__wishWalkSpeed : float?;
                             var navmesh_phys__currentWalkVelocity : float3?)
  if zombie_ability__activated || zombie_boss__abilityActivatedLastTime < 0.
    zombie_boss__abilityActivatedLastTime = info.curTime
    zombie_boss__abilityActivatePeriod = rnd_float(zombie_boss__abilityActivatePeriodRange.x, zombie_boss__abilityActivatePeriodRange.y)
    return
  if (info.curTime - zombie_boss__abilityActivatedLastTime) < zombie_boss__abilityActivatePeriod
    return
  query(walker_agent__priorityTarget) <| $ [es] (transform aka target_transform : float3x4)
    var resDir = normalize(boss_transform[0])
    if zombie_boss__ability_random_target
      using() <| $(var soldiers : EidList)
        query() <| $ [es(REQUIRE=zombie__nearestNavmeshSearchRadius)] (eid aka soldier_eid : EntityId;
                                                                       human__aimTm : float3x4;
                                                                       isDowned : bool = false;
                                                                       isAlive : bool = false;
                                                                       human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID)
          if isAlive && !isDowned && !human_anim__vehicleSelected
            let from = boss_transform[3] + float3(0.f, 1.f, 0.f)
            let vec = human__aimTm[3] - from
            let dir = normalize(vec)
            let dist = length(vec)
            if dist < zombie_boss__abilityActivateDist && (!zombie_boss__ability_random_target_trace || !rayhit_normalized(from, dir, dist, ETF_DEFAULT, -1))
              push(soldiers, soldier_eid)
        if length(soldiers) != 0
          let selected = rnd_int(0, length(soldiers) - 1)
          walker_agent__priorityTarget = soldiers[selected]
          let resTm = get_TMatrix(walker_agent__priorityTarget, "human__aimTm")
          if resTm != null
            resDir = normalize((*resTm)[3] - boss_transform[3])
          zombie_boss__abilityActivatedLastTime = info.curTime
          zombie_boss__abilityActivatePeriod = rnd_float(zombie_boss__abilityActivatePeriodRange.x, zombie_boss__abilityActivatePeriodRange.y)
          zombie_ability__activated = true
    elif distance_sq(target_transform[3], boss_transform[3]) < square(zombie_boss__abilityActivateDist)
      resDir = normalize(target_transform[3] - boss_transform[3])
      zombie_boss__abilityActivatedLastTime = info.curTime
      zombie_boss__abilityActivatePeriod = rnd_float(zombie_boss__abilityActivatePeriodRange.x, zombie_boss__abilityActivatePeriodRange.y)
      zombie_ability__activated = true
    if navmesh_phys__wishLookDir != null && navmesh_phys__wishWalkSpeed != null && navmesh_phys__currentWalkVelocity != null
      *navmesh_phys__wishLookDir = resDir
      *navmesh_phys__wishWalkSpeed = 0.
      *navmesh_phys__currentWalkVelocity = float3()


[es(track=zombie_ability__activated)]
def zombie_ability_anim_track(info : Event;
                              eid : EntityId;
                              zombie_avility__subTemplate : string;
                              zombie_ability__activated : bool;
                              zombie_ability__animTime : float;
                              var beh_tree__enabled : bool&)
  if zombie_ability__activated
    beh_tree__enabled = false
    addSubTemplate(eid, zombie_avility__subTemplate) <| $(var init)
      set(init, "zombie_ability__endTime", get_sync_time() + zombie_ability__animTime)
      set(init, "game_effect__attachedTo", eid)

[es(tag=server)]
def calculate_spawns_for_zombie_mode(info : ParallelUpdateFrameDelayed;
                                     eid : EntityId;
                                     transform aka human_transform : float3x4;
                                     human__inDomeZoneEid : EntityId;
                                     var zombie__navmeshNextCheckSpawnAt : float&;
                                     zombie__navmeshAgressionLimits : float2;
                                     zombie__navmeshCheckEnemyRadius : float;
                                     zombie__navmeshAutoSpawnerMinPeriod : float;
                                     zombie__nearestNavmeshSpawnSpread : float;
                                     zombie__navmeshMaxSpawnEnemyNear : int;
                                     zombie__navmeshAutoSpawnerTemplates : StringList;
                                     zombie__navmeshAutoSpawnerChanceRange : FloatList;
                                     zombie__nearestNavmeshSearchRadius : float)
  if !!human__inDomeZoneEid || zombie__navmeshNextCheckSpawnAt > info.curTime
    return

  var zombieCount = 0
  let maxDistSq = square(zombie__navmeshCheckEnemyRadius)

  let isPlanter = find_query() <| $ [es] (bomb_site_participants__currentPlanterEid : EntityId)
    return bomb_site_participants__currentPlanterEid == eid

  query() <| $ [es(REQUIRE=zombie, REQUIRE_NOT=(deadEntity, zone_zombie))] (transform aka zombie_transform : float3x4;
                                                                            var walker_agent__priorityTarget : EntityId&;
                                                                            isAlive = true)
    if isAlive && length_sq(zombie_transform[3] - human_transform[3]) < maxDistSq
      zombieCount++
    if isPlanter && !walker_agent__priorityTarget
      walker_agent__priorityTarget = eid

  let skipSpawnZombie = zombieCount >= zombie__navmeshMaxSpawnEnemyNear
  if skipSpawnZombie
    zombie__navmeshNextCheckSpawnAt = info.curTime + zombie__navmeshAutoSpawnerMinPeriod
    return

  let randAngle = rnd_float(0., (2. * PI))
  let dir = angles_to_dir(float2(randAngle, 0.))
  let resultSpawnRad = rnd_float(-zombie__nearestNavmeshSpawnSpread, zombie__nearestNavmeshSpawnSpread) + zombie__nearestNavmeshSearchRadius
  var outNavmeshPos = human_transform[3] + dir * resultSpawnRad

  let spawnFailed = find_query() <| $ [es] (transform aka friendly_transform : float3x4;
                                            zombie__nearestNavmeshSearchRadius : float)
    return length_sq(outNavmeshPos - friendly_transform[3]) < square(zombie__nearestNavmeshSearchRadius - zombie__nearestNavmeshSpawnSpread)
  if spawnFailed
    return

  let projRadius = 1.
  let projExtents = float3(projRadius, FLT_MAX, projRadius)
  if !project_to_nearest_navmesh_point_no_obstacles(outNavmeshPos, projExtents)
    return

  let extents = float3(2., FLT_MAX, 2.)
  if !check_path(outNavmeshPos, human_transform[3], extents, 3., 3.)
    zombie__navmeshNextCheckSpawnAt = info.curTime + zombie__navmeshAutoSpawnerMinPeriod
    return

  let curWinNum = rnd_float(0.0, 1.0)
  var curChanceRange = 0.
  for enemyTempl, chance in zombie__navmeshAutoSpawnerTemplates, zombie__navmeshAutoSpawnerChanceRange
    curChanceRange += chance
    if curWinNum < curChanceRange
      zombie__navmeshNextCheckSpawnAt = info.curTime + zombie__navmeshAutoSpawnerMinPeriod
      var tm = IDENT_TM
      tm[3] = outNavmeshPos

      var resTemplate = add_sub_template_name(string(enemyTempl), "travel_zombie_additional")
      resTemplate = add_sub_template_name(resTemplate, "zombie_arise")
      let agressiveDist = rnd_float(zombie__navmeshAgressionLimits.x, zombie__navmeshAgressionLimits.y)
      createEntity(resTemplate) <| $(var init : ComponentsInitializer)
        set(init, "transform", tm)
        set(init, "beh_tree__enabled", false)
        set(init, "zombie__findClosestTargetDist", agressiveDist)
        set(init, "beh_tree__blackboard__enemyRadius", agressiveDist)
      break

[es(tag=server)]
def update_zone_progress_for_zombie(info : ParallelUpdateFrameDelayed;
                                    eid : EntityId;
                                    bomb_site__capzoneEid : EntityId;
                                    hitpoints__hp : float;
                                    hitpoints__maxHp : float;
                                    var zone_zombie__completed : bool&)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__progress : float&)
    capzone__progress = 1.01f - safediv(hitpoints__hp, hitpoints__maxHp)
    if capzone__progress >= 1.0 && !zone_zombie__completed
      zone_zombie__completed = true
      sendEvent(eid, EventBombSiteExplosion())

[es(on_appear, REQUIRE=zombie_mode_human)]
def reset_cleanup_time_on_zombie_travel_mode_soldier(evt : Event;
                                                     var human_inventory__lootCleanupTime : float&)
  human_inventory__lootCleanupTime = -1.

[es(tag=server, track=isAlive, on_disappear)]
def update_zone_progress_on_zombie_died(evt : Event;
                                        eid : EntityId;
                                        bomb_site__capzoneEid : EntityId;
                                        hitpoints__hp : float;
                                        hitpoints__maxHp : float;
                                        isAlive : bool;
                                        var zone_zombie__completed : bool&)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__progress : float&)
    capzone__progress = 1.01f - safediv(hitpoints__hp, hitpoints__maxHp)
    if (capzone__progress >= 1.0 || !isAlive) && !zone_zombie__completed
      zone_zombie__completed = true
      sendEventImmediate(eid, EventBombSiteExplosion())


[es(REQUIRE=hitpoints__hp)]
def update_zone_tm_for_zombie(info : ParallelUpdateFrameDelayed;
                              transform aka zombie_transform : float3x4;
                              bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (var transform aka zone_transform : float3x4)
    zone_transform = zombie_transform

[es(tag=server, REQUIRE=transform)]
def update_zone_damage(evt : EventShellExplodedServer)
  query() <| $ [es] (active aka zone_active : bool;
                     transform aka zone_transform : float3x4;
                     var capzone__progress : float&;
                     capzone__bombSiteEid : EntityId)
    if !zone_active
      return
    query(capzone__bombSiteEid) <| $ [es] (active aka crater_active : bool;
                                           var zombie_crater__shellsNum : int&;
                                           zombie_crater__shellsMax : int;
                                           var capzone__alwaysHide : bool?)
      if !crater_active || !is_point_in_box_zone(evt.pos, zone_transform)
        return
      zombie_crater__shellsNum++
      capzone__progress = safediv(float(zombie_crater__shellsNum), float(zombie_crater__shellsMax))
      if zombie_crater__shellsNum >= zombie_crater__shellsMax
        sendEvent(capzone__bombSiteEid, EventBombSiteExplosion())
        if capzone__alwaysHide != null
          *capzone__alwaysHide = true


[es(tag=server, REQUIRE=hitpoints__alwaysDowned, track=(isAlive, isDowned, human_anim__vehicleSelected), REQUIRE=(isAlive, isDowned, human_anim__vehicleSelected))]
def zombie_evacuation_recalc_on_downed(evt : Event)
  query() <| $ [es(REQUIRE=zombie_evacuation)] (eid : EntityId;
                                                active aka evacuation_active : bool;
                                                bomb_site__capzoneEid : EntityId;
                                                zombie_evacuation__time : float;
                                                var zombie_evacuation__atTime : float&;
                                                var zombie_evacuation__finalized : bool&)
    if !evacuation_active
      return
    query(bomb_site__capzoneEid) <| $ [es] (active aka zone_active : bool)
      if !zone_active
        return
      var hasSomeoneInVehicle = false
      var hasHumans = false
      query() <| $ [es(REQUIRE=human, REQUIRE_NOT=zombie)] (isAlive : bool;
                                                            isDowned : bool;
                                                            human_anim__vehicleSelected : EntityId)
        hasSomeoneInVehicle ||= !!human_anim__vehicleSelected && has(human_anim__vehicleSelected, "zombie_evacuation")
        hasHumans ||= isAlive && !isDowned && !human_anim__vehicleSelected

      if !hasHumans
        if hasSomeoneInVehicle && !zombie_evacuation__finalized
          zombie_evacuation__finalized = true
          sendEvent(eid, EventBombSiteExplosion())
      elif hasSomeoneInVehicle && zombie_evacuation__atTime < 0.
        zombie_evacuation__atTime = get_sync_time() + zombie_evacuation__time

[es(tag=server, on_event=EventBombSiteExplosion, before=bomb_site_explosion_set_capzone_status, REQUIRE=zombie_evacuation)]
def calculate_team_tokens_es(evt : Event)
  var teamTokens = 0
  query() <| $ [es(REQUIRE=player_zombieMode)] (possessed : EntityId;
                                                player__tokens : int)
    query(possessed) <| $ [es] (human_anim__vehicleSelected : EntityId)
      if has(human_anim__vehicleSelected, "zombie_evacuation")
        teamTokens += player__tokens
  broadcast_net_event(EventTeamTokens(tokens = teamTokens))

  var maxBattleTime = -1.0
  let time = get_sync_time()
  query() <| $ [es(REQUIRE=player_zombieMode)] (scoring_player__battleTimeLastStartedAt : float;
                                                scoring_player__battleTime : float)
    let battleTime = scoring_player__battleTime + (scoring_player__battleTimeLastStartedAt >= 0.0 ? time - scoring_player__battleTimeLastStartedAt : 0.0)
    if battleTime > maxBattleTime
      maxBattleTime = battleTime
  broadcast_net_event(EventSaveZombieModeBattleTime(battleTime = int(maxBattleTime)))

[es(tag=server, on_event=EventBombSiteExplosion, REQUIRE=zombie_evacuation)]
def zombie_evacuation_vehicle_set_immunity(evt : Event)
  query() <| $ [es] (var dm__ignoreDamage : bool&)
    dm__ignoreDamage = true

[es(tag=server, REQUIRE=zombie_evacuation, on_appear)]
def zombie_evacuation_security_init(info : Event;
                                    transform : float3x4;
                                    evacuation__securityMinRadToObjective : float;
                                    evacuation__securitySearchRadToObjective : float;
                                    evacuation__security : Object;
                                    var evacuation__securitywavesTemplates : StringList;
                                    var evacuation__securitycount : IntList;
                                    var evacuation__securitySpawnsPos : Point3List)
  var securityCount = 0
  for data in evacuation__security
    let count = get_int(data.value) ?? 0
    if count > 0
      push(evacuation__securitywavesTemplates, data.key)
      push(evacuation__securitycount, count)
      securityCount += count

  if securityCount == 0
    return

  let extents = float3(2., FLT_MAX, 2.)
  let spawnsSearchMul = 1.5
  let resCount = int(float(securityCount) * spawnsSearchMul)
  find_random_points_around_circle(transform[3], evacuation__securitySearchRadToObjective, resCount) <| $(spawns)
    for spawn in spawns
      if length(spawn - transform[3]) > evacuation__securityMinRadToObjective && check_path(transform[3], spawn, extents, 3., 3.)
        push(evacuation__securitySpawnsPos, spawn)


[es(tag=server, REQUIRE=zombie_evacuation)]
def zombie_evacuation_security(info : ParallelUpdateFrameDelayed;
                               evacuation__securitySubTemplate : string;
                               evacuation__securityAgressiveDist : float;
                               evacuation__securitySpawnPeriod : float;
                               evacuation__securitySpawnsPos : Point3List;
                               var evacuation__securitySpawnNextTime : float&;
                               var evacuation__securitywavesTemplates : StringList;
                               var evacuation__securitycount : IntList)
  if evacuation__securitySpawnNextTime > info.curTime
    return

  evacuation__securitySpawnNextTime = info.curTime + evacuation__securitySpawnPeriod
  let templatesCount = length(evacuation__securitywavesTemplates)
  if templatesCount == 0
    return
  let spawnsCount = length(evacuation__securitySpawnsPos)
  if spawnsCount == 0
    return
  let selectedId = rnd_int(0, templatesCount - 1)
  let selectedSpawnId = rnd_int(0, spawnsCount - 1)

  let enemyTempl = string(evacuation__securitywavesTemplates[selectedId])
  let resTemplate = add_sub_template_name(enemyTempl, evacuation__securitySubTemplate)

  createEntity(resTemplate) <| $(var init : ComponentsInitializer)
    var tm = IDENT_TM
    tm[3] = evacuation__securitySpawnsPos[selectedSpawnId]
    set(init, "transform", tm)
    set(init, "beh_tree__enabled", true)
    set(init, "zombie__findClosestTargetDist", evacuation__securityAgressiveDist)
    set(init, "beh_tree__blackboard__enemyRadius", evacuation__securityAgressiveDist)

  evacuation__securitycount[selectedId]--
  if evacuation__securitycount[selectedId] <= 0
    erase(evacuation__securitywavesTemplates, selectedId)
    erase(evacuation__securitycount, selectedId)

[es(tag=server, REQUIRE=zombie_evacuation)]
def zombie_evacuation_finalizer(info : ParallelUpdateFrameDelayed;
                                eid : EntityId;
                                zombie_evacuation__atTime : float;
                                var zombie_evacuation__finalized : bool&)
  if zombie_evacuation__atTime < 0. || zombie_evacuation__atTime > info.curTime
    return
  if !zombie_evacuation__finalized
    zombie_evacuation__finalized = true
    sendEvent(eid, EventBombSiteExplosion())

[es(tag=server, REQUIRE_NOT=(zombie_objective__buildTarget, zombie_mode__excludeAgressive, builder_preview), on_appear)]
def zomie_build_add_target(evt : Event;
                           buildByPlayer : EntityId;
                           eid : EntityId)
  if !!buildByPlayer
    find_query() <| $ [es(REQUIRE=zombie_travel_mode)] ()
      addSubTemplate(eid, "zombie_build_target")
      return true

[es(tag=server, REQUIRE=zombie_evacuation, on_appear, track=active)]
def zombie_evacuation_init_time(evt : Event;
                                active : bool;
                                var zombie_evacuation__activatedAtTime : float&)
  if active
    zombie_evacuation__activatedAtTime = get_sync_time()

[es(tag=server, REQUIRE=zombie_evacuation)]
def zombie_evacuation_patrols_time(info : ParallelUpdateFrameDelayed;
                                   active : bool;
                                   transform aka evacuation_transform : float3x4;
                                   zombie_evacuation__activatedAtTime : float;
                                   // zombie_evacuation__patrolsTimer : float;
                                   // zombie_evacuation__patrolsTimeRange : float2;
                                   var patrols_spawner__percentProgress : int&;
                                   patrols_spawner__wavesStates : Object)
  if !active || zombie_evacuation__activatedAtTime < 0.
    return

  query() <| $ [es] (travel_zombie__lastObjectivePos : float3)
    let maxDist = length(travel_zombie__lastObjectivePos - transform[3])
    var resultDistSq = maxDist * maxDist
    query() <| $ [es(REQUIRE=zombie__nearestNavmeshSearchRadius)] (transform aka friendly_transform : float3x4)
      let distSq = length_sq(evacuation_transform[3] - friendly_transform[3])
      if distSq < resultDistSq
        resultDistSq = distSq
    let distToHuman = sqrt(resultDistSq)
    patrols_spawner__percentProgress = int(cvt(distToHuman, 0., maxDist, 100., 0.))

  query() <| $ [es] (var patrols_spawner__percentProgressUI : int&;
                     var zombie_patrol__spawnPeriod : float2&;
                     var zombie_patrol__spawnTimer : float&;
                     var zombie_patrol__objectiveWavesCount : int&;
                     var objective_spawner__waves : Array&;
                     var patrols_spawner__selectedState : int&)

    var selectedState = 101 //state > 100
    patrols_spawner__percentProgressUI = patrols_spawner__percentProgress

    var selectedPatrolsTime = zombie_patrol__spawnPeriod
    for it in patrols_spawner__wavesStates
      let intProgress = to_int(it.key)
      if patrols_spawner__percentProgress < intProgress
        if selectedState > intProgress
          selectedState = intProgress
          if patrols_spawner__selectedState != selectedState
            let stateData = get_ecs_object(it.value)
            if stateData != null
              let curWaves = get_ecs_array(*stateData, "waves")
              if curWaves != null
                patrols_spawner__selectedState = selectedState
                objective_spawner__waves := *curWaves
                zombie_patrol__objectiveWavesCount = length(objective_spawner__waves)
              else
                logerr("incorrect config for patrols override data")
              let patrolsTimer = get_Point2(*stateData, "patrolsTimer")
              if patrolsTimer != null
                selectedPatrolsTime = *patrolsTimer
              else
                logerr("incorrect config for patrolsTimer override data")

    zombie_patrol__spawnPeriod.x = min(zombie_patrol__spawnPeriod.x, selectedPatrolsTime.x)
    zombie_patrol__spawnPeriod.y = min(zombie_patrol__spawnPeriod.y, selectedPatrolsTime.y)
    // let spendTime = info.curTime - zombie_evacuation__activatedAtTime
    // zombie_patrol__spawnPeriod.x = cvt(spendTime, 0., zombie_evacuation__patrolsTimer, zombie_evacuation__patrolsTimeRange.x, zombie_evacuation__patrolsTimeRange.y)
    // zombie_patrol__spawnPeriod.y = zombie_patrol__spawnPeriod.x
    zombie_patrol__spawnTimer = min(zombie_patrol__spawnTimer, zombie_patrol__spawnPeriod.y)

[es(tag=server, on_appear, REQUIRE=grid_obj, after=grid_obj_init_tm_scale_es, before=grid_obj_update_es)]
def zombie_scaled_init_grid(evt : Event;
                            nPhys__animcharScale : float;
                            var grid_obj__fixedTmScale : float&)
  grid_obj__fixedTmScale = nPhys__animcharScale

[es(tag=server, REQUIRE=zombie_evacuation)]
def zombie_evacuation_throttle(info : ParallelUpdateFrameDelayed;
                               zombie_evacuation__finalized : bool;
                               var vehicle_net_phys : VehiclePhysActor&)
  if zombie_evacuation__finalized
    assume producedCT = vehicle_net_phys.phys.producedCT
    producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_THROTTLE, 1.)
    producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_HAND_BRAKE, 0.)
    producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_BRAKE_LEFT, 0.)
    producedCT |> ground_control_state_setAxisValue(EGroundControlAxis.GCA_BRAKE_RIGHT, 0.)
    producedCT |> ground_control_state_setAutomaticTransmission(true)
    producedCT |> ground_control_state_setKeepDrivingDirectionMode(false)

[es(tag=server, REQUIRE=zombie_evacuation)]
def zombie_evacuation_ship_throttle(info : ParallelUpdateFrameDelayed;
                                    zombie_evacuation__finalized : bool;
                                    var ship_net_phys : ShipActor&)
  if zombie_evacuation__finalized
    ship_control_state_setAxisValue(ship_net_phys.phys.producedCT, EShipControlAxis.SCA_PORT_ENGINE, 1.0)
    ship_control_state_setAxisValue(ship_net_phys.phys.producedCT, EShipControlAxis.SCA_STAR_ENGINE, 1.0)

[es(tag=server, REQUIRE=zombie_mode_human, track=human_anim__vehicleSelected)]
def zombie_evacuation_in_vehicle_invulnerable(evt : Event;
                                              eid : EntityId;
                                              human_anim__vehicleSelected : EntityId;
                                              invulnerable : Tag const?)
  if !!human_anim__vehicleSelected
    if invulnerable == null
      remote_add_sub_template(eid, "human_enable_invulnerable")
  else
    if invulnerable != null
      remote_remove_sub_template(eid, "human_enable_invulnerable")

[es(tag=server)]
def point_auto_spawn_zombies(info : ParallelUpdateFrameDelayed;
                             transform aka zone_transform : float3x4;
                             zombie_crater__autoSpawnHumanDist : float;
                             zombie_crater__spawnPeriod : float;
                             bomb_site__capzoneEid : EntityId;
                             var zombie_crater__next_spawnAtTime : float&;
                             zombie_crater__zombiesLimit : int = 150)
  if info.curTime < zombie_crater__next_spawnAtTime
    return
  if !(get_bool(bomb_site__capzoneEid, "active") ?? false)
    return
  zombie_crater__next_spawnAtTime = info.curTime + zombie_crater__spawnPeriod
  let maxDistSq = square(zombie_crater__autoSpawnHumanDist)
  var humansNear = false
  find_query() <| $ [es] (entity_spawner__aliveHumans : EidList;
                          entity_spawner__aliveZombiesCount : int)
    find_query() <| $ [es] (zombie__navmeshAutoSpawnerTemplates : StringList;
                            zombie__navmeshAutoSpawnerChanceRange : FloatList)
      if entity_spawner__aliveZombiesCount > zombie_crater__zombiesLimit
        return true
      for human in entity_spawner__aliveHumans
        if humansNear
          break
        query(human) <| $ [es] (transform aka soldier_transform : float3x4)
          if distance_sq(soldier_transform[3], zone_transform[3]) < maxDistSq
            humansNear = true
      if humansNear
        let curWinNum = rnd_float(0.0, 1.0)
        var curChanceRange = 0.
        for enemyTempl, chance in zombie__navmeshAutoSpawnerTemplates, zombie__navmeshAutoSpawnerChanceRange
          curChanceRange += chance
          if curWinNum < curChanceRange
            createEntity(string(enemyTempl)) <| $(var init : ComponentsInitializer)
              set(init, "transform", zone_transform)
            break
      return true
    return true

[es(tag=server, on_event=(EventForceCapture, EventBombSiteExplosion))]
def zombie_save_last_objective_pos(evt : Event;
                                   transform : float3x4)
  query() <| $ [es] (var travel_zombie__lastObjectivePos : float3&;
                     var travel_zombie__isFirstObjective : bool&)
    travel_zombie__lastObjectivePos = transform[3]
    travel_zombie__isFirstObjective = false

[es(tag=server, REQUIRE=arena_zombie, REQUIRE_NOT=arena_zombie_not_count)]
def on_zombie_died_in_arena(evt : EventEntityDied;
                            zombie_arena__killsCost : int = 1)
  let zone_eid = get_Eid(evt.offender, "human__inDomeZoneEid") ?? INVALID_ENTITY_ID
  query(zone_eid) <| $ [es] (var zombie_arena__kills : int&;
                             var objective_spawner__active : bool&;
                             bomb_site__capzoneEid : EntityId;
                             zombie_arena__killsRequire : int)
    zombie_arena__kills += zombie_arena__killsCost
    if zombie_arena__kills >= zombie_arena__killsRequire
      sendEvent(zone_eid, EventBombSiteExplosion())
      objective_spawner__active = false
    else
      query(bomb_site__capzoneEid) <| $ [es] (var capzone__progress : float&)
        capzone__progress = safediv(float(zombie_arena__kills), float(zombie_arena__killsRequire))


[es(tag=server)]
def shell_target_relative_dir(evt : CmdPostPhysUpdate;
                              phys_obj__shellTarget : EntityId&;
                              zombie__shellTau : float = 0.01;
                              var phys_obj_net_phys : PhysObjActor)
  let dt = evt.dt
  let speed = length(phys_obj_net_phys.phys.currentState.velocity)
  let dir = normalize(phys_obj_net_phys.phys.currentState.velocity)
  let DPos = phys_obj_net_phys.phys.currentState.location.P
  let FPos = float3(float(DPos.x), float(DPos.y), float(DPos.z))
  let targetAimTm = get_TMatrix(phys_obj__shellTarget, "human__aimTm")
  if targetAimTm != null
    let relDir = normalize((*targetAimTm)[3] - FPos)
    if length((*targetAimTm)[3] - FPos) > 1.f
      let resDir = approach(dir, relDir, dt, zombie__shellTau) * speed
      phys_obj_net_phys.phys.currentState.velocity = resDir


[es(tag=server, on_disappear, REQUIRE=zombie_arena__killsRequire)]
def on_zombie_arena_destroyed(evt : Event;
                              eid : EntityId)
  query() <| $ [es] (var human__inDomeZoneEid : EntityId&)
    if human__inDomeZoneEid == eid
      human__inDomeZoneEid = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=zombie, REQUIRE_NOT=deadEntity)] (var zombie__skipReactHumansInDome : bool&)
    zombie__skipReactHumansInDome = false


[es(tag=gameClient, on_disappear, REQUIRE=zombie_crater)]
def on_zombie_crater_destroyed_fx(evt : Event;
                                  transform : float3x4;
                                  zombie_crater__effectOnDestroy : string)
  createEntity(zombie_crater__effectOnDestroy) <| $(var init)
    init |> set("transform", transform)


[es(tag=gameClient, on_disappear, REQUIRE=zombie_arena)]
def on_zombie_arena_destroyed_fx(evt : Event;
                                 transform : float3x4;
                                 zombie_arena__effectOnDestroy : string)
  createEntity(zombie_arena__effectOnDestroy) <| $(var init)
    init |> set("transform", transform)

[es(tag=server, on_disappear, REQUIRE=zombie_crater)]
def on_zombie_crater_dmg_res(evt : Event;
                             transform : float3x4;
                             zombie_crater__nextRes : string)
  createEntity(zombie_crater__nextRes) <| $(var init)
    init |> set("transform", transform)

[es(on_disappear, REQUIRE=objective_spawner__active)]
def disable_zone_indicator_on_disappear(evt : Event;
                                        bomb_site__capzoneEid : EntityId)
  if !!bomb_site__capzoneEid
    setOptional(bomb_site__capzoneEid, "capzone__alwaysVisibleOnMinimap", false)


[es(tag=gameClient, on_disappear, REQUIRE_NOT=deadEntity)]
def on_zombie_boss_destroyed_fx(evt : Event;
                                animchar : AnimcharBaseComponent;
                                transform : float3x4;
                                zombie__deadEffect : string;
                                zombie__deadEffectNode : string)
  createEntity(zombie__deadEffect) <| $(var init)
    var tm = transform
    let nodeIndex = *animchar.nodeTree |> geomtree_findNodeIndex(zombie__deadEffectNode)
    if nodeIndex >= 0
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(nodeIndex, tm)
    init |> set("transform", tm)


[es(tag=server, on_disappear)]
def zombie_mode_objective_activate_fx_destroyed(evt : Event;
                                                var zombie_arena__waveFxEid : EntityId&)
  if !!zombie_arena__waveFxEid

    destroyEntity(zombie_arena__waveFxEid)
    zombie_arena__waveFxEid = INVALID_ENTITY_ID


[es(tag=server)]
def zombie_arena_initialize_dome(evt : EventRadioObjectiveActivate;
                                 eid : EntityId;
                                 transform aka zone_transform : float3x4;
                                 bomb_site__capzoneEid : EntityId;
                                 zombie_arena__fxOnActivate, zombie_arena__createDomeOnActivate : string;
                                 zombie_arena__zombieWavePeriod : float;
                                 zombie_arena__zombieWavePeriodList : FloatList;
                                 zombie_arena__zombieNextWaveDelay : float;
                                 zombie_arena__zombieFirstWaveDelay : float;
                                 objective_spawner__active : bool;
                                 zombie_arena__fxScale : float3 = float3(1., 1., 1.);
                                 var zombie_arena__zombieNextWaveActivationAfter : float&;
                                 var zombie_arena__zombieFirstWaveActivateAtTime : float&;
                                 var zombie_arena__zombieNextWaveAtTime : float&;
                                 var zombie_arena__domOnActivateEid, zombie_arena__fxOnActivateEid : EntityId&)
  let curTime = get_sync_time()
  if zombie_arena__zombieFirstWaveActivateAtTime > curTime
    send_net_event(evt.bombSiteOperator, CmdHeroLogEvent(event = "zombie_objective", text = "objective/altarAlreadyActivated"))
    return
  if objective_spawner__active
    if zombie_arena__zombieNextWaveActivationAfter > curTime
      send_net_event(evt.bombSiteOperator, CmdHeroLogEvent(event = "zombie_objective", text = "objective/activationCooldown"))
      return
    zombie_arena__zombieNextWaveActivationAfter = curTime + zombie_arena__zombieNextWaveDelay
    zombie_arena__zombieNextWaveAtTime = curTime
    broadcast_hero_log_event("zombie_objective", "objective/nextWaveActivated")
    sendEvent(eid, EventObjectiveActivated())
    // send_net_event(evt.bombSiteOperator, [[CmdHeroLogEvent event="zombie_objective", text="objective/nextWaveActivated"]])
    return

  if zombie_arena__zombieNextWaveAtTime <= 0.
    query(bomb_site__capzoneEid) <| $ [es] (sphere_zone__radius : float)
      zombie_arena__domOnActivateEid = createEntity(zombie_arena__createDomeOnActivate) <| $(var init)
        var tm = transform
        tm |> orthonormalize()
        init |> set("transform", tm)
        init |> set("force_dome__position", zone_transform[3])
        init |> set("force_dome__radius", sphere_zone__radius)
        init |> set("sphere_zone__radius", sphere_zone__radius)
      let radSq = sphere_zone__radius * sphere_zone__radius
      query() <| $ [es(REQUIRE=zombie, REQUIRE_NOT=deadEntity)] (transform aka zombie_transform : float3x4&;
                                                                 var walker_agent__priorityTarget : EntityId&;
                                                                 var walker_agent__targetEid : EntityId&;
                                                                 var zombie__skipReactHumansInDome : bool&)
        if length_sq(zombie_transform[3] - zone_transform[3]) > radSq
          zombie__skipReactHumansInDome = true
        else
          query() <| $ [es] (eid : EntityId;
                             transform aka human_transform : float3x4;
                             isDowned : bool = false;
                             isAlive : bool = false;
                             human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID)
            if length_sq(human_transform[3] - zone_transform[3]) <= radSq
              if !isDowned && isAlive && !human_anim__vehicleSelected
                walker_agent__priorityTarget = eid
                walker_agent__targetEid = eid

    zombie_arena__fxOnActivateEid = createEntity(zombie_arena__fxOnActivate) <| $(var init)
      var tm = zone_transform
      tm[0] *= zombie_arena__fxScale.x
      tm[1] *= zombie_arena__fxScale.y
      tm[2] *= zombie_arena__fxScale.z
      init |> set("transform", tm)

      zombie_arena__zombieFirstWaveActivateAtTime = curTime + zombie_arena__zombieFirstWaveDelay
      let period = length(zombie_arena__zombieWavePeriodList) > 0 ? zombie_arena__zombieWavePeriodList[0] : zombie_arena__zombieWavePeriod
      zombie_arena__zombieNextWaveAtTime = curTime + zombie_arena__zombieFirstWaveDelay + period
      sendEvent(eid, EventObjectiveActivated())

[es(tag=server, on_disappear)]
def zombie_arena_destroy_dome(evt : Event;
                              zombie_arena__domOnActivateEid, zombie_arena__fxOnActivateEid : EntityId)
  if !!zombie_arena__domOnActivateEid
    destroyEntity(zombie_arena__domOnActivateEid)
  if !!zombie_arena__fxOnActivateEid
    destroyEntity(zombie_arena__fxOnActivateEid)

[es(tag=server)]
def first_wave_arena_activator(info : ParallelUpdateFrameDelayed;
                               var zombie_arena__zombieFirstWaveActivateAtTime : float&;
                               var objective_spawner__active : bool&)
  if objective_spawner__active
    return
  if zombie_arena__zombieFirstWaveActivateAtTime > 0. && zombie_arena__zombieFirstWaveActivateAtTime < info.curTime
    objective_spawner__active = true
    zombie_arena__zombieFirstWaveActivateAtTime = -1.

[es(REQUIRE_NOT=(deadEntity, zombie), on_event=CmdPostPhysUpdate, REQUIRE=(human, zombie__navmeshNextCheckSpawnAt))]
def zombie_arena_clamper(evt : Event;
                         var human__inDomeZoneEid : EntityId&;
                         var human_net_phys : HumanActor&)
  find_query() <| $ [es(REQUIRE=zombie_arena)] (eid : EntityId;
                                                objective_spawner__active : bool;
                                                transform : float3x4;
                                                bomb_site__capzoneEid : EntityId;
                                                active : bool;
                                                force_dome__humanClampEps = 0.5)
    if !active || !objective_spawner__active
      return false
    query(bomb_site__capzoneEid) <| $ [es] (sphere_zone__radius : float)
      let pos = float3(human_net_phys.phys.currentState.location.P)
      let vec = transform[3] - pos
      let dist = length(vec)
      let checkRad = sphere_zone__radius - force_dome__humanClampEps
      if checkRad <= 0.
        return
      let t = dist / (checkRad)
      if t > 1.f
        if !!human__inDomeZoneEid
          let resPos = pos + vec * (1.f - 1.f / t)
          human_net_phys.phys.currentState.location.P = DPoint3(resPos)
      else
        human__inDomeZoneEid = eid
    return true

[es(tag=server)]
def reset_only_near_on_hit_zombies(evt : EventOnEntityHit)
  query(evt.victim) <| $ [es] (var zombie__reactOnlyOnClosest : bool&)
    zombie__reactOnlyOnClosest = false

[es(tag=server, track=zombie__reactOnlyOnClosest, REQUIRE=zone_zombie)]
def boss_zombie_activate_all_zone_zombies(evt : Event;
                                          zombie__reactOnlyOnClosest aka base_zombie__reactOnlyOnClosest : bool)
  if !base_zombie__reactOnlyOnClosest
    query() <| $ [es(REQUIRE=zone_zombie)] (var zombie__reactOnlyOnClosest aka other_zombie__reactOnlyOnClosest : bool&;
                                            bomb_site__capzoneEid : EntityId;
                                            active : bool)
      if !!bomb_site__capzoneEid && active
        other_zombie__reactOnlyOnClosest = false

[es(tag=server, REQUIRE_NOT=(zone_zombie, evacuation_zombie, deadEntity))]
def destroy_farawatr_zombies(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             isAlive : bool;
                             transform aka zombie_transform : float3x4;
                             walker_agent__priorityTarget : EntityId;
                             zombie__maxDistanceToHuman : float;
                             zombie__reactOnlyOnClosest : bool;
                             zombie__maxDistanceCheckPeriod : float;
                             zombie__minDistToObjectiveCleaner : float;
                             var zombie__readyForObjectiveCleaner : bool&;
                             var zombie__maxDistanceCheckAtTime : float&)
  zombie__readyForObjectiveCleaner = true
  if !zombie__reactOnlyOnClosest || !!walker_agent__priorityTarget || !isAlive || info.curTime < zombie__maxDistanceCheckAtTime
    return
  zombie__maxDistanceCheckAtTime = info.curTime + zombie__maxDistanceCheckPeriod
  let maxDistSq = square(zombie__maxDistanceToHuman)
  var humansNear = false
  find_query() <| $ [es] (entity_spawner__aliveHumans : EidList)
    for human in entity_spawner__aliveHumans
      if humansNear
        break
      query(human) <| $ [es] (transform aka soldier_transform : float3x4)
        let distToHuman = distance_sq(soldier_transform[3], zombie_transform[3])
        if distToHuman < maxDistSq
          humansNear = true
        zombie__readyForObjectiveCleaner &&= distToHuman > square(zombie__minDistToObjectiveCleaner)
    return true
  if !humansNear
    destroyEntity(eid) //mb teleport it to new spawn? better than recreate

[es(tag=server, on_appear)]
def init_randomize_weight_for_nearest_zombie_spawn(evt : Event;
                                                   eid : EntityId;
                                                   zombie__navmeshAutoSpawnerTemplates : StringList;
                                                   zombie__navmeshAutoSpawnerWeight : FloatList;
                                                   var zombie__navmeshAutoSpawnerChanceRange : FloatList&)
  if length(zombie__navmeshAutoSpawnerTemplates) != length(zombie__navmeshAutoSpawnerWeight)
    logerr("incorrect radnomize weap weight set in /*{eid}*/ /*{getEntityTemplateName(eid)}*/")
    return
  resize(zombie__navmeshAutoSpawnerChanceRange, length(zombie__navmeshAutoSpawnerTemplates))
  var summWeight = 0.
  for weight in zombie__navmeshAutoSpawnerWeight
    summWeight += weight
  if summWeight == 0.
    return
  for weight, chance in zombie__navmeshAutoSpawnerWeight, zombie__navmeshAutoSpawnerChanceRange
    chance = weight / summWeight


[es(tag=gameClient, REQUIRE=zombie_arena, track=objective_spawner__curWaveId, REQUIRE=objective_spawner__curWaveId)]
def change_dome_brightness_on_wave_changed(evt : Event)
  query() <| $ [es] (force_dome__restoreBrightnessTime : float;
                     var force_dome__restoreBrightnessAtTime : float&)
    force_dome__restoreBrightnessAtTime = get_sync_time() + force_dome__restoreBrightnessTime

[es(tag=gameClient)]
def zombie_arena_resource_brightness(info : ParallelUpdateFrameDelayed;
                                     force_dome__maxBrightness : float;
                                     force_dome__restoreBrightnessTime : float;
                                     force_dome__initBrightness : float;
                                     var force_dome__restoreBrightnessAtTime : float&;
                                     var force_dome__brightness : float&)
  if force_dome__restoreBrightnessAtTime < 0.
    return
  let timeDelta = force_dome__restoreBrightnessAtTime - info.curTime
  if timeDelta < 0.
    force_dome__restoreBrightnessAtTime = -1.
    force_dome__brightness = force_dome__initBrightness
    return
  force_dome__brightness = cvt(timeDelta, 0., force_dome__restoreBrightnessTime, force_dome__initBrightness, force_dome__maxBrightness)

[es(tag=server, on_appear, on_event=CmdReInitWaveZombies)]
def init_waves_period_for_zombies_objective(evt : Event;
                                            var zombie_arena__zombieWavePeriodList : FloatList;
                                            zombie_arena__zombieWavePeriod : float;
                                            objective_spawner__waves : Array)
  let wavesCount = length(objective_spawner__waves)
  clear(zombie_arena__zombieWavePeriodList)
  for wave in range(wavesCount)
    let waveData = get_ecs_object(objective_spawner__waves[wave])
    if waveData == null
      logerr("incorrect data in objective_spawner__waves. No objects in it.")
      return
    let period = get_int(*waveData, "nextWavePeriod") ?? -1
    let result = period > 0 ? float(period) : zombie_arena__zombieWavePeriod
    push(zombie_arena__zombieWavePeriodList, result)

[es(tag=server, on_appear, on_event=CmdReInitWaveZombies, track=objective_spawner__curWaveId)]
def init_objective_wave_templates_for_spawner(evt : Event;
                                              objective_spawner__waves : Array;
                                              objective_spawner__curWaveId : int;
                                              var objective_spawner__wavesCount : int&;
                                              var objective_spawner__wavesTemplates : StringList;
                                              var objective_spawner__count : IntList;
                                              var objective_spawner__briefing : das_string;
                                              objective_spawner__multiplier : float = 1.)
  objective_spawner__wavesCount = length(objective_spawner__waves)

  let curWave = objective_spawner__curWaveId % objective_spawner__wavesCount
  let waveData = get_ecs_object(objective_spawner__waves[curWave])
  if waveData == null
    logerr("incorrect data in objective_spawner__waves. No objects in it.")
    return

  objective_spawner__briefing := ""
  for it in *waveData
    if it.key == "wave_briefing"
      objective_spawner__briefing := get_string(it.value, "")
      continue

    if it.key == "nextWavePeriod" //add black list in future
      continue

    var count = get_int(it.value) ?? -1
    count = int(float(count) * objective_spawner__multiplier)
    if count <= 0
      logerr("Expecting positive value for key /*{it.key}*/. Got /*{count}*/")
      continue
    count = it.key == "zombie_eclipse_controller" ? 1 : count

    let alreadyExistIdx = find_index(objective_spawner__wavesTemplates, it.key)
    if alreadyExistIdx >= 0
      objective_spawner__count[alreadyExistIdx] += count
    else
      push(objective_spawner__wavesTemplates, it.key)
      push(objective_spawner__count, count)

[es(tag=server, track=(objective_spawner__curWaveId, active, objective_spawner__active), REQUIRE=objective_spawner__curWaveId, on_event=CmdReInitWaveZombies, after=init_objective_wave_templates_for_spawner)]
def zombie_objective_init_briefing(evt : Event;
                                   active : bool;
                                   objective_spawner__briefing : string;
                                   objective_spawner__active : bool;
                                   var objective_spawner__retriggerAtTime : float&;
                                   objective_spawner__retriggerTime : float = 1.0;
                                   objective_spawner__briefingTime : float = 7.)
  if !active || !objective_spawner__active || empty(objective_spawner__briefing)
    return
  query() <| $ [es(REQUIRE=team__id)] (var team__briefing : das_string&;
                                       var team__goalShowTime : float&;
                                       var team__forceEnableBriefing : bool&)
    if team__briefing != objective_spawner__briefing
      team__briefing := objective_spawner__briefing
    else
      team__forceEnableBriefing = true
      objective_spawner__retriggerAtTime = get_sync_time() + objective_spawner__retriggerTime
    team__goalShowTime = objective_spawner__briefingTime


[es(tag=server, on_appear)]
def zombie_objective_init_briefing_zone(evt : Event;
                                        objective__activationBriefing : string;
                                        objective__deactivationBriefing : string;
                                        bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__activationBriefing : das_string&;
                                          var capzone__deactivationBriefing : das_string&)
    capzone__activationBriefing := objective__activationBriefing
    capzone__deactivationBriefing := objective__deactivationBriefing

[es(tag=server, before=activate_entity, track=(active, capzone__activationBriefing), on_event=EventSectorCaptured, REQUIRE=capzone__bombSiteEid)]
def zombie_init_objective_briefing(evt : Event;
                                   active : bool;
                                   capzone__isSectorCaptured : bool;
                                   capzone__briefingTime : float = 7.;
                                   objective_spawner__briefingActivationTime : float = 2.;
                                   capzone__activationBriefing : string = "";
                                   capzone__deactivationBriefing : string = "")
  query() <| $ [es] (var travel_zombie__isFirstObjective : bool&;
                     var travel_zombie__delayedActivateObjAtTime : float&;
                     var travel_zombie__delayedActivateObjName : das_string&)
    if active
      if !empty(capzone__activationBriefing)
        if travel_zombie__isFirstObjective
          query() <| $ [es(REQUIRE=team__id)] (var team__briefing : das_string&;
                                               var team__goalShowTime : float&)
            team__briefing := capzone__activationBriefing
            team__goalShowTime := capzone__briefingTime
        else
          travel_zombie__delayedActivateObjName := capzone__activationBriefing
          travel_zombie__delayedActivateObjAtTime = get_sync_time() + capzone__briefingTime + objective_spawner__briefingActivationTime
    elif capzone__isSectorCaptured
      travel_zombie__isFirstObjective = false
      if !empty(capzone__deactivationBriefing)
        query() <| $ [es(REQUIRE=team__id)] (var team__briefing : das_string&;
                                             var team__goalShowTime : float&)
          team__briefing := capzone__deactivationBriefing
          team__goalShowTime := capzone__briefingTime

[es(tag=server)]
def zombie_mode_objective_delayed_briefing(info : ParallelUpdateFrameDelayed;
                                           travel_zombie__delayedActivateObjName : string;
                                           var travel_zombie__delayedActivateObjAtTime : float&)
  if travel_zombie__delayedActivateObjAtTime > 0. && info.curTime > travel_zombie__delayedActivateObjAtTime
    travel_zombie__delayedActivateObjAtTime = -1.
    query() <| $ [es(REQUIRE=team__id)] (var team__briefing : das_string&)
      team__briefing := travel_zombie__delayedActivateObjName

[es(tag=server)]
def zombie_mode_objective_reteigger_briefing(info : ParallelUpdateFrameDelayed;
                                             var objective_spawner__retriggerAtTime : float&)
  if objective_spawner__retriggerAtTime > 0. && objective_spawner__retriggerAtTime < info.curTime
    objective_spawner__retriggerAtTime = -1.
    query() <| $ [es(REQUIRE=team__id)] (var team__forceEnableBriefing : bool&)
      team__forceEnableBriefing = false

[es(tag=server, on_appear, track=active, REQUIRE=zombie_crater)]
def zombie_objective_crater(evt : Event;
                            active : bool;
                            eid : EntityId)
  if active
    query() <| $ [es] (var entity_spawner__activeCraters : EidList;
                       var entity_spawner__activeCratersCount : int&;
                       var entity_spawner__aliveCratersCount : int&)
      let idx = find_index(entity_spawner__activeCraters, eid)
      if idx < 0
        push(entity_spawner__activeCraters, eid)
        entity_spawner__activeCratersCount++
        entity_spawner__aliveCratersCount++


[es(tag=server, on_disappear, REQUIRE=zombie_crater)]
def zombie_objective_patrols_dist_override(evt : Event)
  query() <| $ [es(REQUIRE=zombie_crater)] (var zombie_objective__overridePatrolsDistSq : float&;
                                            active : bool;
                                            zombie_objective__overrideCratersDistOnDestroy : float)
    if active
      zombie_objective__overridePatrolsDistSq = square(zombie_objective__overrideCratersDistOnDestroy)

[es(tag=server, on_disappear, REQUIRE=zombie_crater)]
def zombie_objective_spawn_mult(evt : Event;
                                eid : EntityId)
  find_query() <| $ [es] (var entity_spawner__activeCraters : EidList&;
                          var entity_spawner__activeCratersCount : int&;
                          var entity_spawner__aliveCratersCount : int&)
    var aliveCraters = 0
    let allCraters = length(entity_spawner__activeCraters)
    for crater in entity_spawner__activeCraters
      if crater == eid
        crater = INVALID_ENTITY_ID
      if crater != INVALID_ENTITY_ID
        aliveCraters++
    entity_spawner__aliveCratersCount = aliveCraters
    entity_spawner__activeCratersCount = allCraters
    if aliveCraters == 0
      clear(entity_spawner__activeCraters)
      entity_spawner__activeCratersCount = 0
      return true
    if aliveCraters == allCraters
      return true
    query() <| $ [es] (var objective_spawner__multiplier : float&;
                       objective_spawner__multiplierRange : float2)
      objective_spawner__multiplier = cvt(float(aliveCraters), 1.f, float(allCraters), objective_spawner__multiplierRange.x, objective_spawner__multiplierRange.y)
    return true

[es(tag=server, on_appear)]
def zombie_crater_projector_creator(evt : Event;
                                    transform : float3x4;
                                    zombie_crater__projectorTemplate : string;
                                    zombie_crater__projectorOffset : float3 = float3(0., -1., 0.);
                                    var zombie_crater__projectorEid : EntityId&)
  zombie_crater__projectorEid = createEntity(zombie_crater__projectorTemplate) <| $(var init : ComponentsInitializer)
    var tm = transform
    tm[3] = tm[3] + zombie_crater__projectorOffset
    set(init, "transform", tm)

[es(on_disappear)]
def zombie_crater_projector_disabler(evt : Event;
                                     zombie_crater__projectorEid : EntityId)
  query(zombie_crater__projectorEid) <| $ [es] (var projector__color : float3&)
    projector__color = float3()

[es(tag=server, on_appear)]
def zombie_objective_spawn_creator(evt : Event;
                                   transform : float3x4;
                                   objective_spawner__radius : float;
                                   objective_spawner__spawnsCount : int;
                                   bomb_site__capzoneEid : EntityId = INVALID_ENTITY_ID;
                                   objective_spawner__useZoneRadius : bool = false;
                                   objective_spawner__checkSpawnPath : bool = true;
                                   var objective_spawner__spawns : Point3List&)
  var radius = objective_spawner__radius
  if objective_spawner__useZoneRadius
    query(bomb_site__capzoneEid) <| $ [es] (sphere_zone__radius : float)
      radius = sphere_zone__radius

  let projRadius = 1.
  let projExtents = float3(projRadius, FLT_MAX, projRadius)
  let extents = float3(1.5, FLT_MAX, 1.5)
  let diffDeg = safediv((2.0 * PI), float(objective_spawner__spawnsCount))

  var zonePos = transform[3]
  project_to_nearest_navmesh_point_no_obstacles(zonePos, projExtents)

  for i in range(0, objective_spawner__spawnsCount)
    let dir = angles_to_dir(float2(diffDeg * float(i), 0.))
    var outNavmeshPos = transform[3] + dir * radius
    if project_to_nearest_navmesh_point_no_obstacles(outNavmeshPos, projExtents)
      if !objective_spawner__checkSpawnPath || check_path(outNavmeshPos, zonePos, extents, 3., 3.)
        push(objective_spawner__spawns, outNavmeshPos)

  // find_random_points_around_circle(transform[3], radius, objective_spawner__spawnsCount) <| $(spawns) // incorrect points founded
  //   for spawn in spawns
  //     push(objective_spawner__spawns, spawn)


[es(tag=server, REQUIRE_NOT=zombie_arena)]
def zombie_mode_objective_progress(evt : EventRadioObjectiveActivate;
                                   active : bool;
                                   objective_spawner__activationPeriod : float;
                                   var objective_spawner__nextActivationAfterTime : float&;
                                   var objective_spawner__active : bool&;
                                   var objective_spawner__curWaveId : int&)
  if !active
    send_net_event(evt.bombSiteOperator, CmdHeroLogEvent(event = "zombie_objective", text = "objective/notActivated"))
    return
  let curTime = get_sync_time()
  if objective_spawner__nextActivationAfterTime > curTime
    send_net_event(evt.bombSiteOperator, CmdHeroLogEvent(event = "zombie_objective", text = "objective/alreadyActivated"))
    return
  objective_spawner__nextActivationAfterTime = curTime + objective_spawner__activationPeriod
  if objective_spawner__active
    objective_spawner__curWaveId++
  objective_spawner__active = true

[es(tag=server, REQUIRE=zombie, REQUIRE_NOT=human_net_phys)]
def zombie_radio_damage_server_es(evt : CmdRendinstDamage)
  let riEid = find_ri_extra_eid(evt.handle)
  if !riEid
    return
  query(riEid) <| $ [es] (objective_radio__addTimeOnDamage : float;
                          objective_spawner__activationPeriod : float;
                          var objective_spawner__wavesTemplates : StringList;
                          var objective_spawner__count : IntList;
                          var objective_spawner__active : bool&;
                          var objective_spawner__nextActivationAfterTime : float&)
    if !objective_spawner__active
      return
    objective_spawner__nextActivationAfterTime += objective_radio__addTimeOnDamage
    let curTime = get_sync_time()
    let requireDamage = objective_spawner__nextActivationAfterTime > curTime
    if !requireDamage
      return
    if objective_spawner__nextActivationAfterTime - curTime > objective_spawner__activationPeriod
      objective_spawner__nextActivationAfterTime = -1.
      objective_spawner__active = false
      clear(objective_spawner__wavesTemplates)
      clear(objective_spawner__count)
      sendEventImmediate(riEid, CmdReInitWaveZombies())
      broadcast_hero_log_event("zombie_objective", "objective/resetByZombie")

[es(tag=server)]
def zombie_mode_objective_finalizer(info : ParallelUpdateFrameDelayed;
                                    eid : EntityId;
                                    var objective_spawner__nextActivationAfterTime : float&;
                                    objective_spawner__activationPeriod : float;
                                    objective_spawner__wavesCount : int;
                                    objective_spawner__curWaveId : int;
                                    bomb_site__capzoneEid : EntityId;
                                    var objective_spawner__active : bool&)
  if objective_spawner__nextActivationAfterTime < 0.
    return
  let waveFinished = info.curTime > objective_spawner__nextActivationAfterTime
  if waveFinished
    query(bomb_site__capzoneEid) <| $ [es] (var capzone__progress : float&)
      capzone__progress = safediv(float(objective_spawner__curWaveId), float(objective_spawner__wavesCount))
    if objective_spawner__curWaveId == (objective_spawner__wavesCount - 1)
      objective_spawner__active = false
      objective_spawner__nextActivationAfterTime = -1.
      sendEvent(eid, EventBombSiteExplosion())
      return
  else
    var curSpendTime = float(objective_spawner__curWaveId) * objective_spawner__activationPeriod
    curSpendTime += objective_spawner__activationPeriod - (objective_spawner__nextActivationAfterTime - info.curTime)
    let requireTime = float(objective_spawner__wavesCount) * objective_spawner__activationPeriod
    let curProgress = safediv(curSpendTime, requireTime)
    query(bomb_site__capzoneEid) <| $ [es] (var capzone__progress : float&)
      let diffEps = 0.05
      if curProgress - capzone__progress > diffEps
        capzone__progress = curProgress

[es(tag=gameClient, on_appear, track=(objective_spawner__active, objective_spawner__curWaveId), REQUIRE=(zombie_arena, objective_spawner__curWaveId))]
def zombie_mode_objective_activation_fx(evt : Event;
                                        objective_spawner__active : bool;
                                        zombie_arena__waveFxTemplate : string;
                                        zombie_arena__waveFxTm : float3x4;
                                        zombie_arena__waveFxDestroyTime : float;
                                        transform : float3x4;
                                        var zombie_arena__waveFxEid : EntityId&;
                                        var zombie_arena__waveFxDestroyAtTime : float&)
  if !objective_spawner__active
    return
  zombie_arena__waveFxDestroyAtTime = get_sync_time() + zombie_arena__waveFxDestroyTime
  if !zombie_arena__waveFxEid
    zombie_arena__waveFxEid = createEntity(zombie_arena__waveFxTemplate) <| $(var init : ComponentsInitializer)
      var tm = transform * zombie_arena__waveFxTm
      tm |> orthonormalize()
      set(init, "transform", tm)

[es(tag=gameClient)]
def zombie_mode_objective_destroy_activate_fx(info : ParallelUpdateFrameDelayed;
                                              zombie_arena__waveFxDestroyAtTime : float;
                                              var zombie_arena__waveFxEid : EntityId&)
  if !!zombie_arena__waveFxEid && zombie_arena__waveFxDestroyAtTime < info.curTime
    destroyEntity(zombie_arena__waveFxEid)
    zombie_arena__waveFxEid = INVALID_ENTITY_ID

[es(tag=server)]
def zombie_mode_objective_arena_timers(info : ParallelUpdateFrameDelayed;
                                       objective_spawner__active : bool;
                                       zombie_arena__zombieWavePeriodList : FloatList;
                                       objective_spawner__wavesCount : int;
                                       var zombie_arena__zombieNextWaveAtTime : float&;
                                       var objective_spawner__curWaveId : int&)
  let curTime = info.curTime
  if !objective_spawner__active || zombie_arena__zombieNextWaveAtTime > curTime
    return
  objective_spawner__curWaveId++
  if length(zombie_arena__zombieWavePeriodList) != 0
    let curWaveId = objective_spawner__curWaveId % objective_spawner__wavesCount
    zombie_arena__zombieNextWaveAtTime = curTime + zombie_arena__zombieWavePeriodList[curWaveId]

def set_data_to_all_craters(checkNextTime : float; curWave : int; activate : bool)
  query() <| $ [es(REQUIRE=zombie_crater)] (active : bool;
                                            var zombie_crater__checkHumansNextTime : float&;
                                            var zombie_crater__humansNear : bool&;
                                            var objective_spawner__active : bool&;
                                            var objective_spawner__curWaveId : int&)
    if !active
      return
    zombie_crater__checkHumansNextTime = checkNextTime
    objective_spawner__curWaveId = curWave
    objective_spawner__active = activate
    zombie_crater__humansNear = true

[es(tag=server)]
def zombie_mode_objective_crater_timers(info : ParallelUpdateFrameDelayed;
                                        active : bool;
                                        transform aka zone_transform : float3x4;
                                        zombie_crater__firstWaveHumanDist : float;
                                        zombie_crater__waveHumanDist : float;
                                        zombie_crater__checkHumansPeriod : float;
                                        zombie_crater__minWaveTime : float;
                                        objective_spawner__active : bool;
                                        objective_spawner__curWaveId : int;
                                        var zombie_crater__humansNear : bool&;
                                        var zombie_crater__checkHumansNextTime : float&)
  if zombie_crater__checkHumansNextTime > info.curTime || !active
    return

  let checkDist = objective_spawner__active ? zombie_crater__waveHumanDist : zombie_crater__firstWaveHumanDist
  let checkDistSq = checkDist * checkDist
  var humansNear = false

  find_query() <| $ [es] (entity_spawner__aliveHumans : EidList)
    for human in entity_spawner__aliveHumans
      if humansNear
        break
      query(human) <| $ [es] (transform aka soldier_transform : float3x4)
        if distance_sq(soldier_transform[3], zone_transform[3]) < checkDistSq
          humansNear = true
    return true

  if humansNear
    let checkNextTime = info.curTime + zombie_crater__minWaveTime
    let curWave = objective_spawner__active ? objective_spawner__curWaveId + 1 : objective_spawner__curWaveId
    let activate = true
    set_data_to_all_craters(checkNextTime, curWave, activate)
  else
    zombie_crater__humansNear = false
    zombie_crater__checkHumansNextTime = info.curTime + zombie_crater__checkHumansPeriod

[es(tag=server)]
def zombie_mode_spawner_range_timers(info : ParallelUpdateFrameDelayed;
                                     objective_spawner__active : bool;
                                     objective_radio__spawnerTimeRangePeriod : float;
                                     objective_radio__objectiveSpawnerTimeRange : float2;
                                     objective_radio__spawnerTimeRangeEndTime : float;
                                     var objective_spawner__nextSpawnPeriod : float&)
  if !objective_spawner__active
    return

  if objective_radio__spawnerTimeRangeEndTime < 0.
    objective_spawner__nextSpawnPeriod = objective_radio__objectiveSpawnerTimeRange.y
    return
  let relTIme = objective_radio__spawnerTimeRangeEndTime - info.curTime
  objective_spawner__nextSpawnPeriod = cvt(relTIme, 0., objective_radio__spawnerTimeRangePeriod, objective_radio__objectiveSpawnerTimeRange.x, objective_radio__objectiveSpawnerTimeRange.y)


[es(tag=server, track=(objective_spawner__active, objective_spawner__curWaveId), REQUIRE=objective_spawner__curWaveId)]
def zombie_mode_spawner_range_track(evt : Event;
                                    objective_spawner__active : bool;
                                    var objective_radio__spawnerTimeRangeEndTime : float&;
                                    objective_radio__spawnerTimeRangePeriod : float)
  if objective_spawner__active
    objective_radio__spawnerTimeRangeEndTime = get_sync_time() + objective_radio__spawnerTimeRangePeriod


[es(tag=server, on_appear)]
def zombie_patrol_objective_appear(evt : Event;
                                   zombie_patrol__spawnPeriod : float2;
                                   var zombie_patrol__spawnTimer : float&)
  zombie_patrol__spawnTimer = rnd_float(zombie_patrol__spawnPeriod.x, zombie_patrol__spawnPeriod.y)

[es(tag=server)]
def zombie_patrol_objective_debug_ui_timer(info : ParallelUpdateFrameDelayed;
                                           zombie_patrol__spawnTimer : float;
                                           var zombie_patrol__spawnTimerDebugUIInfo : int&)
  zombie_patrol__spawnTimerDebugUIInfo = int(zombie_patrol__spawnTimer)

[es(tag=server)]
def zombie_patrol_objective_timer(info : ParallelUpdateFrameDelayed;
                                  zombie_patrol__humansInObjective : bool;
                                  var zombie_patrol__spawnTimer : float&)
  if !zombie_patrol__humansInObjective
    zombie_patrol__spawnTimer -= info.dt

[es(tag=server, on_appear)]
def preinit_sphere_zombie_grenade_activator_shell_props_es(evt : Event;
                                                           sphere_zombie__grenadeTemplate : string)
  preinit_activator_shell_props(sphere_zombie__grenadeTemplate)

[es(tag=server)]
def zombie_sphere_destroyer_timer(info : ParallelUpdateFrameDelayed;
                                  transform : float3x4;
                                  hitpoints__lastOffender : EntityId;
                                  zombie__destroyOnTargetRadius : float;
                                  sphere_zombie__grenadeTemplate : string;
                                  walker_agent__priorityTarget : EntityId;
                                  var isAlive : bool&)
  let targetAimTm = get_TMatrix(walker_agent__priorityTarget, "human__aimTm")
  if targetAimTm != null
    let destroyRadiusSq = zombie__destroyOnTargetRadius * zombie__destroyOnTargetRadius
    if length_sq((*targetAimTm)[3] - transform[3]) < destroyRadiusSq
      isAlive = false
      createEntity(sphere_zombie__grenadeTemplate) <| $(var init)
        init |> set("ownerEid", hitpoints__lastOffender)
        init |> set("transform", transform)

[es(tag=server, REQUIRE_NOT=deadEntity)]
def zombie_giant_sphere_on_abilitity_activate(info : ParallelUpdateFrameDelayed;
                                              zombie_ability__activated : bool;
                                              zombie_boss__goupsRequireSpawn : int;
                                              zombie_boss__entitiesInGroup : int;
                                              zombie_boss__entityOnAbility : string;
                                              zombie_boss__entityOnAbilityOffstet : float3;
                                              transform : float3x4;
                                              zombie_boss__entitiesRadius : float;
                                              zombie_boss__entityOnAbilityPeriod : float;
                                              var zombie_boss__entityOnAbilityNextTime : float&;
                                              var zombie_boss__goupsSpawned : int&)
  if !zombie_ability__activated
    zombie_boss__goupsSpawned = 0
    return
  if zombie_boss__goupsSpawned == zombie_boss__goupsRequireSpawn
    return
  if zombie_boss__entityOnAbilityNextTime > info.curTime
    return
  zombie_boss__goupsSpawned++
  zombie_boss__entityOnAbilityNextTime = info.curTime + zombie_boss__entityOnAbilityPeriod
  if zombie_boss__entitiesInGroup <= 0
    return
  let randStartAngle = rnd_float(0., (2. * PI))
  let angleDiff = (2. * PI) / float(zombie_boss__entitiesInGroup)
  for i in range(zombie_boss__entitiesInGroup)
    var tm = transform
    let dir = angles_to_dir(float2(randStartAngle + float(i) * angleDiff, 0.))
    tm[3] = tm[3] + zombie_boss__entityOnAbilityOffstet + dir * zombie_boss__entitiesRadius
    createEntity(zombie_boss__entityOnAbility) <| $(var init : ComponentsInitializer)
      set(init, "transform", tm)


[es(tag=gameClient, no_order)]
def radio_lights_progress_indicator(info : UpdateStageInfoAct;
                                    objective_spawner__nextActivationAfterTime : float;
                                    objective_spawner__activationPeriod : float;
                                    radio_lights__count : int;
                                    radio_lights__completedColor : float4;
                                    radio_lights__failedColor : float4;
                                    radio_light__nextBlinkPeriod : float;
                                    radio_light__completeBlinkingMaxCount : int;
                                    var radio_light__completeState : bool&;
                                    var radio_light__nextBlinkAtTime : float&;
                                    var radio_light__blinkState : bool&;
                                    var radio_light__completeBlinkingCount : int&;
                                    var dynamic_material_channels_arr : Array;
                                    var radio_lights__curRelState : int&;
                                    radio_light__nextBlinkStateChangedMul : float = 1.5;
                                    radio_light__completeBlinkStateChangedMul : float = 0.4)
  if radio_light__nextBlinkAtTime > info.curTime
    return

  let relVal = safediv((objective_spawner__nextActivationAfterTime - info.curTime), objective_spawner__activationPeriod)
  let curStste = int((min(1., 1. - relVal) * float(radio_lights__count)))
  var isChanged = false
  var period = radio_light__nextBlinkPeriod
  let complete = radio_lights__curRelState == radio_lights__count
  if radio_lights__curRelState != curStste
    radio_lights__curRelState = curStste
    isChanged = true
    period *= radio_light__nextBlinkStateChangedMul
  if complete
    period = radio_light__nextBlinkPeriod * radio_light__completeBlinkStateChangedMul

  radio_light__nextBlinkAtTime = info.curTime + period

  if isChanged
    radio_light__blinkState = false //will be inversed later

  for i in range(radio_lights__count)
    var matParams = getRW_ecs_object(dynamic_material_channels_arr[i])
    if matParams != null
      if !complete
        radio_light__completeBlinkingCount = radio_light__completeBlinkingMaxCount
        var color = i < radio_lights__curRelState ? radio_lights__completedColor : radio_lights__failedColor
        if i == radio_lights__curRelState
          color = radio_light__blinkState ? radio_lights__completedColor : radio_lights__failedColor
          radio_light__blinkState = !radio_light__blinkState
        set(*matParams, "dynmat_param__emissive_color", color)
      else // complete
        let color = radio_light__completeState || radio_light__completeBlinkingCount == 0 ? radio_lights__completedColor : radio_lights__failedColor
        set(*matParams, "dynmat_param__emissive_color", color)

  if complete
    if radio_light__completeState && radio_light__completeBlinkingCount > 0
      radio_light__completeBlinkingCount--
    radio_light__completeState = !radio_light__completeState


[es(tag=server, on_appear, before=init_objective_wave_templates_for_spawner, REQUIRE=patrol_objective_controller)]
def zombie_patrol_init_wave_count(evt : Event;
                                  objective_spawner__waves : Array;
                                  var zombie_patrol__objectiveWavesCount : int&)
  zombie_patrol__objectiveWavesCount = length(objective_spawner__waves)

[es(tag=server, on_disappear, REQUIRE=zombie_patrol)]
def zombie_patrol_debug_info_count(evt : Event)
  query() <| $ [es] (var zombie_patrol__spawnCountDebugUIInfo : int&)
    zombie_patrol__spawnCountDebugUIInfo--

[es(on_appear, track=human_hit_tagging__override)]
def human_hit_tagging_override(evt : Event;
                               human_hit_tagging__override : float;
                               var human_hit_tagging__mult : float&)
  human_hit_tagging__mult = human_hit_tagging__override

[es(tag=server)]
def zombie_patrol_objective_creator(info : ParallelUpdateFrameDelayed;
                                    zombie_patrol__objectiveCheckPeriod : float;
                                    zombie_patrol__humanObjectiveDist : float;
                                    zombie_patrol__spawnPeriod : float2;
                                    zombie_patrol__spawnRadius : float;
                                    zombie_patrol__distToRandHuman : float;
                                    zombie_patrol__objectiveWavesCount : int;
                                    objective_spawner__waves : Array;
                                    var zombie_patrol__spawnCountDebugUIInfo : int?;
                                    var zombie_patrol__selectedWaveDebugUIInfo : int?;
                                    var zombie_patrol__spawnTimer : float&;
                                    var zombie_patrol__humansInObjective : bool&;
                                    var zombie_patrol__objectiveCheckAtTime : float&)
  if zombie_patrol__objectiveCheckAtTime > info.curTime
    return
  zombie_patrol__objectiveCheckAtTime = info.curTime + zombie_patrol__objectiveCheckPeriod

  let maxDistSq = zombie_patrol__humanObjectiveDist * zombie_patrol__humanObjectiveDist
  using() <| $(var human_targets : EidList)

    find_query() <| $ [es] (entity_spawner__aliveHumans : EidList)
      for humanEid in entity_spawner__aliveHumans
        query(humanEid) <| $ [es] (transform aka soldier_transform : float3x4;
                                   isAlive : bool = true;
                                   isDowned : bool = false;
                                   squad_member__playerEid : EntityId;
                                   human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                                   human__inDomeZoneEid : EntityId = INVALID_ENTITY_ID)
          if isAlive && !human_anim__vehicleSelected && !isDowned && !human__inDomeZoneEid
            var skip = find_query() <| $ [es(REQUIRE=zombie_objective)] (active : bool;
                                                                         transform aka objective_transform : float3x4;
                                                                         zombie_objective__overridePatrolsDistSq : float = 0.)
              if active
                let distToObjectiveSq = distance_sq(objective_transform[3], soldier_transform[3])
                if zombie_objective__overridePatrolsDistSq > 0.
                  return distToObjectiveSq < zombie_objective__overridePatrolsDistSq
                return distToObjectiveSq < maxDistSq
              return false
            query(squad_member__playerEid) <| $ [es] (disconnected : bool)
              skip ||= disconnected
            if !skip
              push(human_targets, humanEid)
      return true

    let targetsCount = length(human_targets)
    zombie_patrol__humansInObjective = targetsCount == 0

    if targetsCount > 0 && zombie_patrol__spawnTimer < 0.
      let targetId = rnd_int(0, targetsCount - 1)
      let targetEid = human_targets[targetId]
      let targetTm = get_TMatrix(targetEid, "transform")
      var targetPos = float3()
      if targetTm != null
        targetPos = (*targetTm)[3]
      else
        logerr("incorrect target was found")
      var resPos = float3()
      // let eps = 1.3f
      // if find_random_point_around_circle(targetPos, zombie_patrol__spawnRadius * eps, resPos) // works incorrect
      let maxChecks = 5
      let projExtents = float3(1., FLT_MAX, 1.)
      let extents = float3(1.5, FLT_MAX, 1.5)

      var spawnFound = false
      for _i in range(0, maxChecks)
        let dir = angles_to_dir(float2(rnd_float(0., (2.0 * PI)), 0.))
        var outNavmeshPos = targetPos + dir * zombie_patrol__spawnRadius
        if project_to_nearest_navmesh_point_no_obstacles(outNavmeshPos, projExtents)
          if check_path(outNavmeshPos, targetPos, extents, 3., 3.)
            resPos = outNavmeshPos
            spawnFound = true
            break
      if !spawnFound
        return

      let spawnFailed = find_query() <| $ [es(REQUIRE=zombie__nearestNavmeshSearchRadius)] (transform aka friendly_transform : float3x4)
        return length_sq(resPos - friendly_transform[3]) < square(zombie_patrol__distToRandHuman)

      if !spawnFailed
        zombie_patrol__spawnTimer = rnd_float(zombie_patrol__spawnPeriod.x, zombie_patrol__spawnPeriod.y)
        if zombie_patrol__spawnCountDebugUIInfo != null
          (*zombie_patrol__spawnCountDebugUIInfo)++

        let selectedWave = rnd_int(0, zombie_patrol__objectiveWavesCount - 1)
        if zombie_patrol__selectedWaveDebugUIInfo != null
          *zombie_patrol__selectedWaveDebugUIInfo = selectedWave

        createEntity("zombie_patrol_objective") <| $(var init : ComponentsInitializer)
          var tm = IDENT_TM
          tm[3] = resPos
          set(init, "objective_spawner__waves", objective_spawner__waves)
          set(init, "transform", tm)
          set(init, "objective_spawner__curWaveId", selectedWave)
          set(init, "objective_spawner__priorityTarget", targetEid)
          set(init, "active", true)
          set(init, "objective_spawner__active", true)


[es(tag=server)]
def zombie_mode_objective_creator(evt : ParallelUpdateFrameDelayed;
                                  eid : EntityId;
                                  objective_spawner__active : bool;
                                  objective_spawner__aliveZombiesLimit : int;
                                  objective_spawner__spawns : Point3List;
                                  objective_spawner__nextSpawnPeriod : float;
                                  objective_spawner__minDistToHuman : float;
                                  var objective_spawner__nextSpawnAtTime : float&;
                                  var objective_spawner__wavesTemplates : StringList;
                                  var objective_spawner__count : IntList;
                                  objective_spawner__destroyOnComplete : bool = false;
                                  objective_spawner__addSubTemplate : das_string const?;
                                  objective_spawner__priorityTarget : EntityId = INVALID_ENTITY_ID;
                                  objective_spawners__walkSpeedMultRange : float2 const?)
  if !objective_spawner__active
    return
  query() <| $ [es] (entity_spawner__aliveZombiesCount : int;
                     entity_spawner__aliveHumans : EidList)
    if entity_spawner__aliveZombiesCount > objective_spawner__aliveZombiesLimit
      var firstPriorityTarget = INVALID_ENTITY_ID
      var secondPriorityTarget = INVALID_ENTITY_ID
      var thirdPriorityTarget = INVALID_ENTITY_ID
      find_query() <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                      isAlive : bool;
                                                      zombie__readyForObjectiveCleaner : bool;
                                                      walker_agent__priorityTarget : EntityId)
        if !isAlive
          return false
        if zombie__readyForObjectiveCleaner
          firstPriorityTarget = eid
          return true
        if !walker_agent__priorityTarget
          secondPriorityTarget = eid
        if !thirdPriorityTarget
          thirdPriorityTarget = eid
        return false
      let hasZombieForDelete = !!firstPriorityTarget || !!secondPriorityTarget || !!thirdPriorityTarget
      if hasZombieForDelete
        let zombieToClean = (!!firstPriorityTarget ? firstPriorityTarget : (!!secondPriorityTarget ? secondPriorityTarget : thirdPriorityTarget))
        query(zombieToClean) <| $ [es] (var hitpoints__hp : float&;
                                        var isAlive : bool&)
          hitpoints__hp = -1000.
          isAlive = false
      else
        return

    if objective_spawner__nextSpawnAtTime > evt.curTime
      return

    let humansCount = length(entity_spawner__aliveHumans)
    if humansCount == 0
      return

    let typesCount = length(objective_spawner__wavesTemplates)
    let spawnsCount = length(objective_spawner__spawns)

    if typesCount == 0 || spawnsCount == 0
      if objective_spawner__destroyOnComplete
        destroyEntity(eid)
      return

    let templateId = rnd_int(0, typesCount - 1)
    let spawnId = rnd_int(0, spawnsCount - 1)

    if objective_spawner__count[templateId] <= 0
      logerr("incorrect data in objective_spawner__count inited. Field must be removed from spawn list on zombie spawned")
      return

    var humansNear = false
    if objective_spawner__minDistToHuman > 0.
      let maxDistSq = objective_spawner__minDistToHuman * objective_spawner__minDistToHuman
      for human in entity_spawner__aliveHumans
        if humansNear
          break
        query(human) <| $ [es] (transform aka soldier_transform : float3x4)
          if distance_sq(soldier_transform[3], objective_spawner__spawns[spawnId]) < maxDistSq
            humansNear = true
      if humansNear
        return

    var resTemplate = string(objective_spawner__wavesTemplates[templateId])
    if objective_spawner__addSubTemplate != null
      resTemplate = add_sub_template_name(resTemplate, string(*objective_spawner__addSubTemplate))

    createEntity(resTemplate) <| $(var init : ComponentsInitializer)
      var tm = IDENT_TM
      tm[3] = objective_spawner__spawns[spawnId]
      set(init, "transform", tm)
      set(init, "objective_spawner__owner", eid)
      if objective_spawners__walkSpeedMultRange != null
        set(init, "navmesh_phys__walkSpeedMultForce", rnd_float((*objective_spawners__walkSpeedMultRange).x, (*objective_spawners__walkSpeedMultRange).y))
      if !!objective_spawner__priorityTarget
        set(init, "walker_agent__priorityTarget", objective_spawner__priorityTarget)
        set(init, "walker_agent__targetEid", objective_spawner__priorityTarget)
    objective_spawner__count[templateId]--
    objective_spawner__nextSpawnAtTime = evt.curTime + objective_spawner__nextSpawnPeriod

    if objective_spawner__count[templateId] <= 0
      erase(objective_spawner__wavesTemplates, templateId)
      erase(objective_spawner__count, templateId)

def weighted_choice(winNumber : float; choiceRange : int; choiceChances : FloatList)
  var curChanceRange = 0.
  for index, chance in range(0, choiceRange), choiceChances
    curChanceRange += chance
    if winNumber < curChanceRange
      return index
  return -1

[es(tag=server, on_disappear, REQUIRE=paid_loot_special_box)]
def personal_box_on_disappear_es(evt : Event;
                                 eid : EntityId;
                                 special_weapon_box__ownedByPlayer : EntityId)
  query(special_weapon_box__ownedByPlayer) <| $ [es] (var player__ownedPersonalBoxEids : EidList&)
    let boxInd = find_index(player__ownedPersonalBoxEids, eid)
    if boxInd >= 0
      erase(player__ownedPersonalBoxEids, boxInd)

[es(tag=gameClient, REQUIRE=paid_loot_special_box, track=paid_loot__alreadyUsed, on_appear)]
def disable_visibility_es(evt : Event;
                          paid_loot__alreadyUsed : bool;
                          var item__visible : bool&)
  if paid_loot__alreadyUsed
    item__visible = false

[es(tag=server, REQUIRE=paid_loot_special_box)]
def pickup_item_from_special_box_es(evt : CmdPickupSpecialItem;
                                    transform : float3x4;
                                    eid aka shop_eid : EntityId;
                                    paid_loot__regularBoxProb : float;
                                    paid_loot__weapTemplates : StringList;
                                    paid_loot__weapChanceRange : FloatList;
                                    paid_loot__specialWeapTemplatesBase : StringList;
                                    paid_loot__specialWeapRandomizeWeightBase : FloatList;
                                    paid_loot__getTokensProb : float;
                                    paid_loot__tokenNominal : int;
                                    var paid_loot__alreadyUsed : bool&;
                                    var paid_loot__specialWeapTemplates : StringList;
                                    var paid_loot__specialWeapRandomizeWeight : FloatList;
                                    var paid_loot__specialWeapChanceRange : FloatList;
                                    special_weapon_box__ownedByPlayer : EntityId const?)
  if paid_loot__alreadyUsed
    send_net_event(evt.pickuperEid, CmdHeroLogEvent(event = "paid_loot", text = "paid_loot/box_is_already_used"))
    return
  if special_weapon_box__ownedByPlayer != null
    var canBeUsedByCurrentPickuper = false
    query(evt.pickuperEid) <| $ [es] (possessedByPlr : EntityId)
      if possessedByPlr == *special_weapon_box__ownedByPlayer
        canBeUsedByCurrentPickuper = true
    if !canBeUsedByCurrentPickuper
      send_net_event(evt.pickuperEid, CmdHeroLogEvent(event = "paid_loot", text = "paid_loot/personal_box_warning"))
      return
  let callback <- @ <| (eid aka item_eid : EntityId)
    var equipToSlots = false
    send_net_event(evt.pickuperEid, CmdHeroLogEvent(event = "paid_loot", text = "", sound = "events/z/ui/buy_weapon"))
    let itemName = get_string(item_eid, "item__name", "")
    if itemName != ""
      using() <| $(var data : Object)
        set(data, "item", itemName)
        send_net_event(evt.pickuperEid, CmdHeroLogExEvent(event = "paid_loot", key = "paid_loot/random_box", data = ecs_addr(data)))
    query(item_eid) <| $ [es] (item__equipToSlots : Array)
      if length(item__equipToSlots) != 0
        equipToSlots = true
        if equip_item_entity(evt.pickuperEid, item_eid, item__equipToSlots)
          remove_item_from_entity_container(item_eid)
    if equipToSlots
      return

    let res = query(item_eid) <| $ [es] (item__id : int)
      if item__id != INVALID_ITEM_ID
        pickup_one_item_impl(evt.pickuperEid, item_eid)
    if !res
      logwarn("Unable to pickup item {item_eid}, exist={doesEntityExist(item_eid)}")

  query(evt.pickuperEid) <| $ [es] (possessedByPlr : EntityId;
                                    unlocked_special_weapons : StringList)
    query(possessedByPlr) <| $ [es] (player__maxTokens : int;
                                     var player__tokens : int&)
      if rnd_float(0.0, 1.0) < paid_loot__getTokensProb
        if player__tokens < player__maxTokens
          player_get_tokens(evt.pickuperEid, INVALID_ENTITY_ID, paid_loot__tokenNominal, player__maxTokens, player__tokens)
        else
          var relTm = IDENT_TM
          relTm[3] = transform[3]
          relTm[3].y += 0.3
          createEntity("token_free_item") <| $(var init : ComponentsInitializer)
            set(init, "transform", relTm)

    var creatingTemplate = ""
    let getFromRegularBox = rnd_float(0.0, 1.0) < paid_loot__regularBoxProb
    if getFromRegularBox
      let weapIndex = weighted_choice(rnd_float(0.0, 1.0), length(paid_loot__weapTemplates), paid_loot__weapChanceRange)
      if weapIndex >= 0
        creatingTemplate = string(paid_loot__weapTemplates[weapIndex])
    else
      clear(paid_loot__specialWeapTemplates)
      clear(paid_loot__specialWeapRandomizeWeight)
      clear(paid_loot__specialWeapChanceRange)
      for item in unlocked_special_weapons
        let specWeapIndex = find_index(paid_loot__specialWeapTemplatesBase, item)
        if specWeapIndex >= 0
          push(paid_loot__specialWeapTemplates, string(item))
          push(paid_loot__specialWeapRandomizeWeight, paid_loot__specialWeapRandomizeWeightBase[specWeapIndex])
      makeChanceRange(shop_eid, paid_loot__specialWeapTemplates, paid_loot__specialWeapRandomizeWeight, paid_loot__specialWeapChanceRange)
      if !empty(paid_loot__specialWeapChanceRange)
        let weapIndex = weighted_choice(rnd_float(0.0, 1.0), length(paid_loot__specialWeapTemplates), paid_loot__specialWeapChanceRange)
        if weapIndex >= 0
          creatingTemplate = string(paid_loot__specialWeapTemplates[weapIndex])
      else
        let weapIndex = weighted_choice(rnd_float(0.0, 1.0), length(paid_loot__weapTemplates), paid_loot__weapChanceRange)
        if weapIndex >= 0
          creatingTemplate = string(paid_loot__weapTemplates[weapIndex])

    if !empty(creatingTemplate)
      createEntity(creatingTemplate, callback) <| $ [unused_argument(init)] (var init) {}
      paid_loot__alreadyUsed = true


[es(on_appear, tag=server)]
def random_speed_mult_init_for_zombie(evt : Event;
                                      navmesh_phys__walkSpeedMultForce : float;
                                      navmesh_phys__walkSpeedMultRange : float2;
                                      var navmesh_phys__walkSpeedMult : float&)
  if navmesh_phys__walkSpeedMultForce > 0.
    navmesh_phys__walkSpeedMult = navmesh_phys__walkSpeedMultForce
    return
  navmesh_phys__walkSpeedMult = rnd_float(navmesh_phys__walkSpeedMultRange.x, navmesh_phys__walkSpeedMultRange.y)

[es(REQUIRE=entity_spawner__aliveHumans, on_appear)]
def init_zombie_mode_players_es(evt : Event;
                                entity_spawner__playerAddTempl : string)
  query() <| $ [es(REQUIRE=player)] (eid : EntityId)
    addSubTemplate(eid, entity_spawner__playerAddTempl)

[es(REQUIRE=player, on_appear)]
def init_players_on_zombie_mode_es(evt : Event;
                                   eid : EntityId)
  query() <| $ [es(REQUIRE=entity_spawner__aliveHumans)] (entity_spawner__playerAddTempl : string)
    addSubTemplate(eid, entity_spawner__playerAddTempl)

[es(tag=server, on_appear)]
def personal_box_info_init_es(evt : Event;
                              transform : float3x4;
                              personal_box_info__groupIndex : int)
  query() <| $ [es] (eid : EntityId;
                     personal_box_creator__groupIndex : int;
                     personal_box_creator__numPlayers : int;
                     var personal_box_creator__startPositions : TMatrixList&)
    if personal_box_info__groupIndex == personal_box_creator__groupIndex
      if length(personal_box_creator__startPositions) >= personal_box_creator__numPlayers
        logerr("There are /*{length(personal_box_creator__startPositions)}*/ positions for boxes, but in the game there are only /*{personal_box_creator__numPlayers}*/ players")
        return
      push(personal_box_creator__startPositions, transform)
      if length(personal_box_creator__startPositions) == personal_box_creator__numPlayers
        sendEvent(eid, EventCreatorReady())

[es(tag=server, on_appear)]
def personal_box_creator_init_positions_es(evt : Event;
                                           eid : EntityId;
                                           personal_box_creator__groupIndex : int;
                                           personal_box_creator__numPlayers : int;
                                           var personal_box_creator__startPositions : TMatrixList&)
  query() <| $ [es] (transform : float3x4;
                     personal_box_info__groupIndex : int)
    if personal_box_info__groupIndex == personal_box_creator__groupIndex
      if length(personal_box_creator__startPositions) >= personal_box_creator__numPlayers
        logerr("There are /*{length(personal_box_creator__startPositions)}*/ positions for boxes, but in the game there are only /*{personal_box_creator__numPlayers}*/ players")
        return
      push(personal_box_creator__startPositions, transform)
      if length(personal_box_creator__startPositions) == personal_box_creator__numPlayers
        sendEvent(eid, EventCreatorReady())

[es(tag=server, on_event=EventCreatorReady)]
def personal_box_creator_init_es(evt : Event;
                                 groupName : string;
                                 personal_box_creator__startPositions : TMatrixList;
                                 personal_box_creator__template : string;
                                 var personal_box_creator__ready : bool&;
                                 var personal_box_creator__boxEids : EidList)
  let numBoxes = length(personal_box_creator__startPositions)
  resize(personal_box_creator__boxEids, numBoxes)
  personal_box_creator__ready = true

  if empty(groupName)
    return
  var curBoxInd = 0
  query() <| $ [es] (eid : EntityId; var player__ownedPersonalBoxEids : EidList&)
    let personalBoxEid = createEntity(personal_box_creator__template) <| $(var init : ComponentsInitializer)
      init |> set("transform", personal_box_creator__startPositions[curBoxInd])
      init |> set("special_weapon_box__ownedByPlayer", eid)
    personal_box_creator__boxEids[curBoxInd] = personalBoxEid
    push(player__ownedPersonalBoxEids, personalBoxEid)
    curBoxInd++

[es(tag=server, on_appear)]
def assign_owner_to_personal_box_es(evt : Event;
                                    eid aka player_eid : EntityId;
                                    var player__ownedPersonalBoxEids : EidList&)
  query() <| $ [es] (groupName : string;
                     eid aka creator_eid : EntityId;
                     personal_box_creator__ready : bool;
                     personal_box_creator__startPositions : TMatrixList;
                     personal_box_creator__template : string;
                     var personal_box_creator__boxEids : EidList)
    if !personal_box_creator__ready
      logerr("personal box creator /*{creator_eid}*/ can't be used, probably personal_box_info were not set for it")
      return
    if empty(groupName)
      for pos, boxEid in personal_box_creator__startPositions, personal_box_creator__boxEids
        if boxEid == INVALID_ENTITY_ID
          boxEid = createEntity(personal_box_creator__template) <| $(var init : ComponentsInitializer)
            init |> set("transform", pos)
            init |> set("special_weapon_box__ownedByPlayer", player_eid)
          push(player__ownedPersonalBoxEids, boxEid)
          return

def private check_other_active_capzones_in_group(checkingGroup : string)
  var thereIsStilActiveCapzone = false
  query() <| $ [es(REQUIRE=capzone)] (active : bool;
                                      groupName : string)
    if groupName == checkingGroup && active
      thereIsStilActiveCapzone = true
      return
  return thereIsStilActiveCapzone

[es(tag=server, track=active, REQUIRE=capzone)]
def sektor_finished_es(evt : Event;
                       active : bool;
                       groupName aka captured_groupName : string)
  if !active && !check_other_active_capzones_in_group(captured_groupName)
    query() <| $ [es] (eid aka creator_eid : EntityId;
                       groupName aka creator_groupName : string;
                       personal_box_creator__ready : bool;
                       personal_box_creator__startPositions : TMatrixList;
                       personal_box_creator__template : string;
                       personal_box_creator__numPlayers : int;
                       var personal_box_creator__boxEids : EidList;
                       var personal_box_creator__wasUsed : bool&)
      if captured_groupName == creator_groupName && !personal_box_creator__wasUsed
        if !personal_box_creator__ready
          logerr("personal box creator /*{creator_eid}*/ can't create personal boxes, probably personal_box_info were not set for it")
          return
        personal_box_creator__wasUsed = true
        var curBoxInd = 0
        query() <| $ [es] (eid aka player_eid : EntityId; var player__ownedPersonalBoxEids : EidList&)
          if curBoxInd >= personal_box_creator__numPlayers
            logerr("new /*{personal_box_creator__template}*/ can't be created for /*{player_eid}*/ player, seems like there are more than /*{personal_box_creator__numPlayers}*/ players in the game session")
            return
          let personalBoxEid = createEntity(personal_box_creator__template) <| $(var init : ComponentsInitializer)
            init |> set("transform", personal_box_creator__startPositions[curBoxInd])
            init |> set("special_weapon_box__ownedByPlayer", player_eid)
          personal_box_creator__boxEids[curBoxInd] = personalBoxEid
          push(player__ownedPersonalBoxEids, personalBoxEid)
          curBoxInd++

[es(tag=server, on_appear)]
def create_special_boxes_es(evt : Event;
                            transform : float3x4;
                            special_box_creator__probability : float;
                            special_box_creator__template : string)
  if rnd_float(0.0, 1.0) < special_box_creator__probability
    createEntity(special_box_creator__template) <| $(var init : ComponentsInitializer)
      init |> set("transform", transform)

[es(tag=gameClient, REQUIRE=paid_loot_special_box, on_appear)]
def init_animation_for_box_es(evt : Event;
                              paid_loot_anim__nodeName : string;
                              var paid_loot_anim__progressVarId : int&;
                              var phys_vars : PhysVars&;
                              var paid_loot_anim__progress : float&)
  paid_loot_anim__progressVarId = phys_vars |> registerVar(paid_loot_anim__nodeName, 0.0)
  paid_loot_anim__progress = -1.0

[es(tag=gameClient, REQUIRE=paid_loot_special_box, track=paid_loot__alreadyUsed, on_appear, after=init_animation_for_box_es)]
def start_anim_progress_es(evt : Event;
                           paid_loot__alreadyUsed : bool;
                           var paid_loot_anim__openedAt : float&;
                           var paid_loot_anim__progress : float&)
  if paid_loot__alreadyUsed
    paid_loot_anim__progress = 0.0
    paid_loot_anim__openedAt = get_sync_time()

[es(tag=gameClient, REQUIRE=paid_loot_special_box, no_order)]
def special_box_anim_progress(info : ParallelUpdateFrameDelayed;
                              paid_loot_anim__progressVarId : int;
                              paid_loot_anim__startAngle : float;
                              paid_loot_anim__openedAngle : float;
                              paid_loot_anim__openedAt : float;
                              paid_loot_anim__timeToOpen : float;
                              var animchar : AnimcharBaseComponent;
                              var animchar_node_wtm : AnimcharNodesMat44;
                              var animchar_render__root_pos : vec4f&;
                              var phys_vars : PhysVars;
                              var anim_phys : AnimatedPhys;
                              var paid_loot_anim__progress : float&)
  if paid_loot_anim__progress < 0.0 || paid_loot_anim__progress > paid_loot_anim__openedAngle
    return
  paid_loot_anim__progress = cvt(info.curTime, paid_loot_anim__openedAt, paid_loot_anim__openedAt + paid_loot_anim__timeToOpen, paid_loot_anim__startAngle, paid_loot_anim__openedAngle)
  phys_vars |> setVar(paid_loot_anim__progressVarId, paid_loot_anim__progress)

  anim_phys_update(anim_phys, animchar, phys_vars)
  animchar_act(animchar, 0.f, true)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

[es(tag=server, on_appear, REQUIRE=zombie_mode__tokenParams)]
def init_token_nominals_and_max_amount_es(evt : Event;
                                          zombie_mode__maxTokensAmount : int;
                                          zombie_mode__tokenNominal : int)
  query() <| $ [es] (var player__maxTokens : int&)
    player__maxTokens = zombie_mode__maxTokensAmount

  query() <| $ [es] (var token_free__nominal : int&)
    token_free__nominal = zombie_mode__tokenNominal

  query() <| $ [es] (var paid_loot__tokenNominal : int&)
    paid_loot__tokenNominal = zombie_mode__tokenNominal

[es(tag=server, on_appear)]
def init_player_token_max_amount_es(evt : Event;
                                    var player__maxTokens : int&)
  query() <| $ [es(REQUIRE=zombie_mode__tokenParams)] (zombie_mode__maxTokensAmount : int)
    player__maxTokens = zombie_mode__maxTokensAmount

[es(tag=server, on_appear)]
def init_token_free_nominal_es(evt : Event;
                               var token_free__nominal : int&)
  query() <| $ [es(REQUIRE=zombie_mode__tokenParams)] (zombie_mode__tokenNominal : int)
    token_free__nominal = zombie_mode__tokenNominal

[es(tag=server, on_appear)]
def init_box_tokens_nominal_es(evt : Event;
                               var paid_loot__tokenNominal : int&)
  query() <| $ [es(REQUIRE=zombie_mode__tokenParams)] (zombie_mode__tokenNominal : int)
    paid_loot__tokenNominal = zombie_mode__tokenNominal

def private player_get_tokens(heroEid : EntityId;
                              token_eid : EntityId;
                              token_free__nominal : int;
                              player__maxTokens : int;
                              var player__tokens : int&)
  using() <| $(var data : Object)
    if player__tokens < player__maxTokens
      player__tokens += token_free__nominal
      set(data, "item", token_free__nominal)
      send_net_event(heroEid, CmdHeroLogExEvent(event = "tokens", key = "tokens/get_tokens", data = ecs_addr(data)))
      destroyEntity(token_eid)
    else
      set(data, "item", player__maxTokens)
      send_net_event(heroEid, CmdHeroLogExEvent(event = "tokens", key = "tokens/cant_get_more_tokens", data = ecs_addr(data)))

[es(tag=server, REQUIRE=token_free__tag)]
def pickup_token_free_es(evt : CmdPickupSpecialItem;
                         eid aka token_eid : EntityId;
                         token_free__nominal : int)
  query(evt.pickuperEid) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (possessedByPlr : EntityId)
    query(possessedByPlr) <| $ [es] (player__maxTokens : int;
                                     var player__tokens : int&)
      player_get_tokens(evt.pickuperEid, token_eid, token_free__nominal, player__maxTokens, player__tokens)

[es(tag=server, REQUIRE=(human, hitpoints__alwaysDowned), track=isDowned)]
def drop_tokens_on_player_death(evt : Event;
                                possessedByPlr : EntityId;
                                isDowned : bool;
                                transform : float3x4)
  if !isDowned
    return
  var nominal = -1
  query() <| $ [es(REQUIRE=zombie_mode__tokenParams)] (zombie_mode__tokenNominal : int)
    nominal = zombie_mode__tokenNominal
  if nominal <= 0
    logerr("can't drop player's tokens, because token nominal is unknown, probably zombie_travel_mode entity is missing")
    return

  query(possessedByPlr) <| $ [es] (var player__tokens : int&; tokens__spawnOffset = float3(0.30, 0.30, 0.0))
    let numFreeTokens = player__tokens / nominal
    player__tokens = 0
    let angleIncrement = 360.0 / float(numFreeTokens)
    let rotationAxis = float3(0.0, 1.0, 0.0)
    var additionalOffsetTm = IDENT_TM
    additionalOffsetTm[3] = tokens__spawnOffset
    for i in range(numFreeTokens)
      var rotTm : float3x4
      make_tm(rotationAxis, deg_to_rad(float(i) * angleIncrement), rotTm)
      var tm = transform * rotTm
      tm = tm * additionalOffsetTm
      drop_item_on_ground(tm)
      var relTm = IDENT_TM
      relTm[3] = tm[3]
      relTm[3].y += 0.3
      createEntity("token_free_item") <| $(var init : ComponentsInitializer)
        set(init, "transform", relTm)

[es(tag=gameClient, REQUIRE=token_free__tag)]
def token_rotation_es(info : ParallelUpdateFrameDelayed;
                      token_free__rotationSpeedDegPerSecond : float;
                      var transform : float3x4&)
  let rotationAxis = float3(0.0, 1.0, 0.0)
  let rotAngle = token_free__rotationSpeedDegPerSecond * info.dt
  var rotTm : float3x4
  make_tm(rotationAxis, deg_to_rad(rotAngle), rotTm)
  transform = transform * rotTm

[es(tag=server, on_appear, REQUIRE=zombie_mode_human)]
def init_grenade_resupply_num_es(evt : Event;
                                 soldier__sKind : string;
                                 zombie_mode__resupplyGrenadesNum : int;
                                 zombie_mode__antiTankResupplyGrenadesNum : int;
                                 var human__numGrenadesResupply : int&)
  human__numGrenadesResupply = soldier__sKind == "anti_tank" ? zombie_mode__antiTankResupplyGrenadesNum : zombie_mode__resupplyGrenadesNum

[es(tag=server, on_appear, REQUIRE=zombie_mode_human)]
def init_medkits_resupply_num_es(evt : Event;
                                 soldier__sKind : string;
                                 zombie_mode__medicResupplyMedkitsNum : int;
                                 zombie_mode__resupplyMedkitsNum : int;
                                 var human_inventory__usefulBoxItemsCapacity : int&)
  human_inventory__usefulBoxItemsCapacity = soldier__sKind == "medic" ? zombie_mode__medicResupplyMedkitsNum : zombie_mode__resupplyMedkitsNum

[es(tag=gameClient, on_appear, after=human_weap_reset_gun_slot_es, REQUIRE=(zombie_mode_human, hero))]
def switch_on_melee_weapon_zombie_mode_es(evt : Event;
                                          eid : EntityId)
  sendEvent(eid, HumanWeapSetCurrentGun(slot = uint8(HUWeaponSlots.EWS_MELEE)))

[es(tag=server, REQUIRE=zombie_mode_human)]
def on_medic_box_used_es(evt : CmdFinishPlacePlaceableItem;
                         eid : EntityId;
                         soldier__sKind : string)
  if has(evt.itemEid, "medBox") && soldier__sKind == "medic"
    sendEvent(eid, CmdReinitWeaponInSlot(slot = int(HUWeaponSlots.EWS_SECONDARY)))

[es(tag=server, on_appear)]
def init_block_shoot_for_medic_es(evt : Event;
                                  zombie_mode__medicBoxPlaceCooldown : float;
                                  soldier__sKind : string;
                                  human_weap__gunEids : EidList;
                                  var human__blockShootCooldown : float&)
  if soldier__sKind == "medic"
    human__blockShootCooldown = zombie_mode__medicBoxPlaceCooldown
    for gunEid in human_weap__gunEids
      if has(gunEid, "medBox")
        query(gunEid) <| $ [es] (var blockShoot : bool&)
          blockShoot = false

[es(tag=server, on_appear)]
def init_cooldown_for_medic_box_es(evt : Event;
                                   gun__owner : EntityId;
                                   var blockShoot : bool&;
                                   var medBox__canBeUsedAt : float&)
  query(gun__owner) <| $ [es] (human__blockShootCooldown : float)
    medBox__canBeUsedAt = human__blockShootCooldown > 0.0 ? get_sync_time() + human__blockShootCooldown : -1.0
    blockShoot = medBox__canBeUsedAt > 0.0 ? true : false

[es(tag=server, no_order)]
def blockshoot_update_es(info : ParallelUpdateFrameDelayed;
                         medBox__canBeUsedAt : float;
                         var blockShoot : bool&)
  if info.curTime > medBox__canBeUsedAt
    blockShoot = false

[es(tag=server, no_order)]
def block_shoot_log_es(info : ParallelUpdateFrameDelayed;
                       gun__owner : EntityId;
                       blockShoot__logPeriod : float;
                       medBox__canBeUsedAt : float;
                       var blockShoot__shootAttempt : bool&;
                       var blockShoot__nextLogAt : float&)
  if blockShoot__shootAttempt
    blockShoot__shootAttempt = false
    let curTime = info.curTime
    if curTime > blockShoot__nextLogAt
      using() <| $(var data : Object)
        set(data, "seconds", int(medBox__canBeUsedAt - curTime))
        send_net_event(gun__owner, CmdHeroLogExEvent(event = "medbox", key = "medbox/cooldown", data = ecs_addr(data)))
      blockShoot__nextLogAt = curTime + blockShoot__logPeriod

[es(tag=server)]
def human_set_session_finished(evt : EventTeamRoundResult;
                               var human_sessionFinished : bool&)
  human_sessionFinished = true

[es(tag=server, track=human_sessionFinished, REQUIRE=zombie_mode_human)]
def forbid_use_vehicle_on_zombie_session_finished(evt : Event;
                                                  human_sessionFinished : bool)
  if !human_sessionFinished
    return
  query() <| $ [es] (var vehicle__isPlayerCanEnter : bool&)
    vehicle__isPlayerCanEnter = false

[es(tag=server, on_disappear, REQUIRE=item__selfres_syringe)]
def on_syringe_use(evt : Event;
                   eid : EntityId;
                   item__ownerEid : EntityId;
                   item__useCount : int;
                   consumableId : string)
  if item__useCount > 0
    return
  print("selfres {eid} disappear, item__useCount = {item__useCount}, ownerEid = {item__ownerEid}")
  query(item__ownerEid) <| $ [es] (possessedByPlr : EntityId)
    sendEvent(possessedByPlr, EventConsumeItems(consumableId = consumableId, count = 1))

[es(tag=server, on_appear)]
def init_special_weap_templates_base(evt : Event;
                                     var paid_loot__specialWeapTemplatesBase : StringList;
                                     var paid_loot__specialWeapRandomizeWeightBase : FloatList)
  clear(paid_loot__specialWeapTemplatesBase)
  clear(paid_loot__specialWeapRandomizeWeightBase)
  query() <| $ [es] (zombie_mode__unlocksTemplates : StringList)
    if empty(zombie_mode__unlocksTemplates)
      return
    let weightOfOneWeap = 100.0 / float(length(zombie_mode__unlocksTemplates))
    for templ in zombie_mode__unlocksTemplates
      push(paid_loot__specialWeapTemplatesBase, templ)
      push(paid_loot__specialWeapRandomizeWeightBase, weightOfOneWeap)

[es(tag=server, on_appear, REQUIRE=zombie_travel_mode)]
def zombie_travel_mode_init_es(evt : Event;
                               zombie_mode__unlocksTemplates : StringList)
  if empty(zombie_mode__unlocksTemplates)
    return
  query() <| $ [es] (var paid_loot__specialWeapTemplatesBase : StringList;
                     var paid_loot__specialWeapRandomizeWeightBase : FloatList)
    clear(paid_loot__specialWeapTemplatesBase)
    clear(paid_loot__specialWeapRandomizeWeightBase)
    let weightOfOneWeap = 100.0 / float(length(zombie_mode__unlocksTemplates))
    for templ in zombie_mode__unlocksTemplates
      push(paid_loot__specialWeapTemplatesBase, templ)
      push(paid_loot__specialWeapRandomizeWeightBase, weightOfOneWeap)

[es(tag=server, on_appear, REQUIRE=zombie_mode_human)]
def unlock_special_weapons_list_init_es(evt : Event;
                                        squad_member__playerEid : EntityId;
                                        var unlocked_special_weapons : StringList)
  clear(unlocked_special_weapons)
  query(squad_member__playerEid) <| $ [es] (army : string; armies : Object)
    let armyData = armies[army]
    if armyData == null
      logerr("can't fill unlocked_special_weapons cause armies component is empty")
      return
    let consumables = get_ecs_object(*get_ecs_object(armyData), "consumables")
    if consumables == null
      return

    query() <| $ [es] (zombie_mode__unlocksIds : StringList;
                       zombie_mode__unlocksTemplates : StringList)
      if length(zombie_mode__unlocksIds) != length(zombie_mode__unlocksTemplates)
        logerr("wrong length of zombie_mode__unlocksIds or zombie_mode__unlocksTemplates. check out zombie_travel_mode entity")
        return
      if empty(zombie_mode__unlocksIds)
        return

      for unlockId, templ in zombie_mode__unlocksIds, zombie_mode__unlocksTemplates
        if has(*consumables, string(unlockId))
          push(unlocked_special_weapons, templ)

[es(tag=server, on_appear, REQUIRE=zombie_mode_human)]
def init_syringe_from_consumables_es(evt : Event;
                                     eid : EntityId;
                                     zombie_mode__maxSelfresCount : int = 3;
                                     squad_member__playerEid : EntityId)
  query(squad_member__playerEid) <| $ [es] (army : string; armies : Object)
    let armyData = armies[army]
    if armyData == null
      return
    let consumables = get_ecs_object(*get_ecs_object(armyData), "consumables")
    if consumables == null
      return
    assume cons = *consumables
    if has(cons, "selfres_syringe")
      var selfresNum = cons["selfres_syringe"] |> get_int() ?? 0
      selfresNum = min(selfresNum, zombie_mode__maxSelfresCount)
      for _i in range(0, selfresNum)
        createEntity("selfres_syringe_item") <| $(var init : ComponentsInitializer)
          set(init, "item__lastOwner", eid)
          set(init, "item__ownerEid", eid)

def get_unlock_from_squad(squad : Object)
  return squad.requireUnlock ?? ""

def check_squad_unlock_in_consumables(squadUnlock : string; consumables : Object const?)
  if consumables == null
    return false
  return has(*consumables, squadUnlock)

[es(tag=server, on_appear, REQUIRE=player_zombieMode, track=isArmiesReceived, after=init_squad_revive_points)]
def init_heroes_unlocks_es(evt : Event;
                           isArmiesReceived : bool;
                           armies : Object;
                           army : string;
                           var squads__revivePointsList : IntList&)
  if !isArmiesReceived
    return
  let squads = (armies[army] ?as Object)?.squads ?as Array
  let consumables = get_ecs_object(*get_ecs_object(armies[army]), "consumables")
  if squads == null
    return

  for squadIdx, points in iter_range(squads__revivePointsList), squads__revivePointsList
    let squad = squads?[squadIdx] ?as Object
    if squad == null
      continue
    let squadUnlock = get_unlock_from_squad(*squad)
    if squadUnlock != "" && !check_squad_unlock_in_consumables(squadUnlock, consumables)
      points = 0

[es(tag=server, REQUIRE=zombie_mode_human)]
def copy_players_hp_for_ui_es(info : ParallelUpdateFrameDelayed;
                              hitpoints__hp : float;
                              var hitpoints__uiHp : float&)
  hitpoints__uiHp = hitpoints__hp

[es(tag=server, REQUIRE=player_zombieMode)]
def set_prechosen_hero_es(evt : EventSetPrechosenInfo;
                          var player__prechosenSKind : das_string&)
  player__prechosenSKind := evt.prechosenSKind

[es(tag=render, on_appear)]
def set_post_fx_after_zombie_fx_appear(evt : Event;
                                       zombie_damage_indicator__blockDuration : float;
                                       zombie_damage_indicator__thresholds : float3;
                                       zombie_damage_indicator__lightPulsationFreq : float4;
                                       zombie_damage_indicator__lightIntensities : float4;
                                       zombie_damage_indicator__mediumPulsationFreq : float4;
                                       zombie_damage_indicator__mediumIntensities : float4;
                                       zombie_damage_indicator__severePulsationFreq : float4;
                                       zombie_damage_indicator__severeIntensities : float4)

  query() <| $ [es] (var damage_indicator__blockDuration : float&;
                     var damage_indicator__thresholds : float3&;
                     var damage_indicator__lightPulsationFreq : float4&;
                     var damage_indicator__lightIntensities : float4&;
                     var damage_indicator__mediumPulsationFreq : float4&;
                     var damage_indicator__mediumIntensities : float4&;
                     var damage_indicator__severePulsationFreq : float4&;
                     var damage_indicator__severeIntensities : float4&)

    damage_indicator__blockDuration = zombie_damage_indicator__blockDuration
    damage_indicator__thresholds = zombie_damage_indicator__thresholds
    damage_indicator__lightPulsationFreq = zombie_damage_indicator__lightPulsationFreq
    damage_indicator__lightIntensities = zombie_damage_indicator__lightIntensities
    damage_indicator__mediumPulsationFreq = zombie_damage_indicator__mediumPulsationFreq
    damage_indicator__mediumIntensities = zombie_damage_indicator__mediumIntensities
    damage_indicator__severePulsationFreq = zombie_damage_indicator__severePulsationFreq
    damage_indicator__severeIntensities = zombie_damage_indicator__severeIntensities

[es(tag=render, on_appear)]
def set_post_fx_after_post_fx_appear(evt : Event;
                                     var damage_indicator__blockDuration : float&;
                                     var damage_indicator__thresholds : float3&;
                                     var damage_indicator__lightPulsationFreq : float4&;
                                     var damage_indicator__lightIntensities : float4&;
                                     var damage_indicator__mediumPulsationFreq : float4&;
                                     var damage_indicator__mediumIntensities : float4&;
                                     var damage_indicator__severePulsationFreq : float4&;
                                     var damage_indicator__severeIntensities : float4&)

  query() <| $ [es] (zombie_damage_indicator__blockDuration : float;
                     zombie_damage_indicator__thresholds : float3;
                     zombie_damage_indicator__lightPulsationFreq : float4;
                     zombie_damage_indicator__lightIntensities : float4;
                     zombie_damage_indicator__mediumPulsationFreq : float4;
                     zombie_damage_indicator__mediumIntensities : float4;
                     zombie_damage_indicator__severePulsationFreq : float4;
                     zombie_damage_indicator__severeIntensities : float4)

    damage_indicator__blockDuration = zombie_damage_indicator__blockDuration
    damage_indicator__thresholds = zombie_damage_indicator__thresholds
    damage_indicator__lightPulsationFreq = zombie_damage_indicator__lightPulsationFreq
    damage_indicator__lightIntensities = zombie_damage_indicator__lightIntensities
    damage_indicator__mediumPulsationFreq = zombie_damage_indicator__mediumPulsationFreq
    damage_indicator__mediumIntensities = zombie_damage_indicator__mediumIntensities
    damage_indicator__severePulsationFreq = zombie_damage_indicator__severePulsationFreq
    damage_indicator__severeIntensities = zombie_damage_indicator__severeIntensities

[es(tag=server, REQUIRE=zombie_travel_mode)]
def on_objective_completed(evt : EventSectorCaptured;
                           zombie_mode__awardsSectorNames : StringList;
                           zombie_mode__awardsSectorTokens : IntList)
  query(evt.zone) <| $ [es] (groupName : string)
    let idx = find_index(zombie_mode__awardsSectorNames, groupName)
    if idx >= 0
      query() <| $ [es] (disconnected : bool;
                         var player__objectiveTokens : int&)
        if !disconnected
          player__objectiveTokens += zombie_mode__awardsSectorTokens[idx]

[es(tag=server, on_event=EventLevelLoaded)]
def spawn_random_box(evt : Event)
  var box_spawns : array<EntityId>
  query() <| $ [es(REQUIRE=randomBoxSpawn)] (eid : EntityId)
    push(box_spawns, eid)

  if length(box_spawns) == 0
    return

  query(box_spawns[rnd_int(0, length(box_spawns) - 1)]) <| $ [es] (transform : float3x4)
    createEntity("random_weapon_box_victim") <| $(var init : ComponentsInitializer)
      set(init, "transform", transform)

[es(tag=gameClient, on_disappear)]
def paid_door_effect(evt : Event;
                     transform : float3x4;
                     paid_door__effect : string)
  createEntity(paid_door__effect) <| $(var init : ComponentsInitializer)
    set(init, "transform", transform)

[es(tag=server)]
def paid_door_use(evt : CmdUse;
                  active : bool;
                  eid : EntityId;
                  var paid_door__currentCost : int&;
                  var hud_icon__counter : int&;
                  paid_door__deactivateZones : StringList;
                  paid_door__activateChoice : Object const?;
                  transform : float3x4)
  if !active || paid_door__currentCost <= 0
    return
  query(evt.requesterEid) <| $ [es] (var paid_loot__souls : float&; var paid_loot__points : int&; possessedByPlr : EntityId; guid : string)
    paid_loot__souls = float(int(paid_loot__souls))
    var currentPay = min(int(paid_loot__souls), paid_door__currentCost)
    if currentPay <= 0
      return

    paid_loot__souls -= float(currentPay)
    paid_door__currentCost -= currentPay

    send_award_stat(possessedByPlr, guid, "zombieDoorsScore", float(currentPay))

    find_query() <| $ [es] (zomibe_mode__soulsToScoreMult : int)
      currentPay *= zomibe_mode__soulsToScoreMult
      return true

    paid_loot__points += currentPay
    hud_icon__counter = paid_door__currentCost
    send_net_event(possessedByPlr, CmdHeroLogClear())
    if paid_door__currentCost > 0
      send_scene_net_sound(evt.requesterEid, "exchangeSouls")
    else
      destroyEntity(eid)
      broadcast_scene_net_sound("paidDoorOpen", transform[3])

      if length(paid_door__deactivateZones) != 0
        for zone in paid_door__deactivateZones
          query() <| $ [es(REQUIRE=zombieSpawn)] (var active : bool&; groupName : string)
            if groupName == zone
              active = false

      if paid_door__activateChoice != null && length(*paid_door__activateChoice) > 0
        activate_group(select_random_choice(*paid_door__activateChoice))
        broadcast_hero_log_event("zombie_objective", "objective/paidDoorOpen")
      else
        broadcastEvent(EventTeamWon(team = 1)) // players team
        query() <| $ [es(REQUIRE=zombie)] (isAlive : bool; eid aka zombie_eid : EntityId)
          if isAlive
            sendEvent(zombie_eid, CmdKill(offender = zombie_eid, damageType = uint16(int(DamageType.DM_MELEE)), gunPropsId = -1, shellId = -1))

[es(tag=server, on_event=EventTeamRoundResult)]
def zombie_event_finish_hint(evt : Event; var zombie_mode__finishHintShowed : bool&)
  if zombie_mode__finishHintShowed
    return
  zombie_mode__finishHintShowed = true
  query() <| $ [es] (scoring_player__zombieDoorsScore : int; possessed : EntityId)
    using() <| $(var data : Object)
      set(data, "count", scoring_player__zombieDoorsScore)
      send_net_event(possessed, CmdHeroLogExEvent(event = "paid_loot", key = "missionTypeHint/zombieModeSoulsScore", data = ecs_addr(data)))


[es(tag=server, on_appear, track=active)]
def create_random_weapon_stand_shop_guns(evt : Event;
                                         eid : EntityId;
                                         active : bool;
                                         transform : float3x4;
                                         random_weapon_stand_shop__weapTemplates : StringList;
                                         random_weapon_stand_shop__prices : IntList;
                                         var random_weapon_stand_shop__weaponsCreated : bool&;
                                         var random_weapon_stand_shop__weapChances : FloatList&;
                                         random_weapon_stand_shop__weapRandomizeWeight : FloatList;
                                         random_weapon_stand_shop__spawnRelTms : TMatrixList)
  if !active || random_weapon_stand_shop__weaponsCreated
    return
  random_weapon_stand_shop__weaponsCreated = true
  resize(random_weapon_stand_shop__weapChances, length(random_weapon_stand_shop__weapTemplates))
  makeChanceRange(eid, random_weapon_stand_shop__weapTemplates, random_weapon_stand_shop__weapRandomizeWeight, random_weapon_stand_shop__weapChances)
  for placeRelTm in random_weapon_stand_shop__spawnRelTms
    let weaponInd = weighted_choice(rnd_float(0.0, 1.0), length(random_weapon_stand_shop__weapChances), random_weapon_stand_shop__weapChances)
    if weaponInd >= 0
      createEntity(string(random_weapon_stand_shop__weapTemplates[weaponInd]) + "+item_in_world+ui_visible+disable_update+paid_loot_item_with_use_count") <| $(var init)
        init |> set("transform", transform * placeRelTm)
        if weaponInd < length(random_weapon_stand_shop__prices)
          init |> set("paid_loot__cost", random_weapon_stand_shop__prices[weaponInd])

[es(track=active, on_appear, tag=gameClient)]
def update_paid_obstacle_icon(evt : Event;
                              var hud_icon__counter : int&;
                              paid_door__currentCost : int;
                              var hud_icon__isActive : bool&;
                              active : bool)
  hud_icon__isActive = active
  hud_icon__counter = paid_door__currentCost

[es(on_appear, REQUIRE=activateCheck)]
def activate_paid_doors_on_appear(evt : Event;
                                  groupName : string;
                                  var active : bool&)
  find_query() <| $ [es] (activator__lastActivatedGroup : string; activator__enabled : bool)
    if activator__enabled && activator__lastActivatedGroup == groupName
      active = true
      return true
    return false

[es(track=active, on_appear, tag=gameClient)]
def paid_door_minimap_visible(evt : Event;
                              active : bool;
                              var minimap__visibleForAll : bool&)
  minimap__visibleForAll = active

[es(tag=server, track=entity_spawner__curWaveId, REQUIRE=entity_spawner__curWaveId)]
def zombie_wave_souls_event(evt : Event)
  find_query() <| $ [es] (paid_door__currentCost : int; active : bool)
    if !active
      return false
    query() <| $ [es] (paid_loot__souls : float; eid : EntityId)
      using() <| $(var data : Object)
        set(data, "count", int(paid_loot__souls))
        set(data, "currentDoorCost", paid_door__currentCost)
        set(data, "ttl", 25)
        send_net_event(eid, CmdHeroLogExEvent(event = "paid_loot", key = "paid_loot/you_have_souls", data = ecs_addr(data)))
    return true

[es]
def paid_door_use_anim(evt : HumanUseObjectRequest; eid : EntityId)
  if has(evt.objectEid, "paid_door__currentCost")
    run_action(eid, "pickup")

[es(REQUIRE=paid_door__currentCost)]
def paid_door_use_anim_on_door(evt : CmdUse)
  run_action(evt.requesterEid, "pickup")

[es(tag=server, on_appear)]
def zombie_stuck_control_position_init(evt : Event;
                                       var zombie_stuck_control__lastPosition : float3&;
                                       var zombie_stuck_control__lastPositionSaveTime : float&;
                                       transform : float3x4)
  zombie_stuck_control__lastPosition = transform[3]
  zombie_stuck_control__lastPositionSaveTime = get_sync_time()

[es(tag=server)]
def zombie_position_change_update(info : ParallelUpdateFrameDelayed;
                                  eid : EntityId;
                                  zombie_stuck_control__minPositionChange : float;
                                  zombie_stuck_control__minPositionChangeTime : float;
                                  var zombie_stuck_control__lastPositionSaveTime : float&;
                                  var zombie_stuck_control__lastPosition : float3&;
                                  transform : float3x4)
  if info.curTime < zombie_stuck_control__lastPositionSaveTime + zombie_stuck_control__minPositionChangeTime || zombie_stuck_control__minPositionChange < 0.
    return
  zombie_stuck_control__lastPositionSaveTime = info.curTime
  if length_sq(transform[3] - zombie_stuck_control__lastPosition) < square(zombie_stuck_control__minPositionChange)
    sendEvent(eid, CmdKill(offender = eid, damageType = uint16(int(DamageType.DM_MELEE)), gunPropsId = -1, shellId = -1))
  zombie_stuck_control__lastPosition = transform[3]
