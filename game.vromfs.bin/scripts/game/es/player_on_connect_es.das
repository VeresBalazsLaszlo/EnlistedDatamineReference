require ecs
require app
require DngNet
require matching
require daslib/strings_boost
require game.es.player_events
require game.events_game
require game.utils.team
require game.es.net_scope_adder_common
require game.es.sandbox_config_common
require enlisted.game.utils.sandbox_state
require enlisted.game.es.player_group_common
require ecs.common
require game.utils.net_utils

let GROUP_LIMIT = 4

def try_to_assign_wish_team_by_command_line(userid : uint64) : int
  var res = TEAM_UNASSIGNED
  dgs_get_argv_all("team_for_userid") <| $(val : string)
    let team_id <- split_by_chars(val, ",")
    if to_uint64(team_id[0]) == userid
      res = to_int(team_id[1])
      return true
    return false
  return res

[es(REQUIRE=player, tag=server)]
def player_on_connect_script_es(evt : EventOnPlayerConnected;
                                eid aka owner_eid : EntityId;
                                possessed : EntityId;
                                userid : uint64 = INVALID_USER_ID;
                                connid : int = INVALID_CONNECTION_ID;
                                var groupId aka owner_groupId : int64&;
                                var team aka owner_team : int&;
                                var connectedAtTime : float&;
                                var startedAtTime : float&)
  var wishTeam = evt.wishTeam
  let reconnected = evt.reconnected
  let teamLocal = owner_team

  query() <| $ [es] (mission_specified_team_id : int;
                     mission_specified_team__ignoreMatchingTeam : bool)
    if (wishTeam == TEAM_UNASSIGNED && teamLocal == TEAM_UNASSIGNED) || mission_specified_team__ignoreMatchingTeam
      find_query() <| $ [es] (team__id : int)
        if team__id == mission_specified_team_id
          wishTeam = mission_specified_team_id
          return true
        return false

  if wishTeam == TEAM_UNASSIGNED && teamLocal != TEAM_UNASSIGNED
    wishTeam = teamLocal

  let cmdTeam = try_to_assign_wish_team_by_command_line(userid)
  if cmdTeam != TEAM_UNASSIGNED
    wishTeam = cmdTeam
    debug("Team {wishTeam} has been set for {userid} by command line")

  if is_sandbox_enabled()
    let sandboxTeam = sandbox_config_get_int("team", -1)
    if sandboxTeam != -1
      wishTeam = sandboxTeam
      debug("Team {wishTeam} has been set for {userid} by sandbox config")

  debug("Player {owner_eid} with team {teamLocal} and groupId {owner_groupId} has been connected and wish to join {wishTeam} team.")

  query() <| $ [es] (availableTeamStartFrom : int)
    if availableTeamStartFrom > 0 && wishTeam != TEAM_UNASSIGNED
      wishTeam += availableTeamStartFrom
      debug("Player {owner_eid} with team {owner_team} and groupId {owner_groupId} got a new {wishTeam} team. Because avaliable teams count starting from {availableTeamStartFrom}.")

  var openGroup = false
  var playerPartyGroupCount = 1
  var createOpenGroupVoiceChat = false
  find_query() <| $ [es] (players_groups_info : Object)
    let groupInfo = get_ecs_object(players_groups_info, string(owner_groupId))
    if groupInfo != null
      playerPartyGroupCount = get_int(groupInfo, "count") ?? playerPartyGroupCount
      openGroup = get_bool(groupInfo, "openGroup") ?? openGroup
    return true
  if !reconnected && (openGroup || playerPartyGroupCount > 1)
    find_query() <| $ [es] (player_group__wishTeam : int;
                            player_group__openGroup : bool;
                            var player_group__origGroupIds : IntList&;
                            var player_group__openGroupIsActive : bool&;
                            var player_group__membersCount : int&;
                            player_group__id : int64)
      let index = find_index(player_group__origGroupIds, int(owner_groupId))
      if (index != -1 || (openGroup && player_group__openGroup && (wishTeam == TEAM_UNASSIGNED || wishTeam == player_group__wishTeam) &&
          player_group__membersCount + playerPartyGroupCount <= GROUP_LIMIT))
        debug("GroupId for Player {owner_eid} with team {teamLocal} and orig groupId {owner_groupId} was changed to {player_group__id}")
        if index == -1
          player_group__membersCount += playerPartyGroupCount
          if length(player_group__origGroupIds) == 1
            createOpenGroupVoiceChat = true
          push(player_group__origGroupIds, int(owner_groupId))
          if length(player_group__origGroupIds) == player_group__membersCount
            player_group__openGroupIsActive = true
        owner_groupId = player_group__id
        wishTeam = player_group__wishTeam
        return true
      return false

  if wishTeam == TEAM_UNASSIGNED
    var teamId = int(TEAM_UNASSIGNED)
    var teamEid = INVALID_ENTITY_ID
    assign_team(teamId, teamEid)
    debug("Player {owner_eid} wish to join any team due to wishTeam is {wishTeam}. Assign team {teamId}.")
    wishTeam = teamId
    if connid != INVALID_CONNECTION_ID
      add_entity_in_net_scope(teamEid, connid)

  query() <| $ [es] (var mission_specified_team_generator__currentId : int&;
                     mission_specified_team_generator__teamTemplate : string)
    createEntitySync(mission_specified_team_generator__teamTemplate) <| $(var init : ComponentsInitializer)
      set(init, "team__id", mission_specified_team_generator__currentId)
    wishTeam = mission_specified_team_generator__currentId
    mission_specified_team_generator__currentId += 1

  if !reconnected && owner_team == TEAM_UNASSIGNED
    owner_team = wishTeam

  if owner_team == teamLocal
    debug("Player {owner_eid} team {owner_team} it the same.")
  else
    debug("Player {owner_eid} team has been changed from {teamLocal} to {owner_team}")

  if !reconnected
    startedAtTime = get_sync_time()
  connectedAtTime = get_sync_time()

  // on reconnect to aborted connection (i.e. disconnect of old connection wasn't handled) possessed entity might still exist
  if evt.canSpawnEntity && !doesEntityExist(possessed)
    debug("Spawn spuad for team {owner_team} and player {owner_eid}")
    sendEvent(owner_eid, CmdSpawnEntityForPlayer(team = owner_team, possessed = INVALID_ENTITY_ID))

  if team != TEAM_UNASSIGNED
    broadcastEvent(EventTeamMemberJoined(eid = owner_eid, team = owner_team))
  if !reconnected && (openGroup || playerPartyGroupCount > 1)
    group_player_connected(owner_eid, openGroup, playerPartyGroupCount, createOpenGroupVoiceChat)

  if reconnected
    find_query() <| $ [es] (player_group__origGroupIds : IntList; player_group__id : int64)
      if owner_groupId == player_group__id && length(player_group__origGroupIds) > 1
        send_net_event(owner_eid, CmdConnectToVoiceChat(chatId = int(owner_groupId)), target_entity_conn(eid))
        return true
      return false
