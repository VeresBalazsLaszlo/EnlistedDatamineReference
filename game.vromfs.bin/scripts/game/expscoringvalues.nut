let scoreSquads = {
  kills = 30
  longRangeKills = 10
  defenseKills = 30
  attackKills = 30
  tankKills = 150
  apcKills = 100
  bikeKills = 50
  planeKills = 350
  aiPlaneKills = 265
  captures = 450
  assists = 20
  tankKillAssists = 100
  bikeKillAssists = 30
  apcKillAssists = 65
  planeKillAssists = 230
  aiPlaneKillAssists = 25
  reviveAssists = 70
  healAssists = 20
  crewKillAssists = 15
  crewTankKillAssists = 75
  crewBikeKillAssists = 25
  crewApcKillAssists = 50
  crewPlaneKillAssists = 180
  crewAiPlaneKillAssists = 135
  tankKillAssistsAsCrew = 15
  bikeKillAssistsAsCrew = 5
  apcKillAssistsAsCrew = 10
  planeKillAssistsAsCrew = 20
  aiPlaneKillAssistsAsCrew = 15
  builtStructures = 4
  builtGunKills = 18
  builtGunKillAssists = 12
  builtGunTankKills = 45
  builtGunApcKills = 30
  builtGunBikeKills = 15
  builtGunTankKillAssists = 30
  builtGunApcKillAssists = 20
  builtGunBikeKillAssists = 10
  builtGunPlaneKills = 90
  builtGunAiPlaneKills = 70
  builtGunPlaneKillAssists = 60
  builtGunAiPlaneKillAssists = 25
  builtBarbwireActivations = 6
  builtAmmoBoxRefills = 18
  builtMedBoxRefills = 45
  builtCapzoneFortificationActivations = 6
  builtRallyPointUses = 70
  ownedMobileSpawnUses = 100
  plantBomb = 450
  defuseBomb = 300
  killByThrowable = 20
  hostedOnSoldierSpawns = 15
  vehicleRepairs = 55
  vehicleExtinguishes = 55
  landings = 100
  barrageBalloonDestructions = 15
  enemyBuiltFortificationDestructions = 6
  enemyBuiltGunDestructions = 55
  enemyBuiltUtilityDestructions = 55

  tankSpot = 100
  apcSpot = 65
  buildingSpot = 40
  tankSpotSpy = 35
  apcSpotSpy = 20
  buildingSpotSpy = 15

  
  friendlyHits = -30
  friendlyKills = -70
  friendlyKillsSamePlayer2Add = 0
  friendlyKillsSamePlayer3Add = -70
  friendlyKillsSamePlayer4Add = -140
  friendlyKillsSamePlayer5AndMoreAdd = -280
  friendlyTankHits = -25
  friendlyTankKills = -200
  friendlyApcHits = -20
  friendlyApcKills = -125
  friendlyBikeHits = -10
  friendlyBikeKills = -60
  friendlyPlaneHits = -50
  friendlyPlaneKills = -400

  
  gunGameLevelup = 1000
}

let expSquads = scoreSquads.__merge({
  killed = 60 
})

let scoreAlone = scoreSquads.__merge({
  
  crewKillAssists = 0
  crewTankKillAssists = 0
  crewApcKillAssists = 0
  crewBikeKillAssists = 0
  crewPlaneKillAssists = 0
  crewAiPlaneKillAssists = 0
  tankKillAssistsAsCrew = 0
  apcKillAssistsAsCrew = 0
  bikeKillAssistsAsCrew = 0
  planeKillAssistsAsCrew = 0
  aiPlaneKillAssistsAsCrew = 0
})

let expAlone = scoreAlone.__merge({
  killed = 60 
  
})

let scoreParatrooperEvent = scoreSquads.__merge({
  aiPlaneKillAssists = 30
  aiPlaneKillAssistsAsCrew = 30
  builtGunAiPlaneKillAssists = 30
  aiPlaneKills = 90
  crewAiPlaneKillAssists = 30
  builtGunAiPlaneKills = 30
})

let expParatrooperEvent = scoreParatrooperEvent.__merge({
  killed = 60 
})

let expTable = {
  alone = expAlone
  squads = expSquads
  paratrooperEvent = expParatrooperEvent
}

let scoreTable = {
  alone = scoreAlone
  squads = scoreSquads
  paratrooperEvent = scoreParatrooperEvent
}

let getScore = @(scoreMode) scoreTable?[scoreMode] ?? scoreSquads
let getExp = @(scoreMode) expTable?[scoreMode] ?? expSquads

return {
  getScore
  getExp
}