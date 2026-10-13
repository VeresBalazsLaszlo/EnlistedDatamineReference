import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/userstats/serverTime.nut" as time
import "userstats" as userstat
import "%ui/charClient/charClientEvent.nut" as CharClientEvent
from "%sqstd/string.nut" import tostring_r
from "dagor.debug" import debug
from "dagor.workcycle" import resetTimeout
from "string" import split_by_chars
from "%sqstd/timers.nut" import debounce
from "dagor.time" import get_time_msec
from "%ui/helpers/netErrorConverter.nut" import error_response_converter
from "%dngscripts/globalState.nut" import hardPersistWatched
from "eventbus" import eventbus_subscribe
from "app" import get_app_id
from "%sqstd/underscore.nut" import arrayByRows
from "%ui/state/clientState.nut" import appId, gameLanguage
from "%ui/userstats/serverTimeUpdate.nut" import serverTimeUpdate
from "math" import min
from "%ui/ui_library.nut" import *
from "%ui/charClient/charClient.nut" import addPublisherToHeaders

let loginState = require("%ui/state/login_state.nut")

let logUs = with_prefix("[USERSTAT] ")
let matchingNotifications = require("%ui/notifications/matchingNotifications.nut")



let handlers  = {}
let executors = {}
let clientUserStats = CharClientEvent({name   = "userStats",
                                         client = userstat,
                                         handlers,
                                         executors})


let adminHandlers   = {}
let adminUserStats  = CharClientEvent({name     = "userStats.admin",
                                         client   = userstat,
                                         handlers = adminHandlers})

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 300000 
const MAX_DELAY_FOR_MASSIVE_REQUEST_SEC = 300 

let chardToken = Computed(@() userInfo.get()?.token)
let userId = Computed(@() userInfo.get()?.userId)
let statsFilter = hardPersistWatched("statsFilter", { modes = [] })

local needSyncSteamAchievements = false
userId.subscribe(@(_v) needSyncSteamAchievements = loginState.isSteamRunning.get())

const errorLogMaxLen = 10
let errorLog = hardPersistWatched("errorLog", [])
let lastSuccessTime = hardPersistWatched("lastSuccessTime", 0)

function checkError(actionId, result) {
  if (result?.error == null)
    return
  errorLog.mutate(function(l) {
    l.append({ action = actionId, result = result, time = get_time_msec() })
    if (l.len() > errorLogMaxLen)
      l.remove(0)
  })
}

function doRequest(request, cb) {
  userstat.request(request, @(result) error_response_converter(cb, result))
}


let syncSteamAchievements = @() clientUserStats.request("SyncUnlocksWithSteam")

handlers["SyncUnlocksWithSteam"] <- @(_)null

function makeUpdatable(persistName, request, defValue) {
  let dataKey = $"userstat.{persistName}"
  let lastTimeKey = $"userstat.{persistName}.lastTime"
  let data = hardPersistWatched(dataKey, defValue)
  let lastTime = hardPersistWatched(lastTimeKey, { request = 0, update = 0 })
  let dataUpdate = @(v) data.set(v)
  let lastTimeUpdate = @(v) lastTime.set(v)
  let isRequestInProgress = @() lastTime.get().request > lastTime.get().update
    && lastTime.get().request + STATS_REQUEST_TIMEOUT > get_time_msec()
  let canRefresh = @() !isRequestInProgress()
    && chardToken.get() != null
    && (!lastTime.get().update || (lastTime.get().update + STATS_UPDATE_INTERVAL < get_time_msec()))

  function processResult(result, cb) {
    checkError(persistName, result)
    if (cb)
      cb(result)

    serverTimeUpdate(1000 * (result?.response.timestamp ?? 0), lastTime.get().request)
    if (result?.error) {
      dataUpdate(defValue)
      logUs($"Failed to update {persistName}")
      logUs(result)
      return
    }

    logUs($"Updated {persistName}")
    lastSuccessTime.set(get_time_msec())
    dataUpdate(result?.response ?? defValue)

    if (needSyncSteamAchievements) {
      syncSteamAchievements()
      needSyncSteamAchievements = false
    }
  }

  function prepareToRequest() {
    lastTimeUpdate(lastTime.get().__merge({request = get_time_msec()}))
  }

  function refresh(cb = null) {
    if (!chardToken.get() || appId < 0) {
      dataUpdate(defValue)
      if (cb)
        cb({ error = "not logged in" })
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()

    request(function(result){
      processResult(result, cb)
    })
  }

  function forceRefresh(cb = null) {
    lastTimeUpdate(lastTime.get().__merge({ update = 0, request = 0}))
    refresh(cb)
  }

  if (lastTime.get().request > lastTime.get().update)
    forceRefresh()

  return {
    id = persistName
    data
    refresh
    forceRefresh
    processResult
    prepareToRequest
    lastUpdateTime = Computed(@() lastTime.get().update)
  }
}


let descListUpdatable = makeUpdatable("GetUserStatDescList",
  @(cb) doRequest({
    headers = {
      appid = appId,
      token = chardToken.get(),
      language = loc("steam/languageName", gameLanguage).tolower()
    },
    action = "GetUserStatDescList"
  }, cb),
  {})

function isEqualUnordered(arr1, arr2) {
  let tbl1 = arr1.totable()
  let tbl2 = arr2.totable()
  if (tbl1.len() != tbl2.len())
    return false
  foreach (val, _ in tbl1)
    if (val not in tbl2)
      return false
  return true
}

function setStatsModes(modes) {
  let curModes = statsFilter.get().modes
  if (!isEqualUnordered(curModes, modes))
    statsFilter.mutate(function(v) { v.modes = modes })
}

let statsUpdatable = makeUpdatable("GetStats",
  @(cb) doRequest({
      headers = {
        appid = appId,
        token = chardToken.get()
      },
      action = "GetStats"
      data = statsFilter.get(),
    }, cb),
  {})



let lbStatsFilter = hardPersistWatched("lbStatsFilter", { modes = [] })

function setLbStatsModes(modes) {
  lbStatsFilter.mutate(function(v) { v.modes = modes })
}

let lbStatsUpdatable = makeUpdatable("GetLbStats",
  @(cb) doRequest({
      headers = {
        appid = appId,
        token = chardToken.get()
      },
      action = "GetStats"
      data = lbStatsFilter.get(),
    }, cb),
  {})

let unlocksUpdatable = makeUpdatable("GetUnlocks",
  @(cb) doRequest({
      headers = addPublisherToHeaders ({
        appid = appId,
        token = chardToken.get()
      }),
      action = "GetUnlocks"
      data = { withUserLogs = true },
    }, cb),
  {})

let infoTablesUpdatable = makeUpdatable("infoTables",
  @(cb) doRequest({
    headers = {
      appid = appId,
      token = chardToken.get(),
    },
    action = "GetTablesInfo"
  }, cb),
  {})

function updateConfigsIfNeed(token) {
  if (token == null)
    return

  descListUpdatable.forceRefresh()
  unlocksUpdatable.forceRefresh()
  infoTablesUpdatable.forceRefresh()
}

chardToken.subscribe(updateConfigsIfNeed)

let lastMassiveRequestTime = hardPersistWatched("lastMassiveRequestTime", 0)
let massiveRefresh = debounce(
  function(checkTime) {
    logUs("Massive update start")
    foreach (data in [statsUpdatable, descListUpdatable, unlocksUpdatable, infoTablesUpdatable])
      if (data.lastUpdateTime.get() < checkTime) {
        logUs($"Update {data.id}")
        data.forceRefresh()
      }
    lastMassiveRequestTime.set(checkTime)
  }, 0, MAX_DELAY_FOR_MASSIVE_REQUEST_SEC)

let nextMassiveUpdateTime = hardPersistWatched("nextMassiveUpdateTime", 0)
statsUpdatable.data.subscribe(function(stats) {
  local nextUpdate = 0
  let curTime = time.get()
  foreach (tbl in stats?.inactiveTables ?? {}) {
    let startsAt = tbl?["$startsAt"] ?? 0
    if (startsAt > curTime)
      nextUpdate = nextUpdate > 0 ? min(nextUpdate, startsAt) : startsAt
  }
  foreach (tbl in stats?.stats ?? {}) {
    let endsAt = tbl?["$endsAt"] ?? 0
    if (endsAt > curTime)
      nextUpdate = nextUpdate > 0 ? min(nextUpdate, endsAt) : endsAt
  }
  nextMassiveUpdateTime.set(nextUpdate)
})

let lastMassiveRequestQueued = hardPersistWatched("lastMassiveRequestQueued", 0)
if (lastMassiveRequestQueued.get() > lastMassiveRequestTime.get())
  massiveRefresh(lastMassiveRequestQueued.get()) 

function queueMassiveUpdate() {
  logUs("Queue massive update")
  lastMassiveRequestQueued.set(nextMassiveUpdateTime.get())
  massiveRefresh(nextMassiveUpdateTime.get())
}

function startMassiveUpdateTimer() {
  if (nextMassiveUpdateTime.get() <= lastMassiveRequestTime.get())
    return
  resetTimeout(nextMassiveUpdateTime.get() - time.get(), queueMassiveUpdate)
}
startMassiveUpdateTimer()
nextMassiveUpdateTime.subscribe(@(_) startMassiveUpdateTimer())


function regeneratePersonalUnlocks(context = null) {
  clientUserStats.request("RegeneratePersonalUnlocks", {}, context)
}


handlers["RegeneratePersonalUnlocks"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (result?.error)
    return
  unlocksUpdatable.forceRefresh()
  statsUpdatable.forceRefresh()
}


function generatePersonalUnlocks(context = null) {
  clientUserStats.request("GeneratePersonalUnlocks", {data = {table = "daily"}}, context)
}

handlers["GeneratePersonalUnlocks"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}



function setLastSeen(config) {
  clientUserStats.request("SetLastSeenUnlocks", {data = config})
}

handlers["SetLastSeenUnlocks"] <- function(result) {
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}

let unlockRewardsInProgress = Watched({})
function receiveRewards(unlockName, stage, context = null) {
  if (unlockName in unlockRewardsInProgress.get())
    return
  logUs($"receiveRewards {unlockName}={stage}", context)
  unlockRewardsInProgress.mutate(@(u) u[unlockName] <- true)
  clientUserStats.request("GrantRewards",
    {data = {unlock = unlockName, stage = stage}},
    (context ?? {}).__merge({ unlockName }))
}

handlers["GrantRewards"] <- function(result, context) {
  let { unlockName = null } = context
  if (unlockName in unlockRewardsInProgress.get())
    unlockRewardsInProgress.mutate(@(v) v.$rawdelete(unlockName))
  logUs("GrantRewards result:", result)
  if ("error" in result)
    return
  unlocksUpdatable.forceRefresh()
  statsUpdatable.forceRefresh()
}

function receiveRewardsAllUp(unlocksToRewards, context = null) {
  let idsTbl = {}
  let data = []
  foreach (task in unlocksToRewards) {
    let { name, upToStage = -1 } = task
    if (name not in unlockRewardsInProgress.get()) {
      data.append({ unlock = name, up_to_stage = upToStage })
      idsTbl[name] <- true
    }
  }
  if (data.len() == 0)
    return
  let idsTblKeys = idsTbl.keys()
  logUs($"receiveRewardsAllUp: {", ".join(idsTblKeys)}")
  unlockRewardsInProgress.mutate(@(u) u.__update(idsTbl))
  clientUserStats.request("BatchGrantRewards",
    {data = {unlocksToReward = data}},
    (context ?? {}).__merge({ unlocksKeys = idsTblKeys }))
}

function receiveRewardsAll(unlocksToRewards, context = null) {
  let idsTbl = {}
  let data = []
  foreach (task in unlocksToRewards) {
    let { name, stage } = task
    if (name not in unlockRewardsInProgress.get()) {
      data.append({ unlock = name, stage })
      idsTbl[name] <- true
    }
  }
  if (data.len() == 0)
    return
  let idsTblKeys = idsTbl.keys()
  logUs($"receiveRewardsAll: {", ".join(idsTblKeys)}")
  unlockRewardsInProgress.mutate(@(u) u.__update(idsTbl))
  clientUserStats.request("BatchGrantRewards",
    {data = {unlocksToReward = data}},
    (context ?? {}).__merge({ unlocksKeys = idsTblKeys }))
}

handlers["BatchGrantRewards"] <- function(result, context) {
  let { unlocksKeys = [] } = context
  unlockRewardsInProgress.mutate(function(u) {
    foreach (key in unlocksKeys)
      if (key in u)
        u.$rawdelete(key)
  })
  logUs("BatchGrantRewards result:", result)
  if ("error" in result)
    return
  unlocksUpdatable.forceRefresh()
  statsUpdatable.forceRefresh()
}

function resetPersonalUnlockProgress(unlockName, context = null) {
  adminUserStats.request("AdmResetPersonalUnlockProgress", {
    headers = { token = chardToken.get(), userId = userId.get() },
    data = { unlock = unlockName }
  },
  context)
}

adminHandlers["AdmResetPersonalUnlockProgress"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}


function rerollUnlock(unlockName, cb = null) {
  doRequest({
    headers = addPublisherToHeaders({ appid = appId, token = chardToken.get() }),
    data = { unlock = unlockName }
    action = "RerollPersonalUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
    statsUpdatable.forceRefresh()
  })
}


function changeStat(stat, mode, amount, shouldSet, cb = null) {
  local errorText = null
  if (typeof amount != "integer" && typeof amount != "float")
    errorText = $"Amount must be numeric (current = {amount})"
  else if (descListUpdatable.data.get()?.stats?[stat] == null) {
    errorText = $"Stat {stat} does not exist."
    let similar = []
    let parts = split_by_chars(stat, "_", true)
    foreach (s, _v in descListUpdatable.data.get()?.stats ?? {})
      foreach (part in parts)
        if (s.contains(part)) {
          similar.append(s)
          break
        }
    let statsText = "\n      ".join(["  Similar stats:"].extend(arrayByRows(similar, 8).map(@(v) " ".join(v))))
    errorText = "\n  ".join([errorText, statsText], true)
  }

  if (errorText != null) {
    cb?({ error = errorText })
    return
  }

  let headers = addPublisherToHeaders({
    appid = appId,
    token = chardToken.get()
    userId = userId.get()
  })

  doRequest({
      headers
      data = {
        [stat] = shouldSet ? { "$set": amount } : amount,
        ["$mode"] = mode
      }
      action = "ChangeStats"
    },
    function(result) {
      cb?(result)
      if (!result?.error) {
        unlocksUpdatable.forceRefresh()
        statsUpdatable.forceRefresh()
      }
    })
}


function addStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, false, cb)
}


function setStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, true, cb)
}


function sendSpecialStat(stat, value, action, token, cb = null) {
  let haveTxt = value ? "present" : "absent"
  debug($"Sending special stat <{stat}>: {haveTxt}")
  doRequest({
    headers = addPublisherToHeaders({
      appid = get_app_id(),
      token = token
    }),
    data = {
      [stat] = value ? true : false
    },
    action = action
  },
  function(result) {
    if (cb)
      cb({})
    if (result?.error)
      debug($"Failed to send special stat <{stat}>: {result.error}")
    else
      debug($"Succesfully sent special stat <{stat}>")
  })
}


function sendPsPlus(havePsPlus, token, cb = null) {
  sendSpecialStat("have_ps_plus", havePsPlus, "SetPsPlus", token, cb)
}


function sendGamePass(haveGamePass, token, cb = null) {
  sendSpecialStat("have_game_pass", haveGamePass, "SetGamePass", token, cb)
}


function buyUnlock(unlockName, stage, currency, price, cb = null) {
  doRequest({
    headers = addPublisherToHeaders({ appid = appId, token = chardToken.get()})
    data = { name = unlockName, stage = stage, price = price, currency = currency },
    action = "BuyUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(function(_res) {
      statsUpdatable.forceRefresh(cb)
    })
  })
}

let seasonRewards = hardPersistWatched("seasonRewards", null)
function updateSeasonRewards(cb = null) {
  doRequest({
    headers = addPublisherToHeaders({ appid = appId, token = chardToken.get()})
    action = "GetSeasonRewards"
  },
  function(result) {
    if (!result?.error)
      seasonRewards.set(result?.response)
    cb?(result)
  })
}

function clnChangeStats(data, cb = null) {
  statsUpdatable.prepareToRequest()
  unlocksUpdatable.prepareToRequest()
  data["$filter"] <- statsFilter.get()
  doRequest({
    headers = addPublisherToHeaders({ appid = appId, token = chardToken.get()})
    data = data
    action = "ClnChangeStats"
  },
  function(result) {
    statsUpdatable.processResult(result, cb)
    unlocksUpdatable.processResult(result, cb)
  })
}

function clnAddStat(mode, stat, amount, cb = null) {
  let data = {
      [stat] = amount,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

function clnSetStat(mode, stat, amount, cb = null) {
  let statData = {
    ["$set"] = amount
  }

  let data = {
      [stat] = statData,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

function markUserLogsAsSeen(userlogs) {
  doRequest({
    headers = addPublisherToHeaders({
      appid = appId,
      token = chardToken.get()
    }),
    action = "SetLastSeenUserLogs"
    data = { userlogs },
  }, function(result) {
    if ("error" not in result) {
      unlocksUpdatable.forceRefresh()
      statsUpdatable.forceRefresh()
    }
  })
}

matchingNotifications.subscribe("userStat",
  @(ev) ev?.func == "updateConfig" ? queueMassiveUpdate() : unlocksUpdatable.forceRefresh())


function requestAnoPlayerStats(uid, cb){
  doRequest({
    headers = {
      appid = appId,
      token = chardToken.get()
      userId = uid
    },
    action = "AnoGetStats"
    allow_other = true
    data = statsFilter.get()
  }, cb)
}

let debugRecursive = @(v) println(tostring_r(v, { recursionLevel = 7 }))
console_register_command(@() descListUpdatable.forceRefresh(console_print), "userstat.get_desc_list")
console_register_command(@() debugRecursive(descListUpdatable.data.get()) ?? console_print("Done"),
  "userstat.debug_desc_list")
console_register_command(@() statsUpdatable.forceRefresh(console_print), "userstat.get_stats")
console_register_command(@() debugRecursive(statsUpdatable.data.get()) ?? console_print("Done"),
  "userstat.debug_stats")


console_register_command(@() infoTablesUpdatable.forceRefresh(console_print), "userstat.get_tables")

console_register_command(@() unlocksUpdatable.forceRefresh(console_print), "userstat.get_unlocks")
console_register_command(@() regeneratePersonalUnlocks({console_print = true}), "userstat.reset_personal")
console_register_command(@() updateSeasonRewards(@(v) debugRecursive(v?.response ?? v) ?? console_print("Done")), "userstat.get_season_rewards")
console_register_command(@(unlockName) resetPersonalUnlockProgress(unlockName, {console_print = true}), "userstat.reset_unlock_progress")
console_register_command(@() generatePersonalUnlocks({console_print = true}), "userstat.generate_personal")
console_register_command(@() debugRecursive(unlocksUpdatable.data.get()?.personalUnlocks), "userstat.debug_personal")
console_register_command(@(stat, mode, amount) addStat(stat, mode, amount, console_print), "userstat.add_stat")
console_register_command(@(stat, mode, amount) setStat(stat, mode, amount, console_print), "userstat.set_stat")
console_register_command(@(have_psplus) sendPsPlus(have_psplus, chardToken.get()), "userstat.set_ps_plus")
console_register_command(@() syncSteamAchievements(), "userstat.sync_steam_achievements")
console_register_command(@(mode, stat, amount) clnAddStat(mode, stat, amount, console_print), "userstat.cln_add_stat")
console_register_command(@(mode, stat, amount) clnSetStat(mode, stat, amount, console_print), "userstat.cln_set_stat")
console_register_command(@() nextMassiveUpdateTime.set(time.get() + 1), "userstat.test_massive_update")
console_register_command(@(amount) addStat("monthly_challenges", "solo", amount, console_print), "unlocks.add")

console_register_command(@(userlogs) markUserLogsAsSeen(userlogs), "unlocks.markUserLogsAsSeen")


let dbgUserstatFailed = Watched(false)
console_register_command(@() dbgUserstatFailed.set(!dbgUserstatFailed.get()), "userstat.fail")

let cmdList = {
  setLastSeenCmd = @(d) setLastSeen(d?.p ?? d)
  refreshStats = @(_d = null) statsUpdatable.refresh()
  forceRefreshUnlocks = @(_d = null) unlocksUpdatable.forceRefresh()
}

function setUserstatExecutor(event, cb) {
  assert(event not in executors)
  executors[event] <- cb
}

eventbus_subscribe("userstat.cmd", @(d) cmdList?[d.cmd]?(d))

return {
  buyUnlock
  userstatStats = statsUpdatable.data
  userstatUnlocks = unlocksUpdatable.data
  userstatDescList = descListUpdatable.data
  userstatTables = infoTablesUpdatable.data
  setUserstatExecutor
  receiveUnlockRewards = receiveRewards
  receiveUnlockRewardsAll = receiveRewardsAll
  receiveUnlockRewardsAllUp = receiveRewardsAllUp
  sendPsPlusStatusToUserstatServer = sendPsPlus
  sendGamePassStatusToUserstatServer = sendGamePass
  rerollUnlock
  updateSeasonRewards
  seasonRewards
  forceRefreshUnlocks = cmdList.forceRefreshUnlocks
  refreshUserstats = cmdList.refreshStats
  setStatsModes
  userstatLbStats = lbStatsUpdatable.data
  setLbStatsModes
  refreshLbUserstats = lbStatsUpdatable.refresh
  markUserLogsAsSeen
  requestAnoPlayerStats
  unlockRewardsInProgress
  MAX_DELAY_FOR_MASSIVE_REQUEST_SEC
}
