from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG
from "%ui/hud/state/warnings.nut" import addWarnings, warningUpdate
from "%ui/hud/state/team_scores.nut" import myScore, enemyScore, myTeamCanLoseByScore, enemyTeamCanLoseByScore
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/ui_library.nut" import *

let { WARNING_PRIORITIES } = require("%ui/hud/state/warnings.nut")

const WE_LEAD = "score/weLead"
const ENEMY_LEAD = "score/enemyLead"
const WE_HALF = "score/weHalf"
const ENEMY_HALF = "score/enemyHalf"
const WE_LOW = "score/weLow"
const ENEMY_LOW = "score/enemyLow"

let positiveMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM0_COLOR_FG }
let negativeMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM1_COLOR_FG }

addWarnings({
  [WE_LEAD] = positiveMessage,
  [ENEMY_LEAD] = negativeMessage,
  [WE_HALF] = negativeMessage,
  [ENEMY_HALF] = positiveMessage,
  [WE_LOW] = negativeMessage,
  [ENEMY_LOW] = positiveMessage,
})

let state = keepref(Computed(function() {
  let my = myScore.get() ?? 0
  let enemy = enemyScore.get() ?? 0
  let isScoreCompetition = myTeamCanLoseByScore.get() && enemyTeamCanLoseByScore.get()
  return {
    inited             = my > 0 && enemy > 0
    list = {
      [WE_LEAD]        = isScoreCompetition && 0.9 * my >= enemy,
      [ENEMY_LEAD]     = isScoreCompetition && my <= 0.9 * enemy,
      [WE_HALF]        = myTeamCanLoseByScore.get() && my <= 0.5,
      [ENEMY_HALF]     = enemyTeamCanLoseByScore.get() && enemy <= 0.5,
      [WE_LOW]         = myTeamCanLoseByScore.get() && my <= 0.1,
      [ENEMY_LOW]      = enemyTeamCanLoseByScore.get() && enemy <= 0.1,
    }
  }
}))
local prevState = state.get()

state.subscribe(function(newState) {
  if (newState.inited && prevState.inited && !debriefingShow.get())
    foreach (id, value in newState.list)
      if (value != prevState.list[id])
        warningUpdate(id, value)
  prevState = newState
})

debriefingShow.subscribe(@(_v) state.get().list.each(@(_, id) warningUpdate(id, false)))
