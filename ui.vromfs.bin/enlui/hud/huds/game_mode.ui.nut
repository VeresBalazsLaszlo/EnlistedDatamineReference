import "%ui/components/fontawesome.map.nut" as fa
import "%ui/hud/style.nut" as style
import "%ui/hud/huds/gun_game.game_mode.ui.nut" as gunGameModeUI
import "%ui/hud/state/scoring_players.nut" as scoringPlayers
import "%ui/components/mkAnimatedPointsUi.nut" as mkPointsUi
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontawesome
from "team" import TEAM_UNASSIGNED
from "%ui/hud/state/capZones.nut" import capZones, curCapZone, trainZoneEid, nextTrainCapzoneEid, trainCapzoneProgress, visibleZoneGroups, whichTeamAttack, isTwoChainsCapzones
from "%ui/hud/components/capzone.nut" import capzoneWidget, capzoneGap
from "%ui/hud/state/team_scores.nut" import myScore, enemyScore, myScoreBleed, myScoreBleedFast, enemyScoreBleed, enemyScoreBleedFast, failTimerShowTime
  , anyTeamFailTimer, myTeamFailTimer, enemyTeamFailTimer
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid
from "%ui/hud/state/zombie_mode.nut" import isZombieMode, zombieModeCurWave, zombieModeHeroPoints, zombiesNextWaveTime
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/hud/state/gun_game_state.nut" import isGunGameMode
from "%ui/style/designConst.nut" import scoreNestGradientR, scoreNestGradientL
from "%ui/ui_library.nut" import *

const GAP_RATIO = 0.4 

let teamScoreBlink = @(trigger) [{ prop = AnimProp.opacity, from = 0.8, to = 1.0, trigger = trigger, easing = InCubic, duration = 0.5}]
let myTeamScoreBlinkAnim = teamScoreBlink("myTeamScoreChanged")
let enemyTeamScoreBlinkAnim = teamScoreBlink("enemyTeamScoreChanged")

myScore.subscribe(@(_v) anim_start("myTeamScoreChanged"))
enemyScore.subscribe(@(_v) anim_start("enemyTeamScoreChanged"))


let mkText = @(txt, override = {}) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(override)

let hasScoreBar = Computed(@() isTwoChainsCapzones.get() || whichTeamAttack.get() != -1
  || ((myScore.get() ?? 0) != 0 && (enemyScore.get() ?? 0) != 0))

let mkScoreTeam = @(params) function() {
  let score = params.score.get()
  return {
    color = Color(200,100,10)
    size = const [FLEX, fsh(0.5)]
    watch = params.score
    children = score != null
      ? {
          rendObj = ROBJ_PROGRESS_LINEAR
          size = FLEX
          fgColor = params.fgColor
          bgColor = params.bgColor
          fValue = params.fValueMul * score
        }
      : null
    animations = params.anim
  }
}

let scoreTeam1 = mkScoreTeam({
  fgColor = style.TEAM0_COLOR_FG
  bgColor = style.TEAM0_COLOR_BG
  fValueMul = -1
  score = myScore
  anim = myTeamScoreBlinkAnim
})

let scoreTeam2 = mkScoreTeam({
  fgColor = style.TEAM1_COLOR_FG
  bgColor = style.TEAM1_COLOR_BG
  fValueMul = 1
  score = enemyScore
  anim = enemyTeamScoreBlinkAnim
})


let mkScoreBleed = @(params) @() {
  watch = [params.bleed, params.bleedFast]
  size = const [SIZE_TO_CONTENT, hdpx(18)]
  valign = ALIGN_CENTER
  children = params.bleed.get()
    ? {
        rendObj = ROBJ_INSCRIPTION
        fontSize = params.bleedFast.get() ? hdpx(9) : hdpx(16)
        color = params.dirColor
        font = fontawesome.font
        text = params.bleedFast.get() ? params.dirFast : params.dirSlow
        validateStaticText = false
      }
    : null
}

let scoreBleedTeam1 = mkScoreBleed({
  bleed = myScoreBleed
  bleedFast = myScoreBleedFast
  dirColor = style.TEAM0_COLOR_FG
  dirSlow = fa["long-arrow-right"]
  dirFast = $"{fa["forward"]}{fa["forward"]}"
})

let scoreBleedTeam2 = mkScoreBleed({
  bleed = enemyScoreBleed
  bleedFast = enemyScoreBleedFast
  dirColor = style.TEAM1_COLOR_FG
  dirSlow = fa["long-arrow-left"]
  dirFast = $"{fa["backward"]}{fa["backward"]}"
})

let team1 = {
  flow = FLOW_VERTICAL
  halign = ALIGN_LEFT
  size = const [FLEX, fsh(0.5)]
  children = [
    scoreTeam1
    scoreBleedTeam1
  ]
}

let team2 = {
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  size = const [FLEX, fsh(0.5)]
  children = [
    scoreTeam2
    scoreBleedTeam2
  ]
}

let teamScores = {
  size = const [sw(25), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    team1
    team2
  ]
}

function capZonesBlock() {
  let groups = visibleZoneGroups.get()
  let total = groups.reduce(@(res, g) res + g.len(), 0)
    + max(groups.len() - 1, 0) * GAP_RATIO
  let children = []
  local offset = 0.0
  foreach (idx, zList in groups) {
    if (idx != 0) {
      children.append(capzoneGap)
      offset += GAP_RATIO
    }
    foreach (zoneEid in zList) {
      children.append(
        capzoneWidget(zoneEid,
          {
            showDistance = false
            idx = offset
            total
          })
      )
      offset += 1.0
    }
  }

  return {
    watch = visibleZoneGroups
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children
  }
}

let isMyTeamAttacking = Computed(@() localPlayerTeam.get() == whichTeamAttack.get())
let trainCapzone = Computed(@() capZones.get()?[trainZoneEid.get()])

const escortPointsBlockLength = sw(20)
let escortPointSize = [hdpxi(8), hdpxi(8)]
const escortLineHeight = fsh(0.8*0.85)
let trainMarkerSize = [hdpxi(74), hdpxi(24)]
const INACTIVATED_TRAIN_COLOR = Color(90, 90, 90)
const PATH_COLOR_BG = Color(50, 50, 50, 150)

let mkTrainIcon = @(image, color) {
  size = trainMarkerSize
  color
  rendObj = ROBJ_IMAGE
  image
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

let mkTrainMarkerMovement = @(color) mkTrainIcon(
  Picture("ui/skin#train/train_move.svg:{0}:{1}".subst(trainMarkerSize[0], trainMarkerSize[1])),
  color
)
let trainCursor = mkTrainIcon(
  Picture("ui/skin#train/train_cursor.svg:{0}:{1}".subst(trainMarkerSize[0], trainMarkerSize[1])),
  INACTIVATED_TRAIN_COLOR
)
let mkTrainMarker = @(color) mkTrainIcon(
  Picture("ui/skin#train/train_marker.svg:{0}:{1}".subst(trainMarkerSize[0], trainMarkerSize[1])),
  color
)
let trainMarkerConflict = mkTrainMarker(style.TEAM0_COLOR_FG).__merge({
  animations = [{ prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull}]
})

let mkEscortProgress = @(offset, lineLength) function(){
  let progressOffset = offset + lineLength * trainCapzoneProgress.get()
  let curTeamCapturingTrain = trainCapzone.get()?.curTeamCapturingZone ?? TEAM_UNASSIGNED
  let isTrainMoving = curTeamCapturingTrain != TEAM_UNASSIGNED && curTeamCapturingTrain == (trainCapzone.get()?.trainOffenseTeam ?? TEAM_UNASSIGNED)
  let color = curTeamCapturingTrain == TEAM_UNASSIGNED
    ? INACTIVATED_TRAIN_COLOR
    : curTeamCapturingTrain == localPlayerTeam.get() ? style.TEAM0_COLOR_FG : style.TEAM1_COLOR_FG
  let conflictMarker = curTeamCapturingTrain < TEAM_UNASSIGNED
    ? trainMarkerConflict.__merge({ key = curTeamCapturingTrain })
    : null
  return {
    watch = [trainCapzoneProgress, trainCapzone, localPlayerTeam]
    children = [
      mkTrainMarker(color),
      conflictMarker,
      isTrainMoving ? mkTrainMarkerMovement(color) : null,
      trainCursor
    ]
    valign = ALIGN_BOTTOM
    transform = {
      translate = [progressOffset - trainMarkerSize[0]*0.5, 0.0]
    }
  }
}

function mkEscortZoneLine(offset, lineLength, color, progress) {
  let size = [lineLength - escortPointSize[0], escortLineHeight]
  return @() {
    watch = progress.watch
    size
    rendObj = ROBJ_MASK
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    image = Picture("ui/skin#train/segment_way.svg:{0}:{1}".subst(size[0].tointeger(),size[1].tointeger()))
    children = {
      size = [lineLength,escortLineHeight]
      rendObj = ROBJ_PROGRESS_LINEAR
      fgColor = color
      bgColor = PATH_COLOR_BG
      fValue = progress.watch?.get() ?? progress.value
    }
    transform = {translate=[offset + escortPointSize[0] * 0.5,0]}
  }
}

let pathPointImage = Picture("ui/skin#train/train_point.svg:{0}:{1}".subst(escortPointSize[0], escortPointSize[1]))
let pathPointStartImage = Picture("ui/skin#train/train_start.svg:{0}:{1}".subst(escortPointSize[0], escortPointSize[1]))

let mkEscortZonePoint = @(offset, image, color) {
  size = escortPointSize
  color
  rendObj = ROBJ_IMAGE
  image
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = {translate=[offset - escortPointSize[0] * 0.5, 0]}
}

let mkEscortZoneWidget = @(offset, lineLength, lineColor, pointColor, progress) {
  children = [mkEscortZoneLine(offset-lineLength, lineLength, lineColor, progress), mkEscortZonePoint(offset, pathPointImage, pointColor)]
  valign = ALIGN_CENTER
}

let mkEscortStartPoint = @(color) mkEscortZonePoint(0, pathPointStartImage, color).__merge({valign=ALIGN_CENTER})

let trainPathCapzones = Computed(function() {
  let res = []
  foreach (_idx, zList in visibleZoneGroups.get())
    foreach (zoneEid in zList)
      if (capZones.get()?[zoneEid].trainTriggerable)
        res.append(zoneEid)
  return res
})

let wasMyTeamAttacking = Watched(false)
isMyTeamAttacking.subscribe(function(v) {
  if (v)
    wasMyTeamAttacking.set(true)
})

function escortBlock() {
  let colorStart = wasMyTeamAttacking.get() ? style.TEAM0_COLOR_FG : style.TEAM1_COLOR_FG
  let colorEnd = wasMyTeamAttacking.get() ? style.TEAM1_COLOR_FG : style.TEAM0_COLOR_FG
  let escortPoints = [mkEscortStartPoint(colorStart)]
  let pointCount = trainPathCapzones.get().len()
  local index = 1
  let lineLength = pointCount > 0 ? escortPointsBlockLength / pointCount : escortPointsBlockLength
  local progressOffset = 0

  local isPastCapture = trainPathCapzones.get() == ecs.INVALID_ENTITY_ID
  foreach (zoneEid in trainPathCapzones.get()) {
    let offset = index * lineLength
    if (zoneEid == nextTrainCapzoneEid.get()) {
      progressOffset = offset - lineLength
      isPastCapture = true
    }
    let lineColor = isPastCapture && (zoneEid != nextTrainCapzoneEid.get()) ? PATH_COLOR_BG : colorStart
    let pointColor = isPastCapture ? colorEnd : colorStart
    let progress = {
      watch = (zoneEid == nextTrainCapzoneEid.get()) ? trainCapzoneProgress : null
      value = isPastCapture ? 0.0 : 1.0
    }
    escortPoints.append(mkEscortZoneWidget(offset, lineLength, lineColor, pointColor, progress))
    ++index
  }

  let escortProgress = mkEscortProgress(progressOffset, lineLength)
  let points = {
    size = FLEX_H
    children = escortPoints
  }
  return {
    watch = [trainPathCapzones, nextTrainCapzoneEid, wasMyTeamAttacking, trainCapzone,
      localPlayerTeam]
    flow = FLOW_VERTICAL
    gap = hdpx(1)
    children = [escortProgress, points]
    size = const [escortPointsBlockLength, SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
  }
}

let capZoneOnTrainBlock = @() {
  watch = [trainZoneEid, curCapZone]
  children = curCapZone.get()?.eid == trainZoneEid.get()
    ? capzoneWidget(trainZoneEid.get(), const { showDistance = false, total = 1 })
    : null
}

let makeFailTimer = @(endTimeWatch) function(){
  let timeIsRunningOut = endTimeWatch.get() < 10
  let shouldShow = endTimeWatch.get() > 0 && endTimeWatch.get() <= failTimerShowTime
  return {
    watch = endTimeWatch
    margin = const [hdpx(4), 0]
    children = shouldShow
      ? {
          rendObj = ROBJ_TEXT
          color = timeIsRunningOut ? Color(155, 0, 0, 95) : Color(155, 155, 155, 95)
          text = secondsToStringLoc(endTimeWatch.get())
        }.__update(timeIsRunningOut ? fontHeading2 : fontBody)
      : null
  }
}

let failTimerBlock = makeFailTimer(anyTeamFailTimer)
let myTeamFailTimerBlock = makeFailTimer(myTeamFailTimer)
let enemyTeamFailTimerBlock = makeFailTimer(enemyTeamFailTimer)


let scoreToPoints = @(score) score == null ? null : (1000.0 * score + 0.5).tointeger()

let attackerScoreWatch = Computed(function() {
  return scoreToPoints(isMyTeamAttacking.get() ? myScore.get() : enemyScore.get())
})

let teamPoints = mkPointsUi("teamPoints", "ui/skin#initial_squad_size.svg",
  isMyTeamAttacking, attackerScoreWatch)


let modeDomination = @() {
  watch = hasScoreBar
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = fsh(1)
  children = [
    hasScoreBar.get() ? teamScores : null
    {
      flow = FLOW_HORIZONTAL
      children=[
        {size = 0 children = myTeamFailTimerBlock, halign = ALIGN_RIGHT},
        capZonesBlock,
        {size = 0 children = enemyTeamFailTimerBlock, halign = ALIGN_LEFT},
        {size = 0 children = failTimerBlock, halign = ALIGN_LEFT}
      ]
    }
  ]
}


const zombieWaveColor = 0xFFFF5577

function modeZombieWaveUi() {
  let hasTimer = zombiesNextWaveTime.get() > 0
  return {
    watch = [ zombieModeCurWave, zombiesNextWaveTime ]
    size = const [hdpx(180), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    padding = const [fsh(1.1), fsh(2)]
    margin = fsh(1.5)
    rendObj = ROBJ_IMAGE
    image = scoreNestGradientL
    color = 0xFF000000
    children = mkText(loc("zombieMod/curWave", {
      count = zombieModeCurWave.get() + (hasTimer ? 0 : 1)
    }), { color = zombieWaveColor }.__merge(fontBody))
  }
}


function modeZombieWaveTimerUi() {
  let timerVal = zombiesNextWaveTime.get()
  let hasTimer = timerVal > 0
  return {
    watch = zombiesNextWaveTime
    size = const [SIZE_TO_CONTENT, hdpx(60)]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = hasTimer
      ? mkText(loc("zombieMod/nextWaveTime", {
          count = secondsToStringLoc(zombiesNextWaveTime.get())
        }), fontBody)
      : null
  }
}

let zombieKillCounter = Computed(@()
  scoringPlayers.get()?[localPlayerEid.get()].scoring_player__zombieKills ?? 0)
let zombieHeroPointsUi = mkPointsUi("zombieModScore", "ui/skin#events/statistics_halloween_icon.svg",
  Watched(true), zombieModeHeroPoints)
let zombieKillCounterUi = mkPointsUi("killCounter", "ui/skin#statistics_kills_icon.svg",
  Watched(true), zombieKillCounter)

function mkModeZombie() {
  return {
    size = const [sw(100), SIZE_TO_CONTENT]
    padding = const [0, fsh(2)]
    children = [
      modeZombieWaveUi
      modeZombieWaveTimerUi
      {
        size = const [hdpx(180), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        hplace = ALIGN_RIGHT
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        padding = const [fsh(1), fsh(2)]
        margin = fsh(1.5)
        rendObj = ROBJ_IMAGE
        image = scoreNestGradientR
        color = 0xFF000000
        children = [
          zombieHeroPointsUi
          zombieKillCounterUi
        ]
      }
    ]
  }
}


let hasBothSidesPoints = Computed(@() capZones.get().findindex(@(zone) zone?.bothSidesPoints) != null)

let modeInvasion = {
  flow = FLOW_VERTICAL
  gap = fsh(1)
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = hasBothSidesPoints
      children = hasBothSidesPoints.get() ? teamScores : null
    }
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      gap = fsh(1)
      children = [
        @() {
          watch = hasBothSidesPoints
          size = 0
          halign = ALIGN_RIGHT
          children = hasBothSidesPoints.get() ? null : teamPoints
        }
        {
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          gap = fsh(1)
          children = [ capZonesBlock, failTimerBlock ]
        }
      ]
    }
  ]
}


let modeEscort = @() {
  valign = ALIGN_BOTTOM
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
      children = [
      {size = const [0,SIZE_TO_CONTENT], children = teamPoints, halign = ALIGN_RIGHT, padding = const [0, fsh(3)]}
        {
          padding = [0,0,hdpx(16) - escortPointSize[1]/2,0] 
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          children = [escortBlock]
        }
        {size = const [0,SIZE_TO_CONTENT], children = failTimerBlock, halign = ALIGN_LEFT, padding = const [0, fsh(3)]}
      ]
    },
    {
      hplace = ALIGN_CENTER
      children = capZoneOnTrainBlock
    }
  ]
}


let isDominationMode = Computed(@() whichTeamAttack.get() < 0)
let isEscortMode = Computed(@() capZones.get().findindex(@(zone) zone?.trainZone) != null)


let gameModeBlock = @() {
  watch = [isDominationMode, isGunGameMode, isZombieMode]
  hplace = ALIGN_CENTER
  children = isGunGameMode.get() ? gunGameModeUI
           : isZombieMode.get() ? mkModeZombie()
           : isEscortMode.get() ? modeEscort
           : isDominationMode.get() ? modeDomination
           : modeInvasion
}

return gameModeBlock
