import "%dngscripts/ecs.nut" as ecs
from "team" import TEAM_UNASSIGNED
from "matching.errors" import INVALID_SQUAD_ID, INVALID_USER_ID

const scorePlayerInfoComps = [
  ["name", ecs.TYPE_STRING],
  ["player_group__memberIndex", ecs.TYPE_INT, 0],
  ["groupId", ecs.TYPE_INT64, INVALID_SQUAD_ID],
  ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
  ["platform", ecs.TYPE_STRING, ""],
  ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ["army", ecs.TYPE_STRING],
  ["disconnected", ecs.TYPE_BOOL],
  ["possessed", ecs.TYPE_EID],
  ["decorators__nickFrame", ecs.TYPE_STRING],
  ["decorators__portrait", ecs.TYPE_STRING],
  ["player__roomOwner", ecs.TYPE_BOOL],
  ["player_info__military_rank", ecs.TYPE_INT],
  ["player_info__rating", ecs.TYPE_INT],
  ["controlled_soldier__sKind", ecs.TYPE_STRING],
  ["controlled_soldier__sClass", ecs.TYPE_STRING],
  ["playerBotWithoutStat", ecs.TYPE_TAG, null]
]

const scoringPlayerSoldiersStatsComps = [
  ["scoring_player__kills", ecs.TYPE_INT],
  ["scoring_player__tankKills", ecs.TYPE_INT],
  ["scoring_player__apcKills", ecs.TYPE_INT],
  ["scoring_player__planeKills", ecs.TYPE_INT],
  ["scoring_player__aiPlaneKills", ecs.TYPE_INT],
  ["scoring_player__assists", ecs.TYPE_INT],
  ["scoring_player__captures", ecs.TYPE_FLOAT],
  ["scoring_player__plantBomb", ecs.TYPE_FLOAT],
  ["scoring_player__defuseBomb", ecs.TYPE_FLOAT],
  ["scoring_player__attackKills", ecs.TYPE_INT],
  ["scoring_player__defenseKills", ecs.TYPE_INT],
  ["scoring_player__builtStructures", ecs.TYPE_INT],
  ["scoring_player__builtGunKills", ecs.TYPE_INT],
  ["scoring_player__builtGunKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunTankKills", ecs.TYPE_INT],
  ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunApcKills", ecs.TYPE_INT],
  ["scoring_player__builtGunApcKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT],
  ["scoring_player__builtGunAiPlaneKills", ecs.TYPE_INT],
  ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunAiPlaneKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT],
  ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT],
  ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT],
  ["scoring_player__builtMedBoxRefills", ecs.TYPE_INT],
  ["scoring_player__builtRallyPointUses", ecs.TYPE_INT],
  ["scoring_player__ownedMobileSpawnUses", ecs.TYPE_INT],
  ["scoring_player__killByThrowable", ecs.TYPE_INT],
  ["scoring_player__hostedOnSoldierSpawns", ecs.TYPE_INT],
  ["scoring_player__vehicleRepairs", ecs.TYPE_INT],
  ["scoring_player__vehicleExtinguishes", ecs.TYPE_INT],
  ["scoring_player__landings", ecs.TYPE_INT],
  ["scoring_player__reviveAssists", ecs.TYPE_INT],
  ["scoring_player__healAssists", ecs.TYPE_FLOAT],
  ["scoring_player__tankKillAssists", ecs.TYPE_INT],
  ["scoring_player__apcKillAssists", ecs.TYPE_INT],
  ["scoring_player__planeKillAssists", ecs.TYPE_INT],
  ["scoring_player__aiPlaneKillAssists", ecs.TYPE_INT],
  ["scoring_player__tankKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__apcKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__planeKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__aiPlaneKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__crewKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewTankKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewApcKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewPlaneKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewAiPlaneKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__barrageBalloonDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT],
  ["scoring_player__meleeKills", ecs.TYPE_INT],
  ["scoring_player__explosiveKills", ecs.TYPE_INT],
  ["scoring_player__longRangeKills", ecs.TYPE_INT],
  ["scoring_player__gunGameLevelup", ecs.TYPE_INT],
  ["scoring_player__friendlyHits", ecs.TYPE_INT],
  ["scoring_player__friendlyKills", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer2Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer3Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer4Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer5AndMoreAdd", ecs.TYPE_INT],
  ["scoring_player__friendlyTankHits", ecs.TYPE_INT],
  ["scoring_player__friendlyTankKills", ecs.TYPE_INT],
  ["scoring_player__friendlyApcHits", ecs.TYPE_INT],
  ["scoring_player__friendlyApcKills", ecs.TYPE_INT],
  ["scoring_player__friendlyPlaneHits", ecs.TYPE_INT],
  ["scoring_player__friendlyPlaneKills", ecs.TYPE_INT],
  ["scoring_player__zombieKills", ecs.TYPE_INT, 0],
  ["scoring_player__zombieHeadshots", ecs.TYPE_INT, 0],
  ["scoring_player__zombieWaves", ecs.TYPE_INT, 0],
  ["scoring_player__zombieDoorsScore", ecs.TYPE_INT, 0],
  ["scoring_player__zombieTotalScore", ecs.TYPE_INT, 0],
]

const scoringPlayerSoldiersExtraStatsComps = [
  ["scoring_player__bikeKills", ecs.TYPE_INT],
  ["scoring_player__builtGunBikeKills", ecs.TYPE_INT],
  ["scoring_player__builtGunBikeKillAssists", ecs.TYPE_INT],
  ["scoring_player__bikeKillAssists", ecs.TYPE_INT],
  ["scoring_player__bikeKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__crewBikeKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__friendlyBikeHits", ecs.TYPE_INT],
  ["scoring_player__friendlyBikeKills", ecs.TYPE_INT],
  ["scoring_player__apcSpot", ecs.TYPE_INT, 0],
  ["scoring_player__apcSpotSpy", ecs.TYPE_INT, 0],
  ["scoring_player__buildingSpot", ecs.TYPE_INT, 0],
  ["scoring_player__buildingSpotSpy", ecs.TYPE_INT, 0],
  ["scoring_player__tankSpot", ecs.TYPE_INT, 0],
  ["scoring_player__tankSpotSpy", ecs.TYPE_INT, 0],
]

const scoringPlayerPlayerOnlyStatsComps = [
  ["scoring_player__squadDeaths", ecs.TYPE_INT],
]

let scoringPlayerStatsComps = [].extend(
  scoringPlayerSoldiersStatsComps,
  scoringPlayerSoldiersExtraStatsComps,
  scoringPlayerPlayerOnlyStatsComps
)

let scoreStatisticsComps = [].extend(
  scorePlayerInfoComps,
  [["scoring_player__score", ecs.TYPE_INT]],
  scoringPlayerSoldiersStatsComps,
  scoringPlayerPlayerOnlyStatsComps
)

let playerStatisticsFromComps = @(comp) comp.__merge({
  score = comp["scoring_player__score"]
  memberIndex = comp["player_group__memberIndex"]
})

return freeze({
  scoringPlayerSoldiersStatsComps
  scoringPlayerPlayerOnlyStatsComps
  scoringPlayerStatsComps
  scorePlayerInfoComps
  scoreStatisticsComps
  playerStatisticsFromComps
  scoringPlayerSoldiersExtraStatsComps
})
