import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/charClient/charClientEvent.nut" as CharClientEvent
from "dagor.time" import get_time_msec
from "%ui/charClient/charClient.nut" import low_level_client
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/ui_library.nut" import *

const LEADERBOARD_NO_START_LIST_INDEX = 0x7FFFFFFF
const LB_REQUEST_TIMEOUT = 45000
const LB_UPDATE_INTERVAL = 5000 

let curLbData = Watched(null)
let curLbSelfRow = Watched(null)
let curLbRequestData = Watched(null)
let curLbErrName = Watched(null)
local lastRequestTime = 0
local lastUpdateTime = 0


let lbHandlers = {}
let lbClient = CharClientEvent({ name = "leaderboard", client = low_level_client, handlers = lbHandlers })

function setLbHandler(id, func){
  assert(id not in lbHandlers, @() $"lbHnadler is already exist: {id}")
  lbHandlers[id] <- func
}

function mkSelfRequest(requestData) {
  if (requestData == null)
    return null
  let res = clone requestData
  res.start <- LEADERBOARD_NO_START_LIST_INDEX
  res.count <- 0
  return res
}

function setLbRequestData(requestData) {
  if (isEqual(requestData, curLbRequestData.get()))
    return

  if (!isEqual(mkSelfRequest(requestData), mkSelfRequest(curLbRequestData.get())))
    curLbSelfRow.set(null)
  curLbData.set(null) 
  curLbErrName.set(null)
  curLbRequestData.set(requestData)
}

function requestSelfRow() {
  let requestData = curLbRequestData.get()
  if (requestData == null)
    return

  assert(requestData.appid >= 0)
  let selfRequest = mkSelfRequest(requestData)
  lbClient.request("cln_get_leaderboard_json:self", { data = selfRequest }, selfRequest)
}


lbHandlers["cln_get_leaderboard_json:self"] <- function(result, selfRequest) {
  if (!isEqual(selfRequest, mkSelfRequest(curLbRequestData.get())))
    return

  local newSelfRow = null
  foreach (data in result)
    if (data?._id == userInfo.get()?.userId) {
      newSelfRow = data
      newSelfRow.name <- userInfo.get()?.nameorig ?? ""
      break
    }
  curLbSelfRow.set(newSelfRow)
}


let isRequestInProgress = @() lastRequestTime > lastUpdateTime
  && lastRequestTime + LB_REQUEST_TIMEOUT > get_time_msec()

let canRefresh = @() !isRequestInProgress()
  && isLoggedIn.get()
  && (!curLbData.get() || (lastUpdateTime + LB_UPDATE_INTERVAL < get_time_msec()))

function refreshLbData() {
  if (!canRefresh())
    return
  let requestData = curLbRequestData.get()
  if (requestData == null) {
    curLbData.set([])
    curLbErrName.set(null)
    return
  }

  lastRequestTime = get_time_msec()
  lbClient.request("cln_get_leaderboard_json", { data = requestData }, requestData)
}


lbHandlers["cln_get_leaderboard_json"] <- function(result, requestData) {
  lastUpdateTime = get_time_msec()
  if (!isEqual(requestData, curLbRequestData.get())) {
    refreshLbData()
    return
  }

  curLbErrName.set(result?.result.error)

  let isSuccess = result?.result.success ?? true
  let lbTbl = isSuccess ? result : {}
  local selfRow = null
  let newLbData = []
  foreach (name, data in lbTbl) {
    if (typeof data != "table" || (data?.idx ?? -1) < 0)
      continue
    data.name <- name
    newLbData.append(data)
    if (data?._id == userInfo.get()?.userId) {
      selfRow = data
      selfRow.name <- userInfo.get()?.name ?? ""
    }
  }
  newLbData.sort(@(a, b)
    (b?.idx ?? -1) >= 0 <=> (a?.idx ?? -1) >= 0 || (a?.idx ?? -1) <=> (b?.idx ?? -1))

  if (selfRow)
    curLbSelfRow.set(selfRow)
  curLbData.set(newLbData)
}


return {
  curLbData
  curLbSelfRow
  curLbRequestData = Computed(@() curLbRequestData.get())
  curLbErrName = Computed(@() curLbErrName.get())
  setLbHandler
  lbClient
  setLbRequestData
  refreshLbData
  requestSelfRow
}