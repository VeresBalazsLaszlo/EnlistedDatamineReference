import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/popup/popupsState.nut" as popupsState    
import "%ui/squad/squadAPI.nut" as MSquadAPI
import "%ui/squad/consoleSessionManager.nut" as sessionManager
import "%ui/squad/squadState.nut" as squadState
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, CrossPlayStateWeight,
  crossnetworkChat, CrossplayState
from "%ui/permissions/permissions.nut" import checkMultiplayerPermissions
from "%sqstd/timers.nut" import debounce
from "%dngscripts/globalState.nut" import nestWatched
from "math" import fabs
from "%ui/mainScene/invitationsLogState.nut" import pushNotification, removeNotifyById,
  removeNotify, subscribeGroup, InvitationsStyle, InvitationsTypes
from "%ui/contacts/contactsWatchLists.nut" import blockedUids
from "%ui/contacts/contact.nut" import getContactRealnick, getContact, validateNickNames,
  getContactNick, updateContact
from "%ui/contacts/contactPresence.nut" import onlineStatus, isContactOnline, updateSquadPresences
from "matching.api" import matching_listen_notify
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/designConst.nut" import attentionTxtColor
from "%ui/voiceChat/voiceState.nut" import join_voice_chat, leave_voice_chat
from "%ui/chat/chatApi.nut" import leaveChat, createChat, joinChat
from "eventbus" import eventbus_subscribe, eventbus_send
from "%ui/contacts/consoleUidsRemap.nut" import uid2console
from "%ui/helpers/platformUtils.nut" import canInterractCrossPlatformByCrossplay
from "%ui/state/queueState.nut" import availableSquadMaxMembers
from "%sqstd/version_compare.nut" import check_version
from "%ui/currency/currencies.nut" import hasValidBalance
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/matchRandomTeam.nut" import matchRandomTeam
from "%ui/gameModes/gameModeState.nut" import currentGameModeId
from "%ui/soldiers/armySquadTier.nut" import allArmiesTiers
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/incognitoState.nut" import incognitoState
from "%ui/state/client_version.nut" import maxVersionStr
from "app" import get_app_id
from "%sqstd/platform.nut" import is_gdk
from "%sqstd/frp.nut" import subscribeAndInit, subscribeList
from "%ui/ui_library.nut" import *
from "%ui/helpers/platformUtils.nut" import consoleCompare

let { squadId, isInSquad, isSquadLeader, isInvitedToSquad, selfUid,
  squadSharedData, squadServerSharedData, squadMembers,
  squadSelfMember, notifyMemberRemoved, notifyMemberAdded
} = squadState

let logSq = with_prefix("[SQUAD] ")

const INVITE_ACTION_ID = "squad_invite_action"
const SQUAD_OVERDRAFT = 0

enum ChatState {
  INACTIVE
  CREATING
  ACTIVE
}

let squadOnlineMembers = Computed(@()
  squadMembers.get().filter(@(m) isContactOnline(m.userId.tostring(), onlineStatus.get())))

isSquadLeader.subscribe(function(value) {
  if (value)
    squadSharedData.crossnetworkPlay.set(crossnetworkPlay.get())
})

squadSharedData.crossnetworkPlay.set(crossnetworkPlay.get())

let setOnlineBySquad = @(userId, online) updateSquadPresences({ [userId.tostring()] = online })

function SquadMember(userId)  {
  let realnick = getContactRealnick(userId.tostring())
  return {
    userId
    isLeader = squadId.get() == userId
    state = {}
    realnick
  }
}

function applyRemoteDataToSquadMember(member, msquad_data) {
  logSq($"applyRemoteData for {member.userId} from msquad", msquad_data)

  if (msquad_data?.data.name) 
    updateContact(member.userId.tostring(), msquad_data.data.name)

  let newOnline = msquad_data?.online
  if (newOnline != null)
    setOnlineBySquad(member.userId, newOnline)

  let data = msquad_data?.data
  if (typeof(data) != "table")
    return {}

  let oldVal = member.state
  foreach (k,v in data){
    if (k in oldVal && oldVal[k] == v)
      continue
    member.state = oldVal.__merge(data)
    break
  }

  return data
}


let delayedActions = mkWatched(persist, "delayedActions", null)
let isSquadDataInited = nestWatched("isSquadDataInited", false)
let squadChatJoined = nestWatched("squadChatJoined", ChatState.INACTIVE)

let myDataRemote = nestWatched("myDataRemoteWatch", {})
let myDataLocal = Watched({})

let voiceChatId = @(s) $"squad-channel-{s}"

squadId.subscribe(function(_val) {
  isSquadDataInited.set(false)
})

squadMembers.subscribe(function(list) {
  logSq($"Current squad members length: {list.len()}")
  let uidList = []
  list.each(@(m) uidList.append(m.userId))
  validateNickNames(uidList)
})
logSq($"Current squad members length on load scripts: {squadMembers.get().len()}")

let getSquadInviteUid = @(inviterSquadId) $"squad_invite_{inviterSquadId}"

function sendEvent(handlers, val) {
  foreach (h in handlers)
    h(val)
}

function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}

let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

let updateMyDataDebounced = debounce(function() {
  if (squadSelfMember.get() == null)
    return 

  let needSend = myDataLocal.get().findindex(@(value, key)
    !isEqualWithFloat(myDataRemote.get()?[key], value)) != null
  if (needSend) {
    logSq("update my data: ", myDataLocal.get())
    MSquadAPI.setMemberData(myDataLocal.get())
  }
}, 0.1)

subscribeList(updateMyDataDebounced, squadSelfMember, myDataLocal, myDataRemote)

function linkVarToMsquad(name, var) {
  myDataLocal.mutate(@(v) v[name] <- var.get())
  var.subscribe(@(_val) myDataLocal.mutate(@(v) v[name] <- var.get()))
}

linkVarToMsquad("name", keepref(Computed(@() userInfo.get()?.name))) 
let ready = nestWatched("myExtData.ready", false)
let appId = Watched(get_app_id())

let myExtSquadData = {
  inBattle = isInBattleState,
  ready = ready,
  crossnetworkPlay = crossnetworkPlay,
  version = maxVersionStr,
  appId = appId,
  curArmy = curArmy,
  isTeamRandom = matchRandomTeam,
  gameModeId = currentGameModeId,
  armiesTiers = allArmiesTiers,
  incognito = incognitoState
}

let myExtDataRW = {ready}
foreach (name, var in myExtSquadData)
  linkVarToMsquad(name, var)

function setSelfRemoteData(member_data) {
  myDataRemote.set(clone member_data)
  foreach (k, v in member_data) {
    if (k in myExtDataRW) {
      myExtDataRW[k].set(v)
    }
  }
}

function reset() {
  squadId.set(null)
  isInvitedToSquad.set({})

  if (squadSharedData.squadChat.get() != null) {
    let chat_id = squadSharedData.squadChat.get()?.chatId
    leaveChat(chat_id, function(result) {
      if ((result?.error ?? 0) == 0)
        squadChatJoined.set(ChatState.INACTIVE)
      else
        logSq($"leaveChat returned error {result.error}")
    })
    if (chat_id)
      leave_voice_chat(voiceChatId(chat_id))
  }

  foreach (w in squadSharedData)
    w.set(null)
  foreach (w in squadServerSharedData)
    w.set(null)

  foreach (member in squadMembers.get()) {
    setOnlineBySquad(member.userId, null)
    sendEvent(notifyMemberRemoved, member.userId)
  }
  squadMembers.set({})
  delayedActions.set(null)

  myExtSquadData.ready.set(false)
  myDataRemote.set({})
}

function setSquadLeader(squadIdVal){
  squadMembers.mutate(function(s){
    foreach (uid, member in s){
      s[uid].isLeader = member.userId == squadIdVal
    }
  })
}
subscribeAndInit(setSquadLeader, squadId)

function removeInvitedSquadmate(user_id) {
  if (!(user_id in isInvitedToSquad.get()))
    return false
  isInvitedToSquad.mutate(@(value) value.$rawdelete(user_id))
  return true
}

function addInvited(user_id) {
  if (user_id in isInvitedToSquad.get())
    return false
  isInvitedToSquad.mutate(@(value) value[user_id] <- true)
  validateNickNames(user_id)
  return true
}

function applySharedData(dataTable) {
  if (!isInSquad.get())
    return

  foreach (key, w in squadServerSharedData)
    if (key in dataTable)
      w.set(dataTable[key])

  if (!isSquadLeader.get())
    foreach (key, w in squadSharedData)
      w.set(squadServerSharedData[key].get())
}

function checkDisbandEmptySquad() {
  if (squadMembers.get().len() == 1 && !isInvitedToSquad.get().len())
    MSquadAPI.disbandSquad()
}

function revokeSquadInvite(user_id) {
  if (!removeInvitedSquadmate(user_id))
    return

  MSquadAPI.revokeInvite(user_id)
  checkDisbandEmptySquad()
}

function revokeAllSquadInvites() {
  foreach (uid, _ in isInvitedToSquad.get())
    revokeSquadInvite(uid)
}

function leaveSquadSilent(cb = null) {
  if (!isInSquad.get()) {
    cb?()
    return
  }

  if (squadMembers.get().len() == 1)
    revokeAllSquadInvites()

  sessionManager.leave()
  MSquadAPI.leaveSquad({ onAnyResult = function(...) {
    reset()
    cb?()
  }})
}

let showSizePopup = @(text, isError = true)
    popupsState.addPopup({ id = "squadSizePopup", text = text, styleName = isError ? "error" : "" })

let requestMemberData = @(uid) MSquadAPI.getMemberData(uid)

function updateSquadInfo(squad_info) {
  if (squadId.get() != squad_info.id)
    return

  logSq("updateSquadInfo with squad", squad_info.id)
  foreach (uid in squad_info.members) {
    let isMe = (uid == selfUid.get())
    if (uid not in squadMembers.get()) {
      if (isMe && squad_info.members.len() > availableSquadMaxMembers.get()) {
        logSq("Leave from squad, right after join. Squad was already full.")
        leaveSquadSilent(@() showSizePopup(loc("squad/popup/squadFull")))
        continue
      }

      let sMember = SquadMember(uid)
      squadMembers.mutate(@(m) m[uid] <- sMember)
      removeInvitedSquadmate(uid)
    }
    requestMemberData(uid)
  }
  squadMembers.trigger()

  foreach (uid in squad_info?.invites ?? [])
    addInvited(uid)

  if (squad_info?.data)
    applySharedData(squad_info.data)

  isSquadDataInited.set(true)
}

function fetchSquadInfo(context = null) {
  MSquadAPI.getSquadInfo(context)
}

function onSquadJoinError(response) {
  let { error_id = "" } = response
  showMsgbox(loc($"squad/nonAccepted/{error_id}", ": ".concat(loc("squad/inviteError"), error_id)))
}

MSquadAPI.onAcceptInvite({
  onSuccess = function(response) {
    let sid = response?.context.squadId
    logSq($"Invite to squad '{sid}' accepted")
    squadId.set(sid)
    fetchSquadInfo()
  }
  onFailure = function(response) {
    logSq($"Failed invitation accept {response?.error_id}")
    onSquadJoinError(response)
    eventbus_send("ipc.squadIsFull", null)
    logSq("sessionManager.leave on mpi.acceptinvite failure")
    sessionManager.leave()
  }
})

function acceptInviteImpl(invSquadId) {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      logSq("accept squad invitation is not allowed because of multiplayer permissions")
      return
    }

    MSquadAPI.acceptInvite(invSquadId)
  })
}

function acceptSquadInvite(invSquadId) {
  if (!isInSquad.get())
    acceptInviteImpl(invSquadId)
  else
    leaveSquadSilent(@() acceptInviteImpl(invSquadId))
}

function processSquadInvite(contact) {
  
  if (isInSquad.get() && squadId.get() == contact.uid) {
    return
  }

  pushNotification({
    id = getSquadInviteUid(contact.uid)
    inviterUid = contact.uid
    nType = InvitationsTypes.TO_SQUAD
    styleId = InvitationsStyle.TO_BATTLE
    playerName = getContactNick(contact)
    text = loc("squad/invite", {playername=getContactNick(contact)})
    actionsGroup = INVITE_ACTION_ID
    needPopup = true
  })
}

function onInviteRevoked(inviterSquadId, invitedMemberId) {
  if (inviterSquadId == squadId.get())
    removeInvitedSquadmate(invitedMemberId)
  else
    removeNotifyById(getSquadInviteUid(inviterSquadId))
}

function addInviteByContact(inviter) {
  if (inviter.uid == selfUid.get()) 
    return

  if (inviter.userId in blockedUids.get()) {
    logSq("got squad invite from blacklisted user", inviter)
    MSquadAPI.rejectInvite(inviter.uid)
    return
  }

  if (!canInterractCrossPlatformByCrossplay(inviter.realnick, crossnetworkPlay.get())) {
    logSq($"got squad invite from crossplatform user, is crosschat available: {crossnetworkChat.get()}", inviter)
    MSquadAPI.rejectInvite(inviter.uid)
    return
  }

  if (consoleCompare.live.isPlatform && consoleCompare.live.isFromPlatform(inviter.realnick)) {
    logSq("got squad invite from xbox player. It will be silently accepted or hidden", inviter)
    return
  }

  processSquadInvite(inviter)
}

function onInviteNotify(invite_info) {
  if ("invite" in invite_info) {
    let uid = invite_info?.leader.id
    let inviter = uid != null ? updateContact(uid.tostring(), invite_info?.leader.name) : null

    if (invite_info.invite.id == selfUid.get()) {
      if (inviter!=null)
        addInviteByContact(inviter)
    }
    else
      addInvited(invite_info.invite.id)
  }
  else if ("replaces" in invite_info) {
    onInviteRevoked(invite_info.replaces, selfUid.get())
    let uid = invite_info?.leader.id.tostring()
    if (uid != null)
      addInviteByContact(getContact(uid))
  }
}

function execDelayedActions() {
  if (delayedActions.get() == null)
    return

  foreach (func in delayedActions.get())
    func()
  delayedActions.set(null)
}

MSquadAPI.onGetSquadInfo({
  onSuccess = function(result) {
    if ("squad" in result) {
      squadId.set(result.squad.id)
      updateSquadInfo(result.squad)
    }

    let invites = result?.invites ?? []
    validateNickNames(invites, function() {
      foreach (uid in invites)
        addInviteByContact(getContact(uid.tostring()))
    })

    let { needCreateSession = false } = result?.context
    if (!needCreateSession)
      return

    if (sessionManager.isAvailableConsoleSession)
      sessionManager.create(squadId.get(), execDelayedActions)
    else
      execDelayedActions()
  }
  onFailure = function(result) {
    if (result?.error_id == "NOT_SQUAD_MEMBER")
      squadId.set(null)
    delayedActions.set(null)
  }
})

function onMemberDataChanged(response) {
  let { userId = null } = response?.context
  let member = squadMembers.get()?[userId]
  if (member == null)
    return

  let data = applyRemoteDataToSquadMember(member, response)
  let isMe = userId == selfUid.get()
  let isNewMember = userId not in squadMembers.get()
  if (isMe && data)
    setSelfRemoteData(data)
  if (isNewMember)
    sendEvent(notifyMemberAdded, userId)
  squadMembers.trigger()
}

MSquadAPI.onGetMemberData({ onSuccess = @(response) onMemberDataChanged(response) })

function addMember(member) {
  let userId = member.userId
  logSq($"addMember {userId}", member)

  let squadMember = SquadMember(member.userId)
  let realnick = getContactRealnick(member.userId.tostring())
  squadMember.realnick = realnick
  setOnlineBySquad(squadMember.userId, true)
  removeInvitedSquadmate(member.userId)

  squadMembers.mutate(@(val) val[userId] <- squadMember)
  sendEvent(notifyMemberAdded, userId)

  if (squadMembers.get().len() == availableSquadMaxMembers.get() && isInvitedToSquad.get().len() > 0 && isSquadLeader.get()) {
    revokeAllSquadInvites()
    showSizePopup(loc("squad/squadIsReadyExtraInvitesRevoken"))
  }
}

function removeMember(member) {
  let userId = member.userId
  logSq($"removeMember {userId}", member)

  if (userId == selfUid.get()) {
    showMsgbox(loc("squad/kickedMsgbox"))
    reset()
  }
  else if (userId in squadMembers.get()) {
    let m = squadMembers.get()[userId]
    setOnlineBySquad(m.userId, null)
    if (userId in squadMembers.get()) 
      squadMembers.mutate(@(v) v.$rawdelete(userId))
    sendEvent(notifyMemberRemoved, userId)
    checkDisbandEmptySquad()
  }
}

  
function leaveSquad(cb = null) {
  showMsgbox({
    text = loc("squad/leaveSquadQst")
    buttons = [
      { text = loc("Yes"), action = @() leaveSquadSilent(cb), isCurrent = true }
      { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
  })
}

function dismissSquadMember(user_id) {
  let member = squadMembers.get()?[user_id]
  if (!member)
    return

  showMsgbox({
    text = loc("squad/kickPlayerQst",
      { name = getContactNick(getContact(member.userId.tostring())) })
    buttons = [
      { text = loc("Yes"), action = @() MSquadAPI.dismissMember(user_id) }
      { text = loc("No"), isCancel = true, isCurrent = true }
    ]
  })
}

function dismissAllOfflineSquadmates() {
  if (!isSquadLeader.get())
    return

  foreach (member in squadMembers.get()){
    if (!isContactOnline(member.userId.tostring(), onlineStatus.get()))
      MSquadAPI.dismissMember(member.userId)
  }
}

MSquadAPI.onTransferSquad({
  onSuccess = function(response) {
    let { userId = null } = response?.context
    if (isSquadLeader.get())
      myExtSquadData.ready.set(false)
    squadId.set(userId)
    if (selfUid.get() == userId)
      sessionManager.updateData(userId)
  }
})

function transferSquad(userId) {
  if (crossnetworkPlay.get() != CrossplayState.ALL) {
    local leaderCrossplayState = CrossplayState.ALL
    foreach (member in squadOnlineMembers.get()) {
      if (userId == member?.userId && member.state?.crossnetworkPlay in CrossPlayStateWeight)
        leaderCrossplayState = member.state?.crossnetworkPlay
    }

    if (CrossPlayStateWeight[leaderCrossplayState]
        > CrossPlayStateWeight[crossnetworkPlay.get()]) {
      showMsgbox({
        text = loc("squad/leader_different_crossnetwork_play", { color = attentionTxtColor })
        buttons = [ { text = loc("Ok"), isCurrent = true } ]
      })
      return
    }
  }
  MSquadAPI.transferSquad(userId)
}

function doJoinSquadChat() {
  if (squadChatJoined.get() != ChatState.INACTIVE)
    return

  squadChatJoined.set(ChatState.CREATING)
  createChat(function(result) {
    if ((result?.error ?? 0) != 0) {
      squadChatJoined.set(ChatState.INACTIVE)
      logSq($"createChat returned error {result.error}")
      return
    }
    squadChatJoined.set(ChatState.ACTIVE)
    squadSharedData.squadChat.set({
      chatId = result.chatId
      chatKey = result.chatKey
    })
  })
}

MSquadAPI.onCreateSquad({
  onSuccess = @(_) fetchSquadInfo({ needCreateSession = true })
  onFailure = @(_) delayedActions.set(null)
})

function createSquadAndDo(actionsList = null) {
  if (isInSquad.get()) {
    if (actionsList) {
      logSq($"CreateSquadAndDo: squad is ready, do actions")
      foreach (func in actionsList)
        func()
    }
    return
  }

  if (actionsList) {
    logSq($"CreateSquadAndDo: place actions to queue")
    delayedActions.set(actionsList)
  }
  MSquadAPI.createSquad()
}

function invitePlayerImpl(userId) {
  MSquadAPI.invitePlayer(userId)
}

MSquadAPI.onInvitePlayer({
  onFailure = function(response) {
    let { error_id = "" } = response
    logSq($"player invite failed: {error_id}")
    showSizePopup(loc($"error/{error_id}"), false)
  }
})

function inviteToSquadImpl(user_id, needConsoleInvite = true) {
  if (isInSquad.get()) {
    if (user_id in squadMembers.get()) {
      logSq($"Invite: member {user_id}: already in squad")
      return
    }

    if (squadMembers.get().len() >= availableSquadMaxMembers.get()) {
      logSq($"Invite: member {user_id}: squad already full")
      return showSizePopup(loc("squad/popup/squadFull"))
    }

    if (squadMembers.get().len() + isInvitedToSquad.get().len() >= availableSquadMaxMembers.get() + SQUAD_OVERDRAFT) {
      logSq($"Invite: member {user_id}: too many invites")
      return showSizePopup(loc("squad/popup/tooManyInvited"))
    }
  }

  if (!hasValidBalance.get()) {
    logSq($"Invite: member {user_id}: negative balance")
    return showSizePopup(loc("gameMode/negativeBalance"))
  }

  let inviteImpl =  @() invitePlayerImpl(user_id)
  local doInvite = inviteImpl
  if (needConsoleInvite && sessionManager.isAvailableConsoleSession && uid2console.get()?[user_id.tostring()] != null)
    doInvite = @() sessionManager.invite(user_id, inviteImpl)

  if (delayedActions.get() != null) { 
    delayedActions.mutate(@(inv) inv.append(doInvite))
    logSq($"Invite: member {user_id}: saved to delayed. Postpone")
    return
  }

  createSquadAndDo([doInvite, doJoinSquadChat])
}

function inviteToSquad(user_id, needConsoleInvite = true) {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      logSq("invite to squad is not allowed because of multiplayer permissions")
      return
    }
    inviteToSquadImpl(user_id, needConsoleInvite)
  })
}

local isSharedDataRequestInProgress = false

function isSharedDataDifferent() {
  foreach (key, w in squadSharedData)
    if (w.get() != squadServerSharedData[key].get())
      return true

  return false
}

function syncSharedDataImpl() {
  if (isSharedDataRequestInProgress || !isSquadLeader.get() || !isSharedDataDifferent())
    return

  isSharedDataRequestInProgress = true
  let requestData = squadSharedData.map(@(w) w.get())
  MSquadAPI.setSquadData(requestData)
}

MSquadAPI.onSetSquadData({
  onSuccess = function(response) {
    isSharedDataRequestInProgress = false
    applySharedData(response?.context)
    syncSharedDataImpl()
  }
  onFailure = function(_) {
    isSharedDataRequestInProgress = false
  }
})

local syncSharedDataTimer = null
function syncSharedData(...) {
  if (syncSharedDataTimer || !isSquadLeader.get())
    return
  
  syncSharedDataTimer = function() {
    gui_scene.clearTimer(syncSharedDataTimer)
    syncSharedDataTimer = null
    syncSharedDataImpl()
  }
  gui_scene.setInterval(0.1, syncSharedDataTimer)
}

foreach (w in squadSharedData)
  w.subscribe(syncSharedData)

function checkRestrictions(notify) {
  if (!hasValidBalance.get()) {
    showMsgbox({
      text = loc("gameMode/negativeBalance")
      buttons = [
        { text = loc("Ok"), isCurrent = true,
          function action() {
            removeNotify(notify)
            MSquadAPI.rejectInvite(notify.inviterUid)
          }
        }
      ]
    })
    return
  }

  showMsgbox({
    text = loc("squad/acceptInviteQst")
    buttons = [
      { text = loc("Yes"), isCurrent = true,
        function action() {
          removeNotify(notify)
          acceptSquadInvite(notify.inviterUid)
        }
      }
      { text = loc("No"), isCancel = true,
        function action() {
          removeNotify(notify)
          MSquadAPI.rejectInvite(notify.inviterUid)
        }
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}

subscribeGroup(INVITE_ACTION_ID, {
  onShow = checkRestrictions
  onRemove = @(notify) MSquadAPI.rejectInvite(notify.inviterUid)
})

MSquadAPI.onRequestJoin({
  onSuccess = function(response) {
    let { userId = null } = response?.context
    squadId.set(userId)
    fetchSquadInfo()
  },
  onFailure = function(response) {
    logSq($"Failed request join {response?.error_id}")
    onSquadJoinError(response)
  }
})

function requestJoinSquad(userId) {
  MSquadAPI.requestJoin(userId)
}

function onAcceptMembership(newContact) {
  let { realnick, uid } = newContact
  logSq($"Squad application notification from {uid}/{realnick}")
  if ((consoleCompare.live.isFromPlatform(realnick)
      || consoleCompare.psn.isFromPlatform(realnick)) && isSquadLeader.get()) {
    logSq($"Accepting squad membership from {uid}")
    MSquadAPI.acceptMembership(uid)
  } else {
    logSq($"Not squad leader or request was performed from {realnick} non-(xbox or psn) platform. Skipping.")
  }
}

function onApplicationNotify(params) {
  let uid = params?.applicant.id
  if (uid) {
    let contactUid = uid.tostring()
    validateNickNames(uid, @() onAcceptMembership(getContact(contactUid)))
  }
  else
    println($"incorrect uid on contact creation, {uid}")
}


function onApplicationAccept(params) {
  let sid = params?.squad?.id
  logSq($"Squad membership application accepted for squad {sid}")
  squadId.set(sid)
  fetchSquadInfo()
}

function onSquadCreated(params) {
  let sid = params?.requestBy?.userId
  logSq($"Squad created, requested by {sid}")
  squadId.set(sid)
  fetchSquadInfo()
}

let msubscribes = {
  ["msquad.notify_invite"] = onInviteNotify,
  ["msquad.notify_invite_revoked"] = function(params) {
    if (params?.squad?.id != null && params?.invite?.id != null)
      onInviteRevoked(params.squad.id, params.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(params) {
    if (isSquadLeader.get()) {
      let contact = getContact(params.invite.id.tostring())
      removeInvitedSquadmate(contact.uid)
      pushNotification({
        text = loc("squad/mail/reject", {playername = getContactNick(contact) })
        nType = InvitationsTypes.SQUAD_REMOVE
        playerName = getContactNick(contact)
      })
    }
  },
  ["msquad.notify_invite_expired"] = @(params) removeInvitedSquadmate(params.invite.id),
  ["msquad.notify_disbanded"] = function(_params) {
    sessionManager.leave()
    if (!isSquadLeader.get())
      showMsgbox(loc("squad/msgbox_disbanded"))
    reset()
  },
  ["msquad.notify_member_joined"] = addMember,
  ["msquad.notify_member_leaved"] = removeMember,
  ["msquad.notify_leader_changed"] = function(params) {
    let { userId } = params

    squadId.set(userId)
    if (isSquadLeader.get()) {
      myExtSquadData.ready.set(false)
      sessionManager.updateData(userId)
    }
  },
  ["msquad.notify_data_changed"] = function(_params){
    if (isInSquad.get())
      fetchSquadInfo()
  },
  ["msquad.notify_member_data_changed"] = function(params) {
    logSq("Notify member data changed", params)
    MSquadAPI.getMemberData(params.userId)
  },
  ["msquad.notify_member_logout"] = function(params) {
    let {userId} = params
    if (userId not in squadMembers.get())
      return
    setOnlineBySquad(userId, false)
    squadMembers.mutate(function(s){
      s[userId].state.ready <- false
    })
  },
  ["msquad.notify_member_login"] = function(params) {
    let member = squadMembers.get()?[params.userId]
    if (member){
      logSq("member", params.userId, "going to online")
      setOnlineBySquad(member.userId, true)
    }
  },
  ["msquad.notify_squad_created"] = onSquadCreated,
  ["msquad.notify_application"] = onApplicationNotify,
  ["msquad.notify_application_accepted"] = onApplicationAccept,
  ["msquad.notify_application_revoked"] = function(...) {},
  ["msquad.notify_application_denied"] = function(...) {},
}

foreach (k, v in msubscribes) {
  matching_listen_notify(k)
  eventbus_subscribe(k, v)
}

eventbus_subscribe("matching.logged_out", @(...) reset())
eventbus_subscribe("matching.logged_in", function(...) {
  reset()
  fetchSquadInfo()
})

squadSharedData.squadChat.subscribe(function(value) {
  if (value != null) {
    if (squadChatJoined.get() == ChatState.INACTIVE) {
      squadChatJoined.set(ChatState.CREATING)
      joinChat(value?.chatId, value?.chatKey,
        function(result) {
          if ((result?.error ?? 0) == 0)
            squadChatJoined.set(ChatState.ACTIVE)
          else
            logSq($"joinChat returned error {result.error}")
        })
    }
    if (value?.chatId)
      join_voice_chat(voiceChatId(value.chatId))
  }
})

function getUnsuitableCrossplayConditionMembers() {
  let myCPState = crossnetworkPlay.get()
  let res = []

  foreach (m in squadOnlineMembers.get()) {
    let curPlayerCPState = m.state?.crossnetworkPlay
    if (curPlayerCPState in CrossPlayStateWeight
        && userInfo.get()?.userId != m.state?.userId
        && CrossPlayStateWeight[curPlayerCPState] < CrossPlayStateWeight[myCPState])
      res.append(m)
  }
  return res
}

let getUnsuitableVersionConditionMembers = @(gameMode) squadOnlineMembers.get().filter(function(m) {
  let curPlayerVersion = m.state?.version
  let { reqVersion = null } = gameMode
  return curPlayerVersion != null
    && reqVersion != null
    && !check_version(reqVersion, curPlayerVersion)
})

function tryResolveLiveCrossplayPrivilege(callback) {
  if (is_gdk) {
    local leaderCrossplayState = CrossplayState.ALL
    foreach(member in squadOnlineMembers.get()) {
      if (squadId.get() == member?.userId) {
        leaderCrossplayState = member.state?.crossnetworkPlay ?? CrossplayState.ALL
        break
      }
    }

    if (CrossPlayStateWeight[leaderCrossplayState]
        <= CrossPlayStateWeight[crossnetworkPlay.get()]) {
      callback?(true)
      return
    }

    let { try_resolve_crossplay_privilege } = require("%ui/gdk/privileges.nut")
    try_resolve_crossplay_privilege(callback)
  } else
    callback?(true)
}

console_register_command(@() MSquadAPI.disbandSquad(), "msquad.disbandSquad")


return squadState.__merge({
  
  squadOnlineMembers
  myExtSquadData
  
  tryResolveLiveCrossplayPrivilege
  getUnsuitableCrossplayConditionMembers
  getUnsuitableVersionConditionMembers

  inviteToSquad
  dismissAllOfflineSquadmates
  revokeAllSquadInvites
  leaveSquad
  leaveSquadSilent
  transferSquad
  dismissSquadMember

  removeInvitedSquadmate
  revokeSquadInvite
  acceptSquadInvite
  requestJoinSquad

  
  subsMemberAddedEvent = @(func) notifyMemberAdded.append(func)
  subsMemberRemovedEvent = @(func) notifyMemberRemoved.append(func)
})