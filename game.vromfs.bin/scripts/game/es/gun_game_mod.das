require ecs
require app
require DagorSystem
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require enlisted.game.es.offender_cache_common
require HumanPhys
require game.utils.team
require game.utils.sound_utils
require game.utils.net_utils
require DagorRandom
require game.events_game
require enlisted.events_enlisted
require ecs.safe
require DngHuman
require Grid
require DagorMath
require game.es.awards_common
require DngNet
require ecs.common
require game.es.events
require DagorRandom
require game.es.respawn_base_common
require DngDm
require AnimV20

def broadcast_levelup_sound(possessed : EntityId; sound : string)
  send_net_event(possessed, CharsGungameLevelUpSound(sound = sound, isHero = true), target_entity_conn(possessed))
  find_query() <| $ [es] (gun_game__leaderPlayerEid : EntityId)
    if (get_Eid(gun_game__leaderPlayerEid, "possessed") ?? INVALID_ENTITY_ID) == possessed
      send_net_event(possessed, CharsGungameLevelUpSound(sound = sound, isHero = false), enum_connections_except_target(possessed))
    return true

[es(tag=server, on_appear, REQUIRE=possessed,
    on_event=EventApplyDevMode)]
def init_player_for_gun_game_mode(evt : Event;
                                  var squads__revivePointsAfterDeath : int&;
                                  var respawner__respTime : float&;
                                  var squads__respawnPenaltyTimeThreshold : float&;
                                  var respawner__respawnWhenInactiveTimeout : float&;
                                  var respawner__respawnGroupId : int&;
                                  var respawner__canSpawnMinTime : float&;
                                  var respawner__missionStartDelay : float&;
                                  var respawner__respEndTime : float&)
  if (find_query() <| $ [es(REQUIRE=gunGameModeLogic)] () => true)
    squads__respawnPenaltyTimeThreshold = 0.0
    respawner__respTime = 0.0
    respawner__respawnWhenInactiveTimeout = 0.0
    respawner__canSpawnMinTime = 0.0
    squads__revivePointsAfterDeath = 100
  if (find_query() <| $ [es(REQUIRE=charsGunGameModeLogic)] () => true)
    respawner__missionStartDelay = 0.0
    respawner__respEndTime = 0.0
    respawner__respawnGroupId = get_respawn_group()

[es(tag=server, on_appear)]
def init_player_for_chars_gun_game(evt : Event;
                                   var chars_gun_game_player__currentGroup : int&;
                                   var chars_gun_game_player__currentCharId : int&;
                                   var chars_gun_game_player__currentGroupAvailableCharIds : IntList&)
  find_query() <| $ [es] (chars_gun_game__charsInGroupsCounts : IntList)
    chars_gun_game_player__currentGroup = 0
    for idx in range(chars_gun_game__charsInGroupsCounts[chars_gun_game_player__currentGroup])
      push(chars_gun_game_player__currentGroupAvailableCharIds, idx)
    let randInd = rnd_int(0, length(chars_gun_game_player__currentGroupAvailableCharIds) - 1)
    chars_gun_game_player__currentCharId = chars_gun_game_player__currentGroupAvailableCharIds[randInd]
    erase(chars_gun_game_player__currentGroupAvailableCharIds, randInd)
    return true

[es(tag=server, before=(human_weap_created_server_es, human_weapon_init_es, init_soldier_equipment), on_appear, track=squad_member__playerEid, REQUIRE=human, REQUIRE_NOT=charsGunGameSoldierTag)]
def add_chars_gun_game_subtemplate(evt : Event; eid : EntityId; squad_member__playerEid : EntityId)
  if !squad_member__playerEid
    return
  find_query() <| $ [es(REQUIRE=charsGunGameModeLogic)]
    remote_add_sub_template(eid, "chars_gun_game_soldier")
    return true

[es(tag=server, on_appear, REQUIRE=charsGunGameSoldierTag, track=squad_member__playerEid)]
def init_soldier_equipment(evt : Event; eid : EntityId; squad_member__playerEid : EntityId)
  if !squad_member__playerEid
    return
  find_query() <| $ [es(REQUIRE=charsGunGameModeLogic)]
    chars_gun_game_init_weapon(eid)
    chars_gun_game_init_equip(eid, squad_member__playerEid)
    query(squad_member__playerEid) <| $ [es] (chars_gun_game_player__currentCharSound : string;
                                              scoring_player__squadDeaths : int)
      if scoring_player__squadDeaths == 0
        broadcast_levelup_sound(eid, chars_gun_game_player__currentCharSound)
    return true

[es(tag=server, on_appear, REQUIRE=charsGunGameModeLogic)]
def init_chars_gun_game_mod(evt : Event;
                            chars_gun_game__groups : Array;
                            var gun_game__levelsCount : int&;
                            var chars_gun_game__groupsCount : int&;
                            var chars_gun_game__charsInGroupsCounts : IntList&)
  clear(chars_gun_game__charsInGroupsCounts)
  chars_gun_game__groupsCount = length(chars_gun_game__groups)
  gun_game__levelsCount = 0
  for group in chars_gun_game__groups
    let groupArray = get_ecs_array(group)
    if groupArray == null
      logerr("Bad gun game chars group")
      return
    let groupSize = length(*groupArray)
    push(chars_gun_game__charsInGroupsCounts, groupSize)
    gun_game__levelsCount += groupSize

[es(tag=server, on_appear, REQUIRE=respbase, before=respawn_bases_check_group_es)]
def count_respbase_in_chars_gungame_mode(evt : Event; eid : EntityId; var respawnBaseGroup : int&)
  find_query() <| $ [es] (var chars_gun_game__allRespawns : EidList&;
                          var chars_gun_game__availableRespawns : EidList&;
                          var chars_gun_game__respawnsAvailableTime : FloatList&)
    push(chars_gun_game__allRespawns, eid)
    push(chars_gun_game__availableRespawns, eid)
    push(chars_gun_game__respawnsAvailableTime, 0.)
    respawnBaseGroup = length(chars_gun_game__allRespawns)
    return true

let RESP_BLOCK_HEIGHT = 3.

[es(tag=server, no_order)]
def update_respawns_availability(info : UpdateStageInfoAct;
                                 var chars_gun_game__respawnsNextCheckTime : float&;
                                 chars_gun_game__respawsCheckInterval : float;
                                 chars_gun_game__respawnsAvailableTime : FloatList&;
                                 chars_gun_game__allRespawns : EidList;
                                 var chars_gun_game__availableRespawns : EidList&)
  if info.curTime < chars_gun_game__respawnsNextCheckTime
    return
  chars_gun_game__respawnsNextCheckTime = info.curTime + chars_gun_game__respawsCheckInterval
  clear(chars_gun_game__availableRespawns)
  for respEid, respInd in chars_gun_game__allRespawns, range(length(chars_gun_game__respawnsAvailableTime))
    if info.curTime < chars_gun_game__respawnsAvailableTime[respInd]
      continue
    query(respEid) <| $ [es] (gun_game__respawnFriendlyRadius : float; transform aka resp_transform : float3x4)
      var blockResp = false
      let distSq = gun_game__respawnFriendlyRadius * gun_game__respawnFriendlyRadius
      find_query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (transform aka soldier_transform : float3x4)
        blockResp = distance_sq(soldier_transform[3].xz, resp_transform[3].xz) < distSq && abs(soldier_transform[3].y - resp_transform[3].y) < RESP_BLOCK_HEIGHT
        return blockResp
      if !blockResp
        push(chars_gun_game__availableRespawns, respEid)

def get_respawn_group()
  var groupId = -1
  find_query() <| $ [es] (var chars_gun_game__availableRespawns : EidList&;
                          chars_gun_game__respawnsCooldown : float;
                          chars_gun_game__allRespawns : EidList;
                          var chars_gun_game__respawnsAvailableTime : FloatList&)
    if length(chars_gun_game__availableRespawns) == 0
      let respInd = rnd_int(0, length(chars_gun_game__allRespawns) - 1)
      groupId = *get_int(chars_gun_game__allRespawns[respInd], "respawnBaseGroup")
    else
      let respIndInAvailables = rnd_int(0, length(chars_gun_game__availableRespawns) - 1)
      let respEid = chars_gun_game__availableRespawns[respIndInAvailables]
      erase(chars_gun_game__availableRespawns, respIndInAvailables)

      groupId = *get_int(respEid, "respawnBaseGroup")
      let respIndInAll = find_index(chars_gun_game__allRespawns, respEid)
      if respIndInAll >= 0
        chars_gun_game__respawnsAvailableTime[respIndInAll] = get_sync_time() + chars_gun_game__respawnsCooldown
    return true
  return groupId

[es(tag=server, no_order)]
def choose_respawn_for_next_spawn(info : UpdateStageInfoAct;
                                  respawner__enabled : bool;
                                  chars_gun_game_player__currentCharId : int;
                                  var respawner__respRequested : bool&;
                                  var respawner__respawnGroupId : int&)
  if respawner__enabled && chars_gun_game_player__currentCharId != -1 && (find_query() <| $ [es(REQUIRE=charsGunGameModeLogic)] () => true)
    respawner__respRequested = true
    if respawner__respawnGroupId == -1
      respawner__respawnGroupId = get_respawn_group()

[es(tag=server, track=possessedByPlr, after=init_soldier_equipment, on_appear, REQUIRE=charsGunGameSoldierTag)]
def reset_respawn_group_on_soldier_spawn(evt : Event; possessedByPlr : EntityId)
  query(possessedByPlr) <| $ [es] (var respawner__respawnGroupId : int&)
    respawner__respawnGroupId = -1

[es(tag=server, on_appear, REQUIRE=gunGameModeLogic, REQUIRE_NOT=charsGunGameModeLogic)]
def init_gun_game_mod(evt : Event;
                      var gun_game__levelsCount : int&;
                      var gun_game__levels : Array&)
  gun_game__levelsCount = length(gun_game__levels)
  for level in gun_game__levels
    var levelObj = getRW_ecs_object(level)
    if levelObj != null
      let listOfWeap = get_ecs_StringList(*levelObj, "weapons")
      let listOfAmmo = get_ecs_StringList(*levelObj, "ammoTemplates")

      let additionalInfo = (levelObj?.additionalWeapInfo)

      if listOfWeap != null
        let weaponsCount = length(*listOfWeap)
        let selector = rnd_int(0, weaponsCount - 1)

        if additionalInfo != null
          let listOfAdditionalInfo = *additionalInfo as Array
          *levelObj |> set("selectedAdditionalInfo", (*listOfAdditionalInfo)[selector])

        let weaponTemplateName = string((*listOfWeap)[selector])
        *levelObj |> set("selectedSessionWeapon", weaponTemplateName)
        if listOfAmmo != null
          *levelObj |> set("selectedSessionAmmo", (*listOfAmmo)[selector])
        else
          let ammoTemplate = getTemplateByName(weaponTemplateName)
          if ammoTemplate != null
            let holdersArray = getTemplateComponent(*ammoTemplate, "gun__ammoHolders") ?as Array
            if holdersArray != null && length(*holdersArray) > 0
              *levelObj |> set("selectedSessionAmmo", (*holdersArray)[0])

def clear_player_item_container(var itemContainer : EidList)
  for itemEid in itemContainer
    if has(itemEid, "ammo_holder__id")
      let ind = find_index(itemContainer, itemEid)
      if ind >= 0
        erase(itemContainer, ind)
      destroyEntity(itemEid)

def reset_human_weap_info_templates_for_slot(slot_id : int; var weap_templates : Object; var gun_mods_by_slot : Array; var weap_info : Array)
  let weaponSlotName = get_human_weapon_slot_name(slot_id)

  let gunsCount = min(int(HUWeaponSlots.EWS_NUM), length(gun_mods_by_slot))
  for i in range(gunsCount)
    var gunMods = gun_mods_by_slot[i] as Object
    if gunMods != null
      *gunMods |> clear()

  weap_templates |> set(weaponSlotName, "")
  var weapInfoSlot = weap_info[slot_id] |> getRW_ecs_object()
  if weapInfoSlot != null
    *weapInfoSlot |> clear()
    *weapInfoSlot |> set("numReserveAmmo", 0)
    *weapInfoSlot |> set("reserveAmmoTemplate", "")

def gun_game_init_level(eid : EntityId;
                        squad_member__playerEid : EntityId;
                        var human_inventory__dropsLoot : bool&;
                        var human_net_phys : HumanActor;
                        var itemContainer : EidList;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunModsBySlot : Array;
                        var human_weap__weapInfo : Array)
  find_query() <| $ [es(REQUIRE=gunGameModeLogic, REQUIRE_NOT=charsGunGameModeLogic)] (gun_game__levels : Array&;
                                                                                       gun_game__levelsCount : int;
                                                                                       gun_game__finished : bool)
    human_inventory__dropsLoot = false
    if gun_game__finished
      return false

    clear_player_item_container(itemContainer)
    query(squad_member__playerEid) <| $ [es] (gun_game__currentLevel : int;
                                              var gun_game__currentLevelWeapSlot : int&;
                                              var gun_game__killsForNextLevelRequire : int&;
                                              var gun_game__killsForNextLevel : int&;
                                              var gun_game__levelPropsId : int&)
      if (gun_game__currentLevel >= gun_game__levelsCount)
        logerr("invalid level for player /*{squad_member__playerEid}*/ /*{gun_game__currentLevel}*/ >= /*{gun_game__levelsCount}*/")
        return
      let level = get_ecs_object(gun_game__levels[gun_game__currentLevel])
      if level != null
        var weapon = level?.selectedSessionWeapon ?? "knife"
        weapon = add_sub_template_name(weapon, "gun_game_mode_weapon_components")

        let ammo = level?.numReserveAmmo ?? 10
        gun_game__killsForNextLevelRequire = level?.levelKills ?? 2
        if (gun_game__killsForNextLevel <= 0)
          gun_game__killsForNextLevel = gun_game__killsForNextLevelRequire
        let ammoTemplate = level?.selectedSessionAmmo ?? ""

        let weaponSlotName = level?.weaponSlot ?? "primary"
        let slotId = int(HUWeaponSlots(weaponSlotName))

        if gun_game__currentLevelWeapSlot >= 0
          reset_human_weap_info_templates_for_slot(gun_game__currentLevelWeapSlot, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)

        human_weap__weapTemplates |> set(weaponSlotName, weapon)
        var weapInfoSlot = human_weap__weapInfo[slotId] |> getRW_ecs_object()
        if weapInfoSlot != null
          *weapInfoSlot |> set("numReserveAmmo", ammo)
          *weapInfoSlot |> set("reserveAmmoTemplate", ammoTemplate)
          let additionalInfo = level?.selectedAdditionalInfo
          if additionalInfo != null
            let additionalInfoObj = *additionalInfo as Object
            for kv in *additionalInfoObj
              *weapInfoSlot |> set(kv.key, kv.value)

        gun_game__levelPropsId = -1
        reset_weapon_state(human_net_phys.phys)
        sendEvent(eid, CmdReinitWeapons())
        sendEvent(eid, HumanWeapSetCurrentGun(slot = uint8(slotId)))
        gun_game__currentLevelWeapSlot = slotId
    return true

def chars_gun_game_init_weapon(soldier_eid : EntityId)
  query(soldier_eid) <| $ [es] (squad_member__playerEid : EntityId;
                                var human_inventory__dropsLoot : bool&;
                                var human_net_phys : HumanActor;
                                var itemContainer : EidList;
                                var human_weap__throwMode : bool&;
                                var human_weap__weapTemplates : Object;
                                var human_weap__gunModsBySlot : Array;
                                var human_weap__weapInfo : Array)
    find_query() <| $ [es(REQUIRE=charsGunGameModeLogic)] (chars_gun_game__groups : Array&)
      human_inventory__dropsLoot = false
      human_weap__throwMode = false
      clear_player_item_container(itemContainer)
      query(squad_member__playerEid) <| $ [es] (chars_gun_game_player__currentCharId : int;
                                                chars_gun_game_player__currentGroup : int;
                                                var gun_game__killsForNextLevelRequire : int&;
                                                var gun_game__killsForNextLevel : int&)
        let group = get_ecs_array(chars_gun_game__groups[chars_gun_game_player__currentGroup])
        let currentCharInfo = get_ecs_object((*group)[chars_gun_game_player__currentCharId])

        gun_game__killsForNextLevelRequire = currentCharInfo?.levelKills ?? 2
        if (gun_game__killsForNextLevel <= 0)
          gun_game__killsForNextLevel = gun_game__killsForNextLevelRequire

        let weapons = get_ecs_array(currentCharInfo, "weapons")
        var newSlot = -1

        for slot in each_enum(HUWeaponSlots.EWS_PRIMARY)
          if int(slot) >= length(human_weap__weapInfo)
            break
          reset_human_weap_info_templates_for_slot(int(slot), human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)

        for weapon in *weapons
          let weaponObj = get_ecs_object(weapon)
          var weaponTempl = weaponObj?.gametemlpate ?? "knife"
          weaponTempl = add_sub_template_name(weaponTempl, "chars_gun_game_mode_weapon_components")

          let ammo = weaponObj?.numReserveAmmo ?? 5
          let ammoTemplate = weaponObj?.ammoTemplate ?? ""

          let weaponSlotName = weaponObj?.weaponSlot ?? "primary"
          let slotId = int(HUWeaponSlots(weaponSlotName))

          if newSlot == -1
            newSlot = slotId

          human_weap__weapTemplates |> set(weaponSlotName, weaponTempl)
          var weapInfoSlot = human_weap__weapInfo[slotId] |> getRW_ecs_object()
          if weapInfoSlot != null
            *weapInfoSlot |> set("numReserveAmmo", ammo)
            *weapInfoSlot |> set("reserveAmmoTemplate", ammoTemplate)
            let additionalInfo = weaponObj?.additionalWeapInfo
            if additionalInfo != null
              let additionalInfoObj = *additionalInfo as Object
              for kv in *additionalInfoObj
                *weapInfoSlot |> set(kv.key, kv.value)

        reset_weapon_state(human_net_phys.phys)
        sendEvent(soldier_eid, CmdReinitWeapons())
        sendEvent(soldier_eid, HumanWeapSetCurrentGun(slot = uint8(newSlot)))
        send_net_event(squad_member__playerEid, CharsGungameSetCurrentMainSlot(slotId = uint8(newSlot)))
      return true

[es(tag=gameClient)]
def gun_game_get_cur_main_slot(evt : CharsGungameSetCurrentMainSlot;
                               var chars_gun_game_player__curMainGunSlot : int&)
  chars_gun_game_player__curMainGunSlot = int(evt.slotId)

[es(tag=gameClient, REQUIRE=(hero, charsGunGameSoldierTag))]
def gun_game_switch_weapon(info : ParallelUpdateFrameDelayed;
                           human_weap__gunEids : EidList;
                           possessedByPlr : EntityId;
                           var human_weap__throwMode : bool&;
                           var human_net_phys : HumanActor&)
  query(possessedByPlr) <| $ [es] (var chars_gun_game_player__curMainGunSlot : int&)
    if chars_gun_game_player__curMainGunSlot < 0 || chars_gun_game_player__curMainGunSlot > length(human_weap__gunEids)
      return
    if !human_weap__gunEids[chars_gun_game_player__curMainGunSlot]
      return
    human_weap__throwMode = false
    set_chosen_weapon(human_net_phys.phys.producedCT, HUWeaponSlots(chars_gun_game_player__curMainGunSlot))
    reset_weapon_state(human_net_phys.phys)
    chars_gun_game_player__curMainGunSlot = -1

[es(tag=server, on_appear, track=gun__owner, REQUIRE=gunGameModeWeapon)]
def init_weapon_for_gun_game_mode(evt : Event;
                                  gun__owner : EntityId;
                                  gun__propsId : int)
  query(gun__owner) <| $ [es] (squad_member__playerEid : EntityId)
    query(squad_member__playerEid) <| $ [es] (var gun_game__levelPropsId : int&)
      gun_game__levelPropsId = gun__propsId

[es(tag=server, on_appear, track=gun__owner, after=gun_load_props_es, REQUIRE=charsGunGameModeWeapon)]
def init_weapon_for_chars_gun_game_mode(evt : Event;
                                        gun__owner : EntityId;
                                        gun__propsId : int)
  query(gun__owner) <| $ [es] (squad_member__playerEid : EntityId)
    query(squad_member__playerEid) <| $ [es] (var chars_gun_game_player__levelPropsIds : IntList&)
      push(chars_gun_game_player__levelPropsIds, gun__propsId)

def gun_game_init_level(eid : EntityId)
  query(eid) <| $ [es] (squad_member__playerEid : EntityId;
                        var human_inventory__dropsLoot : bool&;
                        var human_net_phys : HumanActor;
                        var itemContainer : EidList;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunModsBySlot : Array;
                        var human_weap__weapInfo : Array)
    gun_game_init_level(eid, squad_member__playerEid, human_inventory__dropsLoot, human_net_phys, itemContainer, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)


[es(tag=server, before=(human_weap_created_server_es, human_weapon_init_es), on_appear, track=squad_member__playerEid, REQUIRE=human)]
def init_soldier_for_gun_game_mod(evt : Event;
                                  eid : EntityId;
                                  squad_member__playerEid : EntityId;
                                  var human_inventory__dropsLoot : bool&;
                                  var human_net_phys : HumanActor;
                                  var itemContainer : EidList;
                                  var human_weap__weapTemplates : Object;
                                  var human_weap__gunModsBySlot : Array;
                                  var human_weap__weapInfo : Array)
  if !squad_member__playerEid
    return
  gun_game_init_level(eid, squad_member__playerEid, human_inventory__dropsLoot, human_net_phys, itemContainer, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)

[es(tag=server, on_event=EventFirstPlayerSpawned, REQUIRE=gunGameModeLogic, REQUIRE_NOT=charsGunGameModeLogic)]
def gun_game_start_timer(evt : Event;
                         gun_game__resetSpawnsTimeout : float;
                         var gun_game__resetSpawnsAtTime : float&)
  gun_game__resetSpawnsAtTime = get_sync_time() + gun_game__resetSpawnsTimeout

[es(tag=server, no_order, REQUIRE=gunGameModeLogic, REQUIRE_NOT=charsGunGameModeLogic)]
def gun_game_reset_spawn_team_timer(info : UpdateStageInfoAct;
                                    gun_game__resetSpawnsAtTime : float)
  if info.curTime < gun_game__resetSpawnsAtTime || gun_game__resetSpawnsAtTime < 0.
    return
  var team1SpawnExist = false
  var team2SpawnExist = false
  query() <| $ [es(REQUIRE=respbase)] (gun_game__respawnFriendlyRadius : float;
                                       transform : float3x4;
                                       var team aka respawn_team : int&)
    let respawnBasePos = transform[3]
    respawn_team = TEAM_UNASSIGNED
    find_entity_in_grid(ecs_hash("humans"), BSphere3(respawnBasePos, gun_game__respawnFriendlyRadius), GridEntCheck.POS) <| $(eid : EntityId)
      var conflictTeamsFound = false
      query(eid) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int)
        if respawn_team != TEAM_UNASSIGNED && respawn_team != team
          respawn_team = 3 //invalid base team for gun game mode
          conflictTeamsFound = true
          return
        respawn_team = team
      return conflictTeamsFound
    if respawn_team == TEAM_UNASSIGNED
      team1SpawnExist = true
      team2SpawnExist = true
    else
      team1SpawnExist ||= respawn_team == 1
      team2SpawnExist ||= respawn_team == 2
  if !team1SpawnExist || !team2SpawnExist
    find_query() <| $ [es(REQUIRE=respbase)] (var team aka respawn_team : int&)
      respawn_team = TEAM_UNASSIGNED
      return true

def broadcast_new_leader(old_leader : EntityId; new_leader : EntityId)
  broadcast_net_event(EventGunGameNewLeader(
    oldLeaderPlayerEid = old_leader, newLeaderPlayerEid = new_leader))

def broadcast_level_reach(leader : EntityId; level : int)
  broadcast_net_event(EventGunGameLevelReached(
    playerEid = leader, level = level))

[es(tag=render)]
def create_chars_change_effect(evt : CharsGunGameEffect; eid : EntityId; transform : float3x4)
  createEntity("event_gungame_change_effect") <| $(var init)
    var tm = transform
    tm[3] += transform[0] * 0.4
    init |> set("transform", tm)
    init |> set("event_gungame_change_effect__attachedTo", eid)

[es(tag=render, no_order)]
def chars_change_effect_update(info : UpdateStageInfoAct;
                               event_gungame_change_effect__attachedTo : EntityId;
                               var transform aka effect_transform : float3x4&)
  query(event_gungame_change_effect__attachedTo) <| $ [es] (transform aka soldier_transform : float3x4)
    effect_transform[3] = soldier_transform[3]
    effect_transform[3] += soldier_transform[0] * 0.4

[es(tag=server, on_appear)]
def damaging_throwable_set_disappear_time(evt : Event;
                                          var damaging_throwable__deathTime : float&;
                                          damaging_throwable__lifeTime : float)
  damaging_throwable__deathTime = get_sync_time() + damaging_throwable__lifeTime

[es(REQUIRE=hiddenThrowerProjectile)]
def set_throwable_anim_var_id(info : ParallelUpdateFrameDelayed;
                              eid : EntityId;
                              grenade__selectedWeaponVar : string)
  find_query() <| $ [es] (grenade_thrower__projectileEntity : EntityId;
                          var grenade_thrower__selectedGrenadeVarId : int&)
    if grenade_thrower__projectileEntity == eid
      grenade_thrower__selectedGrenadeVarId = animV20_add_enum_value(grenade__selectedWeaponVar)
      return true
    return false

[es(tag=server, track=(isAlive, isDowned), on_event=EventEntityDied, before=destroy_nonlootable_weapons, REQUIRE=charsGunGameSoldierTag)]
def destroy_throwable_item_on_death(evt : Event;
                                    isAlive : bool;
                                    isDowned : bool;
                                    human_weap__gunEids : EidList;
                                    var human_weap__throwMode : bool&)
  if isAlive && !isDowned
    return

  if human_weap__throwMode
    human_weap__throwMode = false
    query(human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]) <| $ [es] (grenade_thrower__projectileEntity : EntityId)
      if has(grenade_thrower__projectileEntity, "hiddenThrowerProjectile")
        destroyEntity(grenade_thrower__projectileEntity)

[es(tag=server)]
def damaging_throwable_destroy(evt : CmdPostPhysUpdate;
                               eid : EntityId;
                               damaging_throwable__deathTime : float)
  if damaging_throwable__deathTime > 0. && get_sync_time() > damaging_throwable__deathTime
    destroyEntity(eid)

[es(tag=server)]
def damaging_throwable_hit(evt : EventOnCollision;
                           shell__gun_props_id : int;
                           damaging_throwable__damageMinSpeed : float;
                           var damaging_throwable__damageDone : bool&;
                           shell__owner : EntityId)
  if damaging_throwable__damageDone || shell__owner == evt.offender || length(evt.pvel) < damaging_throwable__damageMinSpeed
    return
  damaging_throwable__damageDone = true
  query(evt.offender) <| $ [es(REQUIRE=human)] (eid : EntityId)
    sendEvent(eid, CmdKill(offender = shell__owner, damageType = uint16(int(DamageType.DM_MELEE)), gunPropsId = shell__gun_props_id, shellId = -1))
    query(shell__owner) <| $ [es] (possessedByPlr : EntityId;
                                   guid : string)
      add_award(possessedByPlr, "kill_by_throwable")
      send_award_stat(possessedByPlr, guid, "killByThrowable")

[es(tag=server, REQUIRE=gunGameModeLogic, REQUIRE_NOT=charsGunGameModeLogic)]
def gun_game_mode_score(evt : EventAnyEntityDied;
                        gun_game__levelsCount : int;
                        gun_game__announceLevelReach : IntList;
                        var gun_game__finished : bool&;
                        var gun_game__leaderLevel : int&;
                        var gun_game__leaderPlayerEid : EntityId&)
  if gun_game__finished
    return
  assume victimEid = evt.victim
  assume offenderEid = evt.offender
  let offenderInfo = get_offender_from_cache(offenderEid)
  let victimInfo = get_offender_from_cache(victimEid)
  query(offenderInfo.player) <| $ [es] (team : int;
                                        possessed : EntityId;
                                        var gun_game__levelPropsId : int&;
                                        var gun_game__currentLevel : int&;
                                        var gun_game__killsForNextLevel : int&)
    if evt.gunPropsId >= 0 && gun_game__levelPropsId != evt.gunPropsId
      return

    let isFriendly = is_teams_friendly(team, get_int(victimInfo.player, "team") ?? TEAM_UNASSIGNED)
    if isFriendly
      return
    gun_game__killsForNextLevel--
    if (gun_game__killsForNextLevel <= 0)
      let nextGunGameLevel = gun_game__currentLevel + 1
      send_award_stat(offenderInfo.player, offenderInfo.guid, "gunGameLevelup")

      if nextGunGameLevel >= gun_game__levelsCount
        broadcastEvent(EventTeamWon(team = team))
        gun_game__finished = true
        return

      gun_game__currentLevel = nextGunGameLevel
      gun_game__levelPropsId = -1

      if gun_game__currentLevel > gun_game__leaderLevel
        gun_game__leaderLevel = gun_game__currentLevel
        if gun_game__leaderPlayerEid != offenderInfo.player
          broadcast_new_leader(gun_game__leaderPlayerEid, offenderInfo.player)
          gun_game__leaderPlayerEid = offenderInfo.player
        if gun_game__announceLevelReach |> has_value(gun_game__leaderLevel)
          broadcast_level_reach(gun_game__leaderPlayerEid, gun_game__leaderLevel)

      send_scene_net_sound(offenderEid, "gunGameNextLevel")

      find_query() <| $ [es] (team__id : int;
                              var team__gunGameLevel : int&)
        if team == team__id
          if gun_game__currentLevel > team__gunGameLevel
            team__gunGameLevel = gun_game__currentLevel
          return true
        return false
      gun_game_init_level(possessed)

def chars_gun_game_init_equip(soldier_eid : EntityId; player_eid : EntityId)
  query(soldier_eid) <| $ [es] (human_equipment__slots : Object;
                                var human_equipment__equipForCreateCount : int&;
                                var human_equipment__equipSlotsForDestroy : EidList&)
    find_query() <| $ [es] (chars_gun_game__groups : Array;
                            gun_game__leaderPlayerEid : EntityId;
                            var chars_gun_game__leaderIcon : das_string&)
      query(player_eid) <| $ [es] (var chars_gun_game_player__currentCharIcon : das_string&;
                                   var chars_gun_game_player__currentCharSound : das_string&;
                                   var decorators__portrait : das_string&;
                                   chars_gun_game_player__currentGroup : int;
                                   chars_gun_game_player__currentCharId : int)
        let group = get_ecs_array(chars_gun_game__groups[chars_gun_game_player__currentGroup])
        let currentCharInfo = get_ecs_object((*group)[chars_gun_game_player__currentCharId])
        let equipments = get_ecs_object(*currentCharInfo, "equipment")

        let charIcon = get_ecs_string(*currentCharInfo, "icon") ?? ""
        chars_gun_game_player__currentCharIcon := charIcon
        decorators__portrait := charIcon
        chars_gun_game_player__currentCharSound := (get_ecs_string(*currentCharInfo, "sound") ?? "")
        if gun_game__leaderPlayerEid == player_eid
          chars_gun_game__leaderIcon := charIcon

        clear(human_equipment__equipSlotsForDestroy)
        for oldEquip in human_equipment__slots
          let itemEid = get_ecs_object(oldEquip.value)?.item ?? INVALID_ENTITY_ID
          if itemEid != INVALID_ENTITY_ID
            push(human_equipment__equipSlotsForDestroy, itemEid)

        human_equipment__equipForCreateCount = 0
        for equipElem in *equipments
          let slot_name = equipElem.key

          var equipTempl = get_string(equipElem.value, "")
          if getTemplateByName(equipTempl) == null
            logerr("bad templ /*{equipTempl}*/")
            continue

          equipTempl = add_sub_template_name(equipTempl, "equip_for_swap")
          let finalizeCreation <- @ <| (itemEid : EntityId)
            sendEventImmediate(soldier_eid, CmdEquipItemDirect(itemEid = itemEid, slot = slot_name, allowReorderSlots = false, dropPrevItem = false))

          human_equipment__equipForCreateCount += 1
          createEntity(equipTempl, finalizeCreation) <| $(var init : ComponentsInitializer)
            set(init, "item__lastOwner", soldier_eid)
            set(init, "item__ownerEid", soldier_eid)
            set(init, "skeleton_attach__attached", true)
            set(init, "animchar_attach__attachedTo", soldier_eid)
      return true

[es(tag=gameClient)]
def additional_update_frames_for_attaches_after_clothes_change(evt : CmdSetAdditionalUpdateFrames; var attaches_list__additionalUpdateFrames : int&)
  attaches_list__additionalUpdateFrames = evt.framesCount

[es(tag=server, after=(equip_item_direct, equip_item))]
def destroy_prev_equip_component(evt : CmdEquipItemDirect;
                                 eid : EntityId;
                                 var human_equipment__slots : Object&;
                                 var human_equipment__equipForCreateCount : int&;
                                 var human_equipment__equipSlotsForDestroy : EidList&)
  if !has(evt.itemEid, "equipForSwap")
    return
  var itemObj = getRW_ecs_object(human_equipment__slots, evt.slot)
  let prevItem = (*itemObj).item ?? INVALID_ENTITY_ID
  destroyEntity(prevItem)
  set(*itemObj, "item", evt.itemEid)
  human_equipment__equipForCreateCount -= 1
  if human_equipment__equipForCreateCount <= 0 && length(human_equipment__equipSlotsForDestroy) > 0
    for equipForDestroySlot in human_equipment__equipSlotsForDestroy
      destroyEntity(equipForDestroySlot)
    clear(human_equipment__equipSlotsForDestroy)
    send_net_event(eid, CmdSetAdditionalUpdateFrames(framesCount = 4))

[es(tag=server, REQUIRE=charsGunGameModeLogic)]
def chars_gun_game_mode_score(evt : EventAnyEntityDied;
                              chars_gun_game__groupsCount : int;
                              chars_gun_game__charsInGroupsCounts : IntList;
                              var chars_gun_game__leaderTotalPoints : int&;
                              var chars_gun_game__winnerTeam : int&;
                              var gun_game__finished : bool&;
                              var gun_game__leaderLevel : int&;
                              var gun_game__leaderPlayerEid : EntityId&)
  if gun_game__finished || evt.victim == evt.offender
    return
  assume victimEid = evt.victim
  assume offenderEid = evt.offender
  let offenderInfo = get_offender_from_cache(offenderEid)
  let victimInfo = get_offender_from_cache(victimEid)
  query(offenderInfo.player) <| $ [es] (team : int;
                                        possessed : EntityId;
                                        var chars_gun_game_player__victims : EidList&;
                                        var chars_gun_game_player__levelPropsIds : IntList&;
                                        var gun_game__killsForNextLevel : int&;
                                        var gun_game__currentLevel : int&;
                                        var chars_gun_game_player__pointsNeedToLead : int&;
                                        var chars_gun_game_player__totalPoints : int&;
                                        var chars_gun_game_player__currentCharId : int&;
                                        var chars_gun_game_player__currentGroupAvailableCharIds : IntList&;
                                        var chars_gun_game_player__currentGroup : int&)
    if evt.gunPropsId >= 0 && (find_index(chars_gun_game_player__levelPropsIds, evt.gunPropsId) == -1)
      return
    if find_index(chars_gun_game_player__victims, victimEid) != -1
      return
    push(chars_gun_game_player__victims, victimEid)

    var points = 1
    points = min(gun_game__killsForNextLevel, points)

    chars_gun_game_player__totalPoints += points
    gun_game__killsForNextLevel -= points

    if chars_gun_game_player__totalPoints > chars_gun_game__leaderTotalPoints
      chars_gun_game__leaderTotalPoints = chars_gun_game_player__totalPoints
      query() <| $ [es] (var chars_gun_game_player__pointsNeedToLead aka other_chars_gun_game_player__pointsNeedToLead : int&;
                         chars_gun_game_player__totalPoints aka other_chars_gun_game_player__totalPoints : int)
        other_chars_gun_game_player__pointsNeedToLead = chars_gun_game__leaderTotalPoints - other_chars_gun_game_player__totalPoints
      if gun_game__leaderPlayerEid != offenderInfo.player
        broadcast_new_leader(gun_game__leaderPlayerEid, offenderInfo.player)
        gun_game__leaderPlayerEid = offenderInfo.player
    chars_gun_game_player__pointsNeedToLead = chars_gun_game__leaderTotalPoints - chars_gun_game_player__totalPoints

    if (gun_game__killsForNextLevel > 0)
      return
    if length(chars_gun_game_player__currentGroupAvailableCharIds) == 0
      if chars_gun_game_player__currentGroup >= chars_gun_game__groupsCount - 1
        chars_gun_game__winnerTeam = team
        broadcastEvent(EventTeamWon(team = team))
        gun_game__finished = true
        return
     // send_award_stat(offenderInfo.player, offenderInfo.guid, "gunGameGroupup")
      chars_gun_game_player__currentGroup += 1
      for idx in range(chars_gun_game__charsInGroupsCounts[chars_gun_game_player__currentGroup])
        push(chars_gun_game_player__currentGroupAvailableCharIds, idx)
    else
      send_award_stat(offenderInfo.player, offenderInfo.guid, "gunGameLevelup")

    let randInd = rnd_int(0, length(chars_gun_game_player__currentGroupAvailableCharIds) - 1)
    chars_gun_game_player__currentCharId = chars_gun_game_player__currentGroupAvailableCharIds[randInd]
    erase(chars_gun_game_player__currentGroupAvailableCharIds, randInd)

    gun_game__currentLevel += 1

    if gun_game__currentLevel > gun_game__leaderLevel
      gun_game__leaderLevel = gun_game__currentLevel

    send_scene_net_sound(offenderEid, "gunGameNextLevel")

    find_query() <| $ [es] (team__id : int;
                            var team__gunGameLevel : int&)
      if team == team__id
        if gun_game__currentLevel > team__gunGameLevel
          team__gunGameLevel = gun_game__currentLevel
        return true
      return false

    chars_gun_game_init_weapon(possessed)
    chars_gun_game_init_equip(possessed, offenderInfo.player)
    clear(chars_gun_game_player__levelPropsIds)
    send_net_event(possessed, CharsGunGameEffect())
    let sound = get_string(offenderInfo.player, "chars_gun_game_player__currentCharSound", "")
    broadcast_levelup_sound(possessed, sound)
    //chars_gun_game_init_items(possessed)

[es(track=(gun__totalAmmo, gun__ammo), on_appear)]
def fast_swap_control_on_ammo_change(evt : Event;
                                     gun__totalAmmo : int;
                                     gun__ammo : int;
                                     var gun__fastSwapAvailable : bool&)
  gun__fastSwapAvailable = (gun__totalAmmo + gun__ammo) == 0

[es(tag=server, on_appear)]
def create_ammo_after_for_throwable(evt : Event;
                                    gun__owner : EntityId;
                                    hidden_fast_thrower__createItem : string)
  for _ in range(2)
    createEntity(hidden_fast_thrower__createItem) <| $(var init : ComponentsInitializer)
      set(init, "item__lastOwner", gun__owner)
      set(init, "item__ownerEid", gun__owner)

[es(tag=server)]
def create_ammo_after_throwable_launch(evt : CmdLaunchShell; eid : EntityId; human_weap__gunEids : EidList)
  for gunEid in human_weap__gunEids
    if evt.gunEid == gunEid
      query(gunEid) <| $ [es] (hidden_fast_thrower__createItem : string)
        createEntity(hidden_fast_thrower__createItem) <| $(var init : ComponentsInitializer)
          set(init, "item__lastOwner", eid)
          set(init, "item__ownerEid", eid)
      let backSwapSlot = get_int(gunEid, "gun__switchBackSlot") ?? -1
      if backSwapSlot >= 0
        sendEventImmediate(human_weap__gunEids[backSwapSlot], CmdLoadAmmo(ammoNum = 1))

def chars_gun_game_init_items(soldier_eid : EntityId)
  query(soldier_eid) <| $ [es] (squad_member__playerEid : EntityId)
    find_query() <| $ [es] (chars_gun_game__groups : Array)
      query(squad_member__playerEid) <| $ [es] (chars_gun_game_player__currentGroup : int;
                                                chars_gun_game_player__currentCharId : int)
        let group = get_ecs_array(chars_gun_game__groups[chars_gun_game_player__currentGroup])
        let currentCharInfo = get_ecs_object((*group)[chars_gun_game_player__currentCharId])
        let items = get_ecs_array(*currentCharInfo, "items")
        for itemTempl in *items
          createEntity(get_string(itemTempl, "")) <| $(var init : ComponentsInitializer)
            set(init, "item__ownerEid", soldier_eid)
      return true
