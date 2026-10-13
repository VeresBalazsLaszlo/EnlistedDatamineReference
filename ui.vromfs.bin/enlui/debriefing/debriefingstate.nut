import "%ui/hud/state/armyData.nut" as armyData
import "%ui/hud/state/soldiersData.nut" as soldiersData
import "%ui/debriefing/debriefing_es.nut" as battleResult
import "%dngscripts/ecs.nut" as ecs
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE
from "%enlSqGlob/sqevents.nut" import EventOnBattleResult
from "%enlSqGlob/wipFeatures.nut" import isDebugDebriefingMode
from "app" import get_session_id
from "eventbus" import eventbus_send
from "%ui/unlocks/taskListState.nut" import dailyTasks
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/hud/state/teams.nut" import teams
from "%ui/hud/state/local_player.nut" import localPlayerEid, localPlayerTeam, localPlayerGroupId,
  localPlayerGroupMembers
from "%ui/state/singleMissionRewardState.nut" import singleMissionRewardId, singleMissionRewardSum
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/state/appState.nut" import isInBattleState
from "%ui/hud/state/practice_state.nut" import isPractice
from "%ui/hud/state/replay_state.nut" import isReplay
from "settings" import get_setting_by_blk_path, set_setting_by_blk_path, save_settings
from "%ui/eventPass/eliteEventPass.nut" import eventTokenMultiplier
from "%ui/gameLauncher.nut" import lastGame
from "%ui/tutorial/battleTutorial.nut" import curBattleTutorial, curBattleTutorialTank,
  curBattleTutorialEngineer, curBattleTutorialAircraft, markCompleted
from "%ui/contacts/contact.nut" import contactUserIds
from "%ui/ui_library.nut" import *

let logD = with_prefix("[DEBRIEFING] ")


const INVALID_SESSION = "0"
const BLK_PATH_HIDE_ANIM = "gameplay/showAnim"

let debriefingShow = nestWatched("debriefingShow", false)
let sourceData = nestWatched("debriefingData", {})
let skipDebriefing = nestWatched("skipDebriefing", false)
let debriefingShowAnim = Watched(get_setting_by_blk_path(BLK_PATH_HIDE_ANIM) ?? true)

function setDebriefingShowAnim(v) {
  debriefingShowAnim.set(v)
  set_setting_by_blk_path(BLK_PATH_HIDE_ANIM, v)
  save_settings()
}

function updateData(data) {
  sourceData.mutate(@(v) v.__update(data))
}



let statsBeforeBattle = nestWatched("statsBeforeBattle", {})

function resetStatsChange() {
  let daily = {}
  foreach (task in dailyTasks.get())
    daily[task.name] <- {
      current = task.current
      isCompleted = task.isCompleted
    }
  statsBeforeBattle.set(daily)
}

function updateStatsChange() {
  logD($"Update stats change, tasks:{dailyTasks.get().len()}")
  let wasTasksProgress = statsBeforeBattle.get()
  let dailyTasksProgress = []
  foreach (task in dailyTasks.get()) {
    let wasTaskData = wasTasksProgress?[task.name]
    if (wasTaskData == null)
      continue

    if (task.current > wasTaskData.current || (task.isCompleted && !wasTaskData.isCompleted))
      dailyTasksProgress.append(task.__merge({
        wasCurrent = wasTaskData.current
      }))
  }
  updateData({ dailyTasksProgress })
}



function updatePlayerInfo() {
  logD($"Update player info, myTeam:{localPlayerTeam.get()}")
  let teamsData = {}
  foreach (team in teams.get())
    if (team?["team__id"]) {
      let teamId = team["team__id"].tostring()
      teamsData[teamId] <- {
        teamId
        armyId = team?["team__armyId"]
        armies = team?["team__armies"]
      }
    }
  updateData({
    localPlayerEid = localPlayerEid.get()
    localPlayerGroupMembers = localPlayerGroupMembers.get()
    localPlayerGroupId = localPlayerGroupId.get()
    myTeam = localPlayerTeam.get()
    teams = teamsData
  })
}



battleResult.subscribe(function(data) {
  logD("Update battle result")
  updateData(data)
  updatePlayerInfo()
  updateStatsChange()
})



let chargeExp = @(expData) eventbus_send("charge_battle_exp_rewards", expData)

let mkGetExpToNextLevel = @(expToLevel)
  @(level, maxLevel) level < (maxLevel ?? (expToLevel.len() - 1))
    ? (expToLevel?[level] ?? 0)
    : 0

function shareExp(list, expSum) {
  let oneExp = (expSum / max(list.len(), 1)).tointeger()
  return list.map(@(_) { exp = oneExp })
}

function calcSingleMissionExpReward(expReward) {
  let { squadsExp = {}, soldiersExp = {} } = expReward
  let expSum = (armyData.get()?.premiumExpMul ?? 1.0) * singleMissionRewardSum.get()
  let tutorial = isTutorial.get()
  return {
    armyExp = expSum.tointeger()
    squadsExp = tutorial ? {} : shareExp(squadsExp, expSum)
    soldiersExp = tutorial ? {} : shareExp(soldiersExp, expSum)
  }
}

function extrapolateStatsExp(soldier, expData, getExpToNextLevel) {
  
  
  local { maxLevel = 1, level, exp } = soldier
  let addExp = expData.exp
  local nextExp = getExpToNextLevel(level, maxLevel)
  let wasExp = {
    exp
    level
    nextExp
  }
  exp += addExp
  while(nextExp > 0 && exp >= nextExp) {
    exp -= nextExp
    if (level < maxLevel)
      level++
    nextExp = getExpToNextLevel(level, maxLevel)
  }

  return expData.__merge({
    exp = addExp
    wasExp = wasExp
    newExp = {
      exp
      level
      nextExp
    }
  })
}

function getSquadData(armyId, squadId, stats) {
  let squad = (armyData.get()?.squads ?? []).findvalue(@(s) s.squadId == squadId)
  let awardScore = (squad?.squad ?? []).reduce(@(res, soldier)
    res + (stats?[soldier?.guid ?? ""].awardScore ?? 0), 0
  )
  let soldierExpBonus = (squad?.squad ?? []).reduce(@(res, soldier)
    max((soldier?.expBonus ?? 0), res), 0
  )
  let { icon = null, nameLocId = null } = getSquadPresentation(squadId, armyId)
  return {
    awardScore = awardScore
    icon
    nameLocId
    wasExp = squad?.exp ?? 0
    wasLevel = squad?.level ?? 0
    toLevelExp = squad?.toLevelExp ?? 0
    battleExpBonus = squad?.battleExpBonus ?? 0.0
    sign = squad?.sign ?? SIGN_NONE
    isRented = squad?.isRented ?? 0.0
  }.__update(soldierExpBonus > 0 ? { soldierExpBonus } : {})
}

function updateBattleStats(battleStats) {
  let { isSquadsProgressHidden = false } = sourceData.get()
  let {
    campaignId = null, armyId = null, squads = [], expToLevel = [],
    globalData = null, isFirstBattleExp = false, level = null, armyProgress = null,
    growthProgress = null, premiumExpMul = null, expHeroAwardsLimit = 0, expPerHeroAward = 0
  } = armyData.get()

  let soldiers = soldiersData.get()
  logD($"Update battle stats, armyId:{armyId}")
  if (armyId == null) {
    logD("Skip soldiers exp reward due unknown armyId")
    return
  }

  let {
    expReward = null, heroes = null, battleHeroAwards = null, isBattleHero = null,
    shouldApplyBattleHeroMult = null, battleHeroSoldier = null, wasPlayerRank = null,
    playerRank = null, scorePrices = null, awards = [], stats = {}, players = []
  } = battleStats


  let isSingleMission = get_session_id() == INVALID_SESSION
  let sMissionRewardId = isSingleMission ? singleMissionRewardId.get() : null
  let { armyExp = 0, squadsExp = {}, soldiersExp = {}, armyExpDetailed = {},
    awardsAdditionalExp = 0, boosts = {}, expMode = ""
  } = !isSingleMission || isDebugDebriefingMode ? expReward
    : sMissionRewardId != null ? calcSingleMissionExpReward(expReward)
    : null

  let items = {}
  let btlStats = {}
  if (!isSquadsProgressHidden)
    foreach (guid, data in stats) {
      let soldier = soldiers?[guid]
      if (!soldier) {
        logD($"Not found soldier {guid} in army {armyId} for reward. Skip")
        continue
      }
      items[guid] <- soldier
      btlStats[guid] <- data
    }

  let getExpToNextLevel = mkGetExpToNextLevel(expToLevel)
  let additionalStats = {}
  foreach (squadData in squads) {
    let sign = squadData?.sign ?? SIGN_NONE
    foreach (soldier in squadData.squad) {
      let { guid, expBonus = 0 } = soldier
      additionalStats[guid] <- { sign, soldierExpBonus = expBonus }
    }
  }

  let playerIds = {}
  foreach (player in players) {
    let { groupId = null, userid = null } = player
    let playerId = userid ?? groupId ?? -1
    if (playerId > 0)
      playerIds[playerId.tostring()] <- true
  }

  updateData({
    armyId
    campaignId
    singleMissionRewardId = sMissionRewardId
    soldiers = {
      items = items
      stats = btlStats.map(function(s, guid) {
        let sExp = soldiersExp?[guid] ?? { exp = 0 }
        let expStats = extrapolateStatsExp(soldiers[guid], sExp, getExpToNextLevel)
        return s.__merge(expStats, additionalStats?[guid] ?? {})
      })
    }
    squads = squadsExp.map(@(expData, squadId) getSquadData(armyId, squadId, btlStats).__update(expData))
    armyExp
    armyExpDetailed
    awardsAdditionalExp
    isFirstBattleExp
    globalData
    armyWasLevel = level
    armyProgress
    growthProgress
    expHeroAwardsLimit
    expPerHeroAward
    premiumExpMul
    heroes
    battleHeroAwards
    isBattleHero
    shouldApplyBattleHeroMult
    battleHeroSoldier
    wasPlayerRank
    playerRank
    scorePrices
    players = players.map(@(player) [player.eid, player]).totable() ?? {}
    awards
    boosts
    expMode
    tokenMultiplier = eventTokenMultiplier.get()
    friends = contactUserIds.get().filter(@(_, userId) userId.tostring() in playerIds)
  })

  if (sMissionRewardId != null && !isDebugDebriefingMode)
    chargeExp({
      armyId
      singleMissionRewardId = sMissionRewardId
      soldiersExp = soldiersExp.map(@(ed) ed.exp)
      squadsExp = squadsExp.map(@(ed) ed.exp)
      armyExp
    })
}

ecs.register_es("soldiers_stats_listener_es",
  {
    [EventOnBattleResult] = function(evt, _eid, _comp) {
      logD("Received battle stats")
      updateBattleStats(evt.data ?? {})
    }
  },
  {})



function resetData() {
  logD("Reset battle data")
  sourceData.set({})
  resetStatsChange()
  skipDebriefing.set(false)
  debriefingShow.set(false)
}

let isResetRequired = keepref(Computed(@() !isInBattleState.get() && skipDebriefing.get()))

foreach (w in [isInBattleState, isResetRequired]) {
  w.subscribe(function(v) {
    if (v)
      resetData()
  })
}

let isDataReady = Computed(@() ("result" in sourceData.get())
  && ("dailyTasksProgress" in sourceData.get())
  && ("armyExp" in sourceData.get())
  && ("teams" in sourceData.get()))

let isNeededShow = keepref(Computed(@() isDataReady.get() && !skipDebriefing.get()))

isNeededShow.subscribe(function(val) {
  if (val) {
    logD("Set show debriefing")
    debriefingShow.set(true)
  }
})

let debriefingData = Computed(@() isDataReady.get() ? sourceData.get() : {})
let isInDebriefing = Computed(@() debriefingShow.get() && isDataReady.get())

function onSkipDebriefing(v) {
  if (v)
    skipDebriefing.set(true)
}

foreach (w in [isTutorial, isPractice, isReplay])
  w.subscribe(onSkipDebriefing)


debriefingData.subscribe(function(debData) {
  let { scene = null } = lastGame.get()
  if (debData != null && (scene == curBattleTutorial.get()
      || scene == curBattleTutorialTank.get()
      || scene == curBattleTutorialEngineer.get()
      || scene == curBattleTutorialAircraft.get()))
    markCompleted()
})

return {
  isInDebriefing
  debriefingData
  debriefingShow
  debriefingShowAnim
  setDebriefingShowAnim
}
