from "team" import TEAM_UNASSIGNED
from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG, TEAM0_COLOR_FG_TR, TEAM1_COLOR_FG_TR
from "%sqstd/math.nut" import lerp
from "net" import get_sync_time
from "%ui/ui_library.nut" import *

let animCapturing = [
  { prop=AnimProp.opacity, from=0.0, to=0.5, duration=0.6, play=true, loop=true, easing=CosineFull }
]

const NEUTRAL_TRANSP = Color(80,80,80,80)
const INACTIVATED_ZONE_FG = Color(160, 150, 120)
const CAPTURE_ZONE_BG = Color(80, 75, 50, 160)
const LOCK_ZONE_FG = Color(160, 160, 160, 160)

let defaultImage = Picture("ui/skin#circle_progress.avif")
let defendImage = Picture("ui/skin#icon_defend.avif")

function getCapZoneColors(capzone_data, hero_team) {
  let currentlyNoCap = capzone_data.capTeam == TEAM_UNASSIGNED || capzone_data.progress == 0.0
  let noLongerActive = !capzone_data.active && capzone_data.wasActive
  let teamCapturing = capzone_data.onlyTeamCanCapture

  let bgColor = teamCapturing == TEAM_UNASSIGNED
    ? (currentlyNoCap || !noLongerActive ? NEUTRAL_TRANSP : CAPTURE_ZONE_BG)
    : teamCapturing == hero_team ? TEAM1_COLOR_FG
      : TEAM0_COLOR_FG

  let fgColor = currentlyNoCap
    ? (noLongerActive ? INACTIVATED_ZONE_FG : NEUTRAL_TRANSP)
    : capzone_data.capTeam == hero_team
      ? (capzone_data.active ? TEAM0_COLOR_FG : TEAM0_COLOR_FG_TR)
      : (capzone_data.active ? TEAM1_COLOR_FG : TEAM1_COLOR_FG_TR)

  return { fgColor, bgColor }
}

function getZoneProgressIcon(capzone_data, hero_team, progress, size) {
  let { fgColor, bgColor } = getCapZoneColors(capzone_data, hero_team)
  let isDefendZone = capzone_data.attackTeam != TEAM_UNASSIGNED
    && capzone_data.bombPlantingTeam == TEAM_UNASSIGNED
    && capzone_data.attackTeam != hero_team
  return {
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = isDefendZone ? defendImage : defaultImage
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = const { pivot = [0.5, 0.5] }
    bgColor
    fgColor
    fValue = progress
  }
}

function getZoneProgress(zoneData) {
  let {progressEndTime=-1, progressPausedAt=-1, progressTotalTime=-1, progressIsPositive=1} = zoneData
  if (progressPausedAt >= 0)
    return progressPausedAt

  if (progressTotalTime <= 0 && progressEndTime < 0)
    return null

  let timeLeft = max(progressEndTime - get_sync_time(), 0)
  return progressIsPositive
    ? (1 - (timeLeft / progressTotalTime))
    : (timeLeft / progressTotalTime)
}

function getLockProgress(zoneData) {
  let {endLockTime=-1, unlockAfterTime=-1} = zoneData
  if (unlockAfterTime <= 0 && endLockTime < 0)
    return 1

  let timeLeft = max(endLockTime - get_sync_time(), 0)
  return timeLeft / unlockAfterTime
}

function mkGenericProgress(zoneData, heroTeam, iconSize, progress, isAnimationAvailable) {
  let zoneGeneric = getZoneProgressIcon(zoneData, heroTeam, progress, iconSize)
  if (!zoneData.isCapturing)
    return zoneGeneric

  let isHeroTeamCapturing = zoneData.curTeamCapturingZone == heroTeam
  let progressIndicator = zoneGeneric.__merge({
    key = {}
    rendObj = ROBJ_IMAGE
    color = isHeroTeamCapturing ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    animations = isAnimationAvailable ? animCapturing : null
  })

  zoneGeneric.children <- progressIndicator
  return zoneGeneric
}

function mkLockProgress(zoneData, heroTeam, iconSize, _progress, _is_animation_available) {
  let zoneGeneric = getZoneProgressIcon(zoneData, heroTeam, getLockProgress(zoneData), iconSize)
  return zoneGeneric.__update({
    behavior = Behaviors.RtPropUpdate
    fgColor = LOCK_ZONE_FG
    update = function() {
      this.fValue = getLockProgress(zoneData)
    }
  })
}

function mkTrainProgress(zoneData, heroTeam, iconSize, progress, isAnimationAvailable) {
  let hasConflict = zoneData.curTeamCapturingZone < TEAM_UNASSIGNED
  let zoneGeneric = getZoneProgressIcon(zoneData, heroTeam, progress, iconSize)
  if (zoneData.curTeamCapturingZone == heroTeam)
    zoneGeneric.fgColor = TEAM0_COLOR_FG
  else if (zoneData.curTeamCapturingZone > TEAM_UNASSIGNED || hasConflict)
    zoneGeneric.fgColor = TEAM1_COLOR_FG
  if (!hasConflict)
    return zoneGeneric

  let progressIndicator = zoneGeneric.__merge({
    key = {}
    rendObj = ROBJ_IMAGE
    color = TEAM0_COLOR_FG
    animations = isAnimationAvailable ? animCapturing : null
  })

  zoneGeneric.children <- progressIndicator
  return zoneGeneric
}

function mkBombProgress(zoneData, heroTeam, iconSize, progress, isAnimationAvailable) {
  let isHeroTeamPlanting = zoneData.bombPlantingTeam == heroTeam
  let zoneGeneric = getZoneProgressIcon(zoneData, heroTeam, 0, iconSize)
  zoneGeneric.__update({
    behavior = Behaviors.RtPropUpdate
    update = function() {
      let currentProgress = getZoneProgress(zoneData) ?? progress
      this.fValue = zoneData.isBombPlanted ? (1 - currentProgress) : currentProgress
    }
  })

  let progressIndicator = zoneGeneric.__merge({
    key = {}
    fgColor = isHeroTeamPlanting ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    animations = zoneData.isBombPlanted && isAnimationAvailable ? animCapturing : null
  })

  zoneGeneric.children <- progressIndicator
  return zoneGeneric
}

function mkProgress(zoneData, heroTeam, iconSize, isAnimationAvailable = true) {
  let { progress, trainZone, locked, bombPlantingTeam } = zoneData
  let isBombZone = bombPlantingTeam > -1
  let progressCtor = locked ? mkLockProgress
    : isBombZone ? mkBombProgress
    : zoneData.trainZone ? mkTrainProgress
    : mkGenericProgress

  local progressValue = 0
  if (trainZone)
    progressValue = 1
  else if (progress >= 1.0)
    progressValue = 1
  else if (progress > 0.0)
    progressValue = lerp(0, 1, 0.015, 0.985, progress)

  return progressCtor(zoneData, heroTeam, iconSize, progressValue, isAnimationAvailable)
}

return mkProgress
