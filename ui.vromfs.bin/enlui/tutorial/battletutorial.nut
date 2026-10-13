from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/curCampaign.nut" import curCampaignConfig
from "%ui/gameLauncher.nut" import lastGame
from "%ui/configs/battleScenes.nut" import defTutorial, getTutorialScene, defTutorialTank, getTutorialTankScene, defTutorialEngineer, getTutorialEngineerScene, defTutorialAircraft
  , getTutorialAircraftScene, defPractice, getPracticeScene
from "%ui/ui_library.nut" import *

const SAVE_FOLDER = "battleTutorial"

let curTutorialGroup = Computed(function() {
  if ("campaigns" not in gameProfile.get()) 
    return {
      id = "notlogged"
      version = 1
      tutorialScene = defTutorial
      tutorialTankScene = defTutorialTank
      tutorialEngineerScene = defTutorialEngineer
      tutorialAircraftScene = defTutorialAircraft
      practiceScene = defPractice
    }

  let groupId = curCampaignConfig.get()?.tutorial
  let group = gameProfile.get()?.tutorials[groupId]
  if (groupId == null || group == null)
    return null

  return {
    id = groupId
    version = group?.version ?? 1
    tutorialScene = getTutorialScene(curArmy.get())
    tutorialTankScene = getTutorialTankScene(curArmy.get())
    tutorialEngineerScene = getTutorialEngineerScene(curArmy.get())
    tutorialAircraftScene = getTutorialAircraftScene(curArmy.get())
    practiceScene = getPracticeScene(curArmy.get())
  }
})

let curBattleTutorial = Computed(@() curTutorialGroup.get()?.tutorialScene)
let curBattleTutorialTank = Computed(@() curTutorialGroup.get()?.tutorialTankScene)
let curBattleTutorialEngineer = Computed(@() curTutorialGroup.get()?.tutorialEngineerScene)
let curBattleTutorialAircraft = Computed(@() curTutorialGroup.get()?.tutorialAircraftScene)
let curPractice = Computed(@() curTutorialGroup.get()?.practiceScene)

let curUnfinishedBattleTutorial = Computed(function() {
  if (!onlineSettingUpdated.get())
    return null

  let group = curTutorialGroup.get()
  if (group == null)
    return null

  let { version, id } = group
  return (settings.get()?[SAVE_FOLDER][id] ?? 0) != version ? group.tutorialScene : null
})

function markCompleted() {
  let group = curTutorialGroup.get()
  if (group == null)
    return

  settings.mutate(function(saved) {
    let saveData = saved?[SAVE_FOLDER] ?? {}
    let { version, id } = group
    saved[SAVE_FOLDER] <- saveData.__merge({ [id] = version })
  })
}

function resetTutorialsSave() {
  if (SAVE_FOLDER in settings.get())
    settings.mutate(function(saved) { saved.$rawdelete(SAVE_FOLDER) })
}

let lastGameTutorialId = Computed(function() {
  let lastScene = lastGame.get()?.scene
  if (lastScene == null)
    return null
  return lastScene == curTutorialGroup.get()?.tutorialScene ? curTutorialGroup.get().id : null
})

console_register_command(markCompleted, "tutorial.markCompleted")
console_register_command(@() console_print($"current: {curBattleTutorial.get()}",
  $"tank: {curBattleTutorialTank.get()}",
  $"engineer: {curBattleTutorialEngineer.get()}",
  $"aircraft: {curBattleTutorialAircraft.get()}"), "tutorial.curTutorial")
console_register_command(resetTutorialsSave, "tutorial.resetComplete")

return {
  curBattleTutorial
  curBattleTutorialTank
  curBattleTutorialEngineer
  curBattleTutorialAircraft
  curPractice
  curUnfinishedBattleTutorial
  lastGameTutorialId
  markCompleted
}
