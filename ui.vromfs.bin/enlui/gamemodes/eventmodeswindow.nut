import "%ui/control/gui_buttons.nut" as JB
import "%ui/mainMenu/profileInfoBlock.nut" as profileInfoBlock
import "%ui/userstats/serverTime.nut" as serverTime
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/leaderboard/shortLb.ui.nut" as shortLbUi
import "%ui/gameModes/eventModeDescription.nut" as eventModeDescription
import "%ui/mpRoom/eventLobbyWnd.nut" as lobbyWnd
import "%ui/components/progressText.nut" as progressText
import "%ui/components/mkWindowTab.nut" as mkWindowTab
import "%ui/components/colorize.nut" as colorize
import "%ui/gameModes/sandbox/customMissionOfferBlock.nut" as customMissionOfferBlock
import "%ui/eventPass/penaltyText.nut" as mkPenaltyText
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/style/designConst.nut" import bigPadding, titleTxtColor, maxContentWidth, defTxtColor,
  commonBtnHeight, navHeight, startBtnWidth, blurBgFillColor, disabledTxtColor, lockedSquadBgColor,
  accentTitleTxtColor
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened, hasCustomRooms,
  selEvent, selectEvent, selLbMode, eventCustomSquads, eventsSquadList, eventsArmiesList,
  eventCurArmyId, eventCustomProfile, allEventsToShow, customRoomsModeSaved, curTab, eventStartTime
from "%ui/gameModes/gameModeState.nut" import eventGameModes
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/mainMenu/mkActiveBoostersMark.nut" import mkActiveBoostersMark
from "%ui/gameModes/unseenEvents.nut" import unseenEvents, markSeenEvent, markAllSeenEvents
from "%ui/components/textButton.nut" import Regular, soundDefault, Accented
from "%ui/mainMenu/mkMenuScene.nut" import mkMenuScene, menuContentAnimation
from "%ui/quickMatchQueue.nut" import leaveQueue, isInQueue
from "%ui/quickMatch.nut" import joinQueue, randTeamAvailable, randTeamCheckbox, alwaysRandTeamSign
from "%ui/soldiers/model/notReadySquadsState.nut" import showCurNotReadySquadsMsg
from "%ui/squad/squadManager.nut" import isInSquad, isSquadLeader,
  getUnsuitableCrossplayConditionMembers, getUnsuitableVersionConditionMembers,
  tryResolveLiveCrossplayPrivilege
from "%ui/restrictionWarnings.nut" import showSquadMembersCrossPlayRestrictionMsgBox,
  showSquadVersionRestrictionMsgBox, showNegativeBalanceRestrictionMsgBox,
  showDeserterRestrictionMsgBox
from "%ui/currency/currencies.nut" import hasValidBalance
from "%ui/soldiers/squads_list.ui.nut" import mkSquadsList
from "%ui/mainScene/changeGameModeButton.nut" import selectedGameMode
from "%ui/leaderboard/lbState.nut" import openLbWnd, curLbIdx, lbPlayersCount, curLbSelfRow
from "%ui/gameModes/eventModeStyle.nut" import verticalGap, localPadding, localGap,
  armieChooseBlockWidth, eventBlockWidth
from "%ui/state/roomState.nut" import isInRoom, roomIsLobby, lobbyStatus, LobbyStatus
from "%ui/mpRoom/enlRoomState.nut" import destroyRoom
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/gameModes/eventRoomsList.nut" import eventRoomsList, modsRoomsList
from "%ui/gameModes/eventRoomInfo.nut" import curEventRoomInfo
from "%ui/gameModes/joinEventRoom.nut" import joinSelEventRoom
from "%ui/gameModes/eventRoomsListState.nut" import selRoom
from "%ui/gameModes/createEventRoomState.nut" import isEditEventRoomOpened
from "%ui/gameModes/eventRoomsListFiltersPopup.nut" import toggleEventFiltersPopup,
  isRoomFilterOpened
from "%ui/gameModes/eventModesPkg.nut" import footer, mkPanel
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%sqstd/math.nut" import ceil
from "%ui/gameModes/sandbox/customMissionOfferState.nut" import FEATURED_MODS_TAB_ID,
  featuredModsRoomsList, isFeaturedAvailable
from "%ui/gameModes/gameModesWnd/serverClusterUi.nut" import serverClusterBtnAbbrev
from "%ui/soldiers/army_select.ui.nut" import mkArmyBtn
from "%ui/state/eventState.nut" import hasEventDeserterPenalty
from "%ui/eventPass/gameModesDescription.nut" import activeBonusMark
from "%ui/ui_library.nut" import *

let { myExtSquadData } = require("%ui/squad/squadManager.nut")


const CONTAINERS_ANIM_DURATION = 0.3
const EVENTS_TAB_ID = "events"
const CUSTOM_MATCHES_TAB_ID = "custom_matches"

let tabHoverAnim = [{ prop = AnimProp.translate, duration = 0.2}]
let tabStateCommon = { translate = [hdpx(380), 0] }
let tabStateHovered = { translate = [0, 0] }
const buttonTabBgNormal = 0xfa015ea2
const buttonTabBgActive = 0xfa0182b5
let unseenIcon = blinkUnseenIcon().__update({pos = const [-hdpx(26), 0]})

let hideBoosters = Computed(@() selEvent.get()?.dontShowBoosters
  || selLbMode.get() == "for_fun_events")

let boostersMark = mkActiveBoostersMark({
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  pos = const [hdpxi(20), 0]
})

let isLeaderboardVisible = Computed(@() (selEvent.get()?.isLeaderboardVisible ?? false)
  || lbPlayersCount.get() > 0)

let windowTabs = Computed(function() {
  let tabs = []
  if (eventGameModes.get().len() > 0)
    tabs.append(EVENTS_TAB_ID)
  if (hasCustomRooms.get())
    tabs.append(CUSTOM_MATCHES_TAB_ID)
  if ((hasCustomRooms.get() && featuredModsRoomsList.get().len() > 0)
      || curTab.get() == FEATURED_MODS_TAB_ID)
    tabs.append(FEATURED_MODS_TAB_ID)
  return tabs
})

function selectEventArmy(armyId){
  eventCurArmyId.set(armyId)
}

eventsArmiesList.subscribe(function(armies) {
  if (!armies.contains(eventCurArmyId.get()))
    selectEventArmy(armies?[0])
})

windowTabs.subscribe(function(v) {
  if (!v.contains(curTab.get()))
    curTab.set(v?[0])
})

function txtColor(sf, isInactive = false) {
  return sf & S_ACTIVE ? titleTxtColor
    : sf & S_HOVER ? titleTxtColor
    : isInactive ? disabledTxtColor : defTxtColor
}

const filterBtnCommonStyle = {
  margin = 0
  hotkeys = [["^J:LT"]]
}

let filterBtnOpenedStyle = freeze(filterBtnCommonStyle.__merge({
  defBgColor = 0xFF40404040
}))

let defQuickMatchBtnParams = {
  size = const [pw(100), hdpx(80)]
  halign = ALIGN_CENTER
  margin = 0
  borderWidth = hdpx(0)
  textParams = fontHeading2
}

function changeWindowTab(delta) {
  let wndTabs = windowTabs.get()
  let curTabIdx = wndTabs.indexof(curTab.get()) ?? 0
  if ((curTabIdx + delta) < wndTabs.len() && (curTabIdx + delta) >= 0)
    curTab.set(wndTabs[curTabIdx + delta])
}

function wndTabsBlock() {
  let children = windowTabs.get().map(@(val)
    mkWindowTab(loc(val), @() curTab.set(val), curTab.get() == val))

  if (isGamepad.get() && windowTabs.get().len() > 1)
    children
      .insert(0, mkHotkey("^J:LB", @() changeWindowTab(-1)))
      .append(mkHotkey("^J:RB", @() changeWindowTab(1)))

  return {
    watch = [isGamepad, curTab, windowTabs]
    flow = FLOW_HORIZONTAL
    size = [FLEX, commonBtnHeight]
    gap = localPadding
    valign = ALIGN_CENTER
    children
  }
}

function mkEventBtn(eventGm) {
  let isSelected = Computed(@() selEvent.get() == eventGm)
  let isUnseen = Computed(@() unseenEvents.get().contains(eventGm.id))
  let isInactive = !eventGm.isEnabled && eventGm.showWhenInactive
  let isEnded = Computed(@() isInactive && (eventGm?.leaderboardTableIdx ?? 0) < curLbIdx.get())
  let { title = "" } = eventGm
  let eventTitle = title != "" ? title : eventGm.id

  return watchElemState(@(sf) {
    size = FLEX_H
    watch = [isSelected, isUnseen, isEnded]
    behavior = Behaviors.Button
    onAttach = @() isSelected.get() ? markSeenEvent(eventGm.id) : null
    onClick = @() selectEvent(eventGm.id)
    onHover = hoverHoldAction("unseenEvent", eventGm.id, @(c) markSeenEvent(c))
    sound = soundDefault
    children = [
      isSelected.get() || (sf & S_HOVER)
        ? {
            rendObj = ROBJ_SOLID
            size = isSelected.get() ? [hdpx(6), FLEX] : [hdpx(6), ph(50)]
            color = txtColor(sf)
            pos = const [-hdpx(16), 0]
          }
        : isUnseen.get() ? unseenIcon : null
        {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          text = eventTitle
          color = txtColor(sf, isInactive)
        }.__update(fontBody)
    ]
  })
}

let eventsListSelector = @() {
  watch = allEventsToShow
  size = [eventBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = localPadding
  children = allEventsToShow.get().map(mkEventBtn)
}

let backBtn = Regular(loc("BACK"), @() isEventModesOpened.set(false), {
  hotkeys = [[$"^{JB.B} | Esc"]]
  size = FLEX_H
})

let mkRightBlockHeader = @(sf, label) {
  size = [FLEX, commonBtnHeight]
  clipChildren = true
  valign = ALIGN_CENTER
  children = [
    {
      size = FLEX
      children = [
        {
          rendObj = ROBJ_WORLD_BLUR_PANEL
          size = FLEX
          fillColor = blurBgFillColor
        }
        {
          rendObj = ROBJ_SOLID
          size = [startBtnWidth, commonBtnHeight]
          color = sf & S_ACTIVE ? buttonTabBgActive : buttonTabBgNormal
          transitions = tabHoverAnim
          transform = sf != 0 ? tabStateHovered : tabStateCommon
        }
      ]
    }
    {
      rendObj = ROBJ_TEXT
      padding = [0, bigPadding]
      color = txtColor(sf)
      text = label
    }.__update(fontHeading2)
  ]
}

function curLbPlacementBlock() {
  let res = { watch = [lbPlayersCount, curLbSelfRow] }
  let { idx = -1 } = curLbSelfRow.get()
  if (idx < 0)
    return res

  local text = ""
  if (lbPlayersCount.get() > 0) {
    let topPercentPlacement = ceil(100.0 * (idx + 1) / lbPlayersCount.get())
    if (topPercentPlacement <= 99)
      text = loc("lbPercentPlacemet", {
        percentPlacement = colorize(accentTitleTxtColor, $"{topPercentPlacement}%") })
  }
  return res.__update({
    rendObj = ROBJ_TEXTAREA
    size = FLEX_H
    behavior = Behaviors.TextArea
    text
  }.__update(fontBody))
}

let briefLeaderboard = watchElemState(@(sf) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = localGap
  behavior = Behaviors.Button
  sound = soundDefault
  onClick = openLbWnd
  children = [
    mkRightBlockHeader(sf, loc("Leaderboard"))
    mkPanel({
      size = FLEX_H
      children = shortLbUi
    })
    curLbPlacementBlock
  ]
})

function upcomingEventMsgbox() {
  let seconds = max(0, (eventStartTime.get()?[selEvent.get()?.queueId] ?? 0) - serverTime.get())
  showMsgbox(loc("events/comingInLong", { time = secondsToHoursLoc(seconds) }))
}

let endedEventMsgbox = @() showMsgbox(loc("events/endedEvent"))

let leaveQueueButton = Regular(loc("Leave queue"), @() leaveQueue(),
  defQuickMatchBtnParams
    .__merge({hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]}))

let mkBattleButton = @(text, onClick) Accented(text, onClick,
  defQuickMatchBtnParams
    .__merge({hotkeys = [["^J:Y", { description = { skip = true }}]]}))

let mkDisabledBattleButton = @(text, onClick) Regular(text, onClick,
  defQuickMatchBtnParams.__merge({
    style = {
      defBgColor = lockedSquadBgColor
      hoverBgColor = lockedSquadBgColor
      activeBgColor = lockedSquadBgColor
    }
    textParams = fontHeading2.__merge({ color = titleTxtColor })
  }))

let upcomingEventBtn = mkDisabledBattleButton(loc("inactiveEvent"), upcomingEventMsgbox)
let endedEventBtn = mkDisabledBattleButton(loc("endedEvent"), endedEventMsgbox)

function joinEventQueue() {
  if (isSquadLeader.get()) {
    let membersList = getUnsuitableCrossplayConditionMembers()
    if (membersList.len() > 0) {
      showSquadMembersCrossPlayRestrictionMsgBox(membersList)
      return
    }
  }

  let unsuitableByVersion = getUnsuitableVersionConditionMembers(selectedGameMode.get())
  if (unsuitableByVersion.len() > 0) {
    showSquadVersionRestrictionMsgBox(unsuitableByVersion.values())
    return
  }

  if (!hasValidBalance.get()) {
    showNegativeBalanceRestrictionMsgBox()
    return
  }

  if (hasEventDeserterPenalty()) {
    showDeserterRestrictionMsgBox()
    return
  }

  let armies = eventsArmiesList.get()
  if (armies.len() > 0 && isEventModesOpened.get()) {
    let specialParams = clone selEvent.get()
    specialParams.eventCurArmy <- armies.indexof(eventCurArmyId.get()) ?? 0
    showCurNotReadySquadsMsg(@() joinQueue(specialParams))
    return
  }
  showCurNotReadySquadsMsg(@() joinQueue(selEvent.get()))
}

let joinEventButton = {
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = mkBattleButton(loc("START"), joinEventQueue)
}

let setNotReadyBtn = Accented(loc("Set not ready"),
  @() myExtSquadData.ready.set(false),
  defQuickMatchBtnParams.__merge({
    hotkeys = [[$"^{JB.B}", { description = { skip = true } }]] }))

let pressWhenReadyBtn = Accented(loc("Press when ready"),
  function() {
    tryResolveLiveCrossplayPrivilege(function(resolved) {
      if (resolved)
        showCurNotReadySquadsMsg(@() myExtSquadData.ready.set(true))
    })
  },
  defQuickMatchBtnParams.__merge({
    hotkeys = [["^J:Y", { description = { skip = true } }]] }))

function toEventBattleButton() {
  let { queues, showWhenInactive = false, leaderboardTableIdx = 0 } = selEvent.get()
  let isEnabled = queues.findvalue(@(q) q.enabled) != null
  return {
    watch = [isInQueue, selEvent, isInSquad, isSquadLeader, curLbIdx, myExtSquadData.ready,
      hideBoosters]
    size = [startBtnWidth, SIZE_TO_CONTENT]
    children = [
      selEvent.get() == null
          ? null
        : showWhenInactive && !isEnabled && leaderboardTableIdx < curLbIdx.get()
          ? endedEventBtn
        : showWhenInactive && !isEnabled
          ? upcomingEventBtn
        : isInSquad.get() && !isSquadLeader.get() && myExtSquadData.ready.get()
          ? setNotReadyBtn
        : isInSquad.get() && !isSquadLeader.get() && !myExtSquadData.ready.get()
          ? pressWhenReadyBtn
        : isInQueue.get()
          ? leaveQueueButton
        : joinEventButton
      hideBoosters.get() ? null : boostersMark
      activeBonusMark
      mkPenaltyText()
    ]
  }
}

function actionIfValidBalance(action) {
  if (hasValidBalance.get())
    action()
  else
    showNegativeBalanceRestrictionMsgBox()
}

let createRoomBtn = Regular(utf8ToUpper(loc("createRoom")),
  @() actionIfValidBalance(@() isEditEventRoomOpened.set(true)), {
    hotkeys = [ ["^J:X", { description = { skip = true } }] ]
  }
)

let activeCustomRoomButton = mkBattleButton(loc("Join"), @() actionIfValidBalance(joinSelEventRoom))
let inactiveCustomRoomButton = mkDisabledBattleButton(loc("noRoomSelected"), @() showMsgbox(loc("noRoomSelected")))
let noSlotsToJoinRoom = mkDisabledBattleButton(loc("noSlotsInRoom"), @() null)

let joinCustomRoomButton = @() {
  watch = selRoom
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = [
    selRoom.get() == null ? inactiveCustomRoomButton
      : (selRoom.get()?.membersCnt ?? 0) >= (selRoom.get()?.maxPlayers ?? 0) ? noSlotsToJoinRoom
      : activeCustomRoomButton
    boostersMark
  ]
}

function clusterAndRandTeamButtons() {
  let { alwaysRandomSide = false, noRandomSide = false } = selEvent.get()
  return {
    watch = [selEvent, randTeamAvailable]
    size = FLEX_H
    flow = FLOW_VERTICAL
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    padding = bigPadding
    gap = bigPadding
    children = [
      alwaysRandomSide ? alwaysRandTeamSign
        : randTeamAvailable.get() && !noRandomSide ? randTeamCheckbox
        : null
      serverClusterBtnAbbrev
    ]
  }
}

function switchEventArmy(delta) {
  let armies = eventsArmiesList.get()
  let armyIdx = armies.indexof(eventCurArmyId.get()) ?? 0
  let newArmyId = armies?[armyIdx + delta]
  if (newArmyId != null)
    selectEventArmy(newArmyId)
}

let tb = @(key, val, params) @() {
  watch = isGamepad
  isHidden = !isGamepad.get()
  children = mkHotkey(key, @() switchEventArmy(val))
}.__update(params)

function eventArmiesSelector() {
  if (curTab.get() != EVENTS_TAB_ID)
    return { watch = curTab }

  let armiesList = eventsArmiesList.get()
  if (armiesList.len() <= 1)
    return { watch = [curTab, eventsArmiesList] }

  let children = [
    {
      flow = FLOW_HORIZONTAL
      children = armiesList.map(@(armyId)
        mkArmyBtn(armyId, Computed(@() armyId == eventCurArmyId.get()), selectEventArmy))
    }
    tb("^J:LT", -1, { hplace = ALIGN_LEFT, pos = const [-hdpx(15), 0] })
    tb("^J:RT", 1, { hplace = ALIGN_RIGHT, pos = const [hdpx(15), 0] })
  ]
  return {
    watch = [curTab, eventsArmiesList, eventCustomProfile]
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    children
  }
}

let topBar = {
  size = [FLEX, navHeight]
  hplace = ALIGN_CENTER
  maxWidth = maxContentWidth
  children = [
    eventArmiesSelector
    profileInfoBlock
  ]
}

let eventSquadsList = @() {
  watch = eventCustomSquads
  size = [armieChooseBlockWidth, FLEX]
  margin = [0, localPadding, 0, 0]
  flow = FLOW_VERTICAL
  gap = bigPadding
  transform = true
  animations = [
    { prop = AnimProp.translate, from = [-sw(20), 0], to = [0, 0],
      duration = CONTAINERS_ANIM_DURATION, easing = InOutCubic, play = true }
  ]
  children = [
    eventCustomSquads.get() == null ? mkSquadsList() : eventsSquadList(eventCustomSquads)
    backBtn
  ]
}

let buttonsBlock = @() {
  watch = isRoomFilterOpened
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  gap = localGap
  children = [
    backBtn
    Regular(
      utf8ToUpper(loc("showFilters")),
      toggleEventFiltersPopup,
      isRoomFilterOpened.get() ? filterBtnOpenedStyle : filterBtnCommonStyle
    )
    createRoomBtn
  ]
}

let mkCentralBlock = @(children) {
  size = FLEX
  flow = FLOW_VERTICAL
  padding = [0, localPadding, 0, 0]
  transform = true
  animations = [{ prop = AnimProp.translate, from = [0, sh(70)], to = [0, 0],
    duration = CONTAINERS_ANIM_DURATION, easing = InOutCubic, play = true }]
  gap = localGap
  children = [
    wndTabsBlock
    children
  ]
}

let mkRightBlock = @(children) {
  size = [startBtnWidth, FLEX]
  flow = FLOW_VERTICAL
  gap = verticalGap
  transform = true
  animations = [
    { prop = AnimProp.translate, from = [sw(30), 0], to = [0, 0],
      duration = CONTAINERS_ANIM_DURATION, easing = InOutCubic, play = true }
  ]
  children
}

let contentEvents = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  onDetach = @() markAllSeenEvents()
  children = [
    eventSquadsList
    mkCentralBlock({
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        eventsListSelector
        eventModeDescription
      ]
    })
    mkRightBlock(@() {
      watch = [selEvent, isLeaderboardVisible]
      size = FLEX
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        {
          size = FLEX
          children = isLeaderboardVisible.get() ? briefLeaderboard : null
        }
        clusterAndRandTeamButtons
        selEvent.get() ? toEventBattleButton : null
      ]
    })
  ]
}

let contentCustomMatches = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    mkCentralBlock({
      size = FLEX
      flow = FLOW_VERTICAL
      gap = localGap
      children = [
        eventRoomsList
        buttonsBlock
      ]
    })
    mkRightBlock({
      size = FLEX
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        mkPanel({
          size = FLEX
          children = curEventRoomInfo
        })
        joinCustomRoomButton
      ]
    })
  ]
}

let contentFeaturedMods = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    mkCentralBlock({
      size = FLEX
      flow = FLOW_VERTICAL
      gap = localGap
      children = [
        modsRoomsList
        buttonsBlock
      ]
    })
    mkRightBlock({
      size = FLEX
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        isFeaturedAvailable ? customMissionOfferBlock : null
        mkPanel({
          size = FLEX
          children = curEventRoomInfo
        })
        joinCustomRoomButton
      ]
    })
  ]
}

let windowContentMap = freeze({
  [EVENTS_TAB_ID] = contentEvents,
  [CUSTOM_MATCHES_TAB_ID] = contentCustomMatches,
  [FEATURED_MODS_TAB_ID] = contentFeaturedMods,
})

let windowAllContent = @() {
  watch = curTab
  size = FLEX
  flow = FLOW_HORIZONTAL
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  hotkeys = [[$"^{JB.B} | Esc",
    { action = @() isEventModesOpened.set(false), description = loc("Close") }]]
  transform = true
  animations = menuContentAnimation
  padding = [bigPadding, 0,0,0]
  children = windowContentMap?[curTab.get()]
}

let eventsWindow = mkMenuScene(topBar, windowAllContent, footer)

let eventsWndHub = @() {
  watch = [isInRoom, roomIsLobby]
  size = FLEX
  children = !isInRoom.get() ? eventsWindow
    : roomIsLobby.get() ? lobbyWnd
    : progressText(loc("lobbyStatus/gameIsRunning"))
}

function open() {
  if (eventGameModes.get().len() <= 0 || customRoomsModeSaved.get())
    curTab.set(CUSTOM_MATCHES_TAB_ID)
  else
    curTab.set(windowTabs.get()?[0])
  sceneWithCameraAdd(eventsWndHub, "events")
}

if (isEventModesOpened.get())
  open()

isEventModesOpened.subscribe(@(v) v ? open() : sceneWithCameraRemove(eventsWndHub))

lobbyStatus.subscribe(function(status) {
  if (status == LobbyStatus.SceneLoadFailure) {
    showMsgbox({
      text = loc($"lobbyStatus/{status}")
      buttons = [
        { text = loc("lobby/destroyRoomBtn"), action = @() destroyRoom(), isCurrent = true }
        { text = loc("Ok"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
      ]
    })
  }
})
