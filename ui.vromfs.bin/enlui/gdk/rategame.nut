import "%dngscripts/platform.nut" as platform
from "%ui/debriefing/debriefingState.nut" import isInDebriefing, debriefingData
from "%ui/feedback.nut" import showGameSatisfyingRequest
from "%ui/state/appState.nut" import isInBattleState
from "%ui/meta/servProfile.nut" import armyStats
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let logRG = require("%enlSqGlob/library_logs.nut").with_prefix("[RateGame]")
let onlineSettings = require("%ui/options/onlineSettings.nut")



const ASKED_ID = "is_rate_asked"
const REQ_BATTLES_TO_RATE = 5
const MIN_BATTLE_TIME_TO_RATE = 300
const MIN_KILLS_TO_RATE = 2
const POS_FACTOR_TO_RATE = 4


let { request_review =  @(fn) fn(false) } = platform.is_gdk ? require("%gdkLib/impl/store.nut")
                                            : null

function showReviewWnd(cbk) {
  logRG("Show game satisfying request")
  showGameSatisfyingRequest(function(result) {
    logRG($"Game satisfying request is {result.isLike ? "positive" : "negative"}")
    if (result.isLike) {
      request_review(cbk)
    }
  })
}

function checkRate(_ = null) {
  if (!onlineSettings.onlineSettingUpdated.get()
      || onlineSettings.settings.get()?[ASKED_ID]
      || isInBattleState.get()
      || isInDebriefing.get())
    return

  let battlesCount = armyStats.get().reduce(@(res, val) res + val.battlesCount, 0)
  if (battlesCount < REQ_BATTLES_TO_RATE)
    return logRG($"not enough battles {battlesCount} / {REQ_BATTLES_TO_RATE}")

  let debData = debriefingData.get()
  let hasWon = debData?.result.success ?? false
  if (!hasWon)
    return logRG("need win battle to display rate")

  let spentTime = debData?.result.time ?? 0
  if (spentTime < MIN_BATTLE_TIME_TO_RATE)
    return logRG($"not enough spent time {spentTime} / {MIN_BATTLE_TIME_TO_RATE}")

  let killsCount = (debData?.awards ?? [])
    .findvalue(@(award) award?.id == "kill")?.value ?? 0
  if (killsCount < MIN_KILLS_TO_RATE)
    return logRG($"not enough kills {killsCount} / {MIN_KILLS_TO_RATE}")

  let playerEid = debData?.localPlayerEid
  let playerTeam = debData?.myTeam
  if (playerEid == null || playerTeam == null)
    return logRG($"wrong player eid = {playerEid} or team = {playerTeam}")

  let players = debData?.players ?? {}
  let playerScore = players?[playerEid].score ?? 0
  let totalScores = players.filter(@(s) s?.team == playerTeam)
  let playerPosition = totalScores.filter(@(s) (s?.score ?? 0) > playerScore).len() + 1
  let minPositionToRate = max(totalScores.len() / POS_FACTOR_TO_RATE, 1)
  if (playerPosition > minPositionToRate)
    return logRG($"bad rating position {playerPosition}, should be among the first {minPositionToRate} players")

  showReviewWnd(function(succ) {
    if (succ) {
      onlineSettings.settings.mutate(@(s) s[ASKED_ID] <- true)
    }
  })
}

onlineSettings.onlineSettingUpdated.subscribe(function(val) {
  if (val)
    logRG((onlineSettings.settings.get()?[ASKED_ID] ?? false)
      ? "is already asked"
      : "not asked yet")
})


console_register_command(@() checkRate(null), "xbox.check_rate")
console_register_command(function() {onlineSettings.settings.mutate(@(s) s[ASKED_ID] <- false)}, "meta.resetSeenRateUs")
console_register_command(function() {
  logRG("Review requested from console command")
  showReviewWnd(function(succ) {
    logRG($"Review succeeded: {succ}")
  })
}, "debug.ask_review")

subscribeList(checkRate, isInBattleState, isInDebriefing, onlineSettings.onlineSettingUpdated, armyStats)
