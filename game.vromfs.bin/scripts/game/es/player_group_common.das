module player_group_common shared

require ecs
require ecs.common
require matching
require ecs.extra_set
require game.es.player_events
require game.utils.team
require game.utils.net_utils
require DngNet

let INVALID_GROUP_ID_INT64 = int64(INVALID_SQUAD_ID)

def find_player_index_in_group(members; uid)
  for i in iter_range(members)
    if members[i] == uid
      return i
  return -1

def is_bot_auto_squad()
  return find_query() <| $ [es] (bots_ai_spawner__botAutoSquad : bool)
    return bots_ai_spawner__botAutoSquad

def find_best_available_group_for_bot(team; exclude_group_id = INVALID_GROUP_ID_INT64)
  var groupEid = INVALID_ENTITY_ID
  var minPlayersInGroup = -1
  query() <| $ [es] (eid : EntityId;
                     player_group__id : int64;
                     player_group__wishTeam : int;
                     player_group__maxBotPlayers : int;
                     player_group__members : ecs::UInt64List)
    if player_group__wishTeam != team || player_group__id == INVALID_GROUP_ID_INT64 || player_group__id == exclude_group_id
      return
    if minPlayersInGroup == -1
      minPlayersInGroup = player_group__maxBotPlayers
    let membersInGroup = length(player_group__members)
    if membersInGroup < minPlayersInGroup
      minPlayersInGroup = membersInGroup
      groupEid = eid
  return groupEid

def define_bot_in_group(bot_eid; exclude_group_id = INVALID_GROUP_ID_INT64)
  ecs::query(bot_eid) <| $ [es(REQUIRE=playerIsBot)] (team : int;
                                                      var groupId : int64&;
                                                      var player_group__memberIndex : int&)
    let bestGroupEid = find_best_available_group_for_bot(team, exclude_group_id)
    if !bestGroupEid
      groupId = INVALID_GROUP_ID_INT64
      player_group__memberIndex = 0
      return
    query(bestGroupEid) <| $ [es] (player_group__id : int64; var player_group__members : ecs::UInt64List&)
      groupId = player_group__id
      player_group__memberIndex = length(player_group__members)
      player_group__members |> push(INVALID_USER_ID)

def redefine_group_for_bot_member(group_id; member_index)
  find_query() <| $ [es(REQUIRE=playerIsBot)] (eid : EntityId; groupId : int64; player_group__memberIndex : int)
    if groupId == group_id && player_group__memberIndex == member_index
      define_bot_in_group(eid, groupId)
      return true
    return false

def group_player_connected(player_eid : EntityId; open_group : bool; group_count : int; create_open_group_voice_chat : bool)
  query(player_eid) <| $ [es] (userid : uint64;
                               groupId : int64;
                               team = TEAM_UNASSIGNED;
                               var player_group__memberIndex : int&)
    let found = ecs::find_query() <| $ [es] (player_group__id : int64;
                                             player_group__maxBotPlayers : int;
                                             var player_group__members : ecs::UInt64List&)
      if player_group__id != groupId
        return false

      player_group__memberIndex = player_group__members |> find_player_index_in_group(userid)

      let playerGroupMembersCount = length(player_group__members)

      if player_group__memberIndex == -1
        let botIndex = player_group__members |> find_player_index_in_group(INVALID_USER_ID)
        if playerGroupMembersCount < player_group__maxBotPlayers || botIndex < 0
          player_group__memberIndex = playerGroupMembersCount
          player_group__members |> push(userid)
          if create_open_group_voice_chat
            query() <| $ [es] (userid aka other_userid : uint64; eid : EntityId)
              if player_group__members |> find_player_index_in_group(other_userid) != -1
                send_net_event(eid, CmdConnectToVoiceChat(chatId = int(groupId)), target_entity_conn(eid))
          else
            send_net_event(player_eid, CmdConnectToVoiceChat(chatId = int(groupId)), target_entity_conn(player_eid))
        else
          redefine_group_for_bot_member(groupId, botIndex)
          player_group__memberIndex = botIndex
          player_group__members[botIndex] = userid
      return true
    if found
      return

    player_group__memberIndex = 0
    createEntitySync("player_group") <| $(var init)
      init |> set("player_group__id", groupId)
      init |> set("player_group__origGroupIds", [int(groupId)])
      init |> set("player_group__members", [userid])
      init |> set("player_group__wishTeam", team)
      init |> set("player_group__membersCount", group_count)
      init |> set("player_group__openGroup", open_group)
