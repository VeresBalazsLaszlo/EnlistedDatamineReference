import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/state/clientState.nut" import appId
from "%ui/leaderboard/lbStateBase.nut" import curLbData, curLbSelfRow, curLbRequestData, setLbRequestData, curLbErrName, refreshLbData, requestSelfRow
from "%ui/userstats/userstatModes.nut" import lbStatsModes
from "%ui/leaderboard/leaderboard_option_state.nut" import separateLeaderboardPlatformName
from "%ui/gameModes/gameModeState.nut" import eventGameModes
from "%ui/userstats/userstat.nut" import userstatLbStats
from "%ui/gameModes/eventModesState.nut" import selEvent, selLbMode
from "%sqstd/frp.nut" import subscribeAndInit, subscribeList
from "%ui/ui_library.nut" import *
from "%ui/leaderboard/lbCategory.nut" import *


const LB_PAGE_ROWS = 25
const REFRESH_PERIOD = 10.0

let lbPage = mkWatched(persist, "lbPage", 0)
let lbCurrentTable = mkWatched(persist, "lbCurrentTable", null)
let isLbWndOpened = mkWatched(persist, "isLbWndOpened", false)
let isRefreshLbEnabled = mkWatched(persist, "isRefreshLbEnabled", false)

let lbPlayersCount = Computed(function() {
  if (curLbData.get() == null)
    return 0
  let { total = 0 } = curLbData.get().findvalue(@(val) "$" in val)?["$"]
  return total > 0 ? total : curLbData.get().len()
})

let curLbPlacement = Computed(function(){
  if (curLbData.get() == null)
    return -1
  return (curLbData.get().findindex(@(val) (val?.self)) ?? -1)
})

let curSeasons = Computed(function() {
  let res = {}
  foreach (mode in lbStatsModes.get())
    res[mode] <- userstatLbStats.get()?.stats[lbCurrentTable.get()?.mode]["$index"] ?? 0
  return res
})

let curLbIdx = Computed(@() (curSeasons.get()?[lbCurrentTable.get()?.mode] ?? 0))
let hasLbHistory = Computed(@() curLbIdx.get() == 0
  || (selEvent.get()?.leaderboardTableIdx ?? curLbIdx.get()) < curLbIdx.get())

let requestDataInternal = keepref(Computed(function() {
  let reqData = lbCurrentTable.get()
  let reqMode = reqData?.mode
  let reqSort = reqData?.sortCategory.field
  if (reqMode == null || reqSort == null
      || userInfo.get()?.token == null
      || appId < 0
      || !lbStatsModes.get().contains(reqMode))
    return null

  let newData =  {
    appid = appId
    category = reqSort
    gameMode = reqMode
    count = LB_PAGE_ROWS
    start = lbPage.get() * LB_PAGE_ROWS
    resolveNick = 1
    group = ""
    table = reqMode
    platformFilter = separateLeaderboardPlatformName.get()
  }
  if (hasLbHistory.get())
    newData.__update({ history = 1 })

  return newData
}))

subscribeAndInit(setLbRequestData, requestDataInternal)

curLbData.subscribe(function(v) {
  if (v != null && curLbPlacement.get() == -1)
    requestSelfRow()
})

let lbCatByGroup = {
  unknown = {
    full = [
      RANK, NAME, BATTLE_RATING, SCORE, BATTLES, VICTORIES_PERCENT,
      KILLS_USING_AIRCRAFT, KILLS_USING_TANK, KILL_DEATH_RATIO, KILLS, BATTLE_TIME,
      BATTLE_RATING_PENALTY, KILLS_USING_APC, KILLS_USING_BIKE
    ]
    best = [TIME_AFTER_BATTLE, BATTLE_RATING, VICTORY_BOOL, SCORE, KILLS, BATTLE_TIME]
    short = [RANK, NAME, BATTLE_RATING]
    sortBy = BATTLE_RATING
  }
  new_year_tournament = {
    full = [
      RANK, NAME, TOURNAMENT_BATTLE_RATING, BATTLE_GROUP_SCORE, SCORE,
      VICTORIES_PERCENT, BATTLES, KILLS_USING_AIRCRAFT, KILLS_USING_TANK, KILLS, BATTLE_TIME,
      KILLS_USING_APC, KILLS_USING_BIKE
    ]
    best = [TIME_AFTER_BATTLE, TOURNAMENT_BATTLE_RATING, VICTORY_BOOL, SCORE, KILLS, BATTLE_TIME]
    short = [RANK, NAME, TOURNAMENT_BATTLE_RATING]
    sortBy = TOURNAMENT_BATTLE_RATING
  }
  for_fun_events = {
    full = [
      RANK, NAME, ZOMBIE_WAVES, ZOMBIE_SCORE, ZOMBIE_KILLS, ZOMBIE_HEADSHOTS, ZOMBIE_BATTLES,
      ZOMBIE_EARLY_QUITS
    ]
    best = [TIME_AFTER_BATTLE, BATTLE_RATING, VICTORY_BOOL, SCORE, KILLS, BATTLE_TIME]
    short = [RANK, NAME, ZOMBIE_WAVES]
    sortBy = ZOMBIE_WAVES
  }
}

let getCategoriesByGroup = @(mode) lbCatByGroup?[mode] ?? lbCatByGroup.unknown

let lbSelCategories = Computed(@() getCategoriesByGroup(selLbMode.get()))

function updateLbMode(_ = null) {
  lbCurrentTable.set({
    mode = selLbMode.get()
    sortCategory = lbSelCategories.get()?.sortBy
  })
}

subscribeList(updateLbMode, selLbMode, lbSelCategories)
updateLbMode()

let ratingBattlesCountByMode = Computed(function() {
  let res = {}
  foreach (mode in eventGameModes.get()) {
    let modeId = mode?.queue.extraParams.leaderboardTables[0]
    if (modeId != null)
      res[modeId] <- userstatLbStats.get()?.stats[modeId]["ratingSessions"] ?? 0
  }
  return res
})

let bestBattlesByMode = Computed(function() {
  let res = {}
  foreach (mode in eventGameModes.get()) {
    let modeId = mode?.queue.extraParams.leaderboardTables[0]
    if (modeId == null)
      continue
    let battles = userstatLbStats.get()?.stats[modeId]["$sessions"] ?? []
    if (battles.len() > 0)
      res[modeId] <- battles
  }
  return res
})

function updateRefreshTimer() {
  if (isRefreshLbEnabled.get()) {
    refreshLbData()
    gui_scene.setInterval(REFRESH_PERIOD, refreshLbData)
  }
  else
    gui_scene.clearTimer(refreshLbData)
}
updateRefreshTimer()
isRefreshLbEnabled.subscribe(@(_) updateRefreshTimer())

console_register_command(@() lbPage.modify(@(v) v + 1), "lb.page_next")
console_register_command(@() lbPage.get() > 0 && lbPage.modify(@(v) v - 1), "lb.page_prev")

return {
  LB_PAGE_ROWS

  curLbData
  curLbSelfRow
  curLbErrName
  isLbWndOpened
  getCategoriesByGroup
  lbSelCategories
  curLbIdx
  lbPlayersCount

  bestBattlesByMode
  ratingBattlesCountByMode
  hasLbHistory
  refreshLbData
  curLbRequestData
  isRefreshLbEnabled
  openLbWnd = @() isLbWndOpened.set(true)
}