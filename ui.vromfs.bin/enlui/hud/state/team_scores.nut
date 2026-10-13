import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%sqstd/frp.nut" import subscribeList
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/state/hero_squad.nut" import heroSquadNumAliveMembers
from "%ui/hud/state/warnings.nut" import warningUpdate, addWarnings
from "%sqstd/timers.nut" import debounce
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/ui_library.nut" import *
from "dasevents" import SessionTimerEnd

let { WARNING_PRIORITIES } = require("%ui/hud/state/warnings.nut")


let teamScoresByEid = mkEcsComputedEidMap({
  comps = [
    ["team__score", ecs.TYPE_FLOAT],
    ["team__squadSpawnCost", ecs.TYPE_INT, 0],
    ["team__failEndTime", ecs.TYPE_FLOAT, 0.0],
    ["team__capzoneTimerEndTime", ecs.TYPE_FLOAT, -1.0],
    ["team__scoreCap", ecs.TYPE_FLOAT],
    ["team__haveScores", ecs.TYPE_BOOL, true],
    ["score_bleed__domBleed", ecs.TYPE_FLOAT, 0.0],
    ["score_bleed__domBleedOn", ecs.TYPE_BOOL],
    ["score_bleed__totalDomBleedOn", ecs.TYPE_BOOL],
    ["team__id", ecs.TYPE_INT],
  ]
})

let myTeamCanFailByTime = mkWatched(persist, "myTeamCanFailByTime", false)
let canIncreaseScore = mkWatched(persist, "canIncreaseScore", false)

addWarnings({
  waitTeamScores = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10, locId = "respawn/no_spawn_scores" }
  zeroScoreFailTimer     = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10 },
  scoreIsLow             = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
  scoreIsHalf            = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
})

const failTimerShowTime = 180

let myScore = Watched(0)
let myTeamFailTime = Watched(0)
let myScoreBleed = Watched(0)
let myScoreBleedFast = Watched(0)
let myTeamCanLoseByScore = Watched(false)

let enemyScore = Watched(0)
let enemyTeamFailTime = Watched(0)
let enemyScoreBleed = Watched(0)
let enemyScoreBleedFast = Watched(0)
let enemyTeamCanLoseByScore = Watched(false)
let roundEndTime = Watched(-1)

let failEndTime = Computed(function(){
  let teamsFailTime = enemyTeamFailTime.get() > 0 && (myTeamFailTime.get() <= 0 || myTeamFailTime.get() > enemyTeamFailTime.get())
    ? enemyTeamFailTime.get()
    : myTeamFailTime.get()
  return teamsFailTime > 0 ?
    roundEndTime.get() > 0 ?
    min(teamsFailTime, roundEndTime.get()) :
    teamsFailTime : roundEndTime.get()
})

let paramsBySideMap = {
  my = {
    score      = myScore
    bleed      = myScoreBleed
    bleedFast  = myScoreBleedFast
    canLoseByScore = myTeamCanLoseByScore
  }
  enemy = {
    score      = enemyScore
    bleed      = enemyScoreBleed
    bleedFast  = enemyScoreBleedFast
    canLoseByScore = enemyTeamCanLoseByScore
  }
}

local isShownZeroScoreWarn = false
function updateScoreWarning() {
  let isMySquadDead = heroSquadNumAliveMembers.get() == 0
  let needZeroScoreWarn = !isMySquadDead && failEndTime.get() > 0 && myTeamCanFailByTime.get()
  if (needZeroScoreWarn != isShownZeroScoreWarn) {
    warningUpdate("zeroScoreFailTimer", needZeroScoreWarn)
    isShownZeroScoreWarn = needZeroScoreWarn
  }
  warningUpdate("waitTeamScores", isMySquadDead && myTeamCanFailByTime.get() && canIncreaseScore.get())
}

let updateScoreWarningDeb = debounce(@() updateScoreWarning(), 0.1)
subscribeList(updateScoreWarningDeb, failEndTime, heroSquadNumAliveMembers, myTeamCanFailByTime, canIncreaseScore)


local scoreIsLowTriggered = false
local scoreIsHalfTriggered = false
function setScoreParams(teamScores, side) {
  local normScore
  normScore = teamScores["team__scoreCap"] > 0 ? teamScores["team__score"] / teamScores["team__scoreCap"].tofloat() : null
  paramsBySideMap[side].score.set(normScore)
  paramsBySideMap[side].canLoseByScore.set(teamScores["team__squadSpawnCost"] > 0 || teamScores["score_bleed__domBleed"] > 0)

  if (teamScores["team__scoreCap"] > 0 && teamScores["team__squadSpawnCost"] > 0 && side == "my") {
    let needWarnLow = normScore <= 0.15
    let needWarnHalf = normScore <= 0.5
    if (scoreIsLowTriggered != needWarnLow) {
      warningUpdate("scoreIsLow", needWarnLow && !scoreIsLowTriggered)
      scoreIsLowTriggered = needWarnLow
    }
    if (scoreIsHalfTriggered != needWarnHalf) {
      warningUpdate("scoreIsHalf", needWarnHalf  && !needWarnLow && !scoreIsHalfTriggered)
      scoreIsHalfTriggered = needWarnHalf
    }
  }
}

function setBleedParams(teamScores, side) {
  paramsBySideMap[side].bleed.set(teamScores["score_bleed__domBleedOn"])
  paramsBySideMap[side].bleedFast.set(teamScores["score_bleed__domBleedOn"] && teamScores["score_bleed__totalDomBleedOn"])
}

function setFailTime(_ = null){
  foreach (teamScores in teamScoresByEid.get()) {
    if (!teamScores["team__haveScores"])
      continue
    local endTime = -1

    if (teamScores.team__capzoneTimerEndTime > 0 && (endTime < 0 || endTime > teamScores.team__capzoneTimerEndTime))
      endTime = teamScores.team__capzoneTimerEndTime
    let teamTime = teamScores["team__failEndTime"]
    if (teamTime > 0 && (endTime < 0 || endTime > teamTime))
      endTime = teamTime

    let side = (teamScores["team__id"] == localPlayerTeam.get()) ? "my" : "enemy"
    if (side == "my") {
      myTeamCanFailByTime.set(teamTime > 0)
      myTeamFailTime.set(endTime)
      canIncreaseScore.set(teamScores["team__scoreCap"] > 0)
    } else {
      enemyTeamFailTime.set(endTime)
    }

    setScoreParams(teamScores, side)
    setBleedParams(teamScores, side)
  }
}

subscribeList(setFailTime, localPlayerTeam, teamScoresByEid)

ecs.register_es("round_end_timer_init",
  {
    [SessionTimerEnd] = @(evt, _, _) roundEndTime.set(evt.time)
    onInit = @(_, comp) roundEndTime.set(comp.session_timer__time_end)
  },
  { comps_ro = [["session_timer__time_end", ecs.TYPE_FLOAT]]}
)

return {
  anyTeamFailTimer = mkCountdownTimerPerSec(failEndTime)
  failTimerShowTime
  myScore
  myScoreBleed
  myScoreBleedFast
  myTeamCanLoseByScore
  enemyScore
  enemyScoreBleed
  enemyScoreBleedFast
  enemyTeamCanLoseByScore
  myTeamFailTimer = mkCountdownTimerPerSec(myTeamFailTime)
  enemyTeamFailTimer = mkCountdownTimerPerSec(enemyTeamFailTime)
}