from "%ui/ui_library.nut" import *

const defTutorial = "gamedata/scenes/tutorial/tutorial_training_ground_normandy_allies.blk" 
let tutorialSceneByArmy = {
  ussr = "gamedata/scenes/tutorial/tutorial_training_ground_moscow_allies.blk"
  ger = "gamedata/scenes/tutorial/tutorial_training_ground_berlin_axis.blk"
  jap = "gamedata/scenes/tutorial/tutorial_training_ground_pacific_axis.blk"
  usa = "gamedata/scenes/tutorial/tutorial_training_ground_normandy_allies.blk"
}

const defTutorialTank = "gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
let tutorialTankSceneByArmy = {
  
}

const defTutorialEngineer = "gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
let tutorialEngineerSceneByArmy = {
  
}

const defTutorialAircraft = "gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
let tutorialAircraftSceneByArmy = {
  
}

const defPractice = "gamedata/scenes/tutorial/_common_training_ground.blk"
let practiceSceneByArmy = {
  ussr = "gamedata/scenes/tutorial/common_training_ground_ussr.blk"
  ger = "gamedata/scenes/tutorial/common_training_ground_germany.blk"
  jap = "gamedata/scenes/tutorial/common_training_ground_japan.blk"
  usa = "gamedata/scenes/tutorial/common_training_ground_usa.blk"
}


const defTestDrive = defPractice
let testDriveSceneByArmy = practiceSceneByArmy


return {
  defTutorial
  getTutorialScene = @(armyId) tutorialSceneByArmy?[armyId] ?? defTutorial
  defTutorialTank
  getTutorialTankScene = @(armyId) tutorialTankSceneByArmy?[armyId] ?? defTutorialTank
  defTutorialEngineer
  getTutorialEngineerScene = @(armyId) tutorialEngineerSceneByArmy?[armyId] ?? defTutorialEngineer
  defTutorialAircraft
  getTutorialAircraftScene = @(armyId) tutorialAircraftSceneByArmy?[armyId] ?? defTutorialAircraft
  defPractice
  getPracticeScene = @(armyId) practiceSceneByArmy?[armyId] ?? defPractice
  getTestDriveScene = @(armyId) testDriveSceneByArmy?[armyId] ?? defTestDrive
}