module respawn_priority_auto_selector_common shared
require ecs
require DagorRandom
require game.es.respawn_base_common


let MIN_NUM_OF_POINTS = 2 // minimum number of points from which select random spawn

struct AutoSpawnPointData
  point : float3
  pointEid : EntityId
  group : int
  zoneEid : EntityId

def AutoSpawnPointData(point : float3; pointEid : EntityId; group : int; zoneEid : EntityId)
  return AutoSpawnPointData(point = point,
           pointEid = pointEid,
           group = group,
           zoneEid = zoneEid)

struct AutoSpawnGroup
  group : int
  zoneEid : EntityId

def accept_random_respawn_group(respawns : table<int; AutoSpawnPointData>; team : int) : int
  var lastEid = INVALID_ENTITY_ID
  var prevEid = INVALID_ENTITY_ID
  query() <| $ [es] (team__id : int;
                     team__lastAutoSpawnCapZoneEid : EntityId;
                     team__prevAutoSpawnCapZoneEid : EntityId)
    if team__id == team
      lastEid = team__lastAutoSpawnCapZoneEid
      prevEid = team__prevAutoSpawnCapZoneEid

  var groups : array<AutoSpawnGroup>
  for respawn in values(respawns)
    let zoneEid = respawn.zoneEid
    let group = respawn.group
    if group >= 0
      groups |> emplace(AutoSpawnGroup(group = group, zoneEid = zoneEid))

  if groups |> empty()
    return -1

  let oneZoneEid = groups[0].zoneEid
  var oneZoneOnly = true
  for group in groups
    if group.zoneEid != oneZoneEid
      oneZoneOnly = false

  if !oneZoneOnly
    if lastEid != INVALID_ENTITY_ID && length(groups) > 1
      var idxToErase = -1
      for group, idx in groups, range(length(groups))
        if lastEid == group.zoneEid
          idxToErase = idx
          break
      if idxToErase >= 0
        groups |> erase(idxToErase)

    if prevEid != INVALID_ENTITY_ID && length(groups) > 1
      var idxToErase = -1
      for group, idx in groups, range(length(groups))
        if prevEid == group.zoneEid
          idxToErase = idx
          break
      if idxToErase >= 0
        groups |> erase(idxToErase)

  let numGroups = length(groups)
  let ridx = (numGroups == 1) ? 0 : rnd_int(0, numGroups - 1)
  let selectedGroup = groups[ridx].group
  let selectedZoneEid = groups[ridx].zoneEid

  query() <| $ [es] (team__id : int;
                     var team__lastAutoSpawnCapZoneEid : EntityId&;
                     var team__prevAutoSpawnCapZoneEid : EntityId&)
    if team__id == team
      team__prevAutoSpawnCapZoneEid = team__lastAutoSpawnCapZoneEid
      team__lastAutoSpawnCapZoneEid = selectedZoneEid

  return selectedGroup

struct AutoSpawnNearestGroup
  nearestGroup : int
  distSq : float

def find_nearest_respawn_group(target : float3; groups : table<int; AutoSpawnPointData>) : AutoSpawnNearestGroup
  var minDistSq = FLT_MAX
  var nearestGroup = -1
  for group in values(groups)
    let distSq = length_sq(target - group.point)
    if distSq < minDistSq
      minDistSq = distSq
      nearestGroup = group.group
  return AutoSpawnNearestGroup(nearestGroup = nearestGroup, distSq = minDistSq)

struct AutoSpawnCapzone
  zoneEid : EntityId
  zonePos : float3

def find_nearest_respawn_groups(capzones : array<AutoSpawnCapzone>;
                                respawnGroups : table<int; AutoSpawnPointData>;
                                var customRespawnGroups : table<int; AutoSpawnPointData>;
                                team : int) : table<int; AutoSpawnPointData>
  var resultRespawnGroups : table<int; AutoSpawnPointData>
  for capzone in capzones
    let zonePos = capzone.zonePos
    let nearest1 = find_nearest_respawn_group(zonePos, respawnGroups)
    let nearest2 = find_nearest_respawn_group(zonePos, customRespawnGroups)
    var selectedGroup = nearest1.nearestGroup

    let customGroup = nearest2.nearestGroup
    if customGroup != -1 && nearest2.distSq < nearest1.distSq
      if key_exists(customRespawnGroups, customGroup)
        let customResp = customRespawnGroups[customGroup]
        let spawnPos = customResp.point

        if is_respawn_at_team_side(spawnPos, zonePos, team)
          if check_exists_navmesh_path_from_respawn_to_capzone(customResp.pointEid, spawnPos, zonePos)
            selectedGroup = customGroup

    if !key_exists(resultRespawnGroups, selectedGroup)
      var targetData = AutoSpawnPointData(float3(), INVALID_ENTITY_ID, selectedGroup, capzone.zoneEid)
      resultRespawnGroups.insert(selectedGroup, targetData)
  return <- resultRespawnGroups

struct AutoSpawnNearestCapzone
  zoneEid : EntityId
  distSq : float

def find_nearest_capzone(target : float3; capzones : array<AutoSpawnCapzone>)
  var minDistSq = FLT_MAX
  var zoneEid = INVALID_ENTITY_ID
  for capzone in capzones
    let point = capzone.zonePos
    let distSq = length_sq(target - point)
    if distSq < minDistSq
      minDistSq = distSq
      zoneEid = capzone.zoneEid
  return AutoSpawnNearestCapzone(zoneEid = zoneEid, distSq = minDistSq)

struct AutoSpawnGroupCapzone
  group : int
  zoneEid : EntityId
  distance : float

def sort_respawn_groups_by_distance(capzones : array<AutoSpawnCapzone>;
                                    respawnGroups : table<int; AutoSpawnPointData>;
                                    customRespawnGroups : table<int; AutoSpawnPointData>) : array<AutoSpawnGroupCapzone>
  var respawnGroupsByDistance : array<AutoSpawnGroupCapzone >
  for respawnGroup in values(respawnGroups)
    let nearest = find_nearest_capzone(respawnGroup.point, capzones)
    respawnGroupsByDistance |> emplace(AutoSpawnGroupCapzone(group = respawnGroup.group, zoneEid = nearest.zoneEid, distance = nearest.distSq))
  for respawnGroup in values(customRespawnGroups)
    let nearest = find_nearest_capzone(respawnGroup.point, capzones)
    respawnGroupsByDistance |> emplace(AutoSpawnGroupCapzone(group = respawnGroup.group, zoneEid = nearest.zoneEid, distance = nearest.distSq))
  respawnGroupsByDistance |> sort() <| $(left; right)
    return left.distance < right.distance
  return <- respawnGroupsByDistance

def get_additional_for_spawn_tab(spawnTab : table<int; AutoSpawnPointData>;
                                 capzones : array<AutoSpawnCapzone>;
                                 respawnGroups : table<int; AutoSpawnPointData>;
                                 customRespawnGroups : table<int; AutoSpawnPointData>) : table<int; AutoSpawnPointData>
  var additionalTab : table<int; AutoSpawnPointData>
  let allSpawnsByDistance <- sort_respawn_groups_by_distance(capzones, respawnGroups, customRespawnGroups)
  var needAddCount = MIN_NUM_OF_POINTS - length(spawnTab)
  for i in 0..length(allSpawnsByDistance)
    if needAddCount == 0
      break
    let spawn = allSpawnsByDistance[i]
    let group = spawn.group
    if !key_exists(spawnTab, group)
      var targetData = AutoSpawnPointData(float3(), INVALID_ENTITY_ID, group, spawn.zoneEid)
      additionalTab.insert(group, targetData)
      needAddCount--
  return <- additionalTab

def get_respawn_groups(can_use_respawn_base_type : string; for_team : int) : table<int; AutoSpawnPointData>
  var respawnGroups : table<int; AutoSpawnPointData>
  query() <| $ [es(REQUIRE=autoRespawnSelector)] (eid : EntityId;
                                                  selectedGroup : int;
                                                  respawn_icon__temporaryInactive : bool;
                                                  transform : float3x4;
                                                  respawnIconType : string;
                                                  team : int)
    if respawnIconType == can_use_respawn_base_type && team == for_team && !respawn_icon__temporaryInactive
      var targetData = AutoSpawnPointData(transform[3], eid, selectedGroup, INVALID_ENTITY_ID)
      respawnGroups.insert(selectedGroup, targetData)
  return <- respawnGroups

def get_custom_respawn_groups(can_use_respawn_base_type : string; for_team : int) : table<int; AutoSpawnPointData>
  var respawnGroups : table<int; AutoSpawnPointData>
  query() <| $ [es(REQUIRE_NOT=(autoRespawnSelector, mobileRespawnSelector))] (eid : EntityId;
                                                                               selectedGroup : int;
                                                                               transform : float3x4;
                                                                               respawnIconType : string;
                                                                               team : int;
                                                                               respawn_point__respawnersQueue : EidList;
                                                                               respawn_icon__active : bool)
    if respawn_icon__active && respawnIconType == can_use_respawn_base_type && team == for_team && length(respawn_point__respawnersQueue) == 0
      var targetData = AutoSpawnPointData(transform[3], eid, selectedGroup, INVALID_ENTITY_ID)
      respawnGroups.insert(selectedGroup, targetData)
  return <- respawnGroups

def get_target_capzones() : array<AutoSpawnCapzone>
  var capzones : array<AutoSpawnCapzone>
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                      active : bool;
                                      transform : float3x4)
    if active
      capzones |> emplace(AutoSpawnCapzone(zoneEid = eid, zonePos = transform[3]))
  return <- capzones

def find_force_respawn_base_group(for_team : int; respawn_type : string) : int
  var respawnGroup = -1
  query() <| $ [es(REQUIRE=forceRespawnBasePriority)] (respawnBaseGroup : int;
                                                       team : int;
                                                       active : bool;
                                                       respawnbaseType : string)
    if active && team == for_team && respawn_type == respawnbaseType
      respawnGroup = respawnBaseGroup
  return respawnGroup

def update_auto_spawn_points(var left : table<int; AutoSpawnPointData>; right : table<int; AutoSpawnPointData>)
  for rightKey, rightValue in keys(right), values(right)
    left.insert(rightKey, rightValue)

def get_respawn_group(can_use_respawn_base_type : string; team : int; for_bot : bool) : int
  let forceRespawnGroup = find_force_respawn_base_group(team, can_use_respawn_base_type)
  if forceRespawnGroup >= 0
    return forceRespawnGroup

  let respawnGroups <- get_respawn_groups(can_use_respawn_base_type, team)
  let capZones <- get_target_capzones()
  if length(capZones) == 0
    return accept_random_respawn_group(respawnGroups, team)

  var _respawnGroupsEmpty_ : table<int; AutoSpawnPointData>
  var customRespawnGroups <- for_bot ? get_custom_respawn_groups(can_use_respawn_base_type, team) : _respawnGroupsEmpty_
  let hasChoice = length(respawnGroups) >= MIN_NUM_OF_POINTS || length(customRespawnGroups) > 0
  if !hasChoice
    return accept_random_respawn_group(respawnGroups, team)

  var prioritySpawnList <- find_nearest_respawn_groups(capZones, respawnGroups, customRespawnGroups, team)
  let hasEnoughSpawnGroups = length(prioritySpawnList) >= MIN_NUM_OF_POINTS
  if !hasEnoughSpawnGroups
    let additiona_for_spawn_tab <- get_additional_for_spawn_tab(prioritySpawnList, capZones, respawnGroups, customRespawnGroups)
    prioritySpawnList |> update_auto_spawn_points(additiona_for_spawn_tab)
  return accept_random_respawn_group(prioritySpawnList, team)
