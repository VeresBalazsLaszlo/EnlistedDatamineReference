require ecs
require game.events_game
require player
require ecs.safe
require game.es.respawn_base_common
require enlisted.events_enlisted
require game.es.respawn_camera_common


[es(tag=server, on_appear, on_event=EventFirstPlayerConnected, after=save_matching_info)]
def free_tank_template_for_team_init(evt : Event;
                                     matching_info__engineerBuildingsLevel : string)
  query() <| $ [es] (team__armies : StringList;
                     @shared_comp team__freeTankAllTemplates : Object;
                     var team__freeTankTemplate : das_string&)
    if length(team__armies) < 2
      return
    let armyTemplates = get_ecs_object(team__freeTankAllTemplates, matching_info__engineerBuildingsLevel)
    if armyTemplates == null
      return
    let freeTankTemplateName = get_string(*armyTemplates, string(team__armies[1]), "")
    if freeTankTemplateName == ""
      return
    team__freeTankTemplate := freeTankTemplateName

[es(tag=server, track=team, track=isArmiesReceived)]
def free_tank_spawn_template_and_availability_for_player(evt : Event;
                                                         army : string;
                                                         armies : Object;
                                                         team : int;
                                                         isArmiesReceived : bool;
                                                         var respawner__freeTankSpawnAvailable : bool&)
  var teamFreeTankTemplateValid = false
  respawner__freeTankSpawnAvailable = false
  if !isArmiesReceived
    return
  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return
  find_query() <| $ [es] (team__id : int; team__freeTankTemplate : string)
    if team__id == team
      teamFreeTankTemplateValid = getTemplateByName(team__freeTankTemplate) != null
      return true
    return false
  if !teamFreeTankTemplateValid
    return
  query() <| $ [es] (matching_info__engineerBuildingsLevel : string)
    let maxVehicleBrForFreeSpawnAvailability = matching_info__engineerBuildingsLevel == "1_3" ? 1 : 3
    for squad in *squads
      let squadObj = squad as Object
      let curVehicle = squadObj?.curVehicle ?as Object
      if curVehicle == null
        continue
      let templName = get_string(*curVehicle, "gametemplate", "")
      if !templateHasComponent(*getTemplateByName(templName), "isTank")
        continue
      let vehicleBr = curVehicle?.growthTier ?? maxVehicleBrForFreeSpawnAvailability
      if vehicleBr > maxVehicleBrForFreeSpawnAvailability
        return
    respawner__freeTankSpawnAvailable = true

[es(tag=server, on_appear, on_event=EventEntityDied, on_disappear, REQUIRE=isTank)]
def team_free_tank_spawn_active_update(evt : Event; team : int)
  find_query() <| $ [es] (team__id : int; var team__freeTankSpawnsActive : bool&)
    if team__id == team
      return false
    team__freeTankSpawnsActive = false
    var tankBrForFreeTankAvailability = -1
    query() <| $ [es] (matching_info__engineerBuildingsLevel : string)
      tankBrForFreeTankAvailability = matching_info__engineerBuildingsLevel == "1_3" ? 3 : 5
    if tankBrForFreeTankAvailability == -1
      return true
    find_query() <| $ [es(REQUIRE=isTank)] (isAlive : bool; ownedBySquad : EntityId; team aka tank_team : int)
      if tank_team == team__id || !isAlive
        return false
      query(ownedBySquad) <| $ [es] (squad__id : int;
                                     squad__ownerPlayer : EntityId)
        query(squad__ownerPlayer) <| $ [es] (army : string;
                                             armies : Object)
          assume squads = (armies[army] ?as Object)?.squads ?as Array
          if squads == null
            return
          let squadObj = (*squads)[squad__id] as Object
          if squadObj == null
            return
          if ((squadObj?.curVehicle ?as Object)?.growthTier ?? 1) >= tankBrForFreeTankAvailability
            team__freeTankSpawnsActive = true
      return team__freeTankSpawnsActive
    return true

[es(tag=gameClient, track=respawner__freeTankSpawnAvailable, REQUIRE=(respawner__freeTankSpawnAvailable, localPlayer))]
def send_event_to_update_free_tank_spawn_icons(evt : Event)
  query() <| $ [es(REQUIRE=respawn_icon__freeTankSpawn)] (eid : EntityId)
    sendEvent(eid, EventUpdateIcon())

[es(track=team__freeTankSpawnsActive, on_appear)]
def free_spawns_active_update_on_team_spawn_active_change(evt : Event; team__freeTankSpawnsActive : bool; team__id : int)
  query() <| $ [es(REQUIRE=vehicleRespbase, REQUIRE_NOT=freeTankRespawnTag)] (team : int;
                                                                              respawnbaseType : string;
                                                                              linkedFreeTankRespawnEid : EntityId;
                                                                              active : bool)
    if team == team__id && respawnbaseType == "vehicle"
      setOptional(linkedFreeTankRespawnEid, "active", active && team__freeTankSpawnsActive)

[es(track=active, REQUIRE=vehicleRespbase, REQUIRE_NOT=freeTankRespawnTag)]
def update_linked_free_spawn_spawn_on_normal_spawn_update(evt : Event; team : int; linkedFreeTankRespawnEid : EntityId; active : bool; respawnbaseType : string)
  find_query() <| $ [es] (team__id : int; team__freeTankSpawnsActive : bool)
    if team__id != team || respawnbaseType != "vehicle"
      return false
    setOptional(linkedFreeTankRespawnEid, "active", active && team__freeTankSpawnsActive)
    return true

[es(tag=server, on_appear, REQUIRE=vehicleRespbase, REQUIRE_NOT=freeTankRespawnTag)]
def create_free_respawn_base_on_tank_respawn_base_appear(evt : Event;
                                                         team : int;
                                                         groupName : string;
                                                         respawnbaseType : string;
                                                         maxVehicleOnSpawn : int;
                                                         transform : float3x4;
                                                         var linkedFreeTankRespawnEid : EntityId&)
  if (find_query() <| $ [es(REQUIRE=isPractice)] () => true)
    return
  if (find_query() <| $ [es(REQUIRE=isTutorial)] () => true)
    return
  if respawnbaseType != "vehicle"
    return
  find_query() <| $ [es] (team__id : int; var team__freeTankRespawnGroupNames : Object&)
    if team != team__id
      return false
    var newSpawnBaseGroup = (get_int(team__freeTankRespawnGroupNames, groupName) ?? -1)
    if newSpawnBaseGroup == -1
      newSpawnBaseGroup = get_new_respawn_group(team)
      if newSpawnBaseGroup == -1
        newSpawnBaseGroup = 1
    set(team__freeTankRespawnGroupNames, groupName, newSpawnBaseGroup)

    linkedFreeTankRespawnEid = createEntity("respawnChooser+resp_free_tank") <| $(var init : ComponentsInitializer)
      set(init, "transform", transform)
      set(init, "team", team)
      set(init, "active", false)
      set(init, "groupName", groupName)
      set(init, "respawnBaseGroup", newSpawnBaseGroup)
      set(init, "maxVehicleOnSpawn", maxVehicleOnSpawn)
    return true

[es(on_appear, tag=gameClient, REQUIRE=respawn_icon__freeTankSpawn)]
def set_initial_pos_for_free_tank_spawn_icon(evt : Event; team : int; var initialPos : float3&; var transform : float3x4)
  initialPos = transform[3]
  transform[3] = initialPos + float3(20, 0, 0)
  find_query() <| $ [es] (respawnCameraForTeam : int;
                          respawnCameraLookFromSide : float3)
    if respawnCameraForTeam == team
      let lookPos = get_above_camera_target()
      var dir = float3(lookPos.x, 0, lookPos.y) - respawnCameraLookFromSide
      dir[1] = 0.
      let offset = normalize(cross(dir, float3(0f, 1f, 0f))) * 20.
      transform[3] = initialPos + offset
      return true
    return false

[es(tag=gameClient, track=respawnCameraLookFromSide)]
def move_side_free_tank_respawn_icon_on_camera_move(evt : Event;
                                                    respawnCameraForTeam : int;
                                                    respawnCameraLookFromSide : float3)
  let lookPos = get_above_camera_target()
  var dir = float3(lookPos.x, 0, lookPos.y) - respawnCameraLookFromSide
  dir[1] = 0.
  let offset = normalize(cross(dir, float3(0f, 1f, 0f))) * 20.
  query() <| $ [es(REQUIRE=respawn_icon__freeTankSpawn)] (var transform : float3x4; initialPos : float3; team : int)
    if respawnCameraForTeam == team
      transform[3] = initialPos + offset
