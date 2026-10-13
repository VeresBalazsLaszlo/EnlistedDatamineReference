import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontawesome
from "math" import fabs
from "%ui/hud/state/capZones.nut" import curCapZone
from "dagor.time" import get_time_msec
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *
from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG

const UPDATE_DELAY = 3000

const ADD_RADIUS = hdpx(25)
const LINE_WIDTH = hdpx(5)
const BASE_ANGLE = 15
const GAP_ANGLE = 2
const RADIUS = 50  
const Y_OFFSET = hdpx(5)
const CHAR_OFFSET = hdpx(10)
const MARKER_H = hdpx(14)
const MARKER_W = hdpx(8)

let inOutQuad = @(p) (p < 0.5) ? (2 * p * p) : (-2 * p * p + 4 * p - 1)

local curContSize = null
local curPlayerTeam = null
local prev = null
local char = null
local charCnt = 0

function getPresence(teamPresence, playerTeam){
  local alliesCount = 0
  local enemiesCount = 0
  foreach (teamId, soldierCount in (teamPresence ?? {})) {
    if (teamId.tointeger() == playerTeam) {
      alliesCount = soldierCount
    } else {
      enemiesCount = soldierCount
    }
  }
  return { alliesCount, enemiesCount }
}

function getAdvantageMiddle(weights, playerTeam) {
  local weightFriendly = 0
  local weightSum = 0
  foreach (teamId, weight in weights) {
    if (teamId.tointeger() == playerTeam)
      weightFriendly = weight.tofloat()
    weightSum += weight.tofloat()
  }
  return weightSum > 0 ? (weightFriendly / weightSum) : 0.5
}

function onZonePresenceChange(){

  if (curPlayerTeam != localPlayerTeam.get())
    curPlayerTeam = localPlayerTeam.get()

  
  if (curCapZone.get() == null){
    prev = null
    curContSize = null
    curPlayerTeam = null
    char = null
    charCnt = 0
    return
  }

  
  if (prev != null)
    return

  
  let initialPresence = getPresence(curCapZone.get().presenceTeamCount, curPlayerTeam)
  prev = {
    alliesCount = initialPresence.alliesCount
    enemiesCount = initialPresence.enemiesCount
    ts = get_time_msec()
    side = initialPresence.alliesCount > initialPresence.enemiesCount ? 1
      : initialPresence.alliesCount < initialPresence.enemiesCount ? -1 : 0
  }
}

curCapZone.subscribe(@(_) onZonePresenceChange())
localPlayerTeam.subscribe(@(_) onZonePresenceChange())

let plusAnim = [
  { prop=AnimProp.scale, from=[1.3,1.3], to=[1,1], duration=0.5, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=1, to=1, duration=0.7, delay = 0.3, play=true}
  { prop=AnimProp.opacity, from=1, to=0, duration=1, delay=1, play=true, easing=OutCubic, onFinish = @() char=null}
]

let minusAnim = [
  { prop=AnimProp.scale, from=[1.2,1.2], to=[1,1], duration=0.5, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0.7,0.7], duration=1.5, delay=0.5, play=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=1, to=1, duration=0.7, delay = 0.3, play=true}
  { prop=AnimProp.opacity, from=1, to=0, duration=1, delay=1, play=true, easing=OutCubic, onFinish = @() char=null}
]

function mkChar(charProps){
  let { side, sign } = charProps
  let offset = curContSize + CHAR_OFFSET
  let pos = [side == "allies" ? -offset : offset, curContSize/2*1.3]
  let color = side == "allies" ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
  let anim = sign == "plus" ? plusAnim : minusAnim
  let text = side == "allies" ? "".concat(fa[sign], fa["user"]) : "".concat(fa["user"], fa[sign])
  charCnt++

  return {
    key = charCnt
    rendObj = ROBJ_INSCRIPTION
    text
    color
    transform = const {pivot = [0.5,0.5]}
    pos
    animations = anim
    opacity = 0
  }.__update(fontawesome)
}

function mkCaptureWeights(alliesCount, enemiesCount, side, advantageMiddle, charProps = null){

  let sum = alliesCount + enemiesCount
  if (sum == 0)
    return null

  const minAngle = BASE_ANGLE
  const maxAngle = 180 - BASE_ANGLE
  let selfSize = curContSize + ADD_RADIUS*2
  let part = inOutQuad(enemiesCount.tofloat() / sum)
  let splitAngle = clamp(BASE_ANGLE + (180 - BASE_ANGLE * 2) * part, minAngle, maxAngle)
  const r = RADIUS

  let middleAngle = clamp(minAngle + (maxAngle-minAngle) * inOutQuad(advantageMiddle), minAngle, maxAngle)
  let middleGapMin = clamp(middleAngle - GAP_ANGLE, minAngle, maxAngle)
  let middleGapMax = clamp(middleAngle + GAP_ANGLE, minAngle, maxAngle)

  let rightSide = splitAngle == minAngle ?
    [
      const [VECTOR_COLOR, TEAM0_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, minAngle, middleGapMin]
    ]
  : splitAngle < middleAngle ?
    [
      const [VECTOR_COLOR, TEAM1_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, minAngle, splitAngle],
      const [VECTOR_COLOR, TEAM0_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, splitAngle, middleGapMin]
    ]
  : [
      const [VECTOR_COLOR, TEAM1_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, minAngle, middleGapMin]
    ]

  let leftSide = splitAngle <= middleAngle ?
    [
      const [VECTOR_COLOR, TEAM0_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, middleGapMax, maxAngle]
    ]
  : splitAngle < maxAngle ? [
      const [VECTOR_COLOR, TEAM1_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, middleGapMax, splitAngle],
      const [VECTOR_COLOR, TEAM0_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, splitAngle, maxAngle]
    ]
  : [
      const [VECTOR_COLOR, TEAM1_COLOR_FG],
      [VECTOR_SECTOR, r, r, r, r, middleGapMax, maxAngle]
    ]

  let marker = [
    const [VECTOR_COLOR, Color(0,0,0,0)],
    [VECTOR_FILL_COLOR, side == 0 ? 0xFFFFFF : side == -1 ? TEAM1_COLOR_FG : TEAM0_COLOR_FG],
    const [VECTOR_WIDTH, 0],
    const [VECTOR_POLY, r, r*2-MARKER_H, r+MARKER_W/2, r*2-MARKER_H/2, r, r*2, r-MARKER_W/2, r*2-MARKER_H/2]
  ]

  let children = [
    {
      rendObj = ROBJ_VECTOR_CANVAS
      flow = FLOW_HORIZONTAL
      size = selfSize
      pos = const [0, Y_OFFSET]
      commands = [
        const [VECTOR_FILL_COLOR, 0],
        const [VECTOR_WIDTH, LINE_WIDTH]
      ].extend(rightSide, leftSide)
    },
    {
      rendObj = ROBJ_VECTOR_CANVAS
      flow = FLOW_HORIZONTAL
      size = selfSize
      pos = const [0, Y_OFFSET]
      transform = {rotate=middleAngle-90}
      commands = [
        const [VECTOR_FILL_COLOR, 0],
        const [VECTOR_WIDTH, LINE_WIDTH]
      ].extend(marker)
    }
  ]

  if (charProps)
    char = mkChar(charProps)

  if (char)
    children.append(char)

  return children
}
let capzoneProgress = memoize(function(contSize){
  return function(){
    let res = {
      halign = ALIGN_CENTER
      key = curCapZone.get()?.eid
      watch = curCapZone
    }

    if (curCapZone.get() == null || prev == null)
      return res

    curContSize = contSize
    let { alliesCount, enemiesCount } = getPresence(curCapZone.get().presenceTeamCount, curPlayerTeam)
    let advantageMiddle = getAdvantageMiddle(curCapZone.get()?.advantageWeights ?? {}, curPlayerTeam)
    if (alliesCount == prev.alliesCount && enemiesCount == prev.enemiesCount)
      return res.__update({children = mkCaptureWeights(alliesCount, enemiesCount, prev.side, advantageMiddle)})


    let enemyCame = enemiesCount > 0 && prev.enemiesCount == 0
    let enemyGone = enemiesCount == 0 && prev.enemiesCount > 0
    let side = alliesCount > enemiesCount ? 1 : alliesCount < enemiesCount ? -1 : 0
    let prevSide = prev.alliesCount > prev.enemiesCount ? 1 : prev.alliesCount < prev.enemiesCount ? -1 : 0
    let ts = get_time_msec()
    let skipMinor = ts - prev.ts < UPDATE_DELAY
    if (side == prevSide && !(enemyCame || enemyGone) && skipMinor)
      return res.__update({children = mkCaptureWeights(alliesCount, enemiesCount, side, advantageMiddle)})


    local charProps
    let aD = fabs(alliesCount - prev.alliesCount)
    let eD = fabs(enemiesCount - prev.enemiesCount)
    let d = (alliesCount - enemiesCount) - (prev.alliesCount - prev.enemiesCount)
    if (enemyCame){
      charProps = const { side = "enemies", sign = "plus" }

    } else if (d > 0) {
      if (aD > eD)
        charProps = const { side = "allies", sign = "plus" }
      else
        charProps = const { side = "enemies", sign = "minus" }

    } else {
      if (aD > eD)
        charProps = const { side = "allies", sign = "minus" }
      else
        charProps = const { side = "enemies", sign = "plus" }
    }

    prev.alliesCount = alliesCount
    prev.enemiesCount = enemiesCount
    prev.side = side
    prev.ts = ts

    return res.__update({
      children = mkCaptureWeights(alliesCount, enemiesCount, side, advantageMiddle, charProps)
    })
  }
})

return capzoneProgress