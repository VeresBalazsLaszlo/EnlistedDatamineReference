import "%dngscripts/ecs.nut" as ecs
let { scoringPlayerStatsComps } = require ("%enlSqGlob/scoreTableStatistics.nut")
let calcScoringPlayerScore = require("%scripts/game/utils/calcPlayerScore.nut")
let { getScoreMode } = require("%enlSqGlob/missionType.nut")

ecs.register_es("enlisted_player_score_es",
{
  [["onInit", "onChange"]] = @(_, comp) comp.scoring_player__score = calcScoringPlayerScore(comp, getScoreMode())
},
{
  comps_rw = [
    ["scoring_player__score", ecs.TYPE_INT],
  ]
  comps_track = scoringPlayerStatsComps
}, {tags="server", before="send_userstats_es"})
