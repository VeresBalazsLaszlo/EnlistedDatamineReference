import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/control/gui_buttons.nut" as JB
import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/components/faComp.nut" as faComp
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/components/crossplayIcon.nut" as crossplayIcon
import "%ui/defSceneWrap.nut" as defSceneWrap
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub, fontBody
from "%ui/style/designConst.nut" import bigPadding, defTxtColor, titleTxtColor, midPadding, commonBorderRadius, accentColor, smallPadding
  , transpBgColor, footerContentHeight, darkTxtColor, panelBgColor, defItemBlur, sidePadding, selectedPanelBgColor
  , modeCardSize, modeNameBlockHeight
from "%sqstd/string.nut" import utf8ToUpper
from "dagor.localize" import doesLocTextExist
from "%ui/components/unseenComponents.nut" import blinkUnseen, unblinkUnseen, unseenPanel
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/gameModes/gameModeState.nut" import currentGameMode, setGameMode, mainModes, tutorialModes
from "%ui/gameModes/seenGameModes.nut" import seenGamemodes, markSeenGamemode, markOpenedGamemodes
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/mainMenu/sectionsState.nut" import curSection
from "%ui/restrictionWarnings.nut" import showVersionRestrictionMsgBox
from "%ui/tutorial/battleTutorial.nut" import curBattleTutorial, curUnfinishedBattleTutorial, markCompleted
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/gameModes/eventModesState.nut" import hasCustomRooms, openCustomGameMode, openEventsGameMode, activeEvents
from "%ui/gameModes/createEventRoomCfg.nut" import actualizeRoomCfg
from "%ui/components/scrollbar.nut" import makeHorizScroll, styling
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/squad/squadManager.nut" import isInSquad, isLeavingWillDisbandSquad, leaveSquad, leaveSquadSilent
from "%ui/gameModes/gameModesWnd/serverClusterUi.nut" import serverClusterBtn
from "%ui/components/defComponents.nut" import doubleSideHighlightLine, doubleSideHighlightLineBottom, doubleSideBg
from "%ui/navigation/commonWndParams.nut" import wndHeader
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/ui_library.nut" import *

let { commonWndParams } = require("%ui/navigation/commonWndParams.nut")

const defTutorialImage = "ui/game_mode_tutorial_2"
const defCustomGameImage = "ui/game_mode_moscow_solo"

const btnSound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let isTutorialsWndOpened = Watched(false)
let hasCrossplayDesc = Watched(crossnetworkPlay.get() != CrossplayState.OFF && needShowCrossnetworkPlayIcon)
let isGameModeWndOpened = mkWatched(persist, "isGameModeWndOpened", false)

let titleTxtStyle = freeze({ color = titleTxtColor }.__update(fontHeading2))
let defTxtStyle = freeze({ color = defTxtColor }.__update(fontBody))
let activeTxtStyle = freeze({ color = darkTxtColor }.__update(fontBody))
let selectedTxtStyle = freeze({ color = accentColor }.__update(fontBody))
let descTxtStyle = freeze({ color = titleTxtColor }.__update(fontSub))


const gap = hdpx(32)
let nameBlockSize = [modeCardSize[0], modeNameBlockHeight]
let unseenPanelPos = [0, -hdpx(68)]
let cardDescriptionHeight = modeCardSize[1] - nameBlockSize[1]

let cardHotkey = mkImageCompByDargKey(JB.A, { hplace = ALIGN_LEFT })

function close(needToClose = true) {
  if (needToClose)
    isGameModeWndOpened.set(false)
  else
    isTutorialsWndOpened.set(false)
}


function mkEventGameMode(activeEvent) {
  let eventQueueData = activeEvent?.queues[0]
  let { locId = "" } = eventQueueData
  let { descGameModeLocId = "", descLocId = "", imageGameMode = null } = eventQueueData?.extraParams
  return {
    id = "events"
    image = imageGameMode ?? defCustomGameImage
    title = doesLocTextExist(locId) ? loc(locId) : loc("events")
    description = doesLocTextExist(descGameModeLocId) ? loc(descGameModeLocId) : loc(descLocId, "")
    isAvailable = true
    needShowCrossplayIcon = true
    isVersionCompatible = true
    onClick = function() {
      openEventsGameMode()
      close()
    }
  }
}


let mkImage = @(image, fbImage, isAvailable, sf) {
  size = FLEX
  clipChildren = true
  children = {
    size = FLEX
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture(image)
    fallbackImage = Picture(fbImage)
  }.__update(isAvailable
    ? {
        transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
        transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
      }
    : { picSaturate = 0.3, tint = Color(0, 0, 0, 128) })
}


let mkLevelLock = @(level){
  size = const [FLEX, hdpx(20)]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  pos = [0, -nameBlockSize[1] - smallPadding]
  children = level <= 0 ? null : [
    faComp("lock", {
      vplace = ALIGN_BOTTOM
      fontSize = activeTxtStyle.fontSize
      color = activeTxtStyle.color
    })
    {
      rendObj = ROBJ_TEXT
      text = loc("levelInfo", { level })
    }.__update(activeTxtStyle)
  ]
}


let descriptionBlock = @(text, sf) @() {
  size = [FLEX, cardDescriptionHeight]
  rendObj = ROBJ_SOLID
  color = transpBgColor
  padding = [hdpx(26), smallPadding]
  valign = ALIGN_BOTTOM
  transform = sf == 0 ? { translate = [0, modeCardSize[1]] } : { translate = [0, 0] }
  transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutCubic}]
  children = {
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    behavior = Behaviors.TextArea
    text
  }.__update(descTxtStyle)
}

let nameBlock = @(name, sf, needShowCrossplayIcon = false, isSelected = false) @() {
  watch = [crossnetworkPlay, isGamepad]
  rendObj = ROBJ_WORLD_BLUR
  size = [FLEX, nameBlockSize[1]]
  fillColor = sf & S_HOVER ? accentColor
    : isSelected ? selectedPanelBgColor
    : panelBgColor
  color = defItemBlur
  valign = ALIGN_CENTER
  padding = [0, smallPadding]
  halign = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = const [pw(80), SIZE_TO_CONTENT]
      text = name
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
    }.__update(sf & S_HOVER ? activeTxtStyle
      : isSelected ? selectedTxtStyle
      : defTxtStyle)
    needShowCrossnetworkPlayIcon && needShowCrossplayIcon
      && crossnetworkPlay.get() != CrossplayState.OFF
        ? crossplayIcon({
            iconSize = hdpxi(26),
            iconColor = sf & S_HOVER ? darkTxtColor
              : isSelected ? accentColor
              : defTxtColor
          })
        : null
    isGamepad.get() && (sf & S_HOVER) ? cardHotkey : null
  ]
}


function mkCustomGameButton(modeCfg, hasSeen, animations) {
  let { image, title, id, onClick, description, needShowCrossplayIcon = false } = modeCfg
  return watchElemState(@(sf) {
    size = modeCardSize
    xmbNode = XmbNode()
    animations
    behavior = Behaviors.Button
    sound = btnSound
    onClick
    onHover = function(on) {
      hasCrossplayDesc.set(on && needShowCrossnetworkPlayIcon
        && needShowCrossplayIcon && crossnetworkPlay.get() != CrossplayState.OFF)
      if (!hasSeen)
        hoverHoldAction("unseenGamemode", id, @(id_) markSeenGamemode(id_))(on)
    }
    children = [
      mkImage(image, defCustomGameImage, true, sf)
      {
        size = FLEX
        clipChildren = true
        children = [
          descriptionBlock(description, sf)
          nameBlock(utf8ToUpper(title), sf, needShowCrossplayIcon)
        ]
      }
      hasSeen ? null
        : unseenPanel(loc("unseen/gamemode"), { pos = unseenPanelPos})
    ]
  })
}

function mkAnimations(idx, len) {
  let delay = idx * min(0.15, 0.9 / len)
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.translate, from = [sw(20), -fsh(5)], to = [0,0], duration = 0.4, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.scale, from = [1.3, 1.3], to = [1,1], duration = 0.3, delay,
      play = true, easing = InOutCubic }
  ]
}

let mkTutorialsButton = @(unseenSign, defaultFbImage, defTutorialParams) watchElemState(function(sf) {
  let tutorialParams = defTutorialParams.get()
  let { image, isAvailable, title, description } = tutorialParams
  return {
    watch = [isInSquad, defaultFbImage, defTutorialParams]
    size = modeCardSize
    xmbNode = XmbNode()
    animations = mkAnimations(0, 1)
    behavior = Behaviors.Button
    sound = btnSound
    onClick = @() isTutorialsWndOpened.set(true)
    children = [
      mkImage(image, defaultFbImage.get(), isAvailable, sf)
      {
        size = FLEX
        clipChildren = true
        children = [
          descriptionBlock(description, sf)
          nameBlock(utf8ToUpper(title), sf)
        ]
      }
      {
        hplace = ALIGN_RIGHT
        children = unseenSign
      }
    ]
  }
})



let title = {
  size = const [fsh(56), hdpx(64)]
  hplace = ALIGN_CENTER
  children = [
    doubleSideBg({
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("change_mode"))
    }.__update(titleTxtStyle))
    doubleSideHighlightLine
    doubleSideHighlightLineBottom
  ]
}


local gameModeOnClickAction = @(_gameMode) null

gameModeOnClickAction = function(gameMode) {
  let { id, isAvailable, isLocal, isVersionCompatible } = gameMode

  if (!isAvailable) {
    if (isInSquad.get() && isLocal)
      showMsgbox({
        text = loc("squad/leaveSquadQst")
        buttons = [
          { text = loc("Yes"),
            isCurrent = true,
            action = @() isLeavingWillDisbandSquad.get()
              ? leaveSquadSilent(@() gameModeOnClickAction(gameMode))
              : leaveSquad(@() gameModeOnClickAction(gameMode))
          }
          { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
        ]
      })
    return
  }

  if (!isVersionCompatible) {
    showVersionRestrictionMsgBox()
    return
  }

  if (curUnfinishedBattleTutorial.get())
    markCompleted()

  setGameMode(id)
  close()
}


let selectedLine = {
  size = const [FLEX, hdpx(4)]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = accentColor
  vplace = ALIGN_BOTTOM
  pos = [0, midPadding]
}


function mkGameModeButton(gameMode, idx, hasSeen, defaultFbImage) {
  let isSelectedW = Computed(@() gameMode == currentGameMode.get())
  let xmbNode = XmbNode()

  let {
    id, image, fbImage, isAvailable, needShowCrossplayIcon,
    isLocked, lockLevel, description
  } = gameMode

  return watchElemState(function(sf) {
    let isSelected = isSelectedW.get()
    let modesCount = isTutorialsWndOpened.get()
      ? tutorialModes.get().len()
      : mainModes.get().len()

    let animations = mkAnimations(idx, modesCount)
    return {
      size = modeCardSize
      watch = [isSelectedW, defaultFbImage, crossnetworkPlay, isTutorialsWndOpened,
        tutorialModes, mainModes]
      onHover = function(on) {
        hasCrossplayDesc.set(on && needShowCrossnetworkPlayIcon && needShowCrossplayIcon
          && crossnetworkPlay.get() != CrossplayState.OFF)
        if (!hasSeen)
          hoverHoldAction("unseenGamemode", id, @(id_) markSeenGamemode(id_))(on)
      }
      onAttach = function() {
        if (!isSelected)
          return
        if (isGamepad.get())
          move_mouse_cursor(id, false)
      }
      behavior = Behaviors.Button
      sound = btnSound
      onClick = @() gameModeOnClickAction(gameMode)
      xmbNode
      key = id
      animations = animations
      children = [
        mkImage(image ?? defaultFbImage.get(), fbImage ?? defaultFbImage.get(),
          isAvailable && !isLocked, sf)
        mkLevelLock(lockLevel)
        {
          size = FLEX
          clipChildren = true
          children = [
            descriptionBlock(description, sf)
            nameBlock(gameMode.title, sf, needShowCrossplayIcon, isSelected)
          ]
        }
        hasSeen ? null
          : unseenPanel(loc("unseen/gamemode"), { pos = unseenPanelPos})
        isSelected ? selectedLine : null
      ]
    }
  })
}


let tblScrollHandler = ScrollHandler()


function mkGameModesList(defaultFbImage, defTutorialParams, customGameMode) {
  let onDetach = @() isTutorialsWndOpened.set(false)

  return function() {
    let seenGM = seenGamemodes.get()?.seen
    let openedGM = seenGamemodes.get()?.opened

    let hasUnseenTutorial = tutorialModes.get().findindex(@(m) m.id not in seenGM) != null
    let hasUnopenedTutorial = tutorialModes.get().findindex(@(m) m.id not in openedGM) != null
    let tutorialUnseen = !hasUnseenTutorial ? null
      : hasUnopenedTutorial ? unblinkUnseen
      : blinkUnseen

    let tutorialsToShow = tutorialModes.get()
      .map(@(mode, idx) mkGameModeButton(mode, idx, seenGM?[mode?.id] ?? false, defaultFbImage))

    let tutorialsToMarkOpened = tutorialModes.get().map(@(m) m.id)
    let modesToMarkOpened = mainModes.get().map(@(m) m.id)
    let modes = mainModes.get()
      .map(@(mode, idx) mkGameModeButton(mode, idx + 1, seenGM?[mode?.id] ?? false, defaultFbImage))
      .insert(0, mkTutorialsButton(tutorialUnseen, defaultFbImage, defTutorialParams))

    if (activeEvents.get().len() > 0) {
      let events = mkEventGameMode(activeEvents.get()[0])
      modes.append(mkCustomGameButton(events,
        seenGM?[events?.id] ?? false,
        mkAnimations(modes.len(), modes.len() + 1)))
      modesToMarkOpened.append(events?.id)
    }

    let custGameMode = customGameMode.get()
    if (custGameMode != null) {
      modes.append(mkCustomGameButton(custGameMode,
        seenGM?[custGameMode?.id] ?? false,
        mkAnimations(modes.len(), modes.len() + 1)))
      modesToMarkOpened.append(custGameMode?.id)
    }
    let modesOnScreen = isTutorialsWndOpened.get() ? tutorialsToShow : modes
    let toMarkOpened = isTutorialsWndOpened.get()
      ? tutorialsToMarkOpened
      : modesToMarkOpened

    let onAttach = @() gui_scene.resetTimeout(0.1, @()
          markOpenedGamemodes(toMarkOpened.filter(@(m) m not in seenGamemodes.get()?.opened)))
    let modesCount = modesOnScreen.len()
    let modesWidth = modesCount * modeCardSize[0] + modesCount * (gap - 1)
    let needScroll = sw(100) - sidePadding * 2 < modesWidth

    return {
      size = FLEX
      onAttach
      onDetach
      watch = [seenGamemodes, customGameMode, mainModes, tutorialModes,
        isTutorialsWndOpened, activeEvents]
      xmbNode = XmbContainer({
        canFocus = false
        scrollSpeed = 10.0
        isViewport = true
      })
      halign = ALIGN_CENTER
      children = needScroll
        ? makeHorizScroll(
          {
            flow = FLOW_HORIZONTAL
            gap
            vplace = ALIGN_CENTER
            children = modesOnScreen.map(@(children) { children })
          }, {
            size = FLEX
            scrollHandler = tblScrollHandler
            styling = scrollStyle
            rootBase = {
              key = "gameModesUnlocksRoot"
              behavior = Behaviors.Pannable
              wheelStep = 0.82
            }
          })
        : {
            hplace = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap
            vplace = ALIGN_CENTER
            children = modesOnScreen.map(@(children) { children })
          }
    }
  }
}


function crossplayDescBlock() {
  let res = { watch = hasCrossplayDesc }
  if (!hasCrossplayDesc.get())
    return res
  return res.__update({
    size = const [fsh(34.6), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = bigPadding
    children = [
      crossplayIcon({ iconSize = hdpxi(32) })
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("crossPlay/enabled/desc")
      }.__update(defTxtStyle)
    ]
  })
}


let bottomBlock = freeze({
  size = const [FLEX, fsh(11)]
  padding = [0, 0, footerContentHeight, 0]
  vplace = ALIGN_BOTTOM
  children = [
    crossplayDescBlock
    serverClusterBtn
  ]
})


function mkChangeGameModeBody() {
  let defaultFbImage = Computed(@() armiesPresentation?[curArmy.get()].queueDefaultImage
    ?? "ui/volokolamsk_city_01")

  let defTutorialParams = Computed(@() {
    image = armiesPresentation?[curArmy.get()].tutorialImage ?? defTutorialImage
    id = "tutorials"
    title = loc("tutorials")
    description = loc("tutorials/desc")
    isAvailable = !isInSquad.get()
    needShowCrossplayIcon = false
    isVersionCompatible = true
  })

  let customGameMode = Computed(function() {
    if (!curBattleTutorial.get() || !hasCustomRooms.get() || isNewbie.get())
      return null

    return {
      id = "customMatches"
      image = armiesPresentation?[curArmy.get()].customGameImage ?? defCustomGameImage
      title = loc("custom_matches")
      description = loc("custom_matches/desc")
      isAvailable = true
      needShowCrossplayIcon = true
      isVersionCompatible = true
      onClick = function() {
        openCustomGameMode()
        close()
      }
    }
  })


  return {
    size = FLEX
    behavior = Behaviors.Button
    sound = btnSound
    onClick = @() null
    children = [
      title
      mkGameModesList(defaultFbImage, defTutorialParams, customGameMode)
      bottomBlock
    ]
  }
}

let changeGameModeWnd = defSceneWrap(
  @() {
    children = [
      wndHeader(@() close(!isTutorialsWndOpened.get()))
      mkChangeGameModeBody()
    ]
  }.__update(commonWndParams),
  {
    maxWidth = sw(100)
  }
)


isLoggedIn.subscribe(function(v) {
  if (v)
    actualizeRoomCfg()
})
if (isLoggedIn.get())
  actualizeRoomCfg()

isGameModeWndOpened.subscribe(function(v) {
  if (v) {
    actualizeRoomCfg()
    sceneWithCameraAdd(changeGameModeWnd, "researches")
  }
  else
    sceneWithCameraRemove(changeGameModeWnd)
})
if (isGameModeWndOpened.get())
  sceneWithCameraAdd(changeGameModeWnd, "researches")

curSection.subscribe(@(_) close())

function openChangeGameModeWnd() {
  isGameModeWndOpened.set(true)
}

return {
  openChangeGameModeWnd
  isGameModeWndOpened
}
