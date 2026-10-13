import "%ui/components/faComp.nut" as faComp
import "%ui/components/crossplayIcon.nut" as crossplayIcon
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import accentColor, defTxtColor, midPadding, transpPanelBgColor, disabledTxtColor, darkTxtColor, defItemBlur
  , titleTxtColor, hoverSlotBgColor, highlightLineTop, highlightSolidLineTop
from "%ui/components/unseenComponents.nut" import blinkUnseen, unblinkUnseen
from "%ui/gameModes/gameModesWnd/gameModeWnd.nut" import openChangeGameModeWnd
from "%ui/gameModes/gameModeState.nut" import currentGameModeId, allGameModesById, hasUnseenGameMode, hasUnopenedGameMode
from "%ui/state/queueState.nut" import canChangeQueueParams
from "%ui/squad/squadState.nut" import isInSquad, isSquadLeader, squadLeaderState
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/gameModes/gameModesWnd/serverClusterUi.nut" import serversToShow
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/cursors.nut" import setTooltip
from "%ui/ui_library.nut" import *

let squadLeaderGameModeId = Computed(@() squadLeaderState.get()?.gameModeId)
let selectedGameModeId = Computed(@() isInSquad.get() && !isSquadLeader.get()
  ? squadLeaderGameModeId.get()
  : currentGameModeId.get())

let selectedGameMode = Computed(@() allGameModesById.get()?[selectedGameModeId.get()])


let canShowCrossplayIcon = Computed(@() needShowCrossnetworkPlayIcon
  && crossnetworkPlay.get() != CrossplayState.OFF
  && (!isInSquad.get() || isSquadLeader.get())
  && selectedGameMode.get()?.needShowCrossplayIcon
)


function gameModeCrossplayIcon() {
  return {
    watch = canShowCrossplayIcon
    hplace = ALIGN_RIGHT
    children = canShowCrossplayIcon.get() ? crossplayIcon({ iconColor = defTxtColor }) : null
  }
}


let gameModeUnseenIcon = @() {
  watch = [hasUnseenGameMode, hasUnopenedGameMode]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = !hasUnseenGameMode.get() ? null
    : hasUnopenedGameMode.get() ? blinkUnseen
    : unblinkUnseen
}


let group = ElemGroup()
let serversComp = serversToShow(group, openChangeGameModeWnd)
let mkTxtColor = @(sf, disabled) disabled
  ? disabledTxtColor
  : sf & S_ACTIVE
    ? titleTxtColor
    : sf & S_HOVER ? darkTxtColor : defTxtColor

let changeModeHotkey = mkHotkey("^J:X", openChangeGameModeWnd)
let changeModeHotkeyHovered = mkHotkey("^J:A", openChangeGameModeWnd)

let mkMissionLikesBtn = @(onClick) watchElemState(@(sf) {
  size = FLEX_V
  flow = FLOW_VERTICAL
  rendObj = ROBJ_WORLD_BLUR
  color = defItemBlur
  fillColor = sf & S_HOVER ? hoverSlotBgColor
    : sf & S_ACTIVE ? accentColor
    : transpPanelBgColor
  behavior = Behaviors.Button
  onHover = @(on) setTooltip(on ? loc("mapsRate/btnHint") : null)
  onClick
  children = [
    highlightSolidLineTop
    {
      size = FLEX_V
      valign = ALIGN_CENTER
      children = faComp("thumbs-up", {
        margin = const [0, hdpx(12)]
        fontSize = hdpx(24)
        color = mkTxtColor(sf, false)
      })
    }
  ]
})

let changeGameModeBtn = watchElemState(function(sf) {
  let gameMode = utf8ToUpper(selectedGameMode.get()?.title ?? "")
  let { isVersionCompatible = true } = selectedGameMode.get()
  return {
    watch = [canChangeQueueParams, selectedGameMode, isGamepad]
    rendObj = ROBJ_WORLD_BLUR
    size = FLEX_H
    color = defItemBlur
    fillColor = sf & S_HOVER
      ? hoverSlotBgColor
      : sf & S_ACTIVE
        ? accentColor
        : transpPanelBgColor
    group
    behavior = Behaviors.Button
    onClick = openChangeGameModeWnd
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
      active = "ui/enlist/button_action"
    }
    key = canChangeQueueParams.get()
    hotkeys = canChangeQueueParams.get() ? [[ "^J:X | G" ]] : null
    children = [
      highlightLineTop
      {
        valign = ALIGN_CENTER
        padding = [0, midPadding]
        margin = [midPadding, 0]
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        children = [
          !(isGamepad.get() && canChangeQueueParams.get()) ? null
            : sf & S_HOVER ? changeModeHotkeyHovered
            : changeModeHotkey
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              {
                rendObj = ROBJ_TEXTAREA
                size = FLEX_H
                behavior = Behaviors.TextArea
                hplace = ALIGN_CENTER
                halign = ALIGN_CENTER
                text = loc("changeGameMode/Mode", { gameMode })
                color = mkTxtColor(sf, !isVersionCompatible)
              }.__update(fontSub)
              serversComp
            ]
          }
          gameModeCrossplayIcon
          gameModeUnseenIcon
        ]
      }
    ]
  }
})



return {
  changeGameModeBtn
  selectedGameMode
  mkMissionLikesBtn
}
