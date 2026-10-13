import "%dngscripts/ecs.nut" as ecs
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "dagor.time" import get_time_msec
from "%ui/ui_library.nut" import *

let { state, stateSetKeyVal, stateDeleteKey } = mkFrameIncrementObservable({}, "state")
let { scoreStatisticsComps, playerStatisticsFromComps, scoringPlayerSoldiersExtraStatsComps } = require ("%enlSqGlob/scoreTableStatistics.nut")

ecs.register_es("scoring_players_ui_es",
  {
    [["onInit", "onChange"]]= @(_, eid, comp) stateSetKeyVal(eid, playerStatisticsFromComps(comp).__merge({
      lastUpdate = get_time_msec()
    }))
    onDestroy=@(_, eid, __) stateDeleteKey(eid)
  },
  {
    comps_track = scoreStatisticsComps
  }
)

ecs.register_es("scoring_players_extra_stats_ui_es",
  {
    [["onInit", "onChange"]]= @(_, eid, comp) stateSetKeyVal(eid, comp)
    onDestroy=@(_, eid, __) stateDeleteKey(eid)
  },
  {
    comps_track = scoringPlayerSoldiersExtraStatsComps
  }
)


return state
