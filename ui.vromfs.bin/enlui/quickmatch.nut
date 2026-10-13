import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/crossplayIcon.nut" as crossplayIcon
import "%ui/options/crossnetwork_save.nut" as saveCrossnetworkPlayValue
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/faComp.nut" as faComp
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, CrossplayState
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/quickMatchQueue.nut" import isInQueue, leaveQueue, joinQueue, timeInQueue, curGameMode, needAutoSquad
from "%ui/tutorial/battleTutorial.nut" import curUnfinishedBattleTutorial
from "%ui/squad/squadState.nut" import isInSquad, squadMembers, isSquadLeader, squadLeaderState
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy
from "string" import endswith
from "%ui/gameModes/gameModeState.nut" import currentGameMode, eventGameModes
from "%ui/components/defcomps.nut" import txt
from "%ui/style/designConst.nut" import titleTxtColor, defTxtColor, smallPadding
from "%dngscripts/platform.nut" import is_gdk
from "%ui/gameModes/eventModesState.nut" import selEvent, isEventModesOpened
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/soldiers/armySquadTier.nut" import getArmyBR, maxMatesArmiesTiers, BRByArmies, getLiveArmyBR
from "%ui/mainScene/changeGameModeButton.nut" import selectedGameMode
from "%ui/state/incognitoState.nut" import incognitoState, isIncognitoAvailable
from "json" import object_to_json_string
from "%ui/style/cursors.nut" import withTooltip
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/offers/offersState.nut" import visibleOffersInWindow
from "%ui/matchRandomTeam.nut" import setEventGm, matchRandomTeam, matchRandomTeamCommon, matchRandomTeamEvent
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeAndInit

let { missionsByQueue, campaignsByMissions } = require("%ui/gameModes/missionsQueues.nut")
let logQM = with_prefix("[QuickMatch] ")

const PLAYER_CUSTOM_PARAM = "playersCustom"
const JOIN_ANY_TEAM = "join_any_team"
const JOIN_GROUP = "join_group"
const FAKE_NAME = "fakeName"

let lastGameMode = nestWatched("lastGameMode", null)

let isInEventGM = Computed(@() isEventModesOpened.get()
  || (curGameMode.get() != null
    && eventGameModes.get().findvalue(function(v) {
      let isSameQueueId = v.queues.findvalue(@(q) q.queueId == curGameMode.get()?.queueId) != null
      return isSameQueueId
    })))
subscribeAndInit(setEventGm, isInEventGM)

let randTeamAvailable = Computed(function() {
  let isAvailable = curUnfinishedBattleTutorial.get() == null
    && (!isInSquad.get() || isSquadLeader.get())

  if (!isInEventGM.get() && isAvailable)
    return true

  return isAvailable
})

function findBrRange(queueSuffixes, BR) {
  if (BR != null) {
    let [ from, to = null ] = BR.split("-").map(@(v) v.tointeger())
    return { from, to = to ?? from }
  }

  
  if (queueSuffixes.len() == 0)
    return { from = 1, to = 5 }

  let queueBRs = queueSuffixes.map(@(v) v.tointeger())
  let last = queueBRs.top()
  return {
    from = queueBRs.reduce(@(res, v) v < res ? v : res, last)
    to = queueBRs.reduce(@(res, v) v > res ? v : res, last)
  }
}

function inRange(br, range) {
  let { from, to } = range
  return br >= from && br <= to
}

function updateBrRange(br, update) {
  if (br.len() == 0) {
    br.__update(update)
    return
  }

  let { from, to } = update
  br.from <- min(br.from, from)
  br.to <- max(br.to, to)
}

let queuesCampaignsData = Computed(function() {
  let BRs = {}
  let armyId = curArmy.get()
  let mapsList = {}
  let squadLeaderInfo = squadLeaderState.get()

  let isRandom = isInSquad.get() && squadLeaderInfo != null
    ? (squadLeaderInfo?.isTeamRandom ?? false)
    : matchRandomTeam.get()

  foreach (queue in selectedGameMode.get()?.queues ?? []) {
    if (queue?.isLocal)
      continue

    let { id, queueSuffixes = [], extraParams = null } = queue
    let { teamAllies = [], teamAxis = [], BR = null } = extraParams

    let queueTeam = teamAllies.contains(armyId) ? 0
      : teamAxis.contains(armyId) ? 1
      : null
    if (!isRandom && queueTeam == null)
      continue

    let availArmies = [
      curArmiesList.get().findvalue(@(army) teamAllies.contains(army))
      curArmiesList.get().findvalue(@(army) teamAxis.contains(army))
    ].filter(@(v) v!=null)

    let range = findBrRange(queueSuffixes, BR)
    let brs = BRByArmies.get()
    let teammates = maxMatesArmiesTiers.get()

    let canQueue = availArmies.findvalue(function(army) {
      if (army != armyId && !isRandom)
        return false
      let br = max(getLiveArmyBR(brs, army), teammates?[army].tier ?? 1)
      return inRange(br, range)
    })

    if (canQueue == null)
      continue

    foreach (army in availArmies) {
      local campaigns = mapsList?[army]
      if (campaigns == null) {
        campaigns = {}
        mapsList[army] <- campaigns
      }

      let missions = missionsByQueue?[id] ?? []
      foreach (mission in missions) {
        let campaign = campaignsByMissions?[mission]
        if (campaign)
          campaigns[campaign] <- true
      }
    }

    updateBrRange(BRs, range)
  }

  foreach (army, campaigns in mapsList) {
    mapsList[army] = campaigns.keys()
  }

  return {
    BRs
    mapsList
  }
})


function getOfferData(testOffer) {
  let offer = visibleOffersInWindow.get().findvalue(@(o) o.guid == testOffer)
  if (offer == null)
    return null

  let { shopItemGuid, br } = offer
  return { br, armyId = shopItems.get()?[shopItemGuid].armies[0] }
}

function joinImpl(gameMode, testOffer = null) {
  let userInfoV = userInfo.get()
  if (userInfoV == null) {
    logQM("joinImpl no userInfo")
    return
  }

  logQM($"joinImpl queues:{", ".join((gameMode?.queues ?? []).map(@(q) q.id))}")
  lastGameMode.set(gameMode)

  let gameParams = { testOffer }
  let { armyId = curArmy.get(), br = 1 } = getOfferData(testOffer)
  let teamLegacy = endswith(armyId, "_allies") ? 0
    : endswith(armyId, "_axis") ? 1
    : null
  let isRandom = matchRandomTeam.get() && testOffer == null
  let teamBRbyArmy = isInSquad.get() && isSquadLeader.get() && maxMatesArmiesTiers.get() != null
    ? maxMatesArmiesTiers.get() : null

  logQM($"  armies:{", ".join(curArmiesList.get())} curArmy:{armyId} teamLegacy:{teamLegacy}")
  foreach (queue in gameMode?.queues ?? []) {
    let { id, queueSuffixes = [], extraParams = null } = queue
    let { teamAllies = [], teamAxis = [], BR = null } = extraParams
    let team = teamAllies.contains(armyId) ? 0
      : teamAxis.contains(armyId) ? 1
      : null
    let queueTeam = gameMode?.eventCurArmy ?? team ?? teamLegacy
    if (!isRandom && queueTeam == null) {
      logQM($"  queue:{id} not fit")
      continue
    }

    let range = findBrRange(queueSuffixes, BR)
    let armies = curArmiesList.get()

    let mteams = []
    let availableTeams = isRandom ? [0, 1] : [queueTeam]
    foreach (teamIdx in availableTeams) {
      let configTeam = teamIdx == 0 ? teamAllies : teamAxis
      let army = armies.findvalue(@(army) configTeam.contains(army))
      let { tier = 1 } = teamBRbyArmy?[army]
      let armyBR = max(tier, br, getArmyBR(army))
      if (inRange(armyBR, range))
        mteams.append(teamIdx)
    }

    if (mteams.len() == 0) {
      logQM($"  queue:{id} no teams")
      continue
    }

    logQM($"  queue:{id} is ok mteams:", mteams, "BR:", range)
    let queueParams = { mteams }
    let customParams = {}
    let customInfo = {
      [JOIN_ANY_TEAM] = isRandom,
      [JOIN_GROUP] = needAutoSquad.get()
    }
    let prepareData = @(data, isIncognito) object_to_json_string(isIncognito
      ? data.__merge({ [FAKE_NAME] = true })
      : data)

    if (isInSquad.get())
      foreach (userId, memberInfo in squadMembers.get())
        customParams[userId.tostring()] <- prepareData(
          customInfo, memberInfo?.state.incognito ?? false)
    else
      customParams[userInfoV.userId.tostring()] <- prepareData(
        customInfo, isIncognitoAvailable && incognitoState.get())

    queueParams[PLAYER_CUSTOM_PARAM] <- customParams
    gameParams[queue.queueId] <- queueParams
  }

  joinQueue(gameMode, gameParams)
}

function join(gameMode, testOffer = null) {
  if (isInQueue.get())
    leaveQueue(@() joinImpl(gameMode))
  else
    joinImpl(gameMode, testOffer)
}

BRByArmies.subscribe(function(_armiesBrs) {
  if (isInQueue.get())
    join(lastGameMode.get())
})

function setRandTeamValue(val) {
  let watch = isInEventGM.get() ? matchRandomTeamEvent : matchRandomTeamCommon
  if (val == watch.get())
    return
  watch.set(val)

  if (isInQueue.get())
    join(lastGameMode.get())
}

let randTeamTextParams = {
  text = loc("queue/anyArmy")
  margin = 0
  color = defTxtColor
}.__update(fontBody)

let matchRandCheckbox = checkbox(matchRandomTeam, null, {
  setValue = setRandTeamValue
  textOnTheLeft = true
  hotkeys = [["^J:RS"]]
})

let mkQuestionMarkTooltip = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  size = const [hdpxi(400), SIZE_TO_CONTENT]
  color = defTxtColor
}.__update(fontSub)

let mkQuestionMarkWithTooltip = @(color, text, size = hdpxi(16))
  withTooltip(faComp("question-circle", {
    size = [size, size]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_INSCRIPTION
    fontSize = size
    color
  }), @() tooltipCtor(mkQuestionMarkTooltip(text)))

let randTeamCheckbox = watchElemState(function(sf) {
  let color = sf & S_HOVER ? titleTxtColor : defTxtColor
  let infoCmp = {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        rendObj = ROBJ_TEXT
        color
      }.__update(randTeamTextParams)
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = smallPadding
        children = [
          {
            rendObj = ROBJ_TEXT
            color
            text = loc("queue/anyArmyBonus")
          }.__update(fontSub)
          mkQuestionMarkWithTooltip(color, loc("queue/anyArmyInfo"))
        ]
      }
    ]
  }

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    behavior = Behaviors.Button
    onClick = @() setRandTeamValue(!matchRandomTeam.get())
    children = [
      infoCmp
      matchRandCheckbox
    ]
  }
})

let setAutoSquad = @(v) needAutoSquad.set(v)
let autoSquadCheckbox = checkbox(needAutoSquad, null, {
  setValue = setAutoSquad
  textOnTheLeft = true

})

function mkAutoSquadCheckbox() {
  let show = Computed(@() (isSquadLeader.get() || !isInSquad.get()) && (currentGameMode.get()?.allowFillGroup ?? true) && (currentGameMode.get()?.maxGroupSize ?? 1) > 1)
  let stateFlags = Watched(0)
  let onElemState = @(s) stateFlags.set(s)
  let watch = [stateFlags, show]
  return function() {
    let color = stateFlags.get() & S_HOVER ? titleTxtColor : defTxtColor
    let text = {
      rendObj = ROBJ_TEXT
      color
      text = loc("squad/autoSquad")
    }.__update(fontSub)
    let questionMark = mkQuestionMarkWithTooltip(color, loc("squad/autoSquadHint"))
    return {
      flow = FLOW_HORIZONTAL
      watch
      onElemState
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = @() needAutoSquad.modify(@(v) !v)
      children = show.get() ? [text, questionMark, autoSquadCheckbox] : null
    }
  }
}

let alwaysRandTeamSign = {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text = loc("modeIsAlwaysForRandTeam")
  color = defTxtColor
}.__update(fontSub)

function activateCrossplay(_val) {
  saveCrossnetworkPlayValue(CrossplayState.ALL)
}

let isCrossplayStateOn = Computed(@() crossnetworkPlay.get() == CrossplayState.ALL)
let canSwitchCrossplayState = Computed(@() !is_gdk || crossnetworkPlay.get() != CrossplayState.OFF)

let hasCrossplayHint = Computed(function() {
  if (!isInQueue.get()
    || isCrossplayStateOn.get())
    return false

  let crossplayHintSec = currentGameMode.get()?.showCrossplayHintAfterSec ?? -1
  if (crossplayHintSec < 0)
    return false

  return timeInQueue.get() / 1000 >= crossplayHintSec
})

let crossplayCheckbox = checkbox(isCrossplayStateOn,
  {
    text = loc("queue/switchCrossplay")
    color = Color(255,255,255)
    margin = 0
  }.__update(fontBody),
  {
    setValue = activateCrossplay
    textOnTheLeft = true
  })

let crossplayHint = @() {
  watch = [hasCrossplayHint, canSwitchCrossplayState]
  flow = FLOW_HORIZONTAL
  gap = fsh(2)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = hasCrossplayHint.get()
    ? [
        crossplayIcon
        {
          flow = FLOW_VERTICAL
          children = [
            txt({
              text = loc("queueCrossplayHint")
              color = titleTxtColor
            }).__update(fontSub)
            canSwitchCrossplayState.get() ? crossplayCheckbox : null
          ]
        }
      ]
    : null
}

let isCurQueueAlwaysRandomSide = Computed(@()
  lastGameMode.get()?.alwaysRandomSide ?? false)

let isCurQueueNoRandomSide = Computed(@()
  lastGameMode.get()?.noRandomSide ?? false)

let isCurEventReqRandomSide = keepref(Computed(function() {
  if (!isEventModesOpened.get())
    return null
  let { alwaysRandomSide = false, noRandomSide = false } = selEvent.get()
  return { alwaysRandomSide, noRandomSide }
}))

isCurEventReqRandomSide.subscribe(function(val) {
  let { alwaysRandomSide = false, noRandomSide = false } = val
  if (alwaysRandomSide)
    setRandTeamValue(true)
  else if (noRandomSide)
    setRandTeamValue(false)
})

return {
  randTeamAvailable
  randTeamCheckbox
  mkAutoSquadCheckbox
  alwaysRandTeamSign
  crossplayHint
  joinQueue = join
  matchRandomTeam
  isCurQueueAlwaysRandomSide
  isCurQueueNoRandomSide
  queuesCampaignsData
  mkQuestionMarkWithTooltip
}
