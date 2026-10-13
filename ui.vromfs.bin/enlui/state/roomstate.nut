import "%enlSqGlob/userInfo.nut" as userInfo
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/modsDownloadManager.nut" import getModStartInfo
from "%enlSqGlob/game_mods_constant.nut" import MOD_BY_VERSION_URL
from "net" import DC_CONNECTION_LOST, EventOnNetworkDestroyed, EventOnConnectedToServer,
  EventOnDisconnectedFromServer
from "dagor.system" import DBGLEVEL
from "dagor.debug" import logerr
from "app" import get_circuit, get_app_id
from "base64" import encodeString
from "%sqstd/json.nut" import object_to_json_string
from "%sqstd/underscore.nut" import deep_clone
from "%ui/matchingClient.nut" import matchingCall, netStateCall
from "%ui/clusterState.nut" import oneOfSelectedClusters
from "%ui/state/appState.nut" import isInBattleState
from "%ui/gameLauncher.nut" import startGame
from "matching.api" import matching_send_response, matching_listen_notify, matching_listen_rpc
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/state/queueState.nut" import isInQueue
from "%ui/chat/chatApi.nut" import leaveChat, createChat, joinChat
from "%ui/chat/chatState.nut" import clearChatState
from "%ui/permissions/permissions.nut" import checkMultiplayerPermissions
from "%ui/squad/squadState.nut" import squadId
from "%ui/squad/squadManager.nut" import leaveSquadSilent
from "eventbus" import eventbus_subscribe
from "dasevents" import MatchingRoomExtraParams, CmdConnectToVoiceChat
from "matching.errors" import OK, error_string, SERVER_ERROR_ROOM_FULL
from "%ui/mainScene/invitationsLogState.nut" import pushNotification, removeNotify, subscribeGroup,
  InvitationsStyle, InvitationsTypes
from "%ui/helpers/remap_nick.nut" import remap_others
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/gameModes/sandbox/customMissionState.nut" import requestModManifest, isFullSonyClient
from "%ui/quickMatchQueue.nut" import joinMatchState
from "%ui/meta/postbox.nut" import postboxSubscribe, postboxMarkRead, postboxSendMessage
from "%dngscripts/platform.nut" import is_sony, is_xbox, is_gdk
from "%ui/gdk/externalIds.nut" import request_xuid_for_user
from "%ui/gdk/activity_export.nut" import ActivityType, make_connection_string, send_invite
from "%ui/ui_library.nut" import *
from "%ui/voiceChat/voiceState.nut" import join_voice_chat, leave_voice_chat
from "das.replay" import is_playing_replay

let { system = null } = require_optional("system")
let loginChain = require("%ui/login/login_chain.nut")
let logR = with_prefix("[RoomState] ")

const INVITE_ACTION_ID = "room_invite_action"

enum LobbyStatus {
  ReadyToStart = "ready_to_launch"
  NotEnoughPlayers = "not_enough_players"
  CreatingGame = "creating_game"
  WaitingBeforeLauch = "waiting_before_launch"
  GameInProgress = "game_in_progress"
  GameInProgressNoLaunched = "game_in_progress_no_launched"
  WaitForDedicatedStart = "wait_for_dedicated_start"
  TeamsDisbalanced = "teams_disbalanced"
  SceneLoadFailure = "scene_load_failure"
}

enum ServerLauncherState {
  Launching = "launching"
  Launched = "launched"
  WaitingForHost = "waiting_for_host"
  HostNotFound = "host_not_found"
  NoSession = "no_session"
}

enum RoomState {
  NONE
  DATA_READY
  GAME_STARTED
}

let room = nestWatched("room", null)
let roomState = nestWatched("roomState", RoomState.NONE)
let roomPasswordToJoin = nestWatched("roomPasswordToJoin", {})
let roomInvites = nestWatched("roomInvites", [])
let roomMembers = nestWatched("roomMembers", [])
let roomIsLobby = nestWatched("roomIsLobby", false)
let connectAllowed = nestWatched("connectAllowed", null)
let hostId  = nestWatched("hostId", null)
let chatId = nestWatched("chatId", null)
let squadVoiceChatId = nestWatched("squadVoiceChatId", null)
let openGroupVoiceChatId = nestWatched("openGroupVoiceChatId", null)
let doConnectToHostOnHostNotfy = nestWatched("doConnectToHostOnHostNotfy", true)
let lobbyLauncherState = Computed(@() room.get()?.public.launcherState ?? ServerLauncherState.NoSession)
let myInfoUpdateInProgress = Watched(false)
let playersWaitingResponseFor = Watched({})
let joinedRoomWithInvite = Watched(false)
let isHostInGame = Watched(true)

let canStartWithLocalDedicated = DBGLEVEL > 0 && system != null
  ? Computed(@() roomIsLobby.get() && room.get()?.public != null)
  : WatchedRo(false)

let isLastMatchDisconnect = nestWatched("isLastMatchDisconnect", false)
let lastSessionStartData = nestWatched("lastSessionStartData", null)
let isWaitForDedicatedStart = Watched(false)
let lobbyStatus = Computed(function() {
  if (isWaitForDedicatedStart.get())
    return LobbyStatus.WaitForDedicatedStart
  let launcherState = lobbyLauncherState.get()
  if (launcherState == LobbyStatus.NotEnoughPlayers)
    return LobbyStatus.NotEnoughPlayers
  if (launcherState == LobbyStatus.WaitingBeforeLauch)
    return LobbyStatus.WaitingBeforeLauch
  if (launcherState == LobbyStatus.TeamsDisbalanced)
    return LobbyStatus.TeamsDisbalanced
  if (launcherState == LobbyStatus.SceneLoadFailure
      || launcherState == ServerLauncherState.HostNotFound)
    return LobbyStatus.SceneLoadFailure
  if (launcherState == ServerLauncherState.Launching
      || launcherState == ServerLauncherState.WaitingForHost)
    return LobbyStatus.CreatingGame
  if (launcherState == ServerLauncherState.Launched)
    return isInBattleState.get() ? LobbyStatus.GameInProgress
      : !connectAllowed.get() ? LobbyStatus.CreatingGame
      : LobbyStatus.GameInProgressNoLaunched
  return LobbyStatus.ReadyToStart
})

let myMemberInfo = Computed(function() {
  let { userId = null } = userInfo.get()
  return roomMembers.get().findvalue(@(m) m.userId == userId)
})
let canOperateRoom = Computed(@() myMemberInfo.get()?.public.operator ?? false)

let getRoomMember =  @(user_id) roomMembers.get().findvalue(@(member) member.userId == user_id)
let hasSquadMates =  @(squad_id) roomMembers.get().findvalue(@(member) member.public?.squadId == squad_id) != null

function cleanupRoomState() {
  logR("cleanupRoomState")
  room.set(null)
  roomState.set(RoomState.NONE)
  playersWaitingResponseFor.set({})
  roomInvites.set([])
  roomMembers.set([])
  roomIsLobby.set(false)
  hostId.set(null)
  connectAllowed.set(null)
  isWaitForDedicatedStart.set(false)
  joinMatchState.set(false)
  if (chatId.get() != null) {
    leaveChat(chatId.get(), null)
    clearChatState(chatId.get())
    chatId.set(null)
  }

  let voiceChatId = squadVoiceChatId.get()
  if (voiceChatId != null) {
    leave_voice_chat(voiceChatId)
    squadVoiceChatId.set(null)
  }
}

function addRoomMember(m) {
  let member = deep_clone(m)
  if (member.public?.host) {
    logR($"found host {member.name} ({member.userId})")
    hostId.set(member.userId)
  }

  member.nameText <- remap_others(member.name)
  roomMembers.mutate(@(value) value.append(member))
  return member
}

function removeRoomMember(user_id) {
  roomMembers.modify(@(v) v.filter(@(member) member.userId != user_id))

  if (user_id == hostId.get()) {
    logR("host leaved from room")
    hostId.set(null)
    connectAllowed.set(null)
  }

  if (user_id == userInfo.get()?.userId)
    cleanupRoomState()
}

function makeCreateRoomCb(user_cb) {
  return function(response) {
    if (response.error != 0)
      logR("failed to create room:", error_string(response.error))
    else {
      roomIsLobby.set(true)
      room.set(deep_clone(response))
      roomState.set(RoomState.DATA_READY)
      matchingCall("mpresence.set_presence", null, {
        lobby = true, roomId = response.roomId, sTime = 0, scene = ""
      })
      logR("you have created the room", response.roomId)
      foreach (member in response.members)
        addRoomMember(member)
    }

    if (squadId.get() != null)
      matchingCall("mrooms.set_member_attributes", null, {
        public = { squadId = squadId.get() }
      })

    if (user_cb)
      user_cb(response)
  }
}

function createRoom(params, user_cb) {
  createChat(function(chat_resp) {
    if (chat_resp.error == 0) {
      params.public.chatId <- chat_resp.chatId
      params.public.chatKey <- chat_resp.chatKey
      chatId.set(chat_resp.chatId)
    }
    matchingCall("mrooms.create_room", makeCreateRoomCb(user_cb), params)
  })
}
function changeAttributesRoom(params, user_cb) {
  matchingCall("mrooms.set_attributes", user_cb, params)
}

let delayedMyAttribs = nestWatched("delayedMyAttribs", null)
function setMemberAttributes(params) {
  if (myInfoUpdateInProgress.get()) {
    delayedMyAttribs.set(params)
    return
  }
  myInfoUpdateInProgress.set(true)
  delayedMyAttribs.set(null)
  let self = callee()
  matchingCall("mrooms.set_member_attributes",
    function(_res) {
      matchingCall("mpresence.set_presence", null, {
        army = params?.public.army ?? "", sTime = 0, scene = ""
      })
      myInfoUpdateInProgress.set(false)
      if (delayedMyAttribs.get() != null)
        self(delayedMyAttribs.get())
    },
    params)
}

function makeLeaveRoomCb(user_cb) {
  return function(r) {
    let response = deep_clone(r)
    if (response.error != 0) {
      logR("failed to leave room:", error_string(response.error))
      response.error = 0
      cleanupRoomState()
    }

    if (room.get()) {
      logR("you left the room", room.get().roomId)
    }

    if (user_cb)
      user_cb(response)
  }
}

function leaveRoom(user_cb = null) {
  if (isInBattleState.get()) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }
  matchingCall("mrooms.leave_room", makeLeaveRoomCb(user_cb))
  matchingCall("mpresence.set_presence", null, { roomId = null, sTime = 0, scene = "" })
}

function forceLeaveRoom() {
  matchingCall("mrooms.leave_room", makeLeaveRoomCb(null))
  matchingCall("mpresence.set_presence", null, { roomId = null, sTime = 0, scene = "" })
}

function destroyRoom(user_cb = null) {
  if (isInBattleState.get()) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }

  matchingCall("mrooms.destroy_room", makeLeaveRoomCb(user_cb))
  matchingCall("mpresence.set_presence", null, { roomId = null, sTime = 0, scene = "" })
}

function makeJoinRoomCb(lobby, user_cb) {
  return function(response) {
    if (response.error != 0) {
      logR("failed to join room:", error_string(response.error))
    }
    else {
      roomIsLobby.set(lobby)

      room.set(deep_clone(response))
      roomState.set(RoomState.DATA_READY)
      let roomId = response.roomId
      logR("you joined room", roomId)
      foreach (member in response.members)
        addRoomMember(member)

      let newChatId = room.get()?.public.chatId
      if (newChatId) {
        joinChat(newChatId, room.get().public.chatKey,
        function(chat_resp) {
          if (chat_resp.error == 0)
            chatId.set(newChatId)
        })
      }

      let squadSelfMember = getRoomMember(userInfo.get()?.userId)
      let selfSquadId = squadSelfMember?.public?.squadId
      if (selfSquadId != null && hasSquadMates(selfSquadId)) {
        let voiceChatId = $"__squad_${selfSquadId}_room_${roomId}"
        squadVoiceChatId.set(voiceChatId)
        join_voice_chat(voiceChatId)
      }
    }

    if (user_cb)
      user_cb(response)
  }
}



function withMemberAppId(params) {
  let member = params?.member ?? {}
  let memberPublic = member?.public ?? {}
  return params.__merge({
    member = member.__merge({ public = memberPublic.__merge({ appId = get_app_id() }) })
  })
}

function joinRoom(params, lobby, user_cb) {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      logR("no permissions to join lobby")
      return
    }

    netStateCall(function() {
      matchingCall("mrooms.join_room", makeJoinRoomCb(lobby, user_cb), withMemberAppId(params))
      matchingCall("mpresence.set_presence", null, {
        lobby, roomId = params.roomId, sTime = 0, scene = ""
      })
    })
  })
}

function makeStartSessionCb(user_cb) {
  return function(response) {
    if (user_cb)
      user_cb(response)
  }
}

function startSession(user_cb) {
  let params = {
    cluster = oneOfSelectedClusters.get()
  }
  matchingCall("mrooms.start_session", makeStartSessionCb(user_cb), params)
}

function startSessionWithLocalDedicated(user_cb, loadTimeout = 30.0) {
  if (!canStartWithLocalDedicated.get()) {
    logerr("Try to start local dedicated when it not allowed")
    return
  }
  let { scene = null, modHash = "" } = room.get()?.public
  if (scene == null && modHash == "") {
    logerr("Trying to start local dedicated server with no scene or mod selected")
    return
  }

  let cmdText = "@start win32/enlisted-ded-dev --listen -config:circuit:t={circuit} -config:scene:t={scene} -invite_data={inviteData} -config:timers/noPlayersExitTimeoutSec:r=120 -noeac -nonetenc"
    .subst({
      circuit = get_circuit()
      scene
      inviteData = encodeString(object_to_json_string({ mode_info = room.get().public }, false))
    })
  logR("Start local dedicated: ", cmdText)
  system?(cmdText) 
  isWaitForDedicatedStart.set(true)
  gui_scene.setTimeout(loadTimeout, function() {
    if (!isWaitForDedicatedStart.get())
      return
    isWaitForDedicatedStart.set(false)
    matchingCall("mrooms.start_session", makeStartSessionCb(user_cb), { cluster = "debug" })
  })
}

function onRoomDestroyed(_notify) {
  cleanupRoomState()
}

function connectToHostImpl() {
  if (hostId.get() == null)
    return

  if (!connectAllowed.get()) {
    showMsgbox(loc("msgboxtext/connectNotAllowed"))
    return
  }
  if (!room.get()) {
    logR("ConnectToHost error: room leaved while wait for callback")
    return
  }

  let { userId = null } = userInfo.get()
  let {
    sessionId = null, gameName = null, modManifestUrl = "", modHash = "",
    modId = "", modVersion = 0, baseModsFilesUrl = null, mode_info = null
  } = room.get()?.public
  let { id_hmac = null, enc_key = null } = getRoomMember(userId)?.private

  let launchParams = {
    sessionId
    modManifestUrl
    modHash
    modId
    modVersion
    baseModsFilesUrl
    game = gameName
    host_urls = getRoomMember(hostId.get())?.public?.host_urls
    authKey = id_hmac
    encKey = enc_key
  }

  matchingCall("mpresence.set_presence", null, { scene = mode_info?.scene ?? "" })

  launchParams.each(function(val, key) {
    if (val == null){
      logR("ConnectToHost error: some room params are null:",key)
    }
  })

  lastSessionStartData.set({
    sessionId = launchParams.sessionId
    loginTime = loginChain.loginTime.get()
  })
  roomState.set(RoomState.GAME_STARTED)
  joinMatchState.set(false)
  isLastMatchDisconnect.set(false)
  if (launchParams.modId != "") {
    requestModManifest(MOD_BY_VERSION_URL.subst(launchParams.modId, launchParams.modVersion), function(manifest, contents) {
      startGame(launchParams.__merge(getModStartInfo(manifest, contents)))
    })
  }
  else if (isHostInGame.get())
    startGame(launchParams)
}

function connectToHost() {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      logR("no permissions to join network game")
      return
    }
    connectToHostImpl()
  })
}

function onDisconnectedFromServer(evt, _eid, _comp) {
  let canReconnect = evt[0] == DC_CONNECTION_LOST 

  leave_voice_chat($"{openGroupVoiceChatId.get()}")
  openGroupVoiceChatId.set(null)

  if (!canReconnect && !roomIsLobby.get())
    forceLeaveRoom()

  if (lastSessionStartData.get() == null)
    return

  let { loginTime } = lastSessionStartData.get()
  lastSessionStartData.set(null)
  let wasRelogin = loginTime != loginChain.loginTime.get()
  if (!wasRelogin && canReconnect && !roomIsLobby.get()) {
    isLastMatchDisconnect.set(canReconnect)
    cleanupRoomState() 
  }
}

function onConnectedToServer() {
  let { extraParams = null } = room.get()?.public
  if (extraParams == null) {
    return
  }

  ecs.g_entity_mgr.broadcastEvent(MatchingRoomExtraParams({
      routeEvaluationChance = extraParams?.routeEvaluationChance ?? 0.0,
      ddosSimulationChance = extraParams?.ddosSimulationChance ?? 0.0,
      ddosSimulationAddRtt = extraParams?.ddosSimulationAddRtt ?? 0,
  }));
}

ecs.register_es("connect_to_open_group_voice_chat", {
  [CmdConnectToVoiceChat] = function(evt, _, _){
    
    
    if (is_playing_replay())
      return
    
    
    let prevChatId = openGroupVoiceChatId.get()
    if (prevChatId != null && prevChatId != evt.chatId)
      leave_voice_chat($"{prevChatId}")
    openGroupVoiceChatId.set(evt.chatId)
    join_voice_chat($"{evt.chatId}")
  }
}
{
  comps_rq = ["player"]
},
{ tags = "gameClient" })

ecs.register_es("enlist_disconnected_from_server_es", {
  [EventOnDisconnectedFromServer] = onDisconnectedFromServer,
  [EventOnNetworkDestroyed] = onDisconnectedFromServer,
})
ecs.register_es("enlist_connected_to_server_es", {
  [EventOnConnectedToServer] = onConnectedToServer,
})

function onHostNotify(notify) {
  logR("onHostNotify", notify)
  if (notify.hostId != hostId.get()) {
    logR($"warning: got host notify from host that is not in current room {notify.hostId} != {hostId.get()}")
    return
  }

  if (notify.roomId != room.get()?.roomId) {
    logR("warning: got host notify for wrong room")
    return
  }

  if (notify.message == "connect-allowed")
    connectAllowed.set(true)

  if (doConnectToHostOnHostNotfy.get() || isWaitForDedicatedStart.get()) {
    isWaitForDedicatedStart.set(false)
    connectToHost()
  }
}

function onRoomMemberJoined(notify) {
  let { roomId = null } = room.get()
  if (notify.roomId != roomId)
    return

  logR($"{notify.name} ({notify.userId}) joined room")
  let { userId = null } = userInfo.get()
  if (notify.userId != userId) {
    let newmember = addRoomMember(notify)
    if (squadVoiceChatId.get() == null) {
      let squadSelfMember = getRoomMember(userId)
      let selfSquadId = squadSelfMember?.public?.squadId
      if (selfSquadId != null && selfSquadId == newmember?.squadId) {
        squadVoiceChatId.set($"__squad_${selfSquadId}_room_${roomId}")
        join_voice_chat(squadVoiceChatId.get())
      }
    }
  }
}

function onRoomMemberLeft(notify) {
  if (notify.roomId != room.get()?.roomId)
    return
  logR($"{notify.name} ({notify.userId}) left from room")
  removeRoomMember(notify.userId)
}

function onRoomMemberKicked(notify) {
  removeRoomMember(notify.userId)
}

function merge_attribs(upd_data, attribs) {
  foreach (key, value in upd_data) {
    if (value == null) {
      if (key in attribs)
        attribs.$rawdelete(key)
    }
    else
      attribs[key] <- value
  }
  return attribs
}

function onRoomAttrChanged(notify) {
  if (!room.get())
    return

  let res = clone room.get()
  let { public = null, private = null } = notify
  if (typeof public == "table")
    merge_attribs(public, res.public)
  if (typeof private == "table")
    merge_attribs(private, res.private)
  room.set(res)
}

function onRoomMemberAttrChanged(notify) {
  if (!roomMembers.get())
    return

  roomMembers.mutate(function(membs) {
    let idx = membs.findindex(@(m) m.userId == notify?.userId)
    if (idx == null)
      return membs

    let member = clone membs[idx]
    let { public = null, private = null } = notify
    if (typeof public == "table")
      merge_attribs(public, member.public)
    if (typeof private == "table")
      merge_attribs(private, member.private)
    membs[idx] = member
    return membs
  })
}

let canInviteToRoom = Computed(@() room.get() != null
  && (room.get()?.public.slotsCnt ?? 0) < (room.get()?.public.maxPlayers ?? 0))

function isInMyRoom(newMemberId){
  return roomMembers.get().findvalue(@(member) member.userId == newMemberId) != null
}

function joinCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    showMsgbox(loc("msgbox/failedJoinRoom", { error = loc($"error/{errStr}", errStr) }))
  }
}

subscribeGroup(INVITE_ACTION_ID, {
  onShow = function(notify) {
    return showMsgbox({
      text = loc("squad/acceptInviteQst")
      buttons = [
        { text = loc("Yes"), isCurrent = true,
          function action() {
            if (room.get() != null)
              return
            let { modId = null } = notify
            if ((modId ?? "") != "" && is_sony && !isFullSonyClient.get()) {
              showMsgbox(loc("mods/disabled"))
              removeNotify(notify)
              return
            }

            let roomId = notify.roomId.tointeger()
            let params = { roomId }
            if (roomId in roomPasswordToJoin.get())
              params.password <- roomPasswordToJoin.get()[roomId]
            joinRoom(params, true, joinCb)
            joinedRoomWithInvite.set(true)
            removeNotify(notify)
          }
        }
        { text = loc("No"), isCancel = true,
          function action() {
            removeNotify(notify)
          }
        }
      ]
    })
  }
})

room.subscribe(function(v){
  if (v == null)
    joinedRoomWithInvite.set(false)
})

function onRoomInvite(mailObj) {
  let { mail_id } = mailObj
  let { roomId, sender_id, sender_name, password = null, modId = null } = mailObj.mail
  roomInvites.mutate(@(i) i.append({
    roomId
    senderId = sender_id
    senderName = sender_name
  }))
  if (password != null)
    roomPasswordToJoin.mutate(@(v) v[roomId] <- password)

  logR("got room invite from", sender_name)

  postboxMarkRead(mail_id)
  postboxSendMessage(sender_id, { subj = "invite_player_reply" })

  pushNotification({
    roomId
    modId
    inviterUid = sender_id
    nType = InvitationsTypes.TO_SQUAD
    styleId = InvitationsStyle.TO_BATTLE
    playerName = sender_name
    text = loc("room/invite", { playername = remap_others(sender_name) })
    actionsGroup = INVITE_ACTION_ID
    needPopup = true
  })
}

function cleanWaitingResponse(senderId) {
  if (senderId in playersWaitingResponseFor.get())
    playersWaitingResponseFor.mutate(@(v) v.$rawdelete(senderId))
}

function onRoomInviteReply(mailObj) {
  let { mail_id } = mailObj
  postboxMarkRead(mail_id)

  let { sender_id } = mailObj.mail
  cleanWaitingResponse(sender_id)
}

function inviteToRoom(user_id){
  if (isInMyRoom(user_id) || !canInviteToRoom.get()){
    logR("Player can not be invited to lobby")
    return
  }
  playersWaitingResponseFor.mutate(@(v) v[user_id] <- true)

  let { roomId, public = {} } = room.get()
  let sendingData = {
    subj = "invite_player"
    roomId
    modId = public?.modId
  }
  if (roomId in roomPasswordToJoin.get())
    sendingData.password <- roomPasswordToJoin.get()[roomId]

  if (is_xbox || is_gdk) {
    request_xuid_for_user(user_id, function(_, xuid) {
      if (xuid == null) { 
        postboxSendMessage(user_id, sendingData)
        return
      }
      let connectionString = make_connection_string(ActivityType.Room, roomId.tostring())
      send_invite(xuid.tointeger(), connectionString)
    })
  }
  else
    postboxSendMessage(user_id, sendingData)
}

function onMatchInvite(reqctx) {
  logR("got match invite from server")
  matching_send_response(reqctx, {})
  joinRoom(reqctx.request, false, function(_cb) {})
}

function list_invites(){
  foreach (i, invite in roomInvites.get())
    logR($"{i} from {invite.senderName} ({invite.senderId}), roomId {invite.roomId}")
}

let gameIsLaunching = Computed(@() !((roomIsLobby.get() || !room.get()) && !isInQueue.get()))

console_register_command(list_invites, "mrooms.list_invites")

postboxSubscribe("invite_player", onRoomInvite)
postboxSubscribe("invite_player_reply", onRoomInviteReply)

foreach (name, cb in {
  ["mrooms.on_room_member_joined"] = onRoomMemberJoined,
  ["mrooms.on_room_member_leaved"] = onRoomMemberLeft,
  ["mrooms.on_room_attributes_changed"] = onRoomAttrChanged,
  ["mrooms.on_room_member_attributes_changed"] = onRoomMemberAttrChanged,
  ["mrooms.on_room_destroyed"] = onRoomDestroyed,
  ["mrooms.on_room_member_kicked"] = onRoomMemberKicked,
  ["mrooms.on_host_notify"] = onHostNotify
}){
  matching_listen_notify(name)
  eventbus_subscribe(name, cb)
}

foreach (name, cb in {
  ["enlmm.on_room_invite"] = onMatchInvite,
}){
  matching_listen_rpc(name)
  eventbus_subscribe(name, cb)
}

eventbus_subscribe("matching.on_disconnect", @(...) cleanupRoomState())

function joinFriendRoomImpl(roomData, actions) {
  let { roomId = "" } = roomData
  let { maxPlayers = 1, membersCnt = 0, hasPassword = false } = roomData?.public ?? roomData
  if (membersCnt >= maxPlayers || hasPassword) {
    actions.open()
    return
  }

  leaveSquadSilent(function() {
    joinRoom({ roomId = roomId.tointeger() }, true, function(response) {
      if (response.error != OK)
        return showMsgbox(response.error == SERVER_ERROR_ROOM_FULL
          ? loc("msgboxtext/roomIsFull")
          : loc("msgbox/failedJoinRoom", "Failed to join room: {error}", {
              error = error_string(response.error)
            }))

      actions.join()
    })
  })
}

function joinFriendRoom(roomId, roomData, joinActions) {
  if (roomData != null) {
    joinFriendRoomImpl(roomData, joinActions)
    return
  }

  matchingCall("mrooms.get_room", function(response) {
    if (response.error != OK) {
      logR($"mrooms.get_room error for room {roomId}: {response.error}")
      return
    }

    joinFriendRoomImpl(response, joinActions)
  }, { roomId })
}

return {
  RoomState

  room
  roomState
  isInRoom = Computed(@() room.get() != null)
  roomInvites
  roomMembers
  roomIsLobby
  lobbyStatus
  isLastMatchDisconnect
  chatId
  roomPasswordToJoin

  setMemberAttributes
  myInfoUpdateInProgress
  createRoom
  changeAttributesRoom
  joinRoom
  leaveRoom
  startSession
  canStartWithLocalDedicated
  startSessionWithLocalDedicated
  destroyRoom
  canOperateRoom
  myMemberInfo
  gameIsLaunching

  connectToHost
  connectAllowed
  doConnectToHostOnHostNotfy
  LobbyStatus

  canInviteToRoom
  isInMyRoom
  inviteToRoom
  joinFriendRoom
  playersWaitingResponseFor
  joinedRoomWithInvite
  isHostInGame
}
