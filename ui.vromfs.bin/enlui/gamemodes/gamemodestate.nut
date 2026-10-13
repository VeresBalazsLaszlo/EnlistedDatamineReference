import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/unlocks/isNewbie.nut" as isNewbie
from "%sqstd/frp.nut" import subscribeAndInit
from "dagor.debug" import logerr
from "dagor.localize" import doesLocTextExist
from "%ui/matchingQueues.nut" import matchingQueues
from "%ui/tutorial/battleTutorial.nut" import curUnfinishedBattleTutorial, curBattleTutorial, curBattleTutorialTank, curBattleTutorialEngineer, curBattleTutorialAircraft, curPractice
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/squad/squadState.nut" import isInSquad
from "%ui/meta/servProfile.nut" import purchasesExt
from "%ui/gameModes/seenGameModes.nut" import seenGamemodes
from "%ui/state/clientState.nut" import gameLanguage
from "%ui/state/client_version.nut" import maxVersionStr
from "%sqstd/version_compare.nut" import check_version
from "%sqstd/globalState.nut" import hardPersistWatched
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/restrictionWarnings.nut" import showEventVersionRestrictionMsgBox
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *

let localSettings = require("%ui/options/localSettings.nut")("quickMatch/")


let selGameModeIdByCampaign = mkWatched(persist, "curGameMode", {})
let savedGameModeIdByCampaign = localSettings({}, "curGameMode")
let hasNewVerionReqShown = hardPersistWatched("hasNewVerionReqShown", false)


const INFANTRY_TUTORIAL_ID = "tutorial"
const TANK_TUTORIAL_ID = "tutorial_tank"
const ENGINEER_TUTORIAL_ID = "tutorial_engineer"
const AIRCRAFT_TUTORIAL_ID = "tutorial_aircraft"

let overrideGameModesImage = [ "squads_common", "squads_newbie" ]

function updateGameMode(gameMode) {
  selGameModeIdByCampaign.set(clone gameMode)
}

subscribeAndInit(updateGameMode, savedGameModeIdByCampaign)

let selGameModeId = Computed(@() selGameModeIdByCampaign.get()?[COMMON_CAMPAIGN])

const defTutorialImage = "ui/game_mode_tutorial_2"
const defTutorialTankImage = "ui/game_mode_tutorial_tank"
const defTutorialEngineerImage = "ui/game_mode_tutorial_engineer"
const defTutorialAircraftImage = "ui/game_mode_tutorial_aircraft"
const defPracticeImage = "ui/game_mode_moscow_tutorial"

let mkGameModeDefaults = @() {
  id = null
  isTutorial = false
  isAvailable = false
  isEnabled = false
  isLocal = false
  minGroupSize = 1
  maxGroupSize = 1
  queues = []
  isLocked = false
  lockLevel = 0
  title = null
  description = null
  image = null
  fbImage = null
  scenes = []
  uiOrder = 0
  needShowCrossplayIcon = true
  reqVersion = null
  isVersionCompatible = true
  isEventQueue = false
  isNewbies = false
  isAvailableForNoobs = false
  isLeaderboardVisible = false
  showWhenInactive = false
  isPreviewImage = false
  leaderboardTables = []
  customProfile = null
  campaignsToShow = []
  expMode = null
  dontShowBoosters = false
  alwaysRandomSide = false
  noRandomSide = false
}

let onlineGameModes = Computed(function() {
  let maxVersionValue = maxVersionStr.get()
  let res = []
  let used = {}
  foreach (queueIdx, queueSrc in matchingQueues.get()) {
    local queue = queueSrc
    let { reqVersion = null, extraParams = {} } = queue
    if ((!(queue?.enabled ?? true) || (queue?.disabled ?? false))
      && !(extraParams?.showWhenInactive ?? false))
        continue

    let id = queue?.id ?? queue?.queueId ?? $"#{queueIdx}"
    if (id in used) {
      logerr($"Not unique queue mode /*{id}*/")
      continue
    }

    if (overrideGameModesImage.contains(extraParams?.uiGameModeId)) {
      queue = clone queue
      queue.image <- armiesPresentation?[curArmy.get()].queueDefaultImage ?? queue?.image
    }

    let { hideOnIncompatableVersion = false } = extraParams
    if (hideOnIncompatableVersion && !check_version(reqVersion, maxVersionValue))
      continue

    used[id] <- true
    res.append(queue)
  }
  res.sort(@(a, b) a.uiOrder <=> b.uiOrder)
  return res
})


let hasHiddenGameModes = Computed(function() {
  let maxVersionValue = maxVersionStr.get()
  foreach (queue in matchingQueues.get()) {
    let { reqVersion = null, extraParams = {} } = queue
    let { hideOnIncompatableVersion = false, isEventQueue = false } = extraParams
    if (hideOnIncompatableVersion && isEventQueue
        && !check_version(reqVersion, maxVersionValue))
      return true
  }
  return false
})

let isHiddenGameModesMsgVisible = keepref(Computed(@()
  !hasNewVerionReqShown.get() && isLoggedIn.get() && !isInBattleState.get()
    && hasHiddenGameModes.get()
))

function checkNewVersionReqMessage(val) {
  if (val) {
    showEventVersionRestrictionMsgBox()
    hasNewVerionReqShown.set(true)
  }
}

subscribeAndInit(checkNewVersionReqMessage, isHiddenGameModesMsgVisible)


let offlineGameModes = Computed(function() {
  if (!curBattleTutorial.get())
    return []

  let armyId = curArmy.get()
  return [
    {
      isLocal = true
      isTutorial = true
      id = INFANTRY_TUTORIAL_ID
      locId = "TUTORIAL"
      descLocId = "tutorial_desc"
      uiOrder = 0
      image = armiesPresentation?[armyId].tutorialImage ?? defTutorialImage
      scenes = [curBattleTutorial.get()]
    },
    {
      isLocal = true
      isTutorial = true
      id = TANK_TUTORIAL_ID
      locId = "TUTORIAL_TANK"
      descLocId = "tutorial_tank_desc"
      uiOrder = 1
      image = armiesPresentation?[armyId].tutorialTankImage ?? defTutorialTankImage
      scenes = [curBattleTutorialTank.get()]
    },
    {
      isLocal = true
      isTutorial = true
      id = ENGINEER_TUTORIAL_ID
      locId = "TUTORIAL_ENGINEER"
      descLocId = "tutorial_engineer_desc"
      uiOrder = 2
      image = armiesPresentation?[armyId].tutorialEngineerImage ?? defTutorialEngineerImage
      scenes = [curBattleTutorialEngineer.get()]
    },
    {
      isLocal = true
      isTutorial = true
      id = AIRCRAFT_TUTORIAL_ID
      locId = "TUTORIAL_AIRCRAFT"
      descLocId = "tutorial_aircraft_desc"
      uiOrder = 3
      image = armiesPresentation?[armyId].tutorialAircraftImage ?? defTutorialAircraftImage
      scenes = [curBattleTutorialAircraft.get()]
    },
    {
      isLocal = true
      id = "practice"
      locId = "PRACTICE"
      descLocId = "practice_desc"
      uiOrder = 4
      image = armiesPresentation?[armyId].practiceImage ?? defPracticeImage
      scenes = [curPractice.get()]
    }
  ]
})

let allGameModes = Computed(function() {
  let isAllowLocal = !isInSquad.get()
  let uiModes = {}
  let res = []
  foreach (queue in [].extend(offlineGameModes.get(), onlineGameModes.get())) {
    let { extraParams = {} } = queue
    let { uiGameModeId = null, minCampaignLevel = 0, isEventQueue = false, campaigns = [],
      newbies = false, availableForNoobs = false, showWhenInactive = false, isPreviewImage = false,
      leaderboardTables = [], customProfile = null, campaignsToShow = [],
      isLeaderboardVisible = false, expMode = null, dontShowBoosters = false,
      alwaysRandomSide = false, noRandomSide = false
    } = extraParams

    if (campaigns.len() > 0 && !campaigns.contains(COMMON_CAMPAIGN))
      continue

    local gMode
    if (uiGameModeId == null) {
      gMode = mkGameModeDefaults()
      res.append(gMode)
    }
    else {
      gMode = uiModes?[uiGameModeId]
      if (gMode == null) {
        gMode = mkGameModeDefaults()
        uiModes[uiGameModeId] <- gMode
        res.append(gMode)
      }
    }
    gMode.queues.append(queue)

    gMode.id = gMode.id ?? queue?.id
    let { maxGroupSize = 1 } = queue
    if (gMode.maxGroupSize == 1)
      gMode.maxGroupSize = maxGroupSize
    else if (gMode.maxGroupSize != maxGroupSize)
      logerr($"Queues in gamemode /*{gMode.id}*/ has different max group size")

    gMode.needShowCrossplayIcon = gMode.maxGroupSize > 1
    gMode.isTutorial = gMode.isTutorial || !!queue?.isTutorial
    gMode.isAvailable = gMode.isAvailable || !queue?.isLocal || isAllowLocal
    gMode.isLocal = gMode.isLocal || !!queue?.isLocal
    gMode.lockLevel = gMode.lockLevel == 0 ? minCampaignLevel
      : min(gMode.lockLevel, minCampaignLevel)
    gMode.image = gMode.image ?? queue?.image ?? extraParams?.image
    gMode.uiOrder = max(gMode.uiOrder, queue?.uiOrder ?? 0)
    gMode.reqVersion = gMode.reqVersion ?? queue?.reqVersion
    gMode.isVersionCompatible = gMode.isVersionCompatible && (queue?.isVersionCompatible ?? true)
    gMode.isEventQueue = gMode.isEventQueue || isEventQueue
    gMode.isNewbies = gMode.isNewbies || newbies
    gMode.isAvailableForNoobs = gMode.isAvailableForNoobs || availableForNoobs
    gMode.isLeaderboardVisible = gMode.isLeaderboardVisible || isLeaderboardVisible
    gMode.scenes = gMode.scenes.len() > 0 ? gMode.scenes : (queue?.scenes ?? [])
    gMode.showWhenInactive = gMode.showWhenInactive || showWhenInactive
    gMode.isPreviewImage = gMode.isPreviewImage || isPreviewImage
    gMode.leaderboardTables.extend(leaderboardTables)
    gMode.customProfile = gMode.customProfile ?? customProfile
    gMode.campaignsToShow.extend(campaignsToShow)
    gMode.isEnabled = gMode.isEnabled || !!queue?.enabled
    gMode.expMode = gMode.expMode ?? expMode
    gMode.dontShowBoosters = gMode.dontShowBoosters
      || dontShowBoosters
      || (expMode == "no_econ_events") 
    gMode.alwaysRandomSide  = gMode.alwaysRandomSide || alwaysRandomSide
    gMode.noRandomSide = gMode.noRandomSide || noRandomSide

    local modeTitle = loc(queue?.locId, "")
    if (modeTitle == "") {
      let { locTable = {} } = extraParams
      modeTitle = locTable?[gameLanguage] ?? locTable?["English"] ?? ""
    }
    gMode.title = gMode.title ?? modeTitle

    let descLocId = queue?.descLocId ?? extraParams?.descLocId
    local modeDescription
    if (descLocId != null && doesLocTextExist(descLocId))
      modeDescription = loc(descLocId)
    else {
      let { descLocTable = {} } = extraParams
      modeDescription = descLocTable?[gameLanguage] ?? descLocTable?["English"] ?? modeTitle
    }
    gMode.description = gMode.description ?? modeDescription
  }
  return res
})

let isNewbieFit = @(gameMode, newbie, allow = false) gameMode.isLocal
  || gameMode.isNewbies == newbie
  || (allow && gameMode.isAvailableForNoobs && newbie)

let mainGameModes = Computed(function() {
  let isNewbieV = isNewbie.get()
  let res = allGameModes.get().filter(@(gm) !gm.isEventQueue)
  let newbieRes = res.filter(@(gm) isNewbieFit(gm, isNewbieV))
  return newbieRes
    .findvalue(@(gm) gm.queues.findvalue(@(qu) qu?.enabled && qu?.queueId) != null) != null
      ? newbieRes 
      : res
})

let splittedModes = Computed(function() {
  let tutorialModes = []
  let mainModes = []
  foreach (mode in mainGameModes.get())
    if (mode.isTutorial)
      tutorialModes.append(mode)
    else
      mainModes.append(mode)
  return { tutorialModes, mainModes }
})

let tutorialModes = Computed(@() splittedModes.get().tutorialModes)

let mainModes = Computed(@() splittedModes.get().mainModes)

let eventGameModes = Computed(function() {
  let isNewbieV = isNewbie.get()
  let boughtGuids = purchasesExt.get()
  return allGameModes.get()
    .filter(function(gm) {
      if (!gm.isEventQueue || !isNewbieFit(gm, isNewbieV, true))
        return false
      let { requirePurchase = "" } = gm?.extraParams
      if (requirePurchase != "")
        return requirePurchase in boughtGuids
      return true
    })
})

let allGameModesById = Computed(function() {
  let res = {}
  foreach (mode in allGameModes.get())
    res[mode.id] <- mode
  return res
})

let hasUnseenGameMode = Computed(@() mainGameModes.get()
  .findvalue(@(gMode) gMode.id not in seenGamemodes.get()?.seen))

let hasUnopenedGameMode = Computed(@() mainGameModes.get()
  .findvalue(@(gMode) gMode.id not in seenGamemodes.get()?.opened))

let currentGameMode = Computed(function() {
  let id = selGameModeId.get()
  let allGm = mainGameModes.get().filter(@(gm) gm.isAvailable)

  return allGm.findvalue(@(gm) gm.scenes.contains(curUnfinishedBattleTutorial.get()))
    ?? allGm.findvalue(@(gm) gm.id == id)
    ?? allGm.findvalue(@(gm) !gm.isLocal)
    ?? allGm?[0]
})

let currentGameModeId = Computed(@() currentGameMode.get()?.id)

function setGameMode(id) {
  let gameMode = mainGameModes.get().findvalue(@(gm) gm.id == id)
  if (gameMode != null) {
    if (onlineGameModes.get().contains(gameMode))
      savedGameModeIdByCampaign.mutate(@(v) v[COMMON_CAMPAIGN] <- id)
    else
      selGameModeIdByCampaign.mutate(@(v) v[COMMON_CAMPAIGN] <- id)
  }
  else
    logerr($"incorrect game mode selected /*{id}*/")
}

console_register_command(@() savedGameModeIdByCampaign.mutate({}), "meta.resetSavedGamemodes")

return {
  allGameModesById
  eventGameModes
  currentGameModeId
  currentGameMode
  setGameMode
  hasUnseenGameMode
  hasUnopenedGameMode
  TANK_TUTORIAL_ID
  ENGINEER_TUTORIAL_ID
  AIRCRAFT_TUTORIAL_ID
  tutorialModes
  mainModes
}
