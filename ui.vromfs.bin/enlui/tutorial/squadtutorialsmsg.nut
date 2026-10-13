import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/soldiers/model/state.nut" import squadsByArmy
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/gameModes/gameModeState.nut" import allGameModesById, TANK_TUTORIAL_ID, AIRCRAFT_TUTORIAL_ID, ENGINEER_TUTORIAL_ID
from "%ui/tutorial/battleTutorial.nut" import curUnfinishedBattleTutorial
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/components/wndManager.nut" import registerWnd, Wnd
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%ui/ui_library.nut" import *

let gameLauncher = require("%ui/gameLauncher.nut")

const WND_UID = "tutorial_available_window"

let TUTORIALS = [
  {
    saveId = "tutorial/tank_tutorial_seen"
    squadType = "tank"
    gameMode = TANK_TUTORIAL_ID
    locId = "tutorial/tank_tutorial_available"
    bigQueryId = "open_tank_tutorial"
  }
  {
    saveId = "tutorial/aircraft_tutorial_seen"
    squadType = "aircraft"
    gameMode = AIRCRAFT_TUTORIAL_ID
    locId = "tutorial/aircraft_tutorial_available"
    bigQueryId = "open_aircraft_tutorial"
  }
  {
    saveId = "tutorial/engineer_tutorial_seen"
    squadType = "engineer"
    gameMode = ENGINEER_TUTORIAL_ID
    locId = "tutorial/engineer_tutorial_available"
    bigQueryId = "open_engineer_tutorial"
  }
]

let curUnseenTutorial = Computed(function() {
  if (userInfo.get() == null
      || curUnfinishedBattleTutorial.get()
      || !onlineSettingUpdated.get())
    return null

  foreach (tutorial in TUTORIALS) {
    let { squadType, saveId, gameMode } = tutorial
    if (settings.get()?[saveId] == true || !allGameModesById.get()?[gameMode])
      continue
    foreach (armySquads in squadsByArmy.get())
      if (armySquads.findvalue(@(v) v?.squadType == squadType) != null)
        return tutorial
  }
  return null
})

let storeShown = @(tutorial) settings.mutate(@(v) v[tutorial.saveId] <- true)

function launchTutorial(tutorial) {
  let gameMode = allGameModesById.get()?[tutorial.gameMode]
  if (!gameMode)
    return

  storeShown(tutorial)
  gameLauncher.startGame({
    game = "enlisted"
    scene = gameMode.scenes[0]
  })
}

function show(tutorial) {
  sendBigQueryUIEvent(tutorial.bigQueryId)
  showMsgbox({
    uid = WND_UID
    text = loc(tutorial.locId)
    buttons = [
      {
        text = loc("Ok"),
        action = @() launchTutorial(tutorial)
        isCurrent = true
      }
      {
        text = loc("Cancel")
        action = @() storeShown(tutorial)
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}

let canShow = registerWnd({
  dataWatch = Computed(@() curUnseenTutorial.get() != null)
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.SQUAD_TUTORIAL
})










let toDisplay = keepref(Computed(@() canShow.get() ? curUnseenTutorial.get() : null))
toDisplay.subscribe(function(tutorial) {
  if (tutorial != null)
    show(tutorial)
})

let resetTutorialSeen = @() settings.mutate(function(v) {
  foreach (tutorial in TUTORIALS)
    v[tutorial.saveId] <- false
})
console_register_command(resetTutorialSeen, "tutorial.resetTutorialsSeen")
