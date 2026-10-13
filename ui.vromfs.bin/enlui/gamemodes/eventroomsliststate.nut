import "%ui/userstats/serverTime.nut" as serverTime
import "math" as math
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, CrossplayState
from "%ui/gameModes/eventRoomsListFilter.nut" import OPT_MULTISELECT
from "%dngscripts/platform.nut" import platformAlias
from "dagor.debug" import logerr
from "%sqstd/timers.nut" import debounce
from "%ui/matchingClient.nut" import matchingCall
from "%sqstd/table.nut" import getValInTblPath
from "matching.errors" import error_string
from "%ui/gameModes/createEventRoomCfg.nut" import createEventRoomCfg, allModes, getValuesFromRule, isModsAvailable
from "%ui/gameModes/sandbox/customMissionOfferState.nut" import featuredMods, featuredModsRoomsList
from "%dngscripts/globalState.nut" import nestWatched
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let { optMode, optFullRooms, optModRooms, optPasswordRooms, optCluster, optDifficulty, optArmiesA, optArmiesB, optCrossplay } = require("%ui/gameModes/eventRoomsListFilter.nut")
let { chooseRandom } = require("%sqstd/rand.nut")

const REFRESH_PERIOD = 10.0

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isRequestInProgress = Watched(false)
let isRefreshEnabled = mkWatched(persist, "isRefreshEnabled", false)
let lastResult = nestWatched("lastResult", {})
let roomsListError = Computed(@()
lastResult.get()?.error ? error_string(lastResult.get().error) : null)
let hideFullRooms = optFullRooms.curValue
let hideModsRooms = optModRooms.curValue
let hidePasswordRooms = optPasswordRooms.curValue
let savedRoomId = nestWatched("savedRoomId", null)
let curSorting = Watched({ column = {}, isReverse = false })
let getServerTime = @() serverTime.get()

let roomsList = Computed(function() {
  let { sortFunc = null } = curSorting.get().column
  local res = lastResult.get()?.digest
  res = res!=null ? clone res : []
  if (!isModsAvailable.get())
    res = res.filter(@(v) v?.scene != null)
  foreach (idx, room in res) {
    if ((room?.sessionLaunchTime ?? -1) > 0)
      res[idx].timeInBattle <- getServerTime() - room.sessionLaunchTime
  }

  if (sortFunc == null)
    return res

  return res.sort(curSorting.get().isReverse ? @(a, b) sortFunc(b, a) : sortFunc)
})

roomsList.subscribe(function(v){
  let featuredModsIds = {}
  featuredMods.get().each(@(val) featuredModsIds[val.id] <- true)
  return featuredModsRoomsList.set(v.filter(@(mod) (mod?.modId ?? "") in featuredModsIds))
})


let selRoom = Computed(@() roomsList.get().findvalue(@(r) r.roomId == savedRoomId.get())
  ?? roomsList.get()?[0])

let mkDebugRooms = @(count) array(count).map(function(_, idx) {
  let room = {
    roomId = 1000 - idx
    membersCnt = 1 + math.rand() % 25
    maxPlayers = 32
    creator = $"WWWWWWWWWWWWWWW{math.rand() % 10}"
    cTime = serverTime.get()
    mode = chooseRandom(allModes.get().len() > 0 ? allModes.get() : ["SQUADS", "LONE_FIGHTERS"])
    cluster = chooseRandom(optCluster.allValues.get())
  }
  foreach (id, rule in createEventRoomCfg.get()?[room.mode].rules ?? {}) {
    let { values, isMultival } = getValuesFromRule(rule)
    if (values.len() == 0)
      continue
    room[id.split("/").top()] <- isMultival ? values.filter(@(_) math.rand() % 2)
      : chooseRandom(values)
  }
  return room
})












let fixedFilters = {
}

function getFiltersByOptions() {
  let res = {}
  let { defaults = {} } = createEventRoomCfg.get()?[allModes.get()?[0]]
  foreach (opt in [optMode, optDifficulty, optArmiesA, optArmiesB, optCluster]) {
    if (opt.optType != OPT_MULTISELECT) {
      logerr("Filter rooms by options support only multiselect options yet")
      continue
    }
    let all = opt.allValues.get()?.len()
    let cur = opt.curValues.get().len()
    if (all == null || all == cur || cur == 0)
      continue
    let idPath = opt.id.split("/")
    let vType = type(getValInTblPath(defaults, idPath))
    res[idPath.top()] <- {
      test = vType == "array" ? "intersect" : "in"
      value = opt.curValues.get()
    }
  }
  if (hideFullRooms.get())
    res.slotsCnt <- { test = "ne", value = 0 }

  if (hideModsRooms.get())
    res.scene <- { test = "ne", value = null}

  if (hidePasswordRooms.get())
    res.hasPassword <- { test = "ne", value = true}

  let crossplayValues = optCrossplay.allValues.get() == null ? [crossnetworkPlay.get()]
    : optCrossplay.curValues.get().len() > 0 ? optCrossplay.curValues.get()
    : optCrossplay.allValues.get()

  if (crossplayValues.len() == 1 && crossplayValues[0] == CrossplayState.OFF) {
    res.crossplay <- { test = "eq", value = "off" }
  } else {
    res.crossPlatform <- {
      test = "intersect",
      value = crossplayValues.map(@(v) $"{platformAlias}_{v}")
    }
  }

  return res
}

function listRoomsCb(response) {
  isRequestInProgress.set(false)
  lastResult.set(isDebugMode.get()
    ? { digest = mkDebugRooms(math.rand() % 100) }
    : response)
}

function updateListRooms() {
  if (isRequestInProgress.get())
    return

  isRequestInProgress.set(true)
  let params = {
    group = "events-lobby"
    cursor = 0
    count = 100
    filter = fixedFilters.__merge(getFiltersByOptions())
  }
  matchingCall("mrooms.fetch_rooms_digest2", listRoomsCb, params)
}

function updateRefreshTimer(isEnabled) {
  if (isEnabled) {
    updateListRooms()
    gui_scene.setInterval(REFRESH_PERIOD, updateListRooms)
  }
  else
    gui_scene.clearTimer(updateListRooms)
}
subscribeAndInit(updateRefreshTimer, isRefreshEnabled)

foreach (opt in [optMode, optDifficulty, optCrossplay, optArmiesA,
  optArmiesB, optCluster, optFullRooms]
)
  (opt?.curValue ?? opt.curValues).subscribe(debounce(@(_) updateListRooms(), 0.2))

function toggleDebugMode() {
  isDebugMode.set(!isDebugMode.get())
  if (isDebugMode.get())
    updateListRooms()
}

console_register_command(toggleDebugMode, "eventRooms.toggleDebugMode")

return {
  roomsList
  roomsListError
  isRequestInProgress
  isRefreshEnabled
  selRoom
  selectRoom = @(roomId) savedRoomId.set(roomId)
  curSorting
}
