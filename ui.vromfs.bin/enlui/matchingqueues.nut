from "%ui/connectHolderR.nut" import isMatchingConnected
from "%ui/state/appState.nut" import isInBattleState
from "%ui/matchingClient.nut" import matchingCall
from "matching.api" import matching_listen_notify
from "%dngscripts/platform.nut" import isPlatformRelevant
from "app" import get_app_id
from "eventbus" import eventbus_subscribe
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

enum FetchState {
  NONE = 0
  PROCESSING = 1
  READY = 2
}

let requestTimeouts = const [5.0, 7.5, 15.0, 30.0]
local timeoutIndex = 0
local fetchState = FetchState.NONE

let matchingQueuesRaw = nestWatched("matchingQueuesRaw", [])

function getGroupSizes(queue) {
  local maxGroupSize
  local minGroupSize

  foreach(team in queue.teams) {
    if (maxGroupSize == null) {
      maxGroupSize = team.maxGroupSize
      minGroupSize = team.minGroupSize
    }
    else {
      maxGroupSize = max(maxGroupSize, team.maxGroupSize)
      minGroupSize = min(minGroupSize, team.minGroupSize)
    }
  }
  return {maxGroupSize, minGroupSize}
}

function processQueues(val) {
  local queues = val.filter(@(q) isPlatformRelevant(q?.allowedPlatforms ?? []))
  if (queues.len() == 0)
    queues = val
  queues = queues.map(@(queue) {
    id = queue.queueId
    locId = queue?.locId
    uiOrder = queue?.extraParams.uiOrder ?? 1000
    uiGroup = queue?.extraParams.uiGroup
    extraParams = clone queue?.extraParams ?? {}
    allowFillGroup = false
  }.__update(queue).__update(getGroupSizes(queue)))
  queues.sort(@(next, prev)
    next.uiOrder <=> prev.uiOrder
    || next.uiGroup <=> prev.uiGroup
    || next.maxGroupSize <=> prev.maxGroupSize
  )
  return queues
}

let matchingQueues = Computed(function(prev) {
  if (prev != FRP_INITIAL && isInBattleState.get())
    return prev
  else if (prev == FRP_INITIAL && isInBattleState.get())
    return {}
  return processQueues(matchingQueuesRaw.get())
})

let isCheckNecessary = Computed(@() matchingQueues.get().len() == 0 && isMatchingConnected.get())

local fetch_matching_queues

function fetchMatchingQueues(force = false) {
  if (fetchState == FetchState.PROCESSING || (!force && fetchState == FetchState.READY))
    return

  if (force)
    timeoutIndex = 0

  fetchState = FetchState.PROCESSING
  fetch_matching_queues()
}

function fetchSucceeded() {
  fetchState = FetchState.READY
  timeoutIndex = 0 
}

function fetchFailed() {
  fetchState = FetchState.NONE
  if (timeoutIndex >= requestTimeouts.len()) {
    timeoutIndex = 0
    
    return
  }

  let delay = requestTimeouts[timeoutIndex++]
  gui_scene.resetTimeout(delay, fetchMatchingQueues)
}

fetch_matching_queues = function() {
  matchingCall("enlmm.get_queues_list",
    function(response) {
      debugTableData(response)
      if (!isMatchingConnected.get()) {
        fetchFailed()
        return
      }

      if (response.error != 0) {
        fetchFailed()
        return
      }

      let queues = response?.queues ?? []
      matchingQueuesRaw.set(queues)
      
      
      if (queues.len() == 0)
        fetchFailed()
      else
        fetchSucceeded()
    }, { appId = get_app_id(), rulesVersion = "1.0" })
}

eventbus_subscribe("matching.logged_in", @(...) fetchMatchingQueues(true))

if (isCheckNecessary.get())
  fetchMatchingQueues(true)
isCheckNecessary.subscribe(function(isNecessary) {
  if (isNecessary)
    fetchMatchingQueues(true)
})

matching_listen_notify("enlmm.notify_games_list_changed")
eventbus_subscribe("enlmm.notify_games_list_changed", @(_notify) fetchMatchingQueues(true))

return {
  matchingQueues
}
