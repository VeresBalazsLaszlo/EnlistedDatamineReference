import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import transpPanelBgColor, defItemBlur, bigPadding, startBtnWidth,
  defTxtColor, titleTxtColor, smallPadding, miniPadding
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/soldiers/armySquadTier.nut" import allArmiesTiers, maxMatesArmiesTiers
from "%ui/quickMatch.nut" import randTeamAvailable, randTeamCheckbox, matchRandomTeam,
  crossplayHint, alwaysRandTeamSign, isCurQueueAlwaysRandomSide, isCurQueueNoRandomSide
from "%ui/state/queueState.nut" import timeInQueue, isInQueue
from "%ui/components/defcomps.nut" import noteTextArea, txt
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/gameModes/eventModesState.nut" import eventsArmiesList, eventCurArmyId,
  eventCustomProfile
from "%ui/components/defComponents.nut" import doubleSideHighlightLine,
  doubleSideHighlightLineBottom, doubleSideBg
from "%ui/unlocks/taskWidgetUi.nut" import mkDailyTasksUi, eventTasksUi, hasDailyTasks
from "%ui/offers/offersState.nut" import eventsKeysSorted, visibleOffersInWindow
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/squad/squadState.nut" import squadLeaderState
from "%ui/squad/squadManager.nut" import isInSquad
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/quickMatchQueue.nut" import testDriveOffer
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/ui_library.nut" import *

const TIME_BEFORE_SHOW_QUEUE = 1

const titleHeight = fsh(5.1)
const spinnerHeight = fsh(4)
let waitingSpinner = spinner(spinnerHeight)
const armyIconWidth = hdpx(120)
const armiesGap = hdpx(20)
const minWidthQueueContent = fsh(55)

let infoContainer = {
  transform = true
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
}


function mkOfferInfo(offerGuid) {
  let offer = visibleOffersInWindow.get().findvalue(@(o) o.guid == offerGuid)
  if (offer == null)
    return null

  let { shopItemGuid, descLocId = null } = offer
  let shopItem = shopItems.get()?[shopItemGuid]
  if (shopItem == null)
    return null

  let { nameLocId = null, armies = [] } = shopItem
  let armyId = armies?[0]
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_BOX
        fillColor = Color(10,10,10,10)
        size = const [armyIconWidth, SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkArmyIcon(armyId)
      }
      {
        margin = bigPadding
        rendObj = ROBJ_TEXT
        color = titleTxtColor
        text = loc(descLocId ?? nameLocId)
      }.__update(fontBody)
    ]
  }
}


function queueTitle() {
  return {
    size = const [FLEX, titleHeight]
    flow = FLOW_VERTICAL
    watch = timeInQueue
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_TOP
    children = [
      doubleSideHighlightLine
      doubleSideBg(
        noteTextArea({
          text = loc("queue/searching", {
            wait_time = secondsToStringLoc(timeInQueue.get()  / 1000)
          })
          halign = ALIGN_CENTER
          color = titleTxtColor
        }).__update(fontBody)
      )
      doubleSideHighlightLineBottom
    ]
  }
}

let mkPlayers = @(players) {
  flow = FLOW_VERTICAL
  gap = miniPadding
  halign = ALIGN_CENTER
  children = players.map(@(name) txt(remap_others(name)))
}

let customProfileText = {
  rendObj = ROBJ_TEXT
  text = loc("army/predefined")
  color = defTxtColor
}.__update(fontSub)

function queueArmiesBlock() {
  let squadLeaderInfo = squadLeaderState.get()
  local armyList = curArmiesList.get()
  local armyId = curArmy.get()
  local isRandomTeam = matchRandomTeam.get()
  if (isInSquad.get() && squadLeaderInfo != null && squadLeaderInfo.len() > 0) {
    armyId = squadLeaderInfo.curArmy
    isRandomTeam = squadLeaderInfo.isTeamRandom
  }

  let eventArmyList = eventsArmiesList.get()
  let isEvent = eventArmyList.len() > 0
  if (isEvent) {
    armyList = eventArmyList
    armyId = eventCurArmyId.get()
  }
  if (!isRandomTeam)
    armyList = armyList.filter(@(army) army == armyId)

  let isCustomProfile = isEvent && eventCustomProfile.get() != null
  return {
    watch = [curArmiesList, curArmy, eventsArmiesList, eventCurArmyId, allArmiesInfo,
      matchRandomTeam, squadLeaderState, isInSquad, eventCustomProfile]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigPadding
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap =  armiesGap
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        children = armyList.map(function(army) {
          let armyTier = Computed(@() maxMatesArmiesTiers.get()?[army].tier
            ?? allArmiesTiers.get()?.armies[army] ?? 1)
          let armyPlayers = Computed(@() maxMatesArmiesTiers.get()?[army].players ?? [])
          return @() {
            watch = [armyTier, armyPlayers]
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            gap = smallPadding
            children = [
              {
                rendObj = ROBJ_BOX
                fillColor = Color(10,10,10,10)
                size = const [armyIconWidth, SIZE_TO_CONTENT]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = mkArmyIcon(allArmiesInfo.get()?[army].id)
              }
              isCustomProfile ? null : mkBattleRatingShort(armyTier.get())
              isInSquad.get() && armyPlayers.get().len() > 0 ? mkPlayers(armyPlayers.get()) : null
            ]
          }
        })
      }
      isCustomProfile ? customProfileText : null
    ]
  }
}

let queueText = {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  maxWidth = hdpx(650)
  color = defTxtColor
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text = loc("battleRating/desc")
}.__update(fontSub)

function mkQueueContent() {
  let needQueueInfo = Computed(@() timeInQueue.get() / 1000 > TIME_BEFORE_SHOW_QUEUE)
  return @() {
    watch = needQueueInfo
    minWidth = minWidthQueueContent
    minHeight = hdpx(220)
    
    size = SIZE_TO_CONTENT
    padding = [0, bigPadding]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = needQueueInfo.get()
      ? [queueArmiesBlock, queueText, waitingSpinner]
      : null
  }
}

let randomTeamHint = noteTextArea({
  text = loc("queue/join_any_team_hint")
  halign = ALIGN_CENTER
  color = titleTxtColor
}).__update(fontSub)

function mkRandomTeamContent() {
  let watch = [
    randTeamAvailable, isCurQueueAlwaysRandomSide, matchRandomTeam, isCurQueueNoRandomSide
  ]
  if (!randTeamAvailable.get() || isCurQueueNoRandomSide.get())
    return { watch }

  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      matchRandomTeam.get() ? null : randomTeamHint
      isCurQueueAlwaysRandomSide.get() ? alwaysRandTeamSign : randTeamCheckbox
    ]
  }
}

let eventTasksBlock = @(event) {
  size = [startBtnWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("eventTasks")
      color = defTxtColor
    }.__update(fontBody)
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = eventTasksUi(event, 2)
    }
  ]
}

let dailyTasksBlock = {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("dailyTasks")
      color = defTxtColor
    }.__update(fontBody)
    mkDailyTasksUi()
  ]
}

let tasksBlock = @(events) @() {
  rendObj = ROBJ_WORLD_BLUR
  watch = hasDailyTasks
  minWidth = minWidthQueueContent
  fillColor = transpPanelBgColor
  color = defItemBlur
  padding = bigPadding
  halign = ALIGN_CENTER
  children = makeVertScroll({
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      hasDailyTasks.get() ? dailyTasksBlock : null
      events.len() > 0 ? eventTasksBlock(events[0]) : null
    ]
  }, {
    size = const [SIZE_TO_CONTENT, hdpx(360)]
    styling = thinStyle
  })
}

local dxSum = 0.0
local dySum = 0.0
local canBeUpdated = false

let wndContent = @(events) {
  flow = FLOW_VERTICAL
  gap = bigPadding
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  padding = [0,0, bigPadding, 0]
  children = [
    queueTitle
    crossplayHint
    @() {
      watch = testDriveOffer
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = testDriveOffer.get()
        ? mkOfferInfo(testDriveOffer.get())
        : [
            mkQueueContent()
            mkRandomTeamContent
          ]
    }
    tasksBlock(events)
  ]
}.__merge(infoContainer)

let wndPosition = { pos = const [0, 0] }
function updatePosition(size) {
  wndPosition.pos <- [sw(50) - size[0] / 2, sh(80) - size[1]]
}
let position = Watched(wndPosition)

return function queueWaitingInfo() {
  if (!isInQueue.get())
    return { watch = isInQueue }

  let events = eventsKeysSorted.get()
  let wndContentUi = wndContent(events)
  let wndSize = calc_comp_size(wndContentUi)
  updatePosition(wndSize)
  return {
    watch = [isInQueue, eventsKeysSorted]
    children = function() {
      let { pos } = position.get()
      return {
        watch = position
        fillColor = transpPanelBgColor
        borderRadius = hdpx(2)
        rendObj = ROBJ_WORLD_BLUR_PANEL
        moveResizeCursors = null
        behavior = [Behaviors.MoveResize, Behaviors.RtPropUpdate]
        update = function() {
          canBeUpdated = true
        }
        stopHover = true
        valign = ALIGN_CENTER
        key = 1
        pos
        onMoveResize = function(dx, dy, _dw, _dh) {
          dxSum += dx
          dySum += dy
          if (!canBeUpdated)
            return null
          canBeUpdated = false
          let newPos = { pos =  [
            clamp(pos[0] + dxSum, 0, sw(100) - wndSize[0]),
            clamp(pos[1] + dySum, 0, sh(100) - wndSize[1])
          ]}
          position.set(newPos)
          dxSum = 0
          dySum = 0
          return newPos
        }
        children = wndContentUi
      }
    }
  }
}