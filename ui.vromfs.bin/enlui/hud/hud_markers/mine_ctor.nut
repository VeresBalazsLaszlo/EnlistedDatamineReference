from "dagor.math" import Point2
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/style/unit_colors.nut" import HUD_COLOR_TEAMMATE_OUTER
from "%ui/hud/state/mine_markers.nut" import mine_markers_Set, mine_markers_GetWatched
from "%ui/hud/huds/player_info/mineIcon.nut" import mineIcon
from "%ui/ui_library.nut" import *

let mineIconSize = [hdpxi(27), hdpxi(27)]
let mineTimerSize = [hdpxi(27), hdpxi(27)]
let mineIconMemo = memoize(@(typ, size) mineIcon(typ, size), 1)

function mkTimerIcon(state) {
  let timerEndtime = Computed(@() state.get().blockedToTime)
  let countDownTimer = mkCountdownTimer(timerEndtime)
  let curProgressW = Computed(@() state.get().installBlockTime > 0 ? countDownTimer.get() / state.get().installBlockTime : 0)
  let commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
  ]
  let sector = commands[1]
  curProgressW.subscribe(@(v) sector[6] = 360.0 * v)
  return @() {
    watch = curProgressW
    size = mineTimerSize
    lineWidth = mineTimerSize[0] * 0.3
    color = Color(255, 255, 255)
    fillColor = Color(122, 1, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    commands
  }
}

function mine(eid){
  let watch = mine_markers_GetWatched(eid)
  let timerIcon = mkTimerIcon(watch)
  return function(){
    let blockedByTimer = watch.get().blockedToTime >= 0
    let mineType = watch.get()?.type
    return {
      data = {
        eid
        minDistance = 0.1
        maxDistance = 10
        distScaleFactor = 0.5
        yOffs = blockedByTimer ? 0.2 : 0.1
        clampToBorder = false
        opacityRangeX = Point2(0.2, 0.2)
        opacityRangeY = Point2(0.2, 0.2)
      }
      rendObj = ROBJ_IMAGE
      color = HUD_COLOR_TEAMMATE_OUTER
      key = eid
      sortOrder = eid
      transform = true
      image = blockedByTimer ? null : mineIconMemo(mineType, mineIconSize[0])
      size = blockedByTimer ? mineTimerSize : mineIconSize
      watch

      children = blockedByTimer ? timerIcon : null
      markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mine)

return {
  mine_ctor = {watch = mine_markers_Set, ctor = @() memoizedMap(mine_markers_Set.get()).values()}
}