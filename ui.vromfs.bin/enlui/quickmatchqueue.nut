import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
import "%dngscripts/ecs.nut" as ecs
import "matching.errors" as matching_errors
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay
from "%ui/squad/squadManager.nut" import revokeAllSquadInvites, dismissAllOfflineSquadmates, squadOnlineMembers, isInSquad, squadId, squadMembers, isInvitedToSquad
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/matchingClient.nut" import matchingCall, netStateCall
from "%ui/state/appState.nut" import isInBattleState
from "matching.api" import matching_listen_notify
from "dagor.time" import get_time_msec
from "app" import get_app_id
from "%ui/permissions/permissions.nut" import checkMultiplayerPermissions
from "gameevents" import EventUserMMQueueJoined
from "eventbus" import eventbus_subscribe
from "%ui/gameModes/missionsRatingState.nut" import getDislikedScenes
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeAndInit

let queueState = require("%ui/state/queueState.nut")
let localSettings = require("%ui/options/localSettings.nut")("quickMatch/")
let { STATUS, curGameMode, queueStatus, isInQueue,
  timeInQueue, queueClusters } = queueState
let logQM = with_prefix("[QuickMatchQueue] ")


let joinMatchState = Watched(false)
let testDriveOffer = Watched(null)
let needAutoSquad = localSettings(true, "needAutoSquad")

isInBattleState.subscribe(function(v) {
  if (!v)
    testDriveOffer.set(null)
})

let isChangesBlocked = Computed(@() isInQueue.get() || joinMatchState.get()
  || (isInSquad.get() && squadMembers.get()?[userInfo.get()?.userId].state.ready))
let showBlockedChangesMessage = @() showMsgbox(loc("queue/changesBlocked"))
let startQueueTime = Watched(0)
local nextQPosUpdateTime = 0

function onTimer() {
  if (queueStatus.get() == STATUS.NOT_IN_QUEUE)
    return

  timeInQueue.set(get_time_msec() - startQueueTime.get())

  let now = get_time_msec()
  if (now > nextQPosUpdateTime) {
    nextQPosUpdateTime = now + 1000000

    matchingCall("enlmm.get_my_queue_postion",
      @(_) nextQPosUpdateTime = now + 5000
    )
  }
}

local wasStatus = queueStatus.get()
queueStatus.subscribe(function(s) {
  if (s == STATUS.NOT_IN_QUEUE) {
    timeInQueue.set(0)
    startQueueTime.set(get_time_msec())
    curGameMode.set(null)
    gui_scene.clearTimer(onTimer)
  } else if (s == STATUS.JOINING || (s == STATUS.IN_QUEUE && wasStatus == STATUS.NOT_IN_QUEUE)) {
    startQueueTime.set(get_time_msec())
    gui_scene.clearTimer(onTimer)
    gui_scene.setInterval(1.0, onTimer)
    if (s == STATUS.JOINING)
      timeInQueue.set(0)

    ecs.g_entity_mgr.broadcastEvent(EventUserMMQueueJoined())
  }
  wasStatus = s
})

function errorText(response) {
  if (response.error == 0)
    return ""
  let errKey = response?.error_id ?? matching_errors.error_string(response.error)
  return loc($"error/{errKey}")
}

function joinQueueCallback(response) {
  if (response.error == 0)
    return

  logQM("joinQueueCallback", response)
  queueStatus.set(STATUS.NOT_IN_QUEUE)
  showMsgbox(errorText(response))
}

function joinImpl(gameMode, gameParams) {
  testDriveOffer.set(gameParams?.testOffer)
  netStateCall(function() {
    curGameMode.set(gameMode)
    queueStatus.set(STATUS.JOINING)

    local squadParams = {}
    if (isInSquad.get() && squadOnlineMembers.get().len() > 1) {
      let smembers = []
      let appIds = {}
      foreach (uid, member in squadOnlineMembers.get()) {
        smembers.append(uid)
        appIds[uid.tostring()] <- member.state?.appId ?? get_app_id()
      }
      squadParams = {
        squad = {
          members = smembers
          leader = squadId.get()
        }
        appIds
      }
    }

    let dislikedScenes = getDislikedScenes()
    foreach (queue in gameMode.queues) {
      let queueId = queue.id
      let queueParams = gameParams?[queueId]
      if (queueParams == null)
        continue

      let params = {
        queueId
        clusters = queueClusters.get().filter(@(has) has).keys()
        allowFillGroup = needAutoSquad.get() ?? queue?.allowFillGroup ?? false
        appId = get_app_id()
        crossplayType = crossnetworkPlay.get()
        dislikedScenes
      }.__update(squadParams, queueParams)
      logQM("enlmm.join_quick_match_queue", params)
      matchingCall("enlmm.join_quick_match_queue", joinQueueCallback, params)
    }
  })
}

function joinQueueImpl(gameMode, gameParams = {}) {
  logQM("joinQueue", gameParams, gameMode)
  if (!isInSquad.get()) {
    joinImpl(gameMode, gameParams)
    return
  }

  let { maxGroupSize = 1, minGroupSize = 1 } = gameMode
  local notReadyMembers = ""
  let squadOnlineMembersVal = squadOnlineMembers.get()
  let squadOnlineMembersAmount = squadOnlineMembersVal.len()
  foreach (member in squadOnlineMembers.get())
    if ((!member.isLeader && !member.state?.ready) || member.state?.inBattle)
      notReadyMembers += ((notReadyMembers != "") ? ", " : "") + remap_nick(member?.realnick)

  if (notReadyMembers.len())
    return showMsgbox(loc("squad/notReadyMembers" { notReadyMembers }))
  if (minGroupSize > squadOnlineMembersAmount)
    return showMsgbox(loc("squad/tooFewMembers" { reqMembers = minGroupSize }))
  if (maxGroupSize < squadOnlineMembersAmount)
    return showMsgbox(loc("squad/tooMuchMembers" { maxMembers = maxGroupSize }))

  let offlineNum = squadMembers.get().len() - squadOnlineMembersAmount
  local msg = offlineNum ? loc("squad/hasOfflineMembers", { number = offlineNum }) : ""
  if (isInvitedToSquad.get().len())
    msg = (msg.len() ? "\n" : "").concat(msg, loc("squad/hasInvites", { number = isInvitedToSquad.get().len() }))

  if (msg.len()) {
    return showMsgbox({
      text = "\n".concat(msg, loc("squad/theyWillNotGoToBattle"))
      buttons = [
        { text = loc("squad/removeAndGoToBattle")
          isCurrent = true
          action = function() {
            dismissAllOfflineSquadmates()
            revokeAllSquadInvites()
            joinImpl(gameMode, gameParams)
          }
        }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
  }
  else
    joinImpl(gameMode, gameParams)
}

function joinQueue(gameMode, gameParams = {}) {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      logQM("no permissions to run multiplayer")
      return
    }
    joinQueueImpl(gameMode, gameParams)
  })
}

function leaveQueue(cb = null) {
  queueStatus.set(STATUS.NOT_IN_QUEUE)
  joinMatchState.set(false)
  testDriveOffer.set(null)
  netStateCall(function() {
    matchingCall("enlmm.leave_quick_match_queue", function(_) { cb?() })
  })
}




foreach (name, cb in {
  ["enlmm.on_quick_match_queue_leaved"] = function(request) {
    print("onQuickMatchQueueLeaved")
    logQM("enlmm.on_quick_match_queue_leaved", request)
    queueStatus.set(STATUS.NOT_IN_QUEUE)
  },
  ["enlmm.matchmacking_succeeded"] = function(request) {
    print("onQuickMatchQueueSucceeded")
    logQM("enlmm.matchmacking_succeeded", request)
    joinMatchState.set(true)
  },
  ["enlmm.on_quick_match_queue_joined"] = function(request) {
    print("onQuickMatchQueueJoined")
    logQM("enlmm.on_quick_match_queue_joined", request)
    queueStatus.set(STATUS.IN_QUEUE)
  },
}){
  matching_listen_notify(name)
  eventbus_subscribe(name,cb)
}

eventbus_subscribe("matching.logged_out", @(...) queueStatus.set(STATUS.NOT_IN_QUEUE))


isInSquad.subscribe(function(_) {
  if (isInQueue.get())
    leaveQueue()
})

let squadMembersGeneration = Watched(0)
local prevSquadMembers = {}
let changeGen = @() squadMembersGeneration.modify(@(v) v + 1)

function onSquadMembersChange(v) {
  local changedGen = false
  foreach (uid, member in v) {
    if (uid in prevSquadMembers)
      continue
    let isLeader = member?.isLeader
    if (!member.state?.ready && isLeader) {
      changeGen()
      changedGen = true
      break
    }
  }
  prevSquadMembers = v
  if (!changedGen && (v.len() != prevSquadMembers.len() || !isEqual(v.keys(), prevSquadMembers.keys())))
    changeGen()
}
subscribeAndInit(onSquadMembersChange, squadMembers)


squadMembersGeneration.subscribe(function(_) {
  if (isInQueue.get())
    leaveQueue()
})

return queueState.__merge({
  joinQueue
  leaveQueue
  isChangesBlocked
  showBlockedChangesMessage
  joinMatchState
  testDriveOffer
  needAutoSquad
})